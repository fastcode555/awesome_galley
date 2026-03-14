import 'package:flutter/foundation.dart';
import 'platform_integration.dart';
import 'web_file_picker.dart';

/// Web-specific implementation of PlatformIntegration.
///
/// Uses Web APIs for file access and browser-based file selection.
class WebPlatformIntegration implements PlatformIntegration {
  final WebFilePicker _filePicker = WebFilePicker();

  /// Gets the web file picker instance for selecting images
  WebFilePicker get filePicker => _filePicker;

  @override
  Future<void> registerFileAssociations() async {
    // File associations are not applicable in web browsers
    if (kDebugMode) {
      print('File associations are not supported on web');
    }
  }

  @override
  Future<void> setAsDefaultApp() async {
    // Setting default app is not applicable in web browsers
    if (kDebugMode) {
      print('Setting default app is not supported on web');
    }
  }

  @override
  Future<List<String>> getLaunchArguments() async {
    // On web, we could check URL parameters
    // For now, return empty list
    if (kDebugMode) {
      print('Launch arguments on web: checking URL parameters');
    }
    
    // Check if there's a file parameter in the URL
    // This would require web-specific URL parsing
    return [];
  }

  @override
  Future<Map<String, dynamic>?> extractExifData(String filePath) async {
    // EXIF extraction on web requires additional libraries
    // For now, return null (can be implemented with exif-js or similar)
    if (kDebugMode) {
      print('EXIF extraction not yet implemented on web');
    }
    return null;
  }
}
