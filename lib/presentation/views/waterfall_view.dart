import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/controllers/gallery_controller.dart';
import '../../application/managers/mode_manager.dart';
import '../../domain/models/image_item.dart';
import '../../infrastructure/cache/cache_preloader.dart';
import '../widgets/optimized_image_item.dart';
import '../widgets/performance_monitor.dart';
import '../widgets/scroll_performance_optimizer.dart';
import '../widgets/error_display.dart';
import '../widgets/unified_loading_indicator.dart';
import '../utils/responsive_layout.dart';
import 'single_image_viewer.dart';

/// Waterfall layout view for displaying image gallery
/// 
/// Displays images in a multi-column waterfall layout with:
/// - Responsive column count based on screen width
/// - Infinite scroll with pagination
/// - Tap to open single image viewer
/// 
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8
class WaterfallView extends StatefulWidget {
  const WaterfallView({super.key});

  @override
  State<WaterfallView> createState() => _WaterfallViewState();
}

class _WaterfallViewState extends State<WaterfallView> {
  final ScrollController _scrollController = ScrollController();
  late final CachePreloader _preloader;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _preloader = CachePreloader();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _preloader.cancelAll();
    super.dispose();
  }

  /// Handle scroll events for pagination and preloading
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when scrolled to 80% of the content
      final controller = context.read<GalleryController>();
      if (!controller.isLoading && controller.hasMoreImages) {
        controller.loadMoreImages();
      }
    }

    // Preload images ahead during scroll
    if (!_isScrolling) {
      _preloadAheadImages();
    }
  }

  /// Preload images that are about to become visible
  void _preloadAheadImages() {
    final controller = context.read<GalleryController>();
    if (controller.images.isEmpty) return;

    // Calculate approximate current index based on scroll position
    final scrollPercent = _scrollController.hasClients &&
            _scrollController.position.maxScrollExtent > 0
        ? (_scrollController.position.pixels /
            _scrollController.position.maxScrollExtent).clamp(0.0, 1.0)
        : 0.0;
    
    final currentIndex = (controller.images.length * scrollPercent)
        .floor()
        .clamp(0, controller.images.length - 1);
    
    // Preload ahead
    _preloader.preloadThumbnails(controller.images, currentIndex);
  }

  /// Handle scroll start - pause preloading during active scroll
  void _onScrollStart() {
    setState(() {
      _isScrolling = true;
    });
    _preloader.cancelAll();
  }

  /// Handle scroll end - resume preloading
  void _onScrollEnd() {
    setState(() {
      _isScrolling = false;
    });
    _preloadAheadImages();
  }

  /// Calculate column count based on screen width
  int _calculateColumnCount(double screenWidth) {
    return ResponsiveLayout.calculateWaterfallColumnsFromWidth(screenWidth);
  }

  @override
  Widget build(BuildContext context) {
    return PerformanceMonitor(
      showOverlay: false, // Set to true in debug mode to see FPS
      child: ScrollPerformanceOptimizer(
        scrollController: _scrollController,
        onScrollStart: _onScrollStart,
        onScrollEnd: _onScrollEnd,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Image Gallery'),
            actions: [
              // Mode indicator
              Consumer<ModeManager>(
                builder: (context, modeManager, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: Text(
                        modeManager.isFileAssociationMode()
                            ? 'Folder View'
                            : 'System View',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Consumer<GalleryController>(
            builder: (context, controller, child) {
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
                  onRetry: () {
                    controller.loadSystemImages();
                  },
                  type: ErrorType.general,
                );
              }

              if (controller.images.isEmpty) {
                return EmptyStateDisplay(
                  message: 'No images found',
                  description: 'Try adding some images to your Pictures folder',
                  icon: Icons.photo_library_outlined,
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final columnCount = _calculateColumnCount(constraints.maxWidth);
                  
                  return CustomScrollView(
                    controller: _scrollController,
                    physics: const OptimizedScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(8.0),
                        sliver: SliverWaterfallGrid(
                          images: controller.images,
                          columnCount: columnCount,
                          onImageTap: (image, index) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SingleImageViewer(
                                  images: controller.images,
                                  initialIndex: index,
                                  onClose: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (controller.isLoading)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: ResponsiveLayout.getPadding(context),
                            child: const UnifiedLoadingIndicator(
                              message: 'Loading more images...',
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
        ),
      ),
    );
  }
}

/// Custom sliver for waterfall grid layout
class SliverWaterfallGrid extends StatelessWidget {
  final List<ImageItem> images;
  final int columnCount;
  final Function(ImageItem, int) onImageTap;

  const SliverWaterfallGrid({
    super.key,
    required this.images,
    required this.columnCount,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate layout
    final columns = _calculateWaterfallLayout();

    return SliverToBoxAdapter(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(columnCount, (columnIndex) {
          return Expanded(
            child: Column(
              children: columns[columnIndex].map((item) {
                final index = images.indexOf(item);
                return RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: GestureDetector(
                      onTap: () => onImageTap(item, index),
                      child: _WaterfallImageItem(item: item),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ),
    );
  }

  /// Calculate waterfall layout by distributing images to shortest column
  List<List<ImageItem>> _calculateWaterfallLayout() {
    final columns = List.generate(columnCount, (_) => <ImageItem>[]);
    final columnHeights = List.filled(columnCount, 0.0);

    for (final image in images) {
      // Find shortest column
      int shortestIndex = 0;
      double minHeight = columnHeights[0];
      
      for (int i = 1; i < columnCount; i++) {
        if (columnHeights[i] < minHeight) {
          minHeight = columnHeights[i];
          shortestIndex = i;
        }
      }

      // Add image to shortest column
      columns[shortestIndex].add(image);
      
      // Update column height (using aspect ratio)
      columnHeights[shortestIndex] += 1.0 / image.aspectRatio;
    }

    return columns;
  }
}

/// Individual image item in waterfall grid with lazy loading
class _WaterfallImageItem extends StatelessWidget {
  final ImageItem item;

  const _WaterfallImageItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return OptimizedImageItem(
      item: item,
      onTap: null, // Tap is handled by parent GestureDetector
    );
  }
}
