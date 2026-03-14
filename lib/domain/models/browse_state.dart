import 'browse_mode.dart';

/// Represents the browsing state of the application for persistence
/// 
/// This class encapsulates the current state of the application including
/// the browse mode, current folder path, scroll position, and current image path.
class BrowseState {
  /// The current browse mode (required)
  final BrowseMode mode;

  /// The current folder path being browsed (optional)
  final String? currentFolderPath;

  /// The current scroll position in the gallery (default: 0.0)
  final double scrollPosition;

  /// The current image path being viewed (optional)
  final String? currentImagePath;

  const BrowseState({
    required this.mode,
    this.currentFolderPath,
    this.scrollPosition = 0.0,
    this.currentImagePath,
  });

  /// Convert the browse state to a JSON map for persistence
  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'currentFolderPath': currentFolderPath,
        'scrollPosition': scrollPosition,
        'currentImagePath': currentImagePath,
      };

  /// Create a browse state from a JSON map
  /// 
  /// Handles missing or invalid mode gracefully by defaulting to systemBrowse
  factory BrowseState.fromJson(Map<String, dynamic> json) {
    // Parse mode with fallback to systemBrowse
    BrowseMode mode;
    try {
      final modeString = json['mode'] as String?;
      if (modeString == null) {
        mode = BrowseMode.systemBrowse;
      } else {
        mode = BrowseMode.values.firstWhere(
          (e) => e.name == modeString,
          orElse: () => BrowseMode.systemBrowse,
        );
      }
    } catch (_) {
      mode = BrowseMode.systemBrowse;
    }

    return BrowseState(
      mode: mode,
      currentFolderPath: json['currentFolderPath'] as String?,
      scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0.0,
      currentImagePath: json['currentImagePath'] as String?,
    );
  }
}
