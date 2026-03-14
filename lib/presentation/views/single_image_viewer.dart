import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/image_item.dart';
import '../../domain/models/image_data.dart';
import '../../application/controllers/image_controller.dart';
import '../widgets/error_display.dart';
import '../widgets/unified_loading_indicator.dart';

/// Single image viewer with zoom, pan, and swipe navigation
/// 
/// Features:
/// - Full screen image display
/// - Pinch to zoom (0.5x - 5x)
/// - Pan when zoomed
/// - Swipe to navigate between images
/// - Double tap to toggle zoom
/// 
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7
class SingleImageViewer extends StatefulWidget {
  final List<ImageItem> images;
  final int initialIndex;
  final VoidCallback onClose;

  const SingleImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.onClose,
  });

  @override
  State<SingleImageViewer> createState() => _SingleImageViewerState();
}

class _SingleImageViewerState extends State<SingleImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  /// Handle page change
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      // Reset zoom when changing images
      _transformationController.value = Matrix4.identity();
    });
  }

  /// Handle double tap to toggle zoom
  void _handleDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    
    if (currentScale > 1.0) {
      // Zoom out to fit
      _transformationController.value = Matrix4.identity();
    } else {
      // Zoom in to 2x
      _transformationController.value = Matrix4.identity()..scale(2.0);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image viewer with page navigation
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final image = widget.images[index];
              return _buildImagePage(image);
            },
          ),

          // Top bar with close button and info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: widget.onClose,
                      ),
                      Expanded(
                        child: Text(
                          widget.images[_currentIndex].fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom bar with navigation hints
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_currentIndex > 0)
                        const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      if (_currentIndex > 0) const SizedBox(width: 8),
                      const Text(
                        'Swipe to navigate',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      if (_currentIndex < widget.images.length - 1)
                        const SizedBox(width: 8),
                      if (_currentIndex < widget.images.length - 1)
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual image page with zoom and pan
  Widget _buildImagePage(ImageItem image) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Container(
            color: Colors.grey[900],
            child: AspectRatio(
              aspectRatio: image.aspectRatio,
              child: _FullResolutionImage(item: image),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget to load and display full resolution image using ImageController
class _FullResolutionImage extends StatefulWidget {
  final ImageItem item;

  const _FullResolutionImage({required this.item});

  @override
  State<_FullResolutionImage> createState() => _FullResolutionImageState();
}

class _FullResolutionImageState extends State<_FullResolutionImage> {
  ImageData? _imageData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_FullResolutionImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.filePath != widget.item.filePath) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final imageController = context.read<ImageController>();
      final imageData = await imageController.loadFullImage(widget.item);
      
      if (mounted) {
        setState(() {
          _imageData = imageData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.grey[800],
        child: const UnifiedLoadingIndicator(
          message: 'Loading full resolution...',
          size: LoadingSize.large,
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        color: Colors.grey[800],
        child: ErrorDisplay(
          message: 'Failed to load image',
          details: _errorMessage,
          onRetry: _loadImage,
          type: ErrorType.corrupted,
        ),
      );
    }

    if (_imageData == null) {
      return Container(
        color: Colors.grey[800],
        child: const ErrorDisplay(
          message: 'Image not available',
          type: ErrorType.general,
        ),
      );
    }

    return Image.memory(
      _imageData!.bytes,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[800],
          child: const ErrorDisplay(
            message: 'Failed to display image',
            details: 'The image could not be rendered',
            type: ErrorType.corrupted,
          ),
        );
      },
    );
  }
}
