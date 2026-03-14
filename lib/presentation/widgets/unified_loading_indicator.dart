import 'package:flutter/material.dart';

/// Unified loading indicator with consistent styling
/// 
/// Provides a standardized loading indicator across the app
/// with optional message and size variants.
/// 
/// Requirements: Task 24.3 - Unified loading indicator style
class UnifiedLoadingIndicator extends StatelessWidget {
  final String? message;
  final LoadingSize size;
  final Color? color;

  const UnifiedLoadingIndicator({
    super.key,
    this.message,
    this.size = LoadingSize.medium,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.colorScheme.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size.dimension,
            height: size.dimension,
            child: CircularProgressIndicator(
              strokeWidth: size.strokeWidth,
              color: indicatorColor,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: size.spacing),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading size variants
enum LoadingSize {
  small(dimension: 16.0, strokeWidth: 2.0, spacing: 4.0),
  medium(dimension: 32.0, strokeWidth: 3.0, spacing: 8.0),
  large(dimension: 48.0, strokeWidth: 4.0, spacing: 12.0);

  final double dimension;
  final double strokeWidth;
  final double spacing;

  const LoadingSize({
    required this.dimension,
    required this.strokeWidth,
    required this.spacing,
  });
}

/// Shimmer loading effect for image placeholders
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}
