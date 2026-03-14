import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'platform_integration.dart';
import 'windows_platform_integration.dart';
import 'macos_platform_integration.dart';
import 'linux_platform_integration.dart';
import 'ios_platform_integration.dart';
import 'android_platform_integration.dart';
import 'web_platform_integration.dart';

/// Factory class to create the appropriate PlatformIntegration instance
/// based on the current platform.
class PlatformIntegrationFactory {
  /// Creates and returns the appropriate PlatformIntegration implementation
  /// for the current platform.
  ///
  /// Returns:
  /// - WindowsPlatformIntegration on Windows
  /// - MacOSPlatformIntegration on macOS
  /// - LinuxPlatformIntegration on Linux
  /// - IOSPlatformIntegration on iOS
  /// - AndroidPlatformIntegration on Android
  /// - WebPlatformIntegration on Web
  static PlatformIntegration create() {
    if (kIsWeb) {
      return WebPlatformIntegration();
    }
    
    if (Platform.isWindows) {
      return WindowsPlatformIntegration();
    } else if (Platform.isMacOS) {
      return MacOSPlatformIntegration();
    } else if (Platform.isLinux) {
      return LinuxPlatformIntegration();
    } else if (Platform.isIOS) {
      return IOSPlatformIntegration();
    } else if (Platform.isAndroid) {
      return AndroidPlatformIntegration();
    }
    
    throw UnsupportedError('Unsupported platform');
  }

  /// Checks if the current platform supports file associations.
  static bool supportsFileAssociations() {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Checks if the current platform requires permission requests.
  static bool requiresPermissions() {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Checks if the current platform is mobile.
  static bool isMobile() {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Checks if the current platform is desktop.
  static bool isDesktop() {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}
