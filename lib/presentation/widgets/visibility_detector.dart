import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Callback when visibility changes
typedef VisibilityCallback = void Function(bool isVisible);

/// Widget that detects when it becomes visible in the viewport
/// 
/// Used for lazy loading images - only load images when they are
/// about to be displayed on screen.
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final VisibilityCallback onVisibilityChanged;
  final double visibilityThreshold;

  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
    this.visibilityThreshold = 0.1,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted) return;

    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    final viewport = RenderAbstractViewport.of(renderObject);
    if (viewport == null) return;

    final scrollableState = Scrollable.maybeOf(context);
    if (scrollableState == null) return;

    final position = scrollableState.position;
    final renderBox = renderObject as RenderBox;
    
    // Get the bounds of this widget
    final bounds = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    
    // Get the viewport bounds
    final viewportHeight = position.viewportDimension;
    final scrollOffset = position.pixels;
    
    // Calculate visibility
    final visibleTop = scrollOffset;
    final visibleBottom = scrollOffset + viewportHeight;
    
    final widgetTop = bounds.top;
    final widgetBottom = bounds.bottom;
    
    // Check if widget is in viewport (with threshold for preloading)
    final preloadMargin = viewportHeight * widget.visibilityThreshold;
    final isNowVisible = widgetBottom >= (visibleTop - preloadMargin) &&
        widgetTop <= (visibleBottom + preloadMargin);

    if (isNowVisible != _isVisible) {
      _isVisible = isNowVisible;
      widget.onVisibilityChanged(_isVisible);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility();
        return false;
      },
      child: widget.child,
    );
  }
}
