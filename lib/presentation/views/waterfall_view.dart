import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../../application/controllers/gallery_controller.dart';
import '../../application/managers/mode_manager.dart';
import '../../domain/models/image_item.dart';
import '../utils/responsive_layout.dart';
import '../widgets/error_display.dart';
import '../widgets/unified_loading_indicator.dart';
import 'single_image_viewer.dart';

class WaterfallView extends StatefulWidget {
  /// 如果传入，则使用这个列表而不是 controller.images（用于 open with 文件夹模式）
  final List<ImageItem>? overrideImages;
  /// 自定义图片点击回调（用于 open with 文件夹模式从瀑布流重新进入详情页）
  final void Function(List<ImageItem> images, int index)? onImageTap;

  const WaterfallView({
    super.key,
    this.overrideImages,
    this.onImageTap,
  });

  @override
  State<WaterfallView> createState() => _WaterfallViewState();
}

class _WaterfallViewState extends State<WaterfallView> {
  final ScrollController _scrollController = ScrollController();
  Timer? _loadMoreDebounce;
  // folder 模式下，是否临时切换到系统图片视图
  bool _showSystemImages = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _loadMoreDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.overrideImages != null && !_showSystemImages) return; // 文件夹模式不分页
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent * 0.85) return;

    // debounce: only fire once per 300ms
    _loadMoreDebounce?.cancel();
    _loadMoreDebounce = Timer(const Duration(milliseconds: 300), () {
      final controller = context.read<GalleryController>();
      if (!controller.isLoading && controller.hasMoreImages) {
        controller.loadMoreImages();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFolderMode = widget.overrideImages != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Gallery'),
        actions: [
          if (isFolderMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: () {
                  final newVal = !_showSystemImages;
                  setState(() => _showSystemImages = newVal);
                  // 切换到系统图片时，如果还没加载过则触发加载
                  if (newVal) {
                    final controller = context.read<GalleryController>();
                    if (controller.images.isEmpty && !controller.isLoading) {
                      controller.loadSystemImages();
                    }
                  }
                },
                child: Text(
                  _showSystemImages ? 'Folder View' : 'System View',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: Consumer<GalleryController>(
        builder: (context, controller, _) {
          if (controller.images.isEmpty && controller.isLoading) {
            return const UnifiedLoadingIndicator(
              message: 'Loading images...',
              size: LoadingSize.large,
            );
          }

          if (controller.errorMessage != null) {
            return ErrorDisplay(
              message: 'Failed to load images',
              details: controller.errorMessage,
              onRetry: controller.loadSystemImages,
              type: ErrorType.general,
            );
          }

          // overrideImages 优先（open with 文件夹模式），但可被 _showSystemImages 覆盖
          final displayImages = (!_showSystemImages && widget.overrideImages != null)
              ? widget.overrideImages!
              : controller.images;

          if (displayImages.isEmpty) {
            return const EmptyStateDisplay(
              message: 'No images found',
              description: 'Try adding some images to your Pictures folder',
              icon: Icons.photo_library_outlined,
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final cols = ResponsiveLayout.calculateWaterfallColumnsFromWidth(
                constraints.maxWidth,
              );
              return CustomScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  if (controller.isScanning && (widget.overrideImages == null || _showSystemImages))
                    SliverToBoxAdapter(child: _ScanningBanner()),
                  SliverPadding(
                    padding: const EdgeInsets.all(4),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: cols,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childCount: displayImages.length,
                      itemBuilder: (context, index) {
                        final item = displayImages[index];
                        return _GridTile(
                          key: ValueKey(item.filePath),
                          item: item,
                          onTap: () {
                            if (widget.onImageTap != null) {
                              widget.onImageTap!(displayImages, index);
                            } else {
                              _openViewer(context, displayImages, index);
                            }
                          },
                          onDelete: () => context.read<GalleryController>().deleteImage(item.filePath),
                          onSizeResolved: (w, h) =>
                              context.read<GalleryController>().updateImageSize(item.filePath, w, h),
                        );
                      },
                    ),
                  ),
                  if (controller.isLoading && (widget.overrideImages == null || _showSystemImages))
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: UnifiedLoadingIndicator(
                          message: 'Loading more...',
                          size: LoadingSize.medium,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _openViewer(BuildContext context, List<ImageItem> images, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SingleImageViewer(
          images: images,
          initialIndex: index,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid tile - hover 时右下角显示删除按钮
// ---------------------------------------------------------------------------

class _GridTile extends StatefulWidget {
  final ImageItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(int w, int h)? onSizeResolved;

  const _GridTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    this.onSizeResolved,
  });

  @override
  State<_GridTile> createState() => _GridTileState();
}

class _GridTileState extends State<_GridTile> {
  bool _hovered = false;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = (widget.item.width > 1 && widget.item.height > 1)
        ? widget.item.width / widget.item.height
        : 1.0;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: AspectRatio(
            aspectRatio: ratio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 图片 + 点击打开
                GestureDetector(
                  onTap: widget.onTap,
                  child: _ThumbnailImage(
                    filePath: widget.item.filePath,
                    needsSizeResolution: widget.item.width <= 1 || widget.item.height <= 1,
                    onSizeResolved: widget.onSizeResolved,
                  ),
                ),
                // hover 时：底部渐变遮罩 + 文件名 + 大小
                if (_hovered)
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(8, 20, 40, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.item.fileName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatSize(widget.item.fileSize),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // hover 时显示删除按钮
                if (_hovered)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: _DeleteButton(onDelete: widget.onDelete),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatefulWidget {
  final VoidCallback onDelete;
  const _DeleteButton({required this.onDelete});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDelete,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.red.shade600
                : Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thumbnail image - uses ScrollAwareImageProvider to skip decoding while
// the list is flinging, then loads once the scroll settles.
// ---------------------------------------------------------------------------

class _ThumbnailImage extends StatefulWidget {
  final String filePath;
  final bool needsSizeResolution;
  final void Function(int w, int h)? onSizeResolved;

  const _ThumbnailImage({
    required this.filePath,
    this.needsSizeResolution = false,
    this.onSizeResolved,
  });

  @override
  State<_ThumbnailImage> createState() => _ThumbnailImageState();
}

class _ThumbnailImageState extends State<_ThumbnailImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final DisposableBuildContext<State<StatefulWidget>> _disposableContext;

  @override
  void initState() {
    super.initState();
    _disposableContext = DisposableBuildContext(this);
  }

  @override
  void dispose() {
    _disposableContext.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = ResizeImage(
      FileImage(File(widget.filePath)),
      width: 400,
      policy: ResizeImagePolicy.fit,
    );
    final scrollAware = ScrollAwareImageProvider(
      context: _disposableContext,
      imageProvider: provider,
    );

    return Image(
      image: scrollAware,
      fit: BoxFit.cover,
      frameBuilder: (ctx, child, frame, wasSynchronous) {
        // 图片首次渲染完成时，如果需要解析尺寸则读取真实宽高
        if ((wasSynchronous || frame != null) && widget.needsSizeResolution) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _resolveSize(scrollAware);
          });
        }
        if (wasSynchronous || frame != null) return child;
        return ColoredBox(color: Colors.grey.shade200);
      },
      errorBuilder: (_, __, ___) => ColoredBox(
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }

  void _resolveSize(ImageProvider provider) {
    if (!mounted || widget.onSizeResolved == null) return;
    final imageStream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      if (mounted) {
        final w = info.image.width;
        final h = info.image.height;
        if (w > 1 && h > 1) {
          widget.onSizeResolved!(w, h);
        }
      }
      imageStream.removeListener(listener);
    });
    imageStream.addListener(listener);
  }
}

// ---------------------------------------------------------------------------
// Scanning banner
// ---------------------------------------------------------------------------

class _ScanningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Scanning for new images...',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }
}
