import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/controllers/image_controller.dart';
import '../../domain/models/image_data.dart';
import '../../domain/models/image_item.dart';
import 'visibility_detector.dart';
import 'error_display.dart';

/// Lazy loading image widget with visibility detection
/// 
/// Features:
/// - Only loads images when visible in viewport
/// - Preloads images slightly before they become visible
/// - Releases memory when images scroll out of view
/// - Shows placeholder while loading
/// - Handles errors gracefully
/// 
/// Requirements: 9.1, 9.5
class LazyImageLoader extends StatefulWidget {
  final ImageItem item;
  final double aspectRatio;
  final BorderRadius? borderRadius;

  const LazyImageLoader({
    super.key,
    required this.item,
    required this.aspectRatio,
    this.borderRadius,
  });

  @override
  State<LazyImageLoader> createState() => _LazyImageLoaderState();
}

class _LazyImageLoaderState extends State<LazyImageLoader> {
  ImageData? _imageData;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isVisible = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void dispose() {
    // Release image data when widget is disposed
    _releaseImage();
    super.dispose();
  }

  /// Handle visibility changes
  void _onVisibilityChanged(bool isVisible) {
    if (!mounted) return;

    setState(() {
      _isVisible = isVisible;
    });

    if (isVisible && _imageData == null && !_isLoading && !_hasError) {
      // Image became visible and not loaded yet - load it
      _loadImage();
    } else if (!isVisible && _imageData != null) {
      // Image scrolled out of view - release memory after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted || _isVisible) return;
        _releaseImage();
      });
    }
  }

  /// Load the thumbnail image
  Future<void> _loadImage() async {
    if (_isLoading || !mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final controller = context.read<ImageController>();
      final imageData = await controller.loadThumbnail(widget.item);

      if (mounted) {
        setState(() {
          _imageData = imageData;
          _isLoading = false;
          _retryCount = 0; // Reset retry count on success
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  /// Retry loading the image
  /// 
  /// Requirement: 10.3 - Provide retry option on timeout
  Future<void> _retryLoad() async {
    if (_retryCount >= _maxRetries) {
      // Max retries reached, show permanent error
      return;
    }

    _retryCount++;
    await _loadImage();
  }

  /// Release image data to free memory
  void _releaseImage() {
    if (_imageData != null) {
      setState(() {
        _imageData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      onVisibilityChanged: _onVisibilityChanged,
      visibilityThreshold: 0.5, // Preload when 50% of viewport away
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: widget.borderRadius,
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return _buildErrorPlaceholder();
    }

    if (_imageData != null) {
      return Image.memory(
        _imageData!.bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    if (_isLoading) {
      return _buildLoadingPlaceholder();
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return CompactErrorDisplay(
      type: ErrorType.corrupted,
      onRetry: _retryCount < _maxRetries ? _retryLoad : null,
      size: 48.0,
    );
  }
}
