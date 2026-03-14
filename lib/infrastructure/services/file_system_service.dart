import 'package:awesome_galley/domain/models/file_info.dart';

/// 抽象接口：提供跨平台的文件系统访问
abstract class FileSystemService {
  /// 获取系统图片目录列表
  /// 
  /// 根据平台返回不同的目录：
  /// - Windows: %USERPROFILE%\Pictures, %USERPROFILE%\Desktop, %USERPROFILE%\Downloads
  /// - macOS/Linux: ~/Pictures, ~/Desktop, ~/Downloads
  /// - iOS/Android: 返回空列表（使用 photo_manager 包处理）
  Future<List<String>> getSystemImageDirectories();

  /// 列出文件夹中的所有图片文件
  /// 
  /// 扫描指定文件夹并过滤支持的图片格式
  /// [folderPath] 要扫描的文件夹路径
  /// [recursive] 是否递归扫描子目录（默认 false）
  /// [maxDepth] 最大递归深度（默认 10）
  /// 返回文件信息列表
  Future<List<FileInfo>> listImagesInFolder(
    String folderPath, {
    bool recursive = false,
    int maxDepth = 10,
  });

  /// 检查文件是否存在
  /// 
  /// [filePath] 文件路径
  /// 返回文件是否存在
  Future<bool> fileExists(String filePath);

  /// 获取文件修改时间
  /// 
  /// [filePath] 文件路径
  /// 返回文件的最后修改时间
  Future<DateTime> getModifiedTime(String filePath);

  /// 获取文件大小
  /// 
  /// [filePath] 文件路径
  /// 返回文件大小（字节）
  Future<int> getFileSize(String filePath);
}
