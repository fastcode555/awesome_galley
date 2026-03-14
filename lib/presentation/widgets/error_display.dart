import 'package:flutter/material.dart';

/// Unified error display widget with consistent styling
/// 
/// Provides standardized error UI across the app with:
/// - Friendly error messages
/// - Retry functionality
/// - Contextual icons
/// - Consistent styling
/// 
/// Requirements: Task 24.3 - Friendly error UI
class ErrorDisplay extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final ErrorType type;
  final IconData? customIcon;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.type = ErrorType.general,
    this.customIcon,
  });

  /// Factory for file not found error
  factory ErrorDisplay.fileNotFound({
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorDisplay(
      message: 'File not found',
      details: details ?? 'The image file could not be located',
      onRetry: onRetry,
      type: ErrorType.fileNotFound,
    );
  }

  /// Factory for corrupted file error
  factory ErrorDisplay.corrupted({
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorDisplay(
      message: 'Image corrupted',
      details: details ?? 'The image file appears to be damaged',
      onRetry: onRetry,
      type: ErrorType.corrupted,
    );
  }

  /// Factory for timeout error
  factory ErrorDisplay.timeout({
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorDisplay(
      message: 'Loading timeout',
      details: details ?? 'The image took too long to load',
      onRetry: onRetry,
      type: ErrorType.timeout,
    );
  }

  /// Factory for permission error
  factory ErrorDisplay.permission({
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorDisplay(
      message: 'Permission denied',
      details: details ?? 'Unable to access the file. Please grant permission.',
      onRetry: onRetry,
      type: ErrorType.permission,
    );
  }

  /// Factory for network error
  factory ErrorDisplay.network({
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorDisplay(
      message: 'Network error',
      details: details ?? 'Unable to load the image. Check your connection.',
      onRetry: onRetry,
      type: ErrorType.network,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                customIcon ?? type.icon,
                size: 48,
                color: type.color,
              ),
            ),
            const SizedBox(height: 16),

            // Error message
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            // Error details
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact error display for small spaces (like image thumbnails)
class CompactErrorDisplay extends StatelessWidget {
  final ErrorType type;
  final VoidCallback? onRetry;
  final double size;

  const CompactErrorDisplay({
    super.key,
    this.type = ErrorType.general,
    this.onRetry,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: size,
              color: type.color.withValues(alpha: 0.7),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error types with associated icons and colors
enum ErrorType {
  general(
    icon: Icons.error_outline,
    color: Colors.red,
  ),
  fileNotFound(
    icon: Icons.search_off,
    color: Colors.orange,
  ),
  corrupted(
    icon: Icons.broken_image,
    color: Colors.red,
  ),
  timeout(
    icon: Icons.access_time,
    color: Colors.orange,
  ),
  permission(
    icon: Icons.lock_outline,
    color: Colors.amber,
  ),
  network(
    icon: Icons.wifi_off,
    color: Colors.blue,
  );

  final IconData icon;
  final Color color;

  const ErrorType({
    required this.icon,
    required this.color,
  });
}

/// Empty state display for when no content is available
class EmptyStateDisplay extends StatelessWidget {
  final String message;
  final String? description;
  final IconData icon;
  final Widget? action;

  const EmptyStateDisplay({
    super.key,
    required this.message,
    this.description,
    this.icon = Icons.image_not_supported,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
