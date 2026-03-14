# 实现计划: 图片浏览器 (Image Gallery Viewer)

## 概述

本实现计划将图片浏览器的设计转化为可执行的开发任务。应用基于 Flutter/Dart 开发，采用分层架构（Presentation、Application、Domain、Infrastructure），支持跨平台运行。

核心功能包括：
- 瀑布流布局展示图片集合
- 高性能缩略图生成与缓存
- 单图全屏查看（缩放、平移、滑动）
- 文件夹快速预览
- 两种浏览模式（系统浏览、文件关联打开）
- 跨平台文件关联支持

## 任务列表

- [x] 1. 项目初始化和依赖配置
  - 创建 Flutter 项目结构
  - 配置 pubspec.yaml 添加所需依赖（image、flutter_cache_manager、path_provider、file_picker、shared_preferences、sqflite、provider/riverpod）
  - 设置多平台支持（iOS、Android、Windows、macOS、Linux、Web）
  - 创建基础目录结构（lib/presentation、lib/application、lib/domain、lib/infrastructure）
  - _需求: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [ ] 2. 数据模型和枚举实现
  - [x] 2.1 实现核心数据模型
    - 创建 lib/domain/models/ 目录
    - 实现 ImageFormat 枚举（支持 JPEG、PNG、GIF、WebP、BMP）
    - 实现 ImageItem 类（包含 id、filePath、fileName、width、height、fileSize、modifiedTime、format）
    - 实现 ImageData 类（包含 bytes、width、height）
    - 实现 FileInfo 类（包含 path、name、size、modifiedTime、format）
    - _需求: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [ ]* 2.2 为 ImageFormat 编写属性测试
    - **属性 1: 支持格式加载正确性**
    - **验证需求: 2.1, 2.2, 2.3, 2.4, 2.5**

  - [x] 2.3 实现元数据模型
    - 实现 ExifData 类（包含 dateTaken、cameraModel、cameraMake、gpsLocation 等）
    - 实现 GpsLocation 类（包含 latitude、longitude）
    - 实现 ImageMetadata 类（包含文件信息和 EXIF 数据）
    - _需求: 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

  - [x] 2.4 实现状态模型
    - 实现 BrowseMode 枚举（systemBrowse、fileAssociation）
    - 实现 BrowseState 类（包含 mode、currentFolderPath、scrollPosition、currentImagePath）
    - 添加 JSON 序列化/反序列化方法
    - _需求: 11.1, 11.2, 12.1, 13.1_

- [ ] 3. Infrastructure Layer - 文件系统服务
  - [x] 3.1 实现 FileSystemService 接口和实现类
    - 创建 lib/infrastructure/services/ 目录
    - 定义 FileSystemService 抽象接口
    - 实现 FileSystemServiceImpl 类
    - 实现 getSystemImageDirectories() 方法（根据平台返回 Pictures、Desktop、Downloads 目录）
    - 实现 listImagesInFolder() 方法（扫描文件夹并过滤支持的图片格式）
    - 实现 fileExists()、getModifiedTime()、getFileSize() 方法
    - _需求: 12.4, 12.5, 12.6, 7.2_

  - [ ]* 3.2 为文件系统服务编写单元测试
    - 测试不同平台的系统目录获取
    - 测试文件夹扫描和格式过滤
    - 测试文件不存在的错误处理
    - _需求: 10.1_

- [ ] 4. Infrastructure Layer - 缩略图生成器
  - [x] 4.1 实现 ThumbnailGenerator 类
    - 创建 lib/infrastructure/generators/ 目录
    - 实现 generateThumbnail() 方法（使用 image 包解码、缩放、编码）
    - 实现 resizeImage() 方法（保持宽高比，最大宽度 400px）
    - 使用 cubic 插值算法确保高质量缩放
    - 添加错误处理（文件损坏、解码失败）
    - _需求: 4.1, 4.2, 4.3_

  - [ ]* 4.2 为缩略图生成器编写属性测试
    - **属性 6: 缩略图宽高比保持**
    - **属性 7: 缩略图宽度约束**
    - **验证需求: 4.2, 4.3**

  - [ ]* 4.3 为缩略图生成器编写单元测试
    - 测试图片损坏时的错误处理
    - 测试不支持格式的错误处理
    - _需求: 10.2, 2.6_


- [ ] 5. Infrastructure Layer - 缓存管理器
  - [x] 5.1 实现 CacheManager 类
    - 创建 lib/infrastructure/cache/ 目录
    - 实现内存缓存（LRU，最多 100 张缩略图）
    - 实现磁盘缓存（使用 flutter_cache_manager，最大 500MB）
    - 实现 getThumbnail() 方法（先查内存缓存，再查磁盘缓存）
    - 实现 cacheThumbnail() 方法（同时写入内存和磁盘缓存）
    - 实现 clearOldCache() 方法（LRU 淘汰策略）
    - 实现 getCacheSize() 方法
    - 实现 generateCacheKey() 方法（基于文件路径和修改时间的 MD5）
    - _需求: 4.4, 4.5, 4.6_

  - [ ]* 5.2 为缓存管理器编写属性测试
    - **属性 8: 缩略图缓存往返**
    - **属性 9: 缓存大小限制**
    - **验证需求: 4.4, 4.5, 4.6**

  - [ ]* 5.3 为缓存管理器编写单元测试
    - 测试磁盘空间不足时的降级处理
    - 测试缓存键生成的唯一性
    - _需求: 10.4_

- [ ] 6. Infrastructure Layer - 状态持久化
  - [x] 6.1 实现 StateRepository 类
    - 创建 lib/infrastructure/repositories/ 目录
    - 使用 SharedPreferences 存储轻量级数据（当前文件夹、滚动位置）
    - 使用 SQLite 存储结构化数据（最近文件夹列表、浏览历史）
    - 创建数据库表（recent_folders、browse_history、cache_metadata）
    - 实现 saveScrollPosition()、getScrollPosition() 方法
    - 实现 saveCurrentFolder()、getCurrentFolder() 方法
    - 实现 addRecentFolder()、getRecentFolders() 方法（最多 10 个）
    - _需求: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6_

  - [ ]* 6.2 为状态持久化编写属性测试
    - **属性 19: 状态持久化往返**
    - **属性 20: 最近文件夹数量限制**
    - **验证需求: 11.1, 11.2, 11.3, 11.4, 11.5**

- [x] 7. Infrastructure Layer - 平台集成
  - [x] 7.1 实现 PlatformIntegration 接口和平台特定实现
    - 创建 lib/infrastructure/platform/ 目录
    - 定义 PlatformIntegration 抽象接口
    - 实现 WindowsPlatformIntegration 类（使用 MethodChannel 注册文件关联）
    - 实现 MacOSPlatformIntegration 类（通过 Info.plist 配置）
    - 实现 LinuxPlatformIntegration 类（创建 .desktop 文件）
    - 实现 getLaunchArguments() 方法（获取启动参数）
    - 实现 extractExifData() 方法（解析 EXIF 信息）
    - _需求: 14.1, 14.2, 14.3, 14.11, 8.7_

  - [x] 7.2 创建原生平台代码（Windows、macOS、Linux）
    - 为 Windows 创建 MethodChannel 处理器（注册表操作）
    - 为 macOS 配置 Info.plist（CFBundleDocumentTypes）
    - 为 Linux 创建 .desktop 文件模板
    - _需求: 14.1, 14.2, 14.3, 14.9, 14.10_

  - [ ]* 7.3 为平台集成编写单元测试
    - 测试启动参数解析
    - 测试文件关联路径传递
    - _需求: 14.11_

- [ ] 8. 检查点 - 基础设施层完成
  - 确保所有测试通过，询问用户是否有问题

- [ ] 9. Domain Layer - 瀑布流布局引擎
  - [x] 9.1 实现 WaterfallLayoutEngine 类
    - 创建 lib/domain/layout/ 目录
    - 实现 calculateLayout() 方法（瀑布流布局算法）
    - 实现 findShortestColumn() 方法（找到当前高度最小的列）
    - 实现 calculateItemHeight() 方法（根据宽高比计算图片项高度）
    - 实现 calculateColumnCount() 方法（根据屏幕宽度计算列数）
    - _需求: 3.1, 3.2, 3.3, 3.5, 3.6, 3.7, 3.8_

  - [ ]* 9.2 为瀑布流布局引擎编写属性测试
    - **属性 3: 瀑布流最短列放置**
    - **属性 4: 瀑布流宽高比保持**
    - **属性 5: 瀑布流列数响应式计算**
    - **验证需求: 3.2, 3.3, 3.5, 3.6, 3.7, 3.8**


- [-] 10. Domain Layer - 图片仓库
  - [x] 10.1 实现 ImageRepository 接口和实现类
    - 创建 lib/domain/repositories/ 目录
    - 定义 ImageRepository 抽象接口
    - 实现 ImageRepositoryImpl 类
    - 实现 scanSystemDirectories() 方法（并行扫描系统目录，最多 10000 张）
    - 实现 scanFolder() 方法（扫描指定文件夹，最多 1000 张）
    - 实现 getRecentFolders()、saveRecentFolder() 方法
    - 添加文件格式过滤和排序逻辑
    - _需求: 12.2, 12.3, 12.4, 12.5, 12.6, 12.7, 12.8, 7.2, 7.7_

  - [ ]* 10.2 为图片仓库编写属性测试
    - **属性 14: 文件夹加载完整性**
    - **属性 15: 文件夹图片排序**
    - **属性 22: 系统目录扫描完整性**
    - **验证需求: 7.2, 7.6, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7, 12.8**

  - [ ]* 10.3 为图片仓库编写单元测试
    - 测试权限不足时的错误处理
    - 测试文件夹不存在的错误处理
    - _需求: 10.5_

- [-] 11. Application Layer - 模式管理器
  - [x] 11.1 实现 ModeManager 类
    - 创建 lib/application/managers/ 目录
    - 实现 initializeMode() 方法（根据启动参数确定模式）
    - 实现 switchToSystemBrowse() 方法
    - 实现 isFileAssociationMode() 方法
    - 使用 ChangeNotifier 实现状态通知
    - _需求: 12.1, 13.1, 13.6_

  - [ ]* 11.2 为模式管理器编写属性测试
    - **属性 21: 启动模式确定性**
    - **验证需求: 12.1, 13.1**

- [-] 12. Application Layer - 图片控制器
  - [x] 12.1 实现 ImageController 类
    - 创建 lib/application/controllers/ 目录
    - 实现 loadThumbnail() 方法（优先从缓存加载）
    - 实现 loadFullImage() 方法（加载原始分辨率）
    - 实现 loadMetadata() 方法（加载元数据和 EXIF）
    - 添加加载状态管理（loading、success、error）
    - 添加超时处理（30 秒）
    - _需求: 4.4, 4.5, 5.2, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 10.3_

  - [ ]* 12.2 为图片控制器编写属性测试
    - **属性 10: 单图查看器加载原始分辨率**
    - **属性 16: 元数据完整性**
    - **验证需求: 5.2, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7**

  - [ ]* 12.3 为图片控制器编写单元测试
    - 测试加载超时的错误处理
    - 测试文件不存在的错误处理
    - 测试文件损坏的错误处理
    - _需求: 10.1, 10.2, 10.3_

- [-] 13. Application Layer - 图库控制器
  - [x] 13.1 实现 GalleryController 类
    - 实现 loadSystemImages() 方法（系统浏览模式）
    - 实现 loadFolderImages() 方法（文件夹浏览模式）
    - 实现 loadMoreImages() 方法（分页加载）
    - 实现 setMode() 方法（切换浏览模式）
    - 使用 Stream 发布图片列表更新
    - 集成 ImageRepository 和 CacheManager
    - _需求: 12.1, 12.2, 12.3, 13.2, 13.3, 3.4_

  - [ ]* 13.2 为图库控制器编写属性测试
    - **属性 23: 文件关联模式文件夹一致性**
    - **验证需求: 13.3, 13.4**

- [ ] 14. 检查点 - 应用层和领域层完成
  - 确保所有测试通过，询问用户是否有问题


- [x] 15. Presentation Layer - 瀑布流视图组件
  - [ ] 15.1 实现 WaterfallView Widget
    - 创建 lib/presentation/views/ 目录
    - 创建 WaterfallView StatefulWidget
    - 实现 _buildWaterfallLayout() 方法（使用 CustomScrollView 和 SliverList）
    - 实现 _calculateColumnCount() 方法（响应式列数计算）
    - 实现 _loadMoreImages() 方法（滚动到底部时触发）
    - 实现 _handleResize() 方法（屏幕尺寸变化时重新布局）
    - 添加 ScrollController 监听滚动事件
    - 集成 GalleryController 获取图片流
    - _需求: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_

  - [ ] 15.2 实现图片项 Widget
    - 创建 ImageItemWidget（显示缩略图）
    - 添加加载指示器
    - 添加错误占位图
    - 实现点击事件处理
    - _需求: 5.1, 10.1, 10.2_

  - [ ]* 15.3 为瀑布流视图编写 Widget 测试
    - 测试列数响应式变化
    - 测试滚动加载更多
    - 测试图片点击事件

- [x] 16. Presentation Layer - 单图查看器组件
  - [ ] 16.1 实现 SingleImageViewer Widget
    - 创建 SingleImageViewer StatefulWidget
    - 使用 InteractiveViewer 实现缩放和平移
    - 实现 _handleSwipe() 方法（使用 PageView 或 GestureDetector）
    - 实现 _handleZoom() 方法（缩放比例限制在 0.5-5.0）
    - 实现 _handlePan() 方法（平移处理）
    - 实现 _handleDoubleTap() 方法（双击缩放切换）
    - 实现 _loadFullResolutionImage() 方法
    - 添加加载指示器和错误处理
    - _需求: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

  - [ ]* 16.2 为单图查看器编写属性测试
    - **属性 11: 滑动导航往返**
    - **属性 12: 缩放比例边界约束**
    - **属性 13: 双击缩放往返**
    - **验证需求: 5.5, 5.6, 6.2, 6.3, 6.5, 6.6, 6.7**

  - [ ] 16.3 添加工具栏和控制按钮
    - 实现关闭按钮
    - 实现"文件夹预览"按钮
    - 实现"信息"按钮
    - 实现"返回系统浏览"按钮（文件关联模式）
    - _需求: 5.4, 7.1, 8.1, 13.6_

- [x] 17. Presentation Layer - 文件夹预览组件
  - [x] 17.1 实现 FolderPreview Widget
    - 创建 FolderPreview StatelessWidget
    - 使用 ListView.builder 实现水平滚动列表
    - 实现 _buildThumbnailList() 方法
    - 实现 _highlightCurrentImage() 方法（高亮当前图片）
    - 实现 _scrollToCurrentImage() 方法（自动滚动到当前图片）
    - 添加图片选择回调
    - _需求: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

  - [ ]* 17.2 为文件夹预览编写 Widget 测试
    - 测试当前图片高亮显示
    - 测试图片选择事件
    - 测试自动滚动到当前图片

- [-] 18. Presentation Layer - 元数据面板组件
  - [x] 18.1 实现 MetadataPanel Widget
    - 创建 MetadataPanel StatelessWidget
    - 显示文件名、分辨率、文件大小、格式、修改日期
    - 条件显示 EXIF 数据（拍摄日期、相机型号、GPS 位置）
    - 使用 BottomSheet 或 Dialog 展示
    - _需求: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

  - [ ]* 18.2 为元数据面板编写 Widget 测试
    - 测试必需字段显示
    - 测试 EXIF 数据条件显示

- [ ] 19. 检查点 - 展示层核心组件完成
  - 确保所有测试通过，询问用户是否有问题


- [-] 20. 应用启动和路由管理
  - [x] 20.1 实现应用入口和初始化
    - 创建 lib/main.dart
    - 实现 main() 函数（配置错误处理、Zone）
    - 实现应用初始化逻辑（数据库、缓存、平台集成）
    - 实现 CrashRecoveryManager（崩溃检测和状态恢复）
    - 根据启动参数初始化 ModeManager
    - _需求: 10.6, 12.1, 13.1_

  - [x] 20.2 实现路由和导航
    - 配置 MaterialApp 路由
    - 实现系统浏览模式的初始路由（显示瀑布流）
    - 实现文件关联模式的初始路由（直接打开单图查看器）
    - 实现模式切换逻辑
    - _需求: 12.1, 13.1, 13.2, 13.5, 13.6_

  - [ ]* 20.3 为启动流程编写集成测试
    - 测试系统浏览模式启动
    - 测试文件关联模式启动
    - 测试崩溃恢复

- [x] 21. 错误处理和日志系统
  - [x] 21.1 实现统一错误处理
    - 创建 lib/core/errors/ 目录
    - 定义错误类型（RecoverableError、UnrecoverableError）
    - 实现错误处理策略（显示提示、记录日志、降级处理）
    - 配置 FlutterError.onError 和 runZonedGuarded
    - _需求: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

  - [x] 21.2 实现日志系统
    - 创建 Logger 类（支持多级日志）
    - 实现日志写入本地文件
    - 实现日志上报（可选，生产环境）
    - _需求: 10.4_

  - [ ]* 21.3 为错误处理编写属性测试
    - **属性 17: 文件不存在错误处理**
    - **属性 18: 文件损坏错误处理**
    - **验证需求: 10.1, 10.2**

- [ ] 22. 性能优化
  - [x] 22.1 实现图片懒加载和预加载
    - 实现可视区域检测（只加载可见图片）
    - 实现预加载策略（提前加载即将可见的图片）
    - 优化内存使用（及时释放不可见图片）
    - _需求: 9.1, 9.5_

  - [x] 22.2 优化滚动性能
    - 使用 RepaintBoundary 减少重绘
    - 优化 Widget 构建（使用 const 构造函数）
    - 实现帧率监控（确保 30 FPS 以上）
    - _需求: 9.1_

  - [x] 22.3 优化图片加载性能
    - 实现缩略图优先加载策略
    - 优化缓存命中率
    - 添加加载超时和重试机制
    - _需求: 9.2, 9.3, 9.4, 10.3_

  - [ ]* 22.4 编写性能测试
    - 测试大量图片加载性能（1000+ 张）
    - 测试滚动流畅度（FPS 监控）
    - 测试内存使用
    - 测试缓存效率

- [x] 23. 平台特定功能实现
  - [x] 23.1 实现桌面端文件关联
    - 为 Windows 实现注册表操作（原生代码）
    - 为 macOS 配置 Info.plist 和处理文件打开事件
    - 为 Linux 创建 .desktop 文件和 MIME 类型注册
    - 实现"设置为默认应用"功能
    - _需求: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7, 14.8, 14.9, 14.10_

  - [ ]* 23.2 为文件关联编写属性测试
    - **属性 24: 文件关联格式支持**
    - **验证需求: 14.4, 14.5, 14.6, 14.7, 14.8, 14.11**

  - [x] 23.3 实现移动端权限请求
    - 为 iOS 实现照片库访问权限请求
    - 为 Android 实现存储权限请求
    - 添加权限被拒绝的提示和引导
    - _需求: 10.5_

  - [x] 23.4 实现 Web 端适配
    - 使用 Web API 访问文件系统
    - 实现文件选择器（替代系统目录扫描）
    - 优化 Web 端性能（减少内存使用）
    - _需求: 1.6_


- [x] 24. UI/UX 优化和主题
  - [x] 24.1 实现应用主题
    - 创建 lib/presentation/theme/ 目录
    - 定义亮色和暗色主题
    - 实现主题切换功能
    - 配置颜色、字体、间距等设计规范

  - [x] 24.2 添加动画和过渡效果
    - 实现瀑布流图片加载动画（淡入效果）
    - 实现单图查看器打开/关闭动画
    - 实现滑动切换图片的过渡动画
    - 实现缩放和平移的流畅动画
    - _需求: 9.4_

  - [x] 24.3 优化加载状态和错误提示
    - 实现统一的加载指示器样式
    - 实现友好的错误提示 UI
    - 添加重试按钮和操作引导
    - _需求: 5.3, 10.1, 10.2, 10.3, 10.5_

  - [x] 24.4 实现响应式布局
    - 适配不同屏幕尺寸（手机、平板、桌面）
    - 实现横屏和竖屏适配
    - 优化触摸和鼠标交互
    - _需求: 3.5, 3.6, 3.7, 3.8_

- [x] 25. 状态管理集成
  - [x] 25.1 配置状态管理框架
    - 选择并配置状态管理方案（Provider 或 Riverpod）
    - 创建全局状态提供者
    - 实现状态依赖注入

  - [x] 25.2 连接控制器和视图
    - 将 GalleryController 注入到 WaterfallView
    - 将 ImageController 注入到 SingleImageViewer
    - 将 ModeManager 注入到应用根组件
    - 实现状态变化的响应式更新

- [ ] 26. 检查点 - 功能集成完成
  - 确保所有测试通过，询问用户是否有问题

- [ ] 27. 端到端测试
  - [ ]* 27.1 编写系统浏览模式端到端测试
    - 测试启动应用 → 扫描系统图片 → 显示瀑布流
    - 测试点击图片 → 打开单图查看器 → 查看元数据
    - 测试滑动切换图片 → 缩放平移 → 关闭查看器
    - _需求: 12.1, 12.2, 12.3, 5.1, 5.5, 5.6, 6.1, 6.5_

  - [ ]* 27.2 编写文件关联模式端到端测试
    - 测试通过文件关联打开图片 → 显示单图查看器
    - 测试浏览同文件夹图片 → 打开文件夹预览
    - 测试切换到系统浏览模式
    - _需求: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 7.1, 7.5_

  - [ ]* 27.3 编写状态持久化端到端测试
    - 测试关闭应用 → 重新打开 → 恢复到上次状态
    - 测试崩溃恢复 → 恢复到上次浏览位置
    - _需求: 11.1, 11.2, 11.3, 11.4, 10.6_

  - [ ]* 27.4 编写性能端到端测试
    - 测试大量图片加载（1000+ 张）
    - 测试滚动流畅度（FPS 监控）
    - 测试内存使用和缓存效率
    - _需求: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 28. 跨平台测试和调试
  - [ ]* 28.1 在各平台上进行测试
    - 在 iOS（iPhone、iPad）上测试
    - 在 Android（手机、平板）上测试
    - 在 Windows（10、11）上测试
    - 在 macOS（Intel、Apple Silicon）上测试
    - 在 Linux（Ubuntu）上测试
    - 在 Web（Chrome、Firefox、Safari）上测试
    - _需求: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

  - [ ]* 28.2 修复平台特定问题
    - 修复文件系统路径差异问题
    - 修复权限请求问题
    - 修复文件关联注册问题
    - 修复性能问题

- [ ] 29. 文档和代码清理
  - [ ] 29.1 编写代码文档
    - 为公共 API 添加文档注释
    - 编写架构说明文档
    - 编写部署指南

  - [ ] 29.2 代码审查和重构
    - 移除未使用的代码
    - 优化代码结构和命名
    - 确保代码符合 Dart 风格指南
    - 运行 dart analyze 和 dart format

- [ ] 30. 最终检查点
  - 确保所有功能正常工作
  - 确保所有测试通过
  - 确保应用在所有目标平台上运行
  - 询问用户是否准备好发布

## 注意事项

- 标记为 `*` 的任务是可选的测试任务，可以跳过以加快 MVP 开发
- 每个任务都引用了具体的需求编号，确保可追溯性
- 检查点任务用于确保增量验证和用户反馈
- 属性测试验证通用正确性属性，单元测试验证特定示例和边界情况
- 所有代码应使用 Dart/Flutter 实现，遵循 Flutter 最佳实践
- 优先实现核心功能，性能优化和平台特定功能可以后续迭代

## 测试覆盖

本实现计划包含以下测试类型：

1. **属性测试**: 验证 24 个正确性属性（标记为 `*` 的子任务）
2. **单元测试**: 验证特定功能和错误处理（标记为 `*` 的子任务）
3. **Widget 测试**: 验证 UI 组件行为（标记为 `*` 的子任务）
4. **集成测试**: 验证组件间交互（标记为 `*` 的子任务）
5. **端到端测试**: 验证完整用户流程（标记为 `*` 的子任务）
6. **性能测试**: 验证性能要求（标记为 `*` 的子任务）
7. **跨平台测试**: 验证平台兼容性（标记为 `*` 的子任务）

测试覆盖率目标：代码覆盖率 ≥ 80%，分支覆盖率 ≥ 75%，关键路径覆盖率 100%。
