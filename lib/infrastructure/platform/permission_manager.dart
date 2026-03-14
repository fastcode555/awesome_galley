import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ios_platform_integration.dart';
import 'android_platform_integration.dart';

/// Manages platform-specific permissions for accessing photos and storage.
class PermissionManager {
  final IOSPlatformIntegration? _iosIntegration;
  final AndroidPlatformIntegration? _androidIntegration;

  PermissionManager()
      : _iosIntegration = Platform.isIOS ? IOSPlatformIntegration() : null,
        _androidIntegration = Platform.isAndroid ? AndroidPlatformIntegration() : null;

  /// Requests necessary permissions for accessing images.
  ///
  /// On iOS: Requests photo library access permission.
  /// On Android: Requests storage permission (varies by Android version).
  /// On other platforms: Returns true (no permissions needed).
  ///
  /// Returns true if permission is granted, false otherwise.
  Future<bool> requestImageAccessPermission() async {
    if (kIsWeb) {
      // Web doesn't require permissions for file picker
      return true;
    }

    if (Platform.isIOS) {
      return await _iosIntegration!.requestPhotoLibraryPermission();
    }

    if (Platform.isAndroid) {
      return await _androidIntegration!.requestStoragePermission();
    }

    // Desktop platforms don't require permissions
    return true;
  }

  /// Checks if image access permission is currently granted.
  ///
  /// Returns true if permission is granted or not required.
  Future<bool> hasImageAccessPermission() async {
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return true;
    }

    if (Platform.isIOS) {
      return await _iosIntegration!.requestPhotoLibraryPermission();
    }

    if (Platform.isAndroid) {
      return await _androidIntegration!.requestStoragePermission();
    }

    return true;
  }

  /// Gets a user-friendly message explaining why permission is needed.
  String getPermissionRationaleMessage() {
    if (Platform.isIOS) {
      return 'Image Gallery Viewer needs access to your photo library to display and browse your images.';
    }

    if (Platform.isAndroid) {
      return 'Image Gallery Viewer needs storage permission to access and display your images.';
    }

    return 'Permission is required to access images.';
  }

  /// Gets a user-friendly message for when permission is denied.
  String getPermissionDeniedMessage() {
    if (Platform.isIOS) {
      return 'Photo library access was denied. Please enable it in Settings > Privacy > Photos to use this app.';
    }

    if (Platform.isAndroid) {
      return 'Storage permission was denied. Please enable it in Settings > Apps > Image Gallery Viewer > Permissions to use this app.';
    }

    return 'Permission was denied. Please enable it in your device settings.';
  }
}
