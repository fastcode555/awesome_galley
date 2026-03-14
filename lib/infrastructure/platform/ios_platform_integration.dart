import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'platform_integration.dart';

/// iOS-specific implementation of PlatformIntegration.
///
/// Handles photo library permissions and file opening via URL schemes.
class IOSPlatformIntegration implements PlatformIntegration {
  static const MethodChannel _channel =
      MethodChannel('image_gallery/platform');

  @override
  Future<void> registerFileAssociations() async {
    // On iOS, file associations are configured in Info.plist
    // This method verifies the configuration at runtime
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
    // iOS doesn't support setting default apps for file types
    // This is a no-op on iOS
    if (kDebugMode) {
      print('Setting default app is not supported on iOS');
    }
  }

  @override
  Future<List<String>> getLaunchArguments() async {
    try {
      // On iOS, files opened via share sheet or URL scheme are passed through app delegate
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

  /// Requests photo library access permission.
  ///
  /// Returns true if permission is granted, false otherwise.
  Future<bool> requestPhotoLibraryPermission() async {
    final status = await Permission.photos.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.photos.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      // Guide user to settings
      await _showPermissionDeniedDialog();
      return false;
    }
    
    return false;
  }

  /// Shows a dialog guiding the user to app settings when permission is denied.
  Future<void> _showPermissionDeniedDialog() async {
    // This should be called from the UI layer with proper context
    // For now, we just open settings
    await openAppSettings();
  }
}
