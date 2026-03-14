import 'package:flutter/material.dart';

/// Custom page transitions for single image viewer
/// 
/// Provides smooth transitions when opening/closing the viewer.
/// 
/// Requirements: Task 24.2 - Viewer open/close animations
class ImageViewerPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final Duration _transitionDuration;

  ImageViewerPageRoute({
    required this.builder,
    Duration transitionDuration = const Duration(milliseconds: 300),
    super.settings,
  }) : _transitionDuration = transitionDuration;

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _transitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade + scale transition
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Slide transition for page navigation
class SlidePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final AxisDirection direction;

  SlidePageRoute({
    required this.builder,
    this.direction = AxisDirection.left,
    super.settings,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    Offset begin;
    switch (direction) {
      case AxisDirection.up:
        begin = const Offset(0.0, 1.0);
        break;
      case AxisDirection.down:
        begin = const Offset(0.0, -1.0);
        break;
      case AxisDirection.left:
        begin = const Offset(1.0, 0.0);
        break;
      case AxisDirection.right:
        begin = const Offset(-1.0, 0.0);
        break;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: child,
    );
  }
}
