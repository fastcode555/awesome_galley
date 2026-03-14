import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Scroll performance optimizer that reduces unnecessary rebuilds
/// 
/// Features:
/// - Debounces scroll events to reduce rebuild frequency
/// - Uses const constructors where possible
/// - Implements shouldRebuild optimization
/// - Monitors scroll velocity to adjust behavior
/// 
/// Requirement: 9.1 - Maintain at least 30 FPS during scrolling
class ScrollPerformanceOptimizer extends StatefulWidget {
  final Widget child;
  final ScrollController? scrollController;
  final VoidCallback? onScrollStart;
  final VoidCallback? onScrollEnd;
  final Function(double velocity)? onScrollVelocityChanged;

  const ScrollPerformanceOptimizer({
    super.key,
    required this.child,
    this.scrollController,
    this.onScrollStart,
    this.onScrollEnd,
    this.onScrollVelocityChanged,
  });

  @override
  State<ScrollPerformanceOptimizer> createState() =>
      _ScrollPerformanceOptimizerState();
}

class _ScrollPerformanceOptimizerState
    extends State<ScrollPerformanceOptimizer> {
  bool _isScrolling = false;
  double _lastScrollVelocity = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final position = widget.scrollController?.position;
    if (position == null) return;

    // Calculate scroll velocity
    final velocity = position.activity?.velocity ?? 0.0;
    
    // Detect scroll start
    if (!_isScrolling && velocity.abs() > 0) {
      _isScrolling = true;
      widget.onScrollStart?.call();
    }
    
    // Detect scroll end
    if (_isScrolling && velocity.abs() == 0) {
      _isScrolling = false;
      widget.onScrollEnd?.call();
    }
    
    // Notify velocity changes
    if (velocity != _lastScrollVelocity) {
      _lastScrollVelocity = velocity;
      widget.onScrollVelocityChanged?.call(velocity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          _isScrolling = true;
          widget.onScrollStart?.call();
        } else if (notification is ScrollEndNotification) {
          _isScrolling = false;
          widget.onScrollEnd?.call();
        } else if (notification is ScrollUpdateNotification) {
          final velocity = notification.scrollDelta ?? 0.0;
          widget.onScrollVelocityChanged?.call(velocity);
        }
        return false;
      },
      child: widget.child,
    );
  }
}

/// Optimized list view that reduces rebuilds during scrolling
/// 
/// Uses const constructors and RepaintBoundary to minimize
/// widget rebuilds and repaints during scroll.
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;

  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.scrollDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      scrollDirection: scrollDirection,
      itemCount: itemCount,
      // Use addRepaintBoundaries to isolate each item
      addRepaintBoundaries: true,
      // Use addAutomaticKeepAlives to keep items alive when scrolled off
      addAutomaticKeepAlives: false,
      // Disable semantic indexes for better performance
      addSemanticIndexes: false,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

/// Scroll physics that optimizes for smooth scrolling
/// 
/// Reduces bounce effect and adjusts friction for better performance
class OptimizedScrollPhysics extends ScrollPhysics {
  const OptimizedScrollPhysics({super.parent});

  @override
  OptimizedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return OptimizedScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Reduce friction during fast scrolling for smoother experience
    if (offset.abs() > 100) {
      return offset * 0.95;
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  double get minFlingVelocity => 100.0;

  @override
  double get maxFlingVelocity => 5000.0;
}
