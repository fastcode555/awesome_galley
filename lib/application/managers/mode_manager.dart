import 'package:flutter/foundation.dart';
import '../../domain/models/browse_mode.dart';

/// Manages the application's browse mode and mode transitions
/// 
/// The ModeManager handles two exclusive browse modes:
/// 1. System Browse Mode: Triggered when app launches directly (no file arguments)
/// 2. File Association Mode: Triggered when opening a single image file via OS file association
/// 
/// The manager:
/// - Determines mode based on launch arguments
/// - Allows switching from File Association mode to System Browse mode
/// - Notifies listeners when mode changes using ChangeNotifier
/// - Tracks the associated file path when in File Association mode
class ModeManager extends ChangeNotifier {
  BrowseMode _currentMode;
  String? _associatedFilePath;

  /// Creates a ModeManager with an initial mode
  /// 
  /// Defaults to systemBrowse mode if not specified
  ModeManager({
    BrowseMode initialMode = BrowseMode.systemBrowse,
    String? associatedFilePath,
  })  : _currentMode = initialMode,
        _associatedFilePath = associatedFilePath;

  /// Gets the current browse mode
  BrowseMode get currentMode => _currentMode;

  /// Gets the associated file path (only valid in fileAssociation mode)
  String? get associatedFilePath => _associatedFilePath;

  /// Initializes the browse mode based on launch arguments
  /// 
  /// If launchArgs contains a file path, enters File Association mode.
  /// Otherwise, enters System Browse mode.
  /// 
  /// [launchArgs] - The command line arguments passed to the application
  void initializeMode(List<String> launchArgs) {
    // Filter out empty strings and Flutter-specific arguments
    final validArgs = launchArgs
        .where((arg) => arg.isNotEmpty && !arg.startsWith('--'))
        .toList();

    if (validArgs.isNotEmpty) {
      // File association mode - launched with a file path
      _currentMode = BrowseMode.fileAssociation;
      _associatedFilePath = validArgs.first;
    } else {
      // System browse mode - launched directly
      _currentMode = BrowseMode.systemBrowse;
      _associatedFilePath = null;
    }

    notifyListeners();
  }

  /// Switches from File Association mode to System Browse mode
  /// 
  /// This allows users to transition from viewing a specific file
  /// to browsing all system images. The associated file path is cleared.
  void switchToSystemBrowse() {
    if (_currentMode == BrowseMode.fileAssociation) {
      _currentMode = BrowseMode.systemBrowse;
      _associatedFilePath = null;
      notifyListeners();
    }
  }

  /// Checks if the current mode is File Association mode
  /// 
  /// Returns true if in fileAssociation mode, false otherwise
  bool isFileAssociationMode() {
    return _currentMode == BrowseMode.fileAssociation;
  }
}
