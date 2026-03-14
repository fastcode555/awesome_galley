import 'dart:async';
import 'package:awesome_galley/domain/models/image_item.dart';
import 'package:awesome_galley/infrastructure/services/file_system_service.dart';
import 'package:awesome_galley/infrastructure/repositories/state_repository.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'image_repository.dart';

/// ImageRepository 的实现类
/// 
/// 负责扫描和加载图片数据，支持两种模式：
/// - 系统图片浏览模式：扫描系统预定义目录（最多 10000 张）
/// - 文件夹浏览模式：扫描指定文件夹（最多 1000 张）
class ImageRepositoryImpl implements ImageRepository {
  final FileSystemService _fileSystem;
  final StateRepository _stateRepository;
  final Uuid _uuid = const Uuid();

  /// 系统浏览模式的图片数量限制
  static const int systemImageLimit = 10000;

  /// 文件夹浏览模式的图片数量限制
  static const int folderImageLimit = 1000;

  ImageRepositoryImpl({
    required FileSystemService fileSystemService,
    required StateRepository stateRepository,
  })  : _fileSystem = fileSystemService,
        _stateRepository = stateRepository;

  @override
  Future<List<ImageItem>> scanSystemDirectories() async {
    print('[ImageRepository] Scanning system directories...');
    // 获取系统图片目录
    final directories = await _fileSystem.getSystemImageDirectories();
    print('[ImageRepository] Found ${directories.length} directories: $directories');

    if (directories.isEmpty) {
      print('[ImageRepository] No directories found');
      return [];
    }

    // 并行扫描所有目录
    final futures = directories.map((dir) => _scanDirectory(dir));
    final results = await Future.wait(futures);

    // 合并所有结果
    final allImages = <ImageItem>[];
    for (final images in results) {
      allImages.addAll(images);
    }
    print('[ImageRepository] Total images found: ${allImages.length}');

    // 按修改日期降序排序（最新的在前）
    allImages.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));

    // 限制最多 10000 张图片
    if (allImages.length > systemImageLimit) {
      return allImages.sublist(0, systemImageLimit);
    }

    return allImages;
  }

  @override
  Future<List<ImageItem>> scanFolder(String folderPath) async {
    // 扫描指定文件夹
    final fileInfoList = await _fileSystem.listImagesInFolder(folderPath);

    // 过滤支持的格式
    final supportedFiles = fileInfoList.where((file) => file.isSupported).toList();

    // 按文件名字母顺序排序
    supportedFiles.sort((a, b) => a.name.compareTo(b.name));

    // 限制最多 1000 张图片
    final limitedFiles = supportedFiles.length > folderImageLimit
        ? supportedFiles.sublist(0, folderImageLimit)
        : supportedFiles;

    // 转换为 ImageItem 列表
    final images = await Future.wait(
      limitedFiles.map((file) => _fileInfoToImageItem(file)),
    );

    return images;
  }

  @override
  Future<List<String>> getRecentFolders() async {
    final recentFolders = await _stateRepository.getRecentFolders();
    return recentFolders.map((folder) => folder.folderPath).toList();
  }

  @override
  Future<void> saveRecentFolder(String folderPath, {int? imageCount}) async {
    await _stateRepository.addRecentFolder(folderPath, imageCount: imageCount);
  }

  /// 扫描单个目录中的所有图片
  /// 
  /// 递归扫描目录及其所有子目录
  Future<List<ImageItem>> _scanDirectory(String directoryPath) async {
    try {
      print('[ImageRepository] Scanning directory recursively: $directoryPath');
      // 递归扫描，最大深度 10 层
      final fileInfoList = await _fileSystem.listImagesInFolder(
        directoryPath,
        recursive: true,
        maxDepth: 10,
      );

      print('[ImageRepository] Found ${fileInfoList.length} images in $directoryPath');

      // 过滤支持的格式
      final supportedFiles = fileInfoList.where((file) => file.isSupported).toList();

      // 转换为 ImageItem 列表
      final images = await Future.wait(
        supportedFiles.map((file) => _fileInfoToImageItem(file)),
      );

      return images;
    } catch (e) {
      // 如果扫描失败（权限不足等），返回空列表
      print('[ImageRepository] Failed to scan directory $directoryPath: $e');
      return [];
    }
  }

  /// 将 FileInfo 转换为 ImageItem
  /// 
  /// 需要读取图片文件以获取宽度和高度信息
  /// 注意：这个方法会读取图片文件，可能会影响性能
  Future<ImageItem> _fileInfoToImageItem(dynamic fileInfo) async {
    // 读取图片尺寸
    final dimensions = await _getImageDimensions(fileInfo.path);

    return ImageItem(
      id: _uuid.v4(),
      filePath: fileInfo.path,
      fileName: fileInfo.name,
      width: dimensions.width,
      height: dimensions.height,
      fileSize: fileInfo.size,
      modifiedTime: fileInfo.modifiedTime,
      format: fileInfo.format,
    );
  }

  /// 获取图片的宽度和高度
  /// 
  /// 使用 image 包解码图片以获取尺寸信息
  /// 如果解码失败（文件不存在、损坏等），返回默认尺寸 (1, 1)
  /// 
  /// 注意：为了性能考虑，这里只解码图片头部信息获取尺寸
  /// 但 image 包目前不支持只读取头部，所以会读取整个文件
  /// 未来可以考虑使用更高效的方法（如 image_size_getter 包）
  Future<ImageDimensions> _getImageDimensions(String filePath) async {
    try {
      final file = File(filePath);
      
      // 检查文件是否存在
      if (!await file.exists()) {
        return ImageDimensions(width: 1, height: 1);
      }
      
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        return ImageDimensions(width: image.width, height: image.height);
      }
    } catch (e) {
      // 如果解码失败（文件损坏、格式不支持等），返回默认尺寸
      // 这样可以避免单个图片错误影响整个扫描过程
    }

    // 默认尺寸（避免除零错误）
    return ImageDimensions(width: 1, height: 1);
  }
}

/// 图片尺寸信息
class ImageDimensions {
  final int width;
  final int height;

  ImageDimensions({required this.width, required this.height});
}
