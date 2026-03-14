import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/managers/mode_manager.dart';
import 'application/controllers/gallery_controller.dart';
import 'domain/models/browse_mode.dart';
import 'domain/models/image_item.dart';
import 'domain/models/image_format.dart';
import 'domain/repositories/image_repository.dart';
import 'domain/repositories/image_repository_impl.dart';
import 'infrastructure/cache/cache_manager.dart';
import 'infrastructure/repositories/state_repository.dart';
import 'infrastructure/services/file_system_service.dart';
import 'infrastructure/services/file_system_service_impl.dart';
import 'infrastructure/platform/platform_integration_factory.dart';
import 'infrastructure/platform/macos_platform_integration.dart';
import 'infrastructure/platform/permission_manager.dart';
import 'presentation/views/waterfall_view.dart';
import 'presentation/views/single_image_viewer.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/theme/theme_manager.dart';
import 'core/errors/errors.dart';
import 'core/logging/logging.dart';

void main() {
  // Run app with error handling (ensureInitialized is called inside the zone)
  runAppWithErrorHandling(const ImageGalleryAppWrapper());
}

/// Wrapper widget to initialize app
class ImageGalleryAppWrapper extends StatefulWidget {
  const ImageGalleryAppWrapper({super.key});

  @override
  State<ImageGalleryAppWrapper> createState() => _ImageGalleryAppWrapperState();
}

class _ImageGalleryAppWrapperState extends State<ImageGalleryAppWrapper> {
  AppInitializer? _initializer;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final initializer = AppInitializer();
      await initializer.initialize();
      
      setState(() {
        _initializer = initializer;
        _isInitialized = true;
      });
    } catch (e, stackTrace) {
      Logger().error('Failed to initialize app', e, stackTrace);
      setState(() {
        _errorMessage = '应用初始化失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(_errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isInitialized = false;
                    });
                    _initializeApp();
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _initializer == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return ImageGalleryApp(initializer: _initializer!);
  }
}

/// Handles application initialization
/// 
/// Responsibilities:
/// - Initialize database and cache
/// - Set up platform integration
/// - Detect and recover from crashes
/// - Determine initial browse mode from launch arguments
class AppInitializer {
  late final SharedPreferences _prefs;
  late final StateRepository _stateRepository;
  late final CacheManager _cacheManager;
  late final FileSystemService _fileSystemService;
  late final ImageRepository _imageRepository;
  late final ModeManager _modeManager;
  late final CrashRecoveryManager _crashRecoveryManager;
  late final PermissionManager _permissionManager;
  late final ThemeManager _themeManager;
  late final Logger _logger;

  SharedPreferences get prefs => _prefs;
  ThemeManager get themeManager => _themeManager;
  StateRepository get stateRepository => _stateRepository;
  CacheManager get cacheManager => _cacheManager;
  FileSystemService get fileSystemService => _fileSystemService;
  ImageRepository get imageRepository => _imageRepository;
  ModeManager get modeManager => _modeManager;
  PermissionManager get permissionManager => _permissionManager;

  /// Initialize all application services
  Future<void> initialize() async {
    _logger = Logger();

    // Initialize logger first
    await _logger.initialize(
      enableConsole: true,
      enableFile: true,
    );
    _logger.info('Application starting...');

    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Initialize crash recovery manager
    _crashRecoveryManager = CrashRecoveryManager();
    await _crashRecoveryManager.initialize();

    // Check for crash and recover state if needed
    final didCrash = await _crashRecoveryManager.didCrashLastTime();
    if (didCrash) {
      _logger.warning('Detected crash from previous session, recovering state...');
      
      // Check if in crash loop
      if (await _crashRecoveryManager.isInCrashLoop()) {
        _logger.fatal('App is in crash loop, performing recovery');
        await _crashRecoveryManager.handleCrashLoop();
      }
    }

    // Mark app as started (for crash detection)
    await _crashRecoveryManager.markAppStarted();

    // Initialize state repository
    _stateRepository = StateRepository(_prefs);
    await _stateRepository.initialize();

    // Initialize cache manager
    _cacheManager = CacheManager();

    // Initialize file system service
    _fileSystemService = FileSystemServiceImpl();

    // Initialize permission manager
    _permissionManager = PermissionManager();

    // Initialize theme manager
    _themeManager = ThemeManager(_prefs);

    // Request permissions on mobile platforms
    if (Platform.isAndroid || Platform.isIOS) {
      _logger.info('Requesting image access permissions...');
      final hasPermission = await _permissionManager.requestImageAccessPermission();
      if (!hasPermission) {
        _logger.warning('Image access permission denied');
        // Continue anyway - user can grant permission later
      } else {
        _logger.info('Image access permission granted');
      }
    }

    // Initialize image repository
    _imageRepository = ImageRepositoryImpl(
      fileSystemService: _fileSystemService,
      stateRepository: _stateRepository,
    );

    // Initialize mode manager with launch arguments
    _modeManager = ModeManager();
    final launchArgs = await _getLaunchArguments();
    _modeManager.initializeMode(launchArgs);

    _logger.info('App initialized successfully');
    _logger.info('Browse mode: ${_modeManager.currentMode}');
    if (_modeManager.associatedFilePath != null) {
      _logger.info('Associated file: ${_modeManager.associatedFilePath}');
    }
    
    // Reset crash count on successful initialization
    await _crashRecoveryManager.resetCrashCount();
  }

  /// Get launch arguments from platform
  Future<List<String>> _getLaunchArguments() async {
    try {
      final platformIntegration = PlatformIntegrationFactory.create();
      return await platformIntegration.getLaunchArguments();
    } catch (e, stackTrace) {
      _logger.warning('Failed to get launch arguments', e, stackTrace);
    }
    return [];
  }

  /// Mark app as closed normally (call on app lifecycle events)
  Future<void> markAppClosedNormally() async {
    await _crashRecoveryManager.markAppClosedNormally();
  }
  
  /// Save current state for crash recovery
  Future<void> saveCurrentState(Map<String, dynamic> state) async {
    await _crashRecoveryManager.saveState(state);
  }
}

/// Main application widget
class ImageGalleryApp extends StatelessWidget {
  final AppInitializer initializer;

  const ImageGalleryApp({
    super.key,
    required this.initializer,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide ModeManager
        ChangeNotifierProvider<ModeManager>.value(
          value: initializer.modeManager,
        ),
        // Provide GalleryController
        ChangeNotifierProvider<GalleryController>(
          create: (_) => GalleryController(
            repository: initializer.imageRepository,
            cacheManager: initializer.cacheManager,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Image Gallery Viewer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AppHome(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Home widget that handles routing based on browse mode
/// 
/// Requirements: 12.1, 13.1, 13.2, 13.5, 13.6
class AppHome extends StatefulWidget {
  const AppHome({super.key});

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> with WidgetsBindingObserver {
  // open with 模式下，关闭详情页后显示文件夹瀑布流
  bool _showFolderWaterfall = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer initialization until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
      _setupFileOpenedListener();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes for crash detection
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App is being closed or backgrounded
      // Note: In a real implementation, we'd mark app as closed normally
    }
  }

  /// 监听 app 已运行时通过 open with 打开的文件（热启动场景）
  void _setupFileOpenedListener() {
    if (!Platform.isMacOS) return;
    final platformIntegration = PlatformIntegrationFactory.create();
    if (platformIntegration is MacOSPlatformIntegration) {
      platformIntegration.listenForOpenedFiles((filePath) async {
        if (!mounted) return;
        print('[AppHome] fileOpened received: $filePath');
        final galleryController = context.read<GalleryController>();
        final modeManager = context.read<ModeManager>();
        // 先加载文件夹图片，再切换模式，避免 UI 闪烁
        final folder = File(filePath).parent.path;
        await galleryController.loadFolderImagesForViewer(folder);
        if (mounted) {
          modeManager.switchToFileAssociation(filePath);
        }
      });
    }
  }

  /// Initialize app based on browse mode
  Future<void> _initializeApp() async {
    final modeManager = context.read<ModeManager>();
    final galleryController = context.read<GalleryController>();

    print('[DEBUG] Initializing app, mode: ${modeManager.currentMode}');

    if (modeManager.currentMode == BrowseMode.fileAssociation) {
      // 冷启动时 getLaunchArguments 成功拿到文件（兼容路径）
      final filePath = modeManager.associatedFilePath;
      if (filePath != null) {
        print('[DEBUG] Cold launch fileAssociation: $filePath');
        final folder = File(filePath).parent.path;
        await galleryController.loadFolderImagesForViewer(folder);
      }
    } else {
      // systemBrowse 模式（包括冷启动 getLaunchArguments 返回空的情况）
      // 热启动的 open with 会通过 fileOpened push 来切换
      print('[DEBUG] Loading system images...');
      await galleryController.loadSystemImages();
      print('[DEBUG] System images loaded: ${galleryController.images.length}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModeManager>(
      builder: (context, modeManager, child) {
        // open with 模式
        if (modeManager.currentMode == BrowseMode.fileAssociation &&
            modeManager.associatedFilePath != null) {
          // 关闭详情页后，显示该文件夹的瀑布流
          if (_showFolderWaterfall) {
            return _buildFolderWaterfallView();
          }
          return _buildFileAssociationView(modeManager.associatedFilePath!);
        }
        return const WaterfallView();
      },
    );
  }

  /// 文件夹瀑布流视图（open with 关闭详情页后显示）
  Widget _buildFolderWaterfallView() {
    return Consumer<GalleryController>(
      builder: (context, galleryController, child) {
        return WaterfallView(
          overrideImages: galleryController.folderImages,
          onImageTap: (images, index) {
            setState(() => _showFolderWaterfall = false);
            // 重新进入详情页需要更新 associatedFilePath
            final modeManager = context.read<ModeManager>();
            modeManager.switchToFileAssociation(images[index].filePath);
          },
        );
      },
    );
  }

  /// open with 模式：只显示该文件夹的图片，不加载系统图片
  Widget _buildFileAssociationView(String filePath) {
    return Consumer<GalleryController>(
      builder: (context, galleryController, child) {
        // 还在加载中
        if (galleryController.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final images = galleryController.folderImages;

        // 加载完但文件夹为空，只显示这一张
        if (images.isEmpty) {
          return SingleImageViewer(
            images: [
              ImageItem(
                id: '0',
                filePath: filePath,
                fileName: File(filePath).uri.pathSegments.last,
                width: 0,
                height: 0,
                fileSize: 0,
                modifiedTime: DateTime.now(),
                format: ImageFormat.fromExtension(
                  filePath.contains('.')
                      ? '.${filePath.split('.').last.toLowerCase()}'
                      : '',
                ),
              )
            ],
            initialIndex: 0,
            onClose: () => setState(() => _showFolderWaterfall = true),
          );
        }

        // 定位到被打开的那张图片
        final index = images.indexWhere((img) => img.filePath == filePath);
        final initialIndex = index >= 0 ? index : 0;

        return SingleImageViewer(
          images: images,
          initialIndex: initialIndex,
          onClose: () => setState(() => _showFolderWaterfall = true),
        );
      },
    );
  }
}
