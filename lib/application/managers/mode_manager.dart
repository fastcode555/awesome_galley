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
    final validArgs = launchArgs
        .where((arg) => arg.isNotEmpty && !arg.startsWith('--'))
        .toList();

    debugPrint('[ModeManager] launchArgs: $launchArgs');
    debugPrint('[ModeManager] validArgs: $validArgs');

    if (validArgs.isNotEmpty) {
      _currentMode = BrowseMode.fileAssociation;
      _associatedFilePath = validArgs.first;
      debugPrint('[ModeManager] → fileAssociation mode, file: $_associatedFilePath');
    } else {
      _currentMode = BrowseMode.systemBrowse;
      _associatedFilePath = null;
      debugPrint('[ModeManager] → systemBrowse mode');
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

  /// 运行时切换到 fileAssociation 模式（app 已运行时通过 open with 打开文件）
  void switchToFileAssociation(String filePath) {
    _currentMode = BrowseMode.fileAssociation;
    _associatedFilePath = filePath;
    debugPrint('[ModeManager] runtime switch → fileAssociation, file: $filePath');
    notifyListeners();
  }

  /// Checks if the current mode is File Association mode
  bool isFileAssociationMode() {
    return _currentMode == BrowseMode.fileAssociation;
  }
}
