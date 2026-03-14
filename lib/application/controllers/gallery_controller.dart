import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/browse_mode.dart';
import '../../domain/models/image_item.dart';
import '../../domain/repositories/image_repository.dart';
import '../../infrastructure/cache/cache_manager.dart';

class GalleryController extends ChangeNotifier {
  final ImageRepository _repository;
  // ignore: unused_field
  final CacheManager _cacheManager;

  List<ImageItem> _images = [];
  List<ImageItem> _folderImages = []; // open with 场景专用，不污染系统浏览
  BrowseMode _currentMode = BrowseMode.systemBrowse;
  String? _currentFolderPath;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMoreImages = true;
  bool _isScanning = false; // background scan in progress

  // DB pagination offset for system browse
  int _dbOffset = 0;
  static const int _pageSize = 50;

  GalleryController({
    required ImageRepository repository,
    required CacheManager cacheManager,
  })  : _repository = repository,
        _cacheManager = cacheManager;

  List<ImageItem> get images => List.unmodifiable(_images);
  List<ImageItem> get folderImages => List.unmodifiable(_folderImages);
  BrowseMode get currentMode => _currentMode;
  String? get currentFolderPath => _currentFolderPath;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  String? get errorMessage => _errorMessage;
  bool get hasMoreImages => _hasMoreImages;

  /// 系统浏览模式入口
  /// 
  /// 策略：
  /// 1. 先从数据库加载第一页（快速显示）
  /// 2. 同时在后台启动文件系统扫描，更新数据库
  /// 3. 扫描完成后刷新 UI
  Future<void> loadSystemImages() async {
    if (_isLoading) return;

    _currentMode = BrowseMode.systemBrowse;
    _currentFolderPath = null;
    _images = [];
    _dbOffset = 0;
    _hasMoreImages = true;
    _setLoading(true);

    try {
      final dbCount = await _repository.getDbImageCount();

      if (dbCount > 0) {
        // 数据库有数据，先快速展示第一页
        final firstPage = await _repository.loadPageFromDb(
          limit: _pageSize,
          offset: 0,
        );
        _dbOffset = _pageSize;
        _images = firstPage;
        _hasMoreImages = firstPage.length >= _pageSize;
        _setLoading(false);
        print('[GalleryController] Loaded ${_images.length} from DB, starting background scan...');
        // 后台扫描更新数据库
        _startBackgroundScan();
      } else {
        // 数据库为空，必须先扫描
        _setLoading(false);
        await _runFullScan();
      }
    } catch (e) {
      print('[GalleryController] Error: $e');
      _setError('Failed to load images: $e');
    }
  }

  /// 后台扫描（不阻塞 UI，扫描完成后刷新）
  void _startBackgroundScan() {
    if (_isScanning) return;
    _isScanning = true;
    notifyListeners();

    Future.microtask(() async {
      try {
        await for (final _ in _repository.scanSystemDirectoriesStream()) {
          // 扫描过程中不更新 UI，只写入数据库
        }
        print('[GalleryController] Background scan complete, refreshing...');
        // 扫描完成后重新从数据库加载第一页
        await _refreshFromDb();
      } catch (e) {
        print('[GalleryController] Background scan error: $e');
      } finally {
        _isScanning = false;
        notifyListeners();
      }
    });
  }

  /// 首次扫描（数据库为空时）：扫描并流式更新 UI
  Future<void> _runFullScan() async {
    _isScanning = true;
    notifyListeners();

    DateTime lastNotify = DateTime.now();
    const throttle = Duration(milliseconds: 500);

    try {
      await for (final batch in _repository.scanSystemDirectoriesStream()) {
        _images.addAll(batch);
        _dbOffset = _images.length;

        final now = DateTime.now();
        if (now.difference(lastNotify) >= throttle) {
          notifyListeners();
          lastNotify = now;
          print('[GalleryController] Scan progress: ${_images.length}');
        }
      }
      notifyListeners();
      print('[GalleryController] Full scan done: ${_images.length} images');
    } catch (e) {
      _setError('Scan failed: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// 扫描完成后从数据库重新加载（保持当前滚动位置的数据量）
  Future<void> _refreshFromDb() async {
    try {
      final count = _images.length.clamp(_pageSize, 500);
      final refreshed = await _repository.loadPageFromDb(
        limit: count,
        offset: 0,
      );
      _images = refreshed;
      _dbOffset = refreshed.length;
      final total = await _repository.getDbImageCount();
      _hasMoreImages = _dbOffset < total;
      notifyListeners();
    } catch (e) {
      print('[GalleryController] Refresh error: $e');
    }
  }

  /// 下滑加载更多（从数据库分页）
  Future<void> loadMoreImages() async {
    if (_isLoading || !_hasMoreImages) return;
    if (_currentMode != BrowseMode.systemBrowse) return;

    _setLoading(true);
    try {
      final more = await _repository.loadPageFromDb(
        limit: _pageSize,
        offset: _dbOffset,
      );
      if (more.isEmpty) {
        _hasMoreImages = false;
      } else {
        _images.addAll(more);
        _dbOffset += more.length;
        final total = await _repository.getDbImageCount();
        _hasMoreImages = _dbOffset < total;
      }
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load more: $e');
    }
  }

  /// 加载指定文件夹（open with 场景）
  /// 只加载该文件夹的图片，不写入系统数据库，不影响系统浏览的 images
  Future<void> loadFolderImagesForViewer(String folderPath) async {
    _setLoading(true);
    _folderImages = [];
    try {
      _folderImages = await _repository.scanFolderOnly(folderPath);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load folder: $e');
    }
  }

  /// 加载指定文件夹（写入数据库，用于最近文件夹功能）
  Future<void> loadFolderImages(String folderPath) async {
    if (_isLoading) return;

    _setLoading(true);
    _currentMode = BrowseMode.fileAssociation;
    _currentFolderPath = folderPath;
    _images = [];
    _hasMoreImages = false;

    try {
      final all = await _repository.scanFolder(folderPath);
      await _repository.saveRecentFolder(folderPath, imageCount: all.length);
      _images = all;
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load folder: $e');
    }
  }

  /// 删除图片：删除文件、数据库记录，并从当前列表移除
  Future<void> deleteImage(String filePath) async {
    try {
      await _repository.deleteImage(filePath);
      _images.removeWhere((img) => img.filePath == filePath);
      _folderImages.removeWhere((img) => img.filePath == filePath);
      _dbOffset = (_dbOffset - 1).clamp(0, _dbOffset);
      notifyListeners();
    } catch (e) {
      print('[GalleryController] Delete failed: $e');
    }
  }

  /// 图片在 UI 显示后更新真实宽高到 DB（针对扫描时未能解析尺寸的图片）
  Future<void> updateImageSize(String filePath, int width, int height) async {
    try {
      await _repository.updateImageSize(filePath, width, height);
      // 更新内存中的 item，触发 UI 刷新（AspectRatio 会重新计算）
      final idx = _images.indexWhere((img) => img.filePath == filePath);
      if (idx >= 0 && (_images[idx].width <= 1 || _images[idx].height <= 1)) {
        _images[idx] = _images[idx].copyWith(width: width, height: height);
        notifyListeners();
      }
    } catch (e) {
      // 非关键操作，静默失败
    }
  }

  void setMode(BrowseMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _images = [];
    _dbOffset = 0;
    _hasMoreImages = true;
    _currentMode = BrowseMode.systemBrowse;
    _currentFolderPath = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
