import 'package:awesome_galley/domain/models/image_item.dart';

/// 抽象接口：提供图片数据的统一访问
/// 
/// ImageRepository 负责扫描和加载图片数据，支持两种模式：
/// - 系统图片浏览模式：扫描系统预定义目录
/// - 文件夹浏览模式：扫描指定文件夹
abstract class ImageRepository {
  /// 扫描系统预定义目录中的所有图片
  /// 
  /// 并行扫描 Pictures、Desktop、Downloads 等系统目录
  /// 过滤支持的图片格式（JPEG、PNG、GIF、WebP、BMP）
  /// 按修改日期降序排序
  /// 最多返回 10000 张图片
  /// 
  /// 返回图片项列表
  Future<List<ImageItem>> scanSystemDirectories();

  /// 扫描指定文件夹中的所有图片
  /// 
  /// [folderPath] 要扫描的文件夹路径
  /// 过滤支持的图片格式
  /// 按文件名字母顺序排序
  /// 最多返回 1000 张图片
  /// 
  /// 返回图片项列表
  Future<List<ImageItem>> scanFolder(String folderPath);

  /// 获取最近浏览的文件夹列表
  /// 
  /// 返回最多 10 个最近浏览的文件夹路径
  Future<List<String>> getRecentFolders();

  /// 保存最近浏览的文件夹
  /// 
  /// [folderPath] 文件夹路径
  /// [imageCount] 可选的图片数量
  Future<void> saveRecentFolder(String folderPath, {int? imageCount});
}
