# FileSystemService

文件系统服务提供跨平台的文件系统访问功能。

## 功能

- 获取系统图片目录（Pictures、Desktop、Downloads）
- 列出文件夹中的图片文件
- 检查文件是否存在
- 获取文件修改时间
- 获取文件大小

## 使用示例

```dart
import 'package:awesome_galley/infrastructure/services/services.dart';

// 创建服务实例
final fileSystemService = FileSystemServiceImpl();

// 获取系统图片目录
final directories = await fileSystemService.getSystemImageDirectories();
print('系统图片目录: $directories');

// 列出文件夹中的图片
final images = await fileSystemService.listImagesInFolder('/path/to/folder');
for (final image in images) {
  print('图片: ${image.name}, 大小: ${image.size} bytes, 格式: ${image.format}');
}

// 检查文件是否存在
final exists = await fileSystemService.fileExists('/path/to/image.jpg');
print('文件存在: $exists');

// 获取文件信息
if (exists) {
  final modifiedTime = await fileSystemService.getModifiedTime('/path/to/image.jpg');
  final size = await fileSystemService.getFileSize('/path/to/image.jpg');
  print('修改时间: $modifiedTime');
  print('文件大小: $size bytes');
}
```

## 平台支持

### Windows
- Pictures: `%USERPROFILE%\Pictures`
- Desktop: `%USERPROFILE%\Desktop`
- Downloads: `%USERPROFILE%\Downloads`

### macOS / Linux
- Pictures: `~/Pictures`
- Desktop: `~/Desktop`
- Downloads: `~/Downloads`

### iOS / Android
- 返回空列表（使用 photo_manager 包处理）

## 支持的图片格式

- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- WebP (.webp)
- BMP (.bmp)

## 错误处理

服务提供三种自定义异常：

- `DirectoryNotFoundException`: 目录不存在
- `FileNotFoundException`: 文件不存在
- `FileSystemException`: 文件系统操作失败

```dart
try {
  final images = await fileSystemService.listImagesInFolder('/invalid/path');
} on DirectoryNotFoundException catch (e) {
  print('目录不存在: $e');
} on FileSystemException catch (e) {
  print('文件系统错误: $e');
}
```
