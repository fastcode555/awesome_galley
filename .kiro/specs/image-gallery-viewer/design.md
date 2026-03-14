# 设计文档

## 概述

图片浏览器是一款基于Flutter开发的跨平台图片查看应用，支持iOS、Android、Windows、macOS、Linux和Web平台。应用提供两种核心浏览模式：系统图片浏览模式（扫描系统所有图片）和文件关联打开模式（通过文件关联打开单个图片）。

核心功能包括：
- 瀑布流布局展示图片集合
- 高性能缩略图生成与缓存机制
- 单图全屏查看，支持缩放、平移和滑动切换
- 文件夹快速预览功能
- 图片元数据显示（包括EXIF信息）
- 跨平台文件关联支持

技术栈：
- Flutter SDK 3.x
- Dart 3.x
- 图片处理：image package
- 缓存：flutter_cache_manager
- 文件系统：path_provider, file_picker
- 平台集成：platform_channel (用于文件关联)
- 状态管理：Provider / Riverpod
- 数据持久化：shared_preferences, sqflite

## 架构设计

### 整体架构

应用采用分层架构设计，确保关注点分离和可测试性：

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Waterfall    │  │ Single Image │  │ Folder       │  │
│  │ View         │  │ Viewer       │  │ Preview      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│                   Application Layer                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Gallery      │  │ Image        │  │ Mode         │  │
│  │ Controller   │  │ Controller   │  │ Manager      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│                     Domain Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Image        │  │ Waterfall    │  │ Cache        │  │
│  │ Repository   │  │ Layout       │  │ Manager      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│                 Infrastructure Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ File System  │  │ Thumbnail    │  │ Platform     │  │
│  │ Service      │  │ Generator    │  │ Integration  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 核心设计原则

1. **平台抽象**: 使用抽象接口隔离平台特定代码，便于跨平台支持
2. **懒加载**: 图片和缩略图按需加载，优化内存使用
3. **缓存优先**: 多级缓存策略（内存缓存 + 磁盘缓存）
4. **响应式设计**: 使用流式架构处理异步数据
5. **错误隔离**: 单个图片加载失败不影响整体浏览体验

### 模式管理

应用支持两种互斥的浏览模式：

**系统图片浏览模式 (System Browse Mode)**:
- 触发条件：直接启动应用
- 行为：扫描系统预定义目录（Pictures、Desktop、Downloads等）
- 显示：瀑布流展示所有找到的图片

**文件关联打开模式 (File Association Mode)**:
- 触发条件：通过操作系统文件关联打开单个图片
- 行为：立即显示目标图片，加载同文件夹的其他图片
- 显示：单图查看器 + 文件夹图片浏览

模式切换：
- 文件关联模式可切换到系统浏览模式
- 系统浏览模式下打开图片不改变模式
- 应用重启时根据启动方式重新确定模式

## 组件和接口

### 1. Presentation Layer 组件

#### 1.1 WaterfallView (瀑布流视图)

**职责**: 以瀑布流布局展示图片集合

**接口**:
```dart
class WaterfallView extends StatefulWidget {
  final Stream<List<ImageItem>> imageStream;
  final Function(ImageItem) onImageTap;
  final int columnCount;
  
  @override
  _WaterfallViewState createState() => _WaterfallViewState();
}
```

**关键方法**:
- `_buildWaterfallLayout()`: 构建瀑布流布局
- `_calculateColumnCount()`: 根据屏幕宽度计算列数
- `_loadMoreImages()`: 滚动到底部时加载更多图片
- `_handleResize()`: 响应屏幕尺寸变化

**状态**:
- `List<List<ImageItem>> columns`: 各列的图片项列表
- `ScrollController scrollController`: 滚动控制器
- `bool isLoading`: 加载状态标志

#### 1.2 SingleImageViewer (单图查看器)

**职责**: 全屏显示单张图片，支持缩放、平移和滑动切换

**接口**:
```dart
class SingleImageViewer extends StatefulWidget {
  final ImageItem currentImage;
  final List<ImageItem> imageList;
  final int initialIndex;
  final Function() onClose;
  
  @override
  _SingleImageViewerState createState() => _SingleImageViewerState();
}
```

**关键方法**:
- `_handleSwipe(SwipeDirection direction)`: 处理滑动手势
- `_handleZoom(double scale)`: 处理缩放手势
- `_handlePan(Offset offset)`: 处理平移手势
- `_handleDoubleTap()`: 处理双击缩放
- `_loadFullResolutionImage()`: 加载原始分辨率图片
- `_showMetadataPanel()`: 显示元数据面板
- `_openFolderPreview()`: 打开文件夹预览

**状态**:
- `int currentIndex`: 当前图片索引
- `double scale`: 当前缩放比例 (0.5 - 5.0)
- `Offset panOffset`: 平移偏移量
- `TransformationController transformController`: 变换控制器

#### 1.3 FolderPreview (文件夹预览)

**职责**: 水平滚动列表展示文件夹中的所有图片缩略图

**接口**:
```dart
class FolderPreview extends StatelessWidget {
  final List<ImageItem> folderImages;
  final ImageItem currentImage;
  final Function(ImageItem) onImageSelect;
  
  @override
  Widget build(BuildContext context);
}
```

**关键方法**:
- `_buildThumbnailList()`: 构建缩略图列表
- `_highlightCurrentImage()`: 高亮当前图片
- `_scrollToCurrentImage()`: 滚动到当前图片位置

#### 1.4 MetadataPanel (元数据面板)

**职责**: 显示图片的详细信息

**接口**:
```dart
class MetadataPanel extends StatelessWidget {
  final ImageMetadata metadata;
  
  @override
  Widget build(BuildContext context);
}
```

**显示内容**:
- 文件名
- 分辨率 (宽 × 高)
- 文件大小
- 图片格式
- 修改日期
- EXIF数据（如果有）：拍摄日期、相机型号、GPS位置

### 2. Application Layer 组件

#### 2.1 GalleryController

**职责**: 管理图片集合的加载和状态

**接口**:
```dart
class GalleryController extends ChangeNotifier {
  final ImageRepository _repository;
  final CacheManager _cacheManager;
  
  Stream<List<ImageItem>> get imageStream;
  BrowseMode get currentMode;
  
  Future<void> loadSystemImages();
  Future<void> loadFolderImages(String folderPath);
  Future<void> loadMoreImages();
  void setMode(BrowseMode mode);
}
```

**关键方法**:
- `loadSystemImages()`: 加载系统图片（扫描预定义目录）
- `loadFolderImages(String folderPath)`: 加载指定文件夹的图片
- `loadMoreImages()`: 分页加载更多图片
- `setMode(BrowseMode mode)`: 设置浏览模式

#### 2.2 ImageController

**职责**: 管理单张图片的加载和操作

**接口**:
```dart
class ImageController extends ChangeNotifier {
  final ThumbnailGenerator _thumbnailGenerator;
  final CacheManager _cacheManager;
  
  Future<ImageData> loadThumbnail(ImageItem item);
  Future<ImageData> loadFullImage(ImageItem item);
  Future<ImageMetadata> loadMetadata(ImageItem item);
}
```

**关键方法**:
- `loadThumbnail(ImageItem item)`: 加载缩略图（优先从缓存）
- `loadFullImage(ImageItem item)`: 加载原始分辨率图片
- `loadMetadata(ImageItem item)`: 加载图片元数据和EXIF信息

#### 2.3 ModeManager

**职责**: 管理应用的浏览模式和模式切换

**接口**:
```dart
enum BrowseMode {
  systemBrowse,
  fileAssociation,
}

class ModeManager extends ChangeNotifier {
  BrowseMode _currentMode;
  String? _associatedFilePath;
  
  BrowseMode get currentMode => _currentMode;
  String? get associatedFilePath => _associatedFilePath;
  
  void initializeMode(List<String> launchArgs);
  void switchToSystemBrowse();
  bool isFileAssociationMode();
}
```

**关键方法**:
- `initializeMode(List<String> launchArgs)`: 根据启动参数初始化模式
- `switchToSystemBrowse()`: 切换到系统浏览模式
- `isFileAssociationMode()`: 检查是否为文件关联模式

### 3. Domain Layer 组件

#### 3.1 ImageRepository

**职责**: 提供图片数据的统一访问接口

**接口**:
```dart
abstract class ImageRepository {
  Future<List<ImageItem>> scanSystemDirectories();
  Future<List<ImageItem>> scanFolder(String folderPath);
  Future<List<ImageItem>> getRecentFolders();
  Future<void> saveRecentFolder(String folderPath);
}

class ImageRepositoryImpl implements ImageRepository {
  final FileSystemService _fileSystem;
  final StateRepository _stateRepository;
  
  @override
  Future<List<ImageItem>> scanSystemDirectories() async {
    // 扫描 Pictures, Desktop, Downloads 等目录
  }
  
  @override
  Future<List<ImageItem>> scanFolder(String folderPath) async {
    // 扫描指定文件夹
  }
}
```

**扫描策略**:
- 系统目录扫描：并行扫描多个预定义目录
- 文件过滤：仅包含支持的图片格式 (JPEG, PNG, GIF, WebP, BMP)
- 数量限制：系统浏览模式最多10000张，文件夹预览最多1000张
- 排序：按修改日期降序（系统模式）或文件名字母顺序（文件夹模式）

#### 3.2 WaterfallLayoutEngine

**职责**: 实现瀑布流布局算法

**接口**:
```dart
class WaterfallLayoutEngine {
  final int columnCount;
  final double columnWidth;
  final double spacing;
  
  List<List<ImageItem>> calculateLayout(List<ImageItem> images);
  int findShortestColumn(List<double> columnHeights);
  double calculateItemHeight(ImageItem item, double columnWidth);
}
```

**算法实现**:
```dart
List<List<ImageItem>> calculateLayout(List<ImageItem> images) {
  // 初始化列
  List<List<ImageItem>> columns = List.generate(columnCount, (_) => []);
  List<double> columnHeights = List.filled(columnCount, 0.0);
  
  for (var image in images) {
    // 找到当前高度最小的列
    int shortestColumnIndex = findShortestColumn(columnHeights);
    
    // 将图片添加到该列
    columns[shortestColumnIndex].add(image);
    
    // 更新列高度
    double itemHeight = calculateItemHeight(image, columnWidth);
    columnHeights[shortestColumnIndex] += itemHeight + spacing;
  }
  
  return columns;
}

int findShortestColumn(List<double> columnHeights) {
  double minHeight = columnHeights[0];
  int minIndex = 0;
  
  for (int i = 1; i < columnHeights.length; i++) {
    if (columnHeights[i] < minHeight) {
      minHeight = columnHeights[i];
      minIndex = i;
    }
  }
  
  return minIndex;
}

double calculateItemHeight(ImageItem item, double columnWidth) {
  // 保持原始宽高比
  double aspectRatio = item.width / item.height;
  return columnWidth / aspectRatio;
}
```

**列数计算**:
```dart
int calculateColumnCount(double screenWidth) {
  if (screenWidth < 600) return 2;      // 移动设备
  if (screenWidth < 1024) return 3;     // 平板设备
  return max(4, (screenWidth / 300).floor()); // 桌面设备
}
```

#### 3.3 CacheManager

**职责**: 管理缩略图的多级缓存

**接口**:
```dart
class CacheManager {
  final MemoryCache _memoryCache;
  final DiskCache _diskCache;
  
  Future<ImageData?> getThumbnail(String imageKey);
  Future<void> cacheThumbnail(String imageKey, ImageData thumbnail);
  Future<void> clearOldCache();
  Future<int> getCacheSize();
}
```

**缓存策略**:

1. **内存缓存 (L1)**:
   - 容量：最多100张缩略图
   - 淘汰策略：LRU (Least Recently Used)
   - 用途：快速访问最近查看的图片

2. **磁盘缓存 (L2)**:
   - 容量：最多500MB
   - 淘汰策略：LRU + 时间戳
   - 存储位置：应用缓存目录
   - 文件命名：`{MD5(filePath)}_{modifiedTime}.jpg`

3. **缓存清理**:
   - 触发条件：缓存大小超过500MB
   - 清理策略：删除最久未使用的缓存项，直到缓存大小降至400MB

**缓存键生成**:
```dart
String generateCacheKey(String filePath, DateTime modifiedTime) {
  String pathHash = md5.convert(utf8.encode(filePath)).toString();
  String timeStamp = modifiedTime.millisecondsSinceEpoch.toString();
  return '${pathHash}_$timeStamp';
}
```

### 4. Infrastructure Layer 组件

#### 4.1 FileSystemService

**职责**: 提供跨平台的文件系统访问

**接口**:
```dart
abstract class FileSystemService {
  Future<List<String>> getSystemImageDirectories();
  Future<List<FileInfo>> listImagesInFolder(String folderPath);
  Future<bool> fileExists(String filePath);
  Future<DateTime> getModifiedTime(String filePath);
  Future<int> getFileSize(String filePath);
}

class FileSystemServiceImpl implements FileSystemService {
  @override
  Future<List<String>> getSystemImageDirectories() async {
    if (Platform.isWindows) {
      return [
        '${Platform.environment['USERPROFILE']}\\Pictures',
        '${Platform.environment['USERPROFILE']}\\Desktop',
        '${Platform.environment['USERPROFILE']}\\Downloads',
      ];
    } else if (Platform.isMacOS || Platform.isLinux) {
      return [
        '${Platform.environment['HOME']}/Pictures',
        '${Platform.environment['HOME']}/Desktop',
        '${Platform.environment['HOME']}/Downloads',
      ];
    }
    // iOS/Android 使用 photo_manager 包
    return [];
  }
}
```

#### 4.2 ThumbnailGenerator

**职责**: 生成高质量缩略图

**接口**:
```dart
class ThumbnailGenerator {
  static const int maxThumbnailWidth = 400;
  
  Future<ImageData> generateThumbnail(String filePath);
  Future<ImageData> resizeImage(ImageData original, int targetWidth);
}
```

**生成算法**:
```dart
Future<ImageData> generateThumbnail(String filePath) async {
  // 1. 解码原始图片
  final bytes = await File(filePath).readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image == null) {
    throw ImageDecodeException('Failed to decode image: $filePath');
  }
  
  // 2. 计算缩略图尺寸（保持宽高比）
  int thumbnailWidth = maxThumbnailWidth;
  int thumbnailHeight = (image.height * thumbnailWidth / image.width).round();
  
  // 3. 使用高质量算法缩放
  final thumbnail = img.copyResize(
    image,
    width: thumbnailWidth,
    height: thumbnailHeight,
    interpolation: img.Interpolation.cubic,
  );
  
  // 4. 编码为JPEG（质量85）
  final thumbnailBytes = img.encodeJpg(thumbnail, quality: 85);
  
  return ImageData(
    bytes: thumbnailBytes,
    width: thumbnailWidth,
    height: thumbnailHeight,
  );
}
```

#### 4.3 PlatformIntegration

**职责**: 处理平台特定功能（文件关联、启动参数等）

**接口**:
```dart
abstract class PlatformIntegration {
  Future<void> registerFileAssociations();
  Future<void> setAsDefaultApp();
  Future<List<String>> getLaunchArguments();
  Future<ImageMetadata> extractExifData(String filePath);
}
```

**平台实现**:

**Windows**:
```dart
class WindowsPlatformIntegration implements PlatformIntegration {
  static const MethodChannel _channel = MethodChannel('image_gallery/platform');
  
  @override
  Future<void> registerFileAssociations() async {
    // 通过 Windows Registry 注册文件关联
    await _channel.invokeMethod('registerFileAssociations', {
      'extensions': ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'],
      'appName': 'Image Gallery Viewer',
      'appPath': Platform.resolvedExecutable,
    });
  }
  
  @override
  Future<List<String>> getLaunchArguments() async {
    // 获取命令行参数
    return Platform.executableArguments;
  }
}
```

**macOS**:
```dart
class MacOSPlatformIntegration implements PlatformIntegration {
  @override
  Future<void> registerFileAssociations() async {
    // 通过 Info.plist 配置文件关联
    // CFBundleDocumentTypes 配置
  }
  
  @override
  Future<List<String>> getLaunchArguments() async {
    // 通过 NSApplication 获取打开的文件路径
    return await _channel.invokeMethod('getOpenedFiles');
  }
}
```

**Linux**:
```dart
class LinuxPlatformIntegration implements PlatformIntegration {
  @override
  Future<void> registerFileAssociations() async {
    // 创建 .desktop 文件
    // 注册 MIME types
  }
}
```

#### 4.4 StateRepository

**职责**: 持久化应用状态

**接口**:
```dart
class StateRepository {
  final SharedPreferences _prefs;
  final Database _db;
  
  Future<void> saveScrollPosition(double position);
  Future<double?> getScrollPosition();
  Future<void> saveCurrentFolder(String folderPath);
  Future<String?> getCurrentFolder();
  Future<void> addRecentFolder(String folderPath);
  Future<List<String>> getRecentFolders();
}
```

**数据存储**:

1. **SharedPreferences** (轻量级数据):
   - 当前文件夹路径
   - 滚动位置
   - 用户偏好设置

2. **SQLite** (结构化数据):
   - 最近浏览的文件夹列表（最多10个）
   - 图片浏览历史
   - 缓存元数据

**数据库Schema**:
```sql
CREATE TABLE recent_folders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  folder_path TEXT NOT NULL UNIQUE,
  last_visited INTEGER NOT NULL,
  image_count INTEGER
);

CREATE TABLE browse_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  image_path TEXT NOT NULL,
  viewed_at INTEGER NOT NULL,
  duration_seconds INTEGER
);

CREATE TABLE cache_metadata (
  cache_key TEXT PRIMARY KEY,
  original_path TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  last_accessed INTEGER NOT NULL
);
```

## 数据模型

### ImageItem

表示瀑布流中的单个图片项

```dart
class ImageItem {
  final String id;              // 唯一标识符
  final String filePath;        // 文件完整路径
  final String fileName;        // 文件名
  final int width;              // 原始宽度
  final int height;             // 原始高度
  final int fileSize;           // 文件大小（字节）
  final DateTime modifiedTime;  // 修改时间
  final ImageFormat format;     // 图片格式
  
  ImageItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.modifiedTime,
    required this.format,
  });
  
  double get aspectRatio => width / height;
}
```

### ImageFormat

支持的图片格式枚举

```dart
enum ImageFormat {
  jpeg,
  png,
  gif,
  webp,
  bmp,
  unknown;
  
  static ImageFormat fromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return ImageFormat.jpeg;
      case '.png':
        return ImageFormat.png;
      case '.gif':
        return ImageFormat.gif;
      case '.webp':
        return ImageFormat.webp;
      case '.bmp':
        return ImageFormat.bmp;
      default:
        return ImageFormat.unknown;
    }
  }
  
  static const List<String> supportedExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'
  ];
}
```

### ImageData

表示图片的二进制数据

```dart
class ImageData {
  final Uint8List bytes;
  final int width;
  final int height;
  
  ImageData({
    required this.bytes,
    required this.width,
    required this.height,
  });
  
  double get aspectRatio => width / height;
  int get sizeInBytes => bytes.length;
}
```

### ImageMetadata

表示图片的元数据信息

```dart
class ImageMetadata {
  final String fileName;
  final String filePath;
  final int width;
  final int height;
  final int fileSize;
  final ImageFormat format;
  final DateTime modifiedTime;
  final ExifData? exifData;
  
  ImageMetadata({
    required this.fileName,
    required this.filePath,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.format,
    required this.modifiedTime,
    this.exifData,
  });
  
  String get resolutionString => '$width × $height';
  String get fileSizeString => _formatFileSize(fileSize);
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
```

### ExifData

表示EXIF元数据

```dart
class ExifData {
  final DateTime? dateTaken;
  final String? cameraModel;
  final String? cameraMake;
  final GpsLocation? gpsLocation;
  final double? focalLength;
  final double? aperture;
  final String? iso;
  final String? exposureTime;
  
  ExifData({
    this.dateTaken,
    this.cameraModel,
    this.cameraMake,
    this.gpsLocation,
    this.focalLength,
    this.aperture,
    this.iso,
    this.exposureTime,
  });
}

class GpsLocation {
  final double latitude;
  final double longitude;
  
  GpsLocation({
    required this.latitude,
    required this.longitude,
  });
  
  String get coordinatesString => 
    '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}
```

### FileInfo

表示文件系统中的文件信息

```dart
class FileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modifiedTime;
  final ImageFormat format;
  
  FileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.modifiedTime,
    required this.format,
  });
  
  bool get isSupported => format != ImageFormat.unknown;
}
```

### BrowseState

表示应用的浏览状态（用于持久化）

```dart
class BrowseState {
  final BrowseMode mode;
  final String? currentFolderPath;
  final double scrollPosition;
  final String? currentImagePath;
  
  BrowseState({
    required this.mode,
    this.currentFolderPath,
    this.scrollPosition = 0.0,
    this.currentImagePath,
  });
  
  Map<String, dynamic> toJson() => {
    'mode': mode.toString(),
    'currentFolderPath': currentFolderPath,
    'scrollPosition': scrollPosition,
    'currentImagePath': currentImagePath,
  };
  
  factory BrowseState.fromJson(Map<String, dynamic> json) => BrowseState(
    mode: BrowseMode.values.firstWhere(
      (e) => e.toString() == json['mode'],
      orElse: () => BrowseMode.systemBrowse,
    ),
    currentFolderPath: json['currentFolderPath'],
    scrollPosition: json['scrollPosition'] ?? 0.0,
    currentImagePath: json['currentImagePath'],
  );
}
```

## 正确性属性

*属性是一个特征或行为，应该在系统的所有有效执行中保持为真——本质上是关于系统应该做什么的形式化陈述。属性作为人类可读规范和机器可验证正确性保证之间的桥梁。*

### 属性 1: 支持格式加载正确性

*对于任意*支持的图片格式（JPEG、PNG、GIF、WebP、BMP），图片浏览器都应该能够成功加载并显示该格式的图片，不应该抛出异常或显示错误。

**验证需求: 2.1, 2.2, 2.3, 2.4, 2.5**

### 属性 2: 不支持格式错误处理

*对于任意*不支持的图片格式，图片浏览器应该显示错误提示信息，而不是崩溃或显示损坏的图片。

**验证需求: 2.6**

### 属性 3: 瀑布流最短列放置

*对于任意*图片序列，当将图片添加到瀑布流时，每张图片都应该被放置在当前高度最小的列中。

**验证需求: 3.2**

### 属性 4: 瀑布流宽高比保持

*对于任意*图片，在瀑布流中显示时，其显示的宽高比应该与原始图片的宽高比相同（误差小于1%）。

**验证需求: 3.3**

### 属性 5: 瀑布流列数响应式计算

*对于任意*屏幕宽度，瀑布流的列数应该根据设备类型正确计算：移动设备（<600px）显示2列，平板设备（600-1024px）显示3列，桌面设备（≥1024px）显示4列或更多。

**验证需求: 3.5, 3.6, 3.7, 3.8**

### 属性 6: 缩略图宽高比保持

*对于任意*图片，生成的缩略图应该保持原图的宽高比（误差小于1%）。

**验证需求: 4.2**

### 属性 7: 缩略图宽度约束

*对于任意*图片，生成的缩略图宽度应该不超过400像素。

**验证需求: 4.3**

### 属性 8: 缩略图缓存往返

*对于任意*图片，首次加载时生成缩略图并缓存后，第二次加载应该从缓存中读取，且两次获取的缩略图应该在视觉上一致（像素差异小于5%）。

**验证需求: 4.4, 4.5**

### 属性 9: 缓存大小限制

*对于任意*缓存操作序列，当缓存大小超过500MB时，系统应该自动删除最久未使用的缓存项，使缓存大小降至500MB以下。

**验证需求: 4.6**

### 属性 10: 单图查看器加载原始分辨率

*对于任意*图片，在单图查看器中加载时，应该加载图片的原始分辨率版本，而不是缩略图。

**验证需求: 5.2**

### 属性 11: 滑动导航往返

*对于任意*图片列表和起始索引，在单图查看器中连续向左滑动N次再向右滑动N次，应该返回到原始图片（前提是不超出边界）。

**验证需求: 5.5, 5.6**

### 属性 12: 缩放比例边界约束

*对于任意*缩放操作序列，单图查看器中的最终缩放比例应该始终在[0.5, 5.0]范围内，超出范围的缩放应该被自动修正到边界值。

**验证需求: 6.2, 6.3, 6.6, 6.7**

### 属性 13: 双击缩放往返

*对于任意*图片，在单图查看器中连续双击两次，应该返回到初始的缩放状态（适应屏幕大小）。

**验证需求: 6.5**

### 属性 14: 文件夹加载完整性

*对于任意*文件夹，文件夹预览器加载的图片数量应该等于该文件夹中支持格式的图片文件数量（或1000，取较小值）。

**验证需求: 7.2**

### 属性 15: 文件夹图片排序

*对于任意*文件夹，文件夹预览器中的图片应该按文件名字母顺序排列。

**验证需求: 7.6**

### 属性 16: 元数据完整性

*对于任意*图片，元数据面板应该显示所有必需字段：文件名、分辨率、文件大小、格式和修改日期。如果图片包含EXIF数据，还应该显示EXIF信息。

**验证需求: 8.2, 8.3, 8.4, 8.5, 8.6, 8.7**

### 属性 17: 文件不存在错误处理

*对于任意*不存在的文件路径，图片浏览器应该显示占位图标和"文件未找到"提示，而不是崩溃。

**验证需求: 10.1**

### 属性 18: 文件损坏错误处理

*对于任意*损坏的图片文件，图片浏览器应该显示错误图标和"图片损坏"提示，而不是崩溃。

**验证需求: 10.2**

### 属性 19: 状态持久化往返

*对于任意*浏览状态（文件夹路径、滚动位置），保存后再恢复，应该返回到完全相同的浏览状态。

**验证需求: 11.1, 11.2, 11.3, 11.4**

### 属性 20: 最近文件夹数量限制

*对于任意*文件夹访问序列，保存的最近浏览文件夹数量应该不超过10个，超过时应该删除最旧的记录。

**验证需求: 11.5**

### 属性 21: 启动模式确定性

*对于任意*启动方式，应用应该根据启动参数确定性地进入系统图片浏览模式（无文件参数）或文件关联打开模式（有文件参数），且两种模式互斥。

**验证需求: 12.1, 13.1**

### 属性 22: 系统目录扫描完整性

*对于任意*系统环境，在系统图片浏览模式下，应该扫描所有预定义目录（Pictures、Desktop、Downloads及用户自定义目录），找到的图片总数应该等于这些目录中支持格式的图片文件总数（或10000，取较小值）。

**验证需求: 12.2, 12.3, 12.4, 12.5, 12.6, 12.7**

### 属性 23: 文件关联模式文件夹一致性

*对于任意*通过文件关联打开的图片，单图查看器中可浏览的图片集合应该等于该图片所在文件夹中所有支持格式的图片。

**验证需求: 13.3, 13.4**

### 属性 24: 文件关联格式支持

*对于任意*支持的图片格式（JPEG、PNG、GIF、WebP、BMP），在桌面平台上都应该能够通过文件关联打开，且接收到的文件路径应该与原始文件路径完全一致。

**验证需求: 14.4, 14.5, 14.6, 14.7, 14.8, 14.11**

## 错误处理

### 错误分类

应用采用分层错误处理策略，根据错误类型采取不同的处理方式：

#### 1. 可恢复错误 (Recoverable Errors)

这些错误不影响应用的整体功能，可以优雅降级：

**文件系统错误**:
- **文件不存在**: 显示占位图标和提示信息，不中断浏览
- **权限不足**: 显示权限提示，引导用户授权，跳过无权限的文件
- **文件损坏**: 显示错误图标，继续加载其他图片

**网络/IO错误**:
- **加载超时**: 显示超时提示，提供重试按钮
- **磁盘空间不足**: 跳过缓存生成，直接加载原图，记录警告日志

**处理策略**:
```dart
class RecoverableError {
  final String message;
  final ErrorType type;
  final Function()? retryAction;
  
  void handle() {
    // 显示用户友好的错误提示
    showErrorSnackbar(message);
    
    // 记录日志用于调试
    logger.warning('Recoverable error: $type - $message');
    
    // 继续执行后续操作
  }
}
```

#### 2. 不可恢复错误 (Unrecoverable Errors)

这些错误会导致应用无法正常工作，需要特殊处理：

**内存不足**:
- 清理内存缓存
- 减少同时加载的图片数量
- 如果仍然失败，显示错误页面并建议重启应用

**数据库损坏**:
- 尝试重建数据库
- 如果失败，清除所有持久化数据，重新初始化

**平台API调用失败**:
- 记录详细错误信息
- 禁用相关功能（如文件关联）
- 显示降级功能提示

**处理策略**:
```dart
class UnrecoverableError {
  final String message;
  final ErrorType type;
  final StackTrace stackTrace;
  
  void handle() {
    // 记录详细错误信息
    logger.error('Unrecoverable error: $type - $message', stackTrace);
    
    // 保存应用状态
    saveCurrentState();
    
    // 显示错误页面
    showErrorPage(
      title: '发生错误',
      message: message,
      actions: [
        ErrorAction.restart,
        ErrorAction.reportBug,
      ],
    );
  }
}
```

### 错误边界

使用Flutter的ErrorWidget和Zone来捕获和处理未预期的错误：

```dart
void main() {
  // 捕获Flutter框架错误
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.error('Flutter error', details.exception, details.stack);
    // 在生产环境显示友好的错误页面
    if (kReleaseMode) {
      // 显示自定义错误widget
    }
  };
  
  // 捕获异步错误
  runZonedGuarded(() {
    runApp(MyApp());
  }, (error, stackTrace) {
    logger.error('Async error', error, stackTrace);
  });
}
```

### 崩溃恢复

应用崩溃后的恢复机制：

1. **状态保存**: 在应用生命周期的关键点自动保存状态
2. **崩溃检测**: 启动时检查上次是否正常退出
3. **状态恢复**: 如果检测到崩溃，恢复到上次保存的状态

```dart
class CrashRecoveryManager {
  static const String _crashFlagKey = 'app_crashed';
  static const String _lastStateKey = 'last_browse_state';
  
  Future<void> markAppStarted() async {
    await _prefs.setBool(_crashFlagKey, true);
  }
  
  Future<void> markAppClosedNormally() async {
    await _prefs.setBool(_crashFlagKey, false);
  }
  
  Future<bool> didCrashLastTime() async {
    return _prefs.getBool(_crashFlagKey) ?? false;
  }
  
  Future<BrowseState?> recoverLastState() async {
    if (await didCrashLastTime()) {
      final stateJson = _prefs.getString(_lastStateKey);
      if (stateJson != null) {
        return BrowseState.fromJson(jsonDecode(stateJson));
      }
    }
    return null;
  }
}
```

### 错误日志

使用分级日志系统记录不同严重程度的错误：

```dart
enum LogLevel {
  debug,   // 调试信息
  info,    // 一般信息
  warning, // 警告（可恢复错误）
  error,   // 错误（不可恢复错误）
  fatal,   // 致命错误（导致崩溃）
}

class Logger {
  void log(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    // 控制台输出
    print('[$level] $message');
    
    // 写入本地日志文件
    _writeToFile(level, message, error, stackTrace);
    
    // 在生产环境上报到错误追踪服务
    if (kReleaseMode && level.index >= LogLevel.error.index) {
      _reportToErrorTracking(level, message, error, stackTrace);
    }
  }
}
```

## 测试策略

### 测试方法

应用采用双重测试策略，结合单元测试和基于属性的测试：

#### 1. 单元测试 (Unit Tests)

用于验证特定示例、边界情况和错误条件：

**适用场景**:
- 具体的边界值测试（如缩放比例边界0.5和5.0）
- 特定的错误场景（如文件不存在、权限不足）
- 集成点测试（如平台通道调用）
- UI组件的特定交互

**示例**:
```dart
test('缩略图宽度不应超过400像素', () {
  final generator = ThumbnailGenerator();
  final image = createTestImage(width: 1920, height: 1080);
  
  final thumbnail = await generator.generateThumbnail(image);
  
  expect(thumbnail.width, lessThanOrEqualTo(400));
});

test('文件不存在时应显示错误提示', () {
  final controller = ImageController();
  
  expect(
    () => controller.loadImage('/nonexistent/path.jpg'),
    throwsA(isA<FileNotFoundException>()),
  );
});
```

#### 2. 基于属性的测试 (Property-Based Tests)

用于验证通用属性在大量随机输入下的正确性：

**配置**:
- 测试框架: `test` + `faker` (Dart)
- 每个属性测试最少100次迭代
- 使用随机种子确保可重现性

**标记格式**:
```dart
// Feature: image-gallery-viewer, Property 3: 瀑布流最短列放置
test('瀑布流应将图片放置在最短列', () {
  final random = Random(42); // 固定种子
  
  for (int i = 0; i < 100; i++) {
    // 生成随机图片列表
    final images = generateRandomImages(random, count: random.nextInt(50) + 10);
    final columnCount = random.nextInt(3) + 2; // 2-4列
    
    // 执行布局算法
    final layout = WaterfallLayoutEngine(columnCount: columnCount);
    final columns = layout.calculateLayout(images);
    
    // 验证每张图片都被放置在添加时的最短列
    // ... 验证逻辑
  }
});
```

**属性测试覆盖**:

每个正确性属性都应该有对应的基于属性的测试：

| 属性编号 | 属性名称 | 测试方法 |
|---------|---------|---------|
| 1 | 支持格式加载正确性 | 生成各种格式的随机图片，验证加载成功 |
| 3 | 瀑布流最短列放置 | 生成随机图片序列，验证放置算法 |
| 4 | 瀑布流宽高比保持 | 生成随机宽高比图片，验证显示比例 |
| 6 | 缩略图宽高比保持 | 生成随机尺寸图片，验证缩略图比例 |
| 8 | 缩略图缓存往返 | 生成随机图片，验证缓存一致性 |
| 11 | 滑动导航往返 | 生成随机滑动序列，验证位置不变 |
| 12 | 缩放比例边界约束 | 生成随机缩放操作，验证边界约束 |
| 19 | 状态持久化往返 | 生成随机状态，验证保存恢复一致性 |

### 测试数据生成

使用生成器创建测试数据：

```dart
class TestDataGenerator {
  final Random random;
  
  TestDataGenerator(this.random);
  
  // 生成随机图片项
  ImageItem generateRandomImage() {
    return ImageItem(
      id: uuid.v4(),
      filePath: '/test/image_${random.nextInt(10000)}.jpg',
      fileName: 'image_${random.nextInt(10000)}.jpg',
      width: random.nextInt(3000) + 100,
      height: random.nextInt(3000) + 100,
      fileSize: random.nextInt(10000000) + 1000,
      modifiedTime: DateTime.now().subtract(
        Duration(days: random.nextInt(365)),
      ),
      format: ImageFormat.values[random.nextInt(5)],
    );
  }
  
  // 生成随机图片列表
  List<ImageItem> generateRandomImages({required int count}) {
    return List.generate(count, (_) => generateRandomImage());
  }
  
  // 生成随机缩放操作序列
  List<double> generateRandomScaleSequence({required int length}) {
    return List.generate(
      length,
      (_) => random.nextDouble() * 10, // 0-10倍缩放
    );
  }
}
```

### 测试覆盖率目标

- **代码覆盖率**: 最低80%
- **分支覆盖率**: 最低75%
- **关键路径覆盖率**: 100%（瀑布流布局、缓存管理、模式切换）

### 集成测试

除了单元测试和属性测试，还需要进行集成测试：

**端到端测试场景**:
1. 启动应用 → 扫描系统图片 → 显示瀑布流
2. 点击图片 → 打开单图查看器 → 滑动切换 → 缩放平移
3. 通过文件关联打开 → 显示目标图片 → 浏览同文件夹图片
4. 关闭应用 → 重新打开 → 恢复到上次状态

**性能测试**:
- 大量图片加载性能（1000+张图片）
- 内存使用监控
- 缓存效率测试
- 滚动流畅度测试（FPS监控）

### 平台特定测试

由于应用是跨平台的，需要在各平台上进行测试：

**测试矩阵**:
- iOS (iPhone, iPad)
- Android (手机, 平板)
- Windows (10, 11)
- macOS (Intel, Apple Silicon)
- Linux (Ubuntu, Fedora)
- Web (Chrome, Firefox, Safari)

**平台特定功能测试**:
- 文件关联注册（桌面平台）
- 文件系统访问权限（移动平台）
- 系统目录扫描（各平台路径差异）
