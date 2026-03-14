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
  const WaterfallView({super.key});

  @override
  State<WaterfallView> createState() => _WaterfallViewState();
}

class _WaterfallViewState extends State<WaterfallView> {
  final ScrollController _scrollController = ScrollController();
  Timer? _loadMoreDebounce;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Gallery'),
        actions: [
          Consumer<ModeManager>(
            builder: (context, modeManager, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  modeManager.isFileAssociationMode() ? 'Folder View' : 'System View',
                  style: const TextStyle(fontSize: 14),
                ),
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

          if (controller.images.isEmpty) {
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
                // ClampingScrollPhysics avoids the rubber-band overdraw on macOS
                physics: const ClampingScrollPhysics(),
                slivers: [
                  if (controller.isScanning)
                    SliverToBoxAdapter(child: _ScanningBanner()),
                  SliverPadding(
                    padding: const EdgeInsets.all(4),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: cols,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childCount: controller.images.length,
                      itemBuilder: (context, index) {
                        final item = controller.images[index];
                        return _GridTile(
                          key: ValueKey(item.filePath),
                          item: item,
                          onTap: () => _openViewer(context, controller.images, index),
                        );
                      },
                    ),
                  ),
                  if (controller.isLoading)
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
// Grid tile - kept as simple as possible to minimise raster work per frame
// ---------------------------------------------------------------------------

class _GridTile extends StatelessWidget {
  final ImageItem item;
  final VoidCallback onTap;

  const _GridTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ratio = (item.width > 0 && item.height > 0)
        ? item.width / item.height
        : 1.0;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: AspectRatio(
            aspectRatio: ratio,
            child: _ThumbnailImage(filePath: item.filePath),
          ),
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
  const _ThumbnailImage({required this.filePath});

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
        if (wasSynchronous || frame != null) return child;
        return ColoredBox(color: Colors.grey.shade200);
      },
      errorBuilder: (_, __, ___) => ColoredBox(
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
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
