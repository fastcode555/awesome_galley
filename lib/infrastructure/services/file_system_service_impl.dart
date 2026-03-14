import 'dart:io';
import 'package:awesome_galley/domain/models/file_info.dart';
import 'package:awesome_galley/domain/models/image_format.dart';
import 'package:path/path.dart' as path;
import 'file_system_service.dart';

/// FileSystemService 的实现类
class FileSystemServiceImpl implements FileSystemService {
  @override
  Future<List<String>> getSystemImageDirectories() async {
    final directories = <String>[];

    if (Platform.isWindows) {
      // Windows 平台 - 扫描用户主目录
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        directories.add(userProfile);
      }
    } else if (Platform.isMacOS || Platform.isLinux) {
      // macOS 和 Linux 平台 - 扫描用户主目录
      final home = Platform.environment['HOME'];
      if (home != null) {
        directories.add(home);
        print('[FileSystemService] Will scan entire home directory: $home');
      }
    }
    // iOS 和 Android 平台返回空列表（将使用 photo_manager 包）

    // 过滤掉不存在的目录
    final existingDirectories = <String>[];
    for (final dir in directories) {
      final exists = await Directory(dir).exists();
      print('[FileSystemService] Directory $dir exists: $exists');
      if (exists) {
        existingDirectories.add(dir);
      }
    }

    print('[FileSystemService] Existing directories: $existingDirectories');
    return existingDirectories;
  }

  /// 需要跳过的目录（系统目录、缓存等）
  static final Set<String> _skipDirectories = {
    'Library',
    'System',
    'Applications',
    '.Trash',
    'node_modules',
    '.git',
    '.cache',
    'Cache',
    'Caches',
    '.npm',
    '.gradle',
    '.m2',
    'AppData',
    'ProgramData',
    'Windows',
    'Program Files',
    'Program Files (x86)',
  };

  /// 检查是否应该跳过该目录
  bool _shouldSkipDirectory(String dirPath) {
    final dirName = path.basename(dirPath);
    
    // 跳过隐藏目录（以 . 开头，但不包括 .Trash）
    if (dirName.startsWith('.') && dirName != '.Trash') {
      return true;
    }
    
    // 跳过系统目录
    if (_skipDirectories.contains(dirName)) {
      return true;
    }
    
    return false;
  }

  @override
  Future<List<FileInfo>> listImagesInFolder(String folderPath, {bool recursive = false, int maxDepth = 10}) async {
    final directory = Directory(folderPath);

    // 检查目录是否存在
    if (!await directory.exists()) {
      throw DirectoryNotFoundException('Directory not found: $folderPath');
    }

    final imageFiles = <FileInfo>[];

    try {
      await _scanDirectory(directory, imageFiles, recursive: recursive, currentDepth: 0, maxDepth: maxDepth);
    } catch (e) {
      throw FileSystemException('Failed to list images in folder: $folderPath', e);
    }

    return imageFiles;
  }

  /// 递归扫描目录
  Future<void> _scanDirectory(
    Directory directory,
    List<FileInfo> imageFiles, {
    required bool recursive,
    required int currentDepth,
    required int maxDepth,
  }) async {
    // 检查深度限制
    if (currentDepth > maxDepth) {
      return;
    }

    // 检查是否应该跳过该目录
    if (_shouldSkipDirectory(directory.path)) {
      print('[FileSystemService] Skipping directory: ${directory.path}');
      return;
    }

    try {
      // 列出目录中的所有实体
      await for (final entity in directory.list(followLinks: false)) {
        try {
          if (entity is File) {
            final filePath = entity.path;
            final extension = path.extension(filePath).toLowerCase();

            // 检查是否为支持的图片格式
            if (ImageFormat.supportedExtensions.contains(extension)) {
              try {
                final stat = await entity.stat();
                final format = ImageFormat.fromExtension(extension);

                imageFiles.add(FileInfo(
                  path: filePath,
                  name: path.basename(filePath),
                  size: stat.size,
                  modifiedTime: stat.modified,
                  format: format,
                ));
              } catch (e) {
                // 忽略无法访问的文件
                continue;
              }
            }
          } else if (entity is Directory && recursive) {
            // 递归扫描子目录
            await _scanDirectory(
              entity,
              imageFiles,
              recursive: recursive,
              currentDepth: currentDepth + 1,
              maxDepth: maxDepth,
            );
          }
        } catch (e) {
          // 忽略无法访问的文件或目录
          continue;
        }
      }
    } catch (e) {
      // 忽略无法访问的目录
      print('[FileSystemService] Cannot access directory: ${directory.path}');
    }
  }

  @override
  Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<DateTime> getModifiedTime(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileNotFoundException('File not found: $filePath');
    }

    try {
      final stat = await file.stat();
      return stat.modified;
    } catch (e) {
      throw FileSystemException('Failed to get modified time: $filePath', e);
    }
  }

  @override
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileNotFoundException('File not found: $filePath');
    }

    try {
      final stat = await file.stat();
      return stat.size;
    } catch (e) {
      throw FileSystemException('Failed to get file size: $filePath', e);
    }
  }
}

/// 自定义异常：目录未找到
class DirectoryNotFoundException implements Exception {
  final String message;
  DirectoryNotFoundException(this.message);

  @override
  String toString() => 'DirectoryNotFoundException: $message';
}

/// 自定义异常：文件未找到
class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);

  @override
  String toString() => 'FileNotFoundException: $message';
}

/// 自定义异常：文件系统异常
class FileSystemException implements Exception {
  final String message;
  final Object? cause;

  FileSystemException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'FileSystemException: $message\nCaused by: $cause';
    }
    return 'FileSystemException: $message';
  }
}
