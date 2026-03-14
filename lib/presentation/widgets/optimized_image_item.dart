import 'package:flutter/material.dart';
import '../../domain/models/image_item.dart';
import 'lazy_image_loader.dart';

/// Optimized image item widget with RepaintBoundary
/// 
/// Wraps the lazy image loader with RepaintBoundary to isolate
/// repaints and improve scroll performance.
/// 
/// Requirement: 9.1 - Maintain at least 30 FPS during scrolling
class OptimizedImageItem extends StatelessWidget {
  final ImageItem item;
  final VoidCallback? onTap;

  const OptimizedImageItem({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Hero(
          tag: 'image_${item.id}',
          child: LazyImageLoader(
            item: item,
            aspectRatio: item.aspectRatio,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
