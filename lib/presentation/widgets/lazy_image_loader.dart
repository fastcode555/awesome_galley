import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/models/image_item.dart';

/// 本地图片懒加载组件
/// 
/// 使用 Image.file + cacheWidth 限制解码分辨率，减少内存占用
/// Flutter 的 ImageCache 自动处理内存缓存
class LazyImageLoader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio.isFinite && aspectRatio > 0 ? aspectRatio : 1.0,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: _LocalCachedImage(filePath: item.filePath),
      ),
    );
  }
}

/// 本地文件图片，带缓存
class _LocalCachedImage extends StatelessWidget {
  final String filePath;

  const _LocalCachedImage({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(filePath),
      fit: BoxFit.cover,
      cacheWidth: 400, // 限制解码宽度，大幅减少内存占用
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _placeholder();
      },
      errorBuilder: (context, error, stackTrace) => _errorWidget(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image_outlined, size: 32, color: Colors.grey),
      ),
    );
  }

  Widget _errorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 32, color: Colors.grey),
      ),
    );
  }
}
