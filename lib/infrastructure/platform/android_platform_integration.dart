import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'platform_integration.dart';

/// Android-specific implementation of PlatformIntegration.
///
/// Handles storage permissions and file opening via intents.
class AndroidPlatformIntegration implements PlatformIntegration {
  static const MethodChannel _channel =
      MethodChannel('image_gallery/platform');

  @override
  Future<void> registerFileAssociations() async {
    // On Android, file associations are configured in AndroidManifest.xml
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
    // On Android, we can open the default apps settings
    try {
      await _channel.invokeMethod('openDefaultAppSettings');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to open default app settings: ${e.message}');
      }
    }
  }

  @override
  Future<List<String>> getLaunchArguments() async {
    try {
      // On Android, files opened via intent are passed through the activity
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

  /// Requests storage permission based on Android version.
  ///
  /// For Android 13+ (API 33+), requests READ_MEDIA_IMAGES permission.
  /// For older versions, requests READ_EXTERNAL_STORAGE permission.
  ///
  /// Returns true if permission is granted, false otherwise.
  Future<bool> requestStoragePermission() async {
    // Check Android version
    final androidVersion = await _getAndroidVersion();
    
    Permission permission;
    if (androidVersion >= 33) {
      // Android 13+ uses granular media permissions
      permission = Permission.photos;
    } else {
      // Older Android versions use storage permission
      permission = Permission.storage;
    }
    
    final status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await permission.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      // Guide user to settings
      await _showPermissionDeniedDialog();
      return false;
    }
    
    return false;
  }

  /// Gets the Android API level.
  Future<int> _getAndroidVersion() async {
    try {
      final version = await _channel.invokeMethod<int>('getAndroidVersion');
      return version ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get Android version: $e');
      }
      return 0;
    }
  }

  /// Shows a dialog guiding the user to app settings when permission is denied.
  Future<void> _showPermissionDeniedDialog() async {
    // This should be called from the UI layer with proper context
    // For now, we just open settings
    await openAppSettings();
  }
}
