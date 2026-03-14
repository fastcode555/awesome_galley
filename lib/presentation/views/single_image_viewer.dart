import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/models/image_item.dart';

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
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen paged image viewer
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 8.0,
                child: Image.file(
                  File(widget.images[index].filePath),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                  ),
                ),
              );
            },
          ),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onClose,
                    ),
                    Expanded(
                      child: Text(
                        widget.images[_currentIndex].fileName,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
