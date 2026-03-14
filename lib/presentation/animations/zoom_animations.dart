import 'package:flutter/material.dart';

/// Smooth zoom animation controller
/// 
/// Provides animated zoom transitions for the image viewer.
/// 
/// Requirements: Task 24.2 - Zoom/pan animations
class ZoomAnimationController {
  final TransformationController transformationController;
  AnimationController? _animationController;
  Animation<Matrix4>? _animation;

  ZoomAnimationController(this.transformationController);

  /// Animate to a specific scale
  void animateToScale({
    required double targetScale,
    required TickerProvider vsync,
    Offset? focalPoint,
    Duration duration = const Duration(milliseconds: 300),
    VoidCallback? onComplete,
  }) {
    final currentMatrix = transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    // If already at target scale, do nothing
    if ((currentScale - targetScale).abs() < 0.01) {
      onComplete?.call();
      return;
    }

    // Calculate target matrix
    final targetMatrix = Matrix4.identity();
    if (focalPoint != null) {
      // Zoom to specific point
      targetMatrix.translate(focalPoint.dx, focalPoint.dy);
      targetMatrix.scale(targetScale);
      targetMatrix.translate(-focalPoint.dx, -focalPoint.dy);
    } else {
      // Zoom to center
      targetMatrix.scale(targetScale);
    }

    // Create animation
    _animationController?.dispose();
    _animationController = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    _animation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOutCubic,
      ),
    );

    _animation!.addListener(() {
      transformationController.value = _animation!.value;
    });

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onComplete?.call();
      }
    });

    _animationController!.forward();
  }

  /// Animate to fit screen
  void animateToFit({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 300),
    VoidCallback? onComplete,
  }) {
    animateToScale(
      targetScale: 1.0,
      vsync: vsync,
      duration: duration,
      onComplete: onComplete,
    );
  }

  /// Animate zoom in (2x)
  void animateZoomIn({
    required TickerProvider vsync,
    Offset? focalPoint,
    Duration duration = const Duration(milliseconds: 300),
    VoidCallback? onComplete,
  }) {
    animateToScale(
      targetScale: 2.0,
      vsync: vsync,
      focalPoint: focalPoint,
      duration: duration,
      onComplete: onComplete,
    );
  }

  /// Dispose animation controller
  void dispose() {
    _animationController?.dispose();
  }
}

/// Matrix4 tween for smooth transformation animations
class Matrix4Tween extends Tween<Matrix4> {
  Matrix4Tween({required Matrix4 begin, required Matrix4 end})
      : super(begin: begin, end: end);

  @override
  Matrix4 lerp(double t) {
    // Decompose matrices
    final beginScale = begin!.getMaxScaleOnAxis();
    final endScale = end!.getMaxScaleOnAxis();
    
    final beginTranslation = begin!.getTranslation();
    final endTranslation = end!.getTranslation();

    // Interpolate scale and translation
    final scale = beginScale + (endScale - beginScale) * t;
    final translation = beginTranslation + (endTranslation - beginTranslation) * t;

    // Create interpolated matrix
    final result = Matrix4.identity();
    result.translate(translation.x, translation.y);
    result.scale(scale);

    return result;
  }
}
