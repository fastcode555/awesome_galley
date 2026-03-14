import 'package:awesome_galley/domain/models/image_item.dart';

/// 抽象接口：提供图片数据的统一访问
abstract class ImageRepository {
  /// 扫描系统目录，以 Stream 方式返回结果
  /// 每扫完一个子目录就 yield 一批 ImageItem，UI 可以立即更新
  /// 扫描结果同时写入数据库
  Stream<List<ImageItem>> scanSystemDirectoriesStream();

  /// 从数据库分页加载图片（不触发文件系统扫描）
  /// 会校验文件是否存在，删除失效记录
  Future<List<ImageItem>> loadPageFromDb({
    required int limit,
    required int offset,
  });

  /// 数据库中图片总数（用于判断是否需要重新扫描）
  Future<int> getDbImageCount();

  /// 扫描指定文件夹中的所有图片
  Future<List<ImageItem>> scanFolder(String folderPath);

  /// 获取最近浏览的文件夹列表
  Future<List<String>> getRecentFolders();

  /// 保存最近浏览的文件夹
  Future<void> saveRecentFolder(String folderPath, {int? imageCount});
}
