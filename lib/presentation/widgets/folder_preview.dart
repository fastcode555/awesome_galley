import 'package:flutter/material.dart';
import '../../domain/models/image_item.dart';

/// A widget that displays a horizontal scrolling list of thumbnail images
/// from the current folder, with the current image highlighted.
///
/// This widget allows users to:
/// - View all images in the current folder as thumbnails
/// - See which image is currently being viewed (highlighted)
/// - Tap on any thumbnail to switch to that image
/// - Auto-scroll to show the current image
class FolderPreview extends StatefulWidget {
  /// List of all images in the current folder
  final List<ImageItem> folderImages;

  /// The currently viewed image
  final ImageItem currentImage;

  /// Callback when a thumbnail is tapped
  final Function(ImageItem) onImageSelect;

  const FolderPreview({
    super.key,
    required this.folderImages,
    required this.currentImage,
    required this.onImageSelect,
  });

  @override
  State<FolderPreview> createState() => _FolderPreviewState();
}

class _FolderPreviewState extends State<FolderPreview> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Auto-scroll to current image after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentImage();
    });
  }

  @override
  void didUpdateWidget(FolderPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the current image changed, scroll to it
    if (oldWidget.currentImage.id != widget.currentImage.id) {
      _scrollToCurrentImage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.black.withValues(alpha: 0.8),
      child: _buildThumbnailList(),
    );
  }

  /// Builds the horizontal scrolling list of thumbnails
  Widget _buildThumbnailList() {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: widget.folderImages.length,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemBuilder: (context, index) {
        final image = widget.folderImages[index];
        final isCurrentImage = image.id == widget.currentImage.id;
        
        return _buildThumbnailItem(image, isCurrentImage);
      },
    );
  }

  /// Builds a single thumbnail item
  Widget _buildThumbnailItem(ImageItem image, bool isCurrentImage) {
    return GestureDetector(
      onTap: () => widget.onImageSelect(image),
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: _highlightCurrentImage(isCurrentImage),
            width: isCurrentImage ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            image.filePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[800],
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Returns the highlight color for the current image
  Color _highlightCurrentImage(bool isCurrentImage) {
    return isCurrentImage ? Colors.blue : Colors.white24;
  }

  /// Scrolls to the current image position in the list
  void _scrollToCurrentImage() {
    if (!_scrollController.hasClients) return;
    
    // Find the index of the current image
    final currentIndex = widget.folderImages.indexWhere(
      (image) => image.id == widget.currentImage.id,
    );
    
    if (currentIndex == -1) return;
    
    // Calculate the scroll position
    // Each item is 100 (width) + 8 (margin) = 108 pixels
    const itemWidth = 108.0;
    final scrollPosition = currentIndex * itemWidth;
    
    // Get the viewport width
    final viewportWidth = _scrollController.position.viewportDimension;
    
    // Center the current image in the viewport
    final targetPosition = scrollPosition - (viewportWidth / 2) + (itemWidth / 2);
    
    // Clamp the position to valid scroll range
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedPosition = targetPosition.clamp(0.0, maxScroll);
    
    // Animate to the position
    _scrollController.animateTo(
      clampedPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
