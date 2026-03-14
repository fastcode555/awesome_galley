# Image Repository

## 概述

ImageRepository 提供图片数据的统一访问接口，支持两种浏览模式：

1. **系统图片浏览模式**：扫描系统预定义目录（Pictures、Desktop、Downloads）
2. **文件夹浏览模式**：扫描指定文件夹

## 使用示例

### 初始化

```dart
import 'package:awesome_galley/domain/repositories/repositories.dart';
import 'package:awesome_galley/infrastructure/services/services.dart';
import 'package:awesome_galley/infrastructure/repositories/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 创建依赖
final fileSystemService = FileSystemServiceImpl();
final prefs = await SharedPreferences.getInstance();
final stateRepository = StateRepository(prefs);
await stateRepository.initialize();

// 创建 ImageRepository
final imageRepository = ImageRepositoryImpl(
  fileSystemService: fileSystemService,
  stateRepository: stateRepository,
);
```

### 扫描系统目录

```dart
// 扫描系统预定义目录中的所有图片
// 并行扫描 Pictures、Desktop、Downloads 等目录
// 按修改日期降序排序，最多返回 10000 张图片
final images = await imageRepository.scanSystemDirectories();

print('找到 ${images.length} 张图片');
for (final image in images.take(10)) {
  print('${image.fileName} - ${image.width}x${image.height}');
}
```

### 扫描指定文件夹

```dart
// 扫描指定文件夹中的所有图片
// 按文件名字母顺序排序，最多返回 1000 张图片
final folderPath = '/Users/username/Pictures/Vacation';
final images = await imageRepository.scanFolder(folderPath);

print('文件夹中有 ${images.length} 张图片');
```

### 管理最近浏览的文件夹

```dart
// 保存最近浏览的文件夹
await imageRepository.saveRecentFolder(
  '/Users/username/Pictures/Vacation',
  imageCount: 150,
);

// 获取最近浏览的文件夹列表（最多 10 个）
final recentFolders = await imageRepository.getRecentFolders();
print('最近浏览的文件夹：');
for (final folder in recentFolders) {
  print('  - $folder');
}
```

## 实现细节

### 扫描策略

#### 系统目录扫描
- **并行扫描**：使用 `Future.wait` 并行扫描多个目录，提高性能
- **格式过滤**：仅包含支持的图片格式（JPEG、PNG、GIF、WebP、BMP）
- **排序**：按修改日期降序排序（最新的图片在前）
- **数量限制**：最多返回 10000 张图片

#### 文件夹扫描
- **格式过滤**：仅包含支持的图片格式
- **排序**：按文件名字母顺序排序
- **数量限制**：最多返回 1000 张图片

### 图片尺寸获取

实现会读取图片文件以获取宽度和高度信息。如果图片文件损坏或无法解码，会返回默认尺寸 (1, 1)，避免单个图片错误影响整个扫描过程。

**性能注意事项**：
- 当前实现使用 `image` 包解码整个图片文件来获取尺寸
- 对于大量图片，这可能会影响性能
- 未来可以考虑使用更高效的方法（如 `image_size_getter` 包）只读取图片头部信息

### 错误处理

- **目录不存在**：返回空列表，不抛出异常
- **权限不足**：跳过无法访问的目录，继续扫描其他目录
- **图片损坏**：使用默认尺寸，不影响其他图片的加载

## 测试

运行单元测试：

```bash
flutter test test/domain/repositories/image_repository_impl_test.dart
```

测试覆盖：
- ✅ 空目录扫描
- ✅ 文件夹扫描和排序
- ✅ 最近文件夹管理
- ✅ 图片数量限制（1000/10000）

## 依赖

- `FileSystemService`：文件系统访问服务
- `StateRepository`：状态持久化服务
- `image` 包：图片解码和尺寸获取
- `uuid` 包：生成唯一 ID

## 相关文件

- `image_repository.dart`：抽象接口定义
- `image_repository_impl.dart`：具体实现
- `test/domain/repositories/image_repository_impl_test.dart`：单元测试
