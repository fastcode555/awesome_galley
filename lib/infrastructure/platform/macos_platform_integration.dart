import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'platform_integration.dart';

/// macOS-specific implementation of PlatformIntegration.
///
/// File associations are configured via Info.plist (CFBundleDocumentTypes).
/// Uses MethodChannel to get files opened via NSApplication.
class MacOSPlatformIntegration implements PlatformIntegration {
  static const MethodChannel _channel =
      MethodChannel('image_gallery/platform');

  /// Supported image file extensions
  static const List<String> _supportedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
  ];

  @override
  Future<void> registerFileAssociations() async {
    // On macOS, file associations are configured in Info.plist
    // This method is a no-op at runtime, but we can verify the configuration
    try {
      await _channel.invokeMethod('verifyFileAssociations');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Warning: File associations may not be properly configured: ${e.message}');
      }
    }
  }

  @override
  Future<void> setAsDefaultApp() async {
    // On macOS, setting as default app requires user interaction
    // We can open System Preferences to the relevant section
    try {
      await _channel.invokeMethod('openDefaultAppSettings', {
        'extensions': _supportedExtensions,
      });
    } on PlatformException catch (e) {
      throw Exception(
          'Failed to open default app settings on macOS: ${e.message}');
    }
  }

  @override
  Future<List<String>> getLaunchArguments() async {
    try {
      // On macOS, files opened via Finder are passed through NSApplication
      final result = await _channel.invokeMethod('getOpenedFiles');
      if (result != null && result is List) {
        return result.cast<String>();
      }
      return [];
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to get launch arguments: ${e.message}');
      }
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> extractExifData(String filePath) async {
    try {
      final result = await _channel.invokeMethod('extractExifData', {
        'filePath': filePath,
      });
      return result != null ? Map<String, dynamic>.from(result) : null;
    } on PlatformException catch (e) {
      // EXIF extraction failure is not critical, return null
      if (kDebugMode) {
        print('Failed to extract EXIF data: ${e.message}');
      }
      return null;
    }
  }
}
