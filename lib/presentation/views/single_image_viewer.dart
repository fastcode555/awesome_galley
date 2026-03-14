import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
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
  bool _showInfo = true;

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

  ImageItem get _current => widget.images[_currentIndex];

  /// 打开文件所在目录
  void _revealInFinder() {
    final dir = p.dirname(_current.filePath);
    if (Platform.isMacOS) {
      // macOS: 用 open -R 高亮选中文件
      Process.run('open', ['-R', _current.filePath]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [dir]);
    } else if (Platform.isWindows) {
      Process.run('explorer', ['/select,', _current.filePath]);
    }
  }

  /// 格式化文件大小
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 图片翻页
          GestureDetector(
            onTap: () => setState(() => _showInfo = !_showInfo),
            child: PageView.builder(
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
          ),

          // 顶部栏
          Positioned(
            top: 0, left: 0, right: 0,
            child: AnimatedOpacity(
              opacity: _showInfo ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: const BoxDecoration(
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
                          _current.fileName,
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
          ),

          // 底部信息栏
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedOpacity(
              opacity: _showInfo ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.black54, Colors.transparent],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 文件名
                      Text(
                        _current.fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // 路径
                      Text(
                        p.dirname(_current.filePath),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // 尺寸 / 大小 / 格式
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.photo_size_select_actual_outlined,
                            label: '${_current.width} × ${_current.height}',
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.storage_outlined,
                            label: _formatSize(_current.fileSize),
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.image_outlined,
                            label: _current.format.name.toUpperCase(),
                          ),
                          const Spacer(),
                          // 打开所在目录按钮
                          TextButton.icon(
                            onPressed: _revealInFinder,
                            icon: const Icon(Icons.folder_open_outlined,
                                color: Colors.white, size: 16),
                            label: const Text(
                              '打开目录',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
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
}

/// 小信息标签
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
