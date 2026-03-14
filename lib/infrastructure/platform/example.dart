// Example usage of the PlatformIntegration module
//
// This file demonstrates how to use the platform integration functionality
// in the Image Gallery Viewer application.

import 'package:flutter/foundation.dart';
import 'platform.dart';

/// Example class demonstrating platform integration usage
class PlatformIntegrationExample {
  final PlatformIntegration? _platformIntegration;

  PlatformIntegrationExample()
      : _platformIntegration = PlatformIntegrationFactory.create();

  /// Initializes platform-specific features
  Future<void> initialize() async {
    if (_platformIntegration == null) {
      if (kDebugMode) {
        print('Platform integration not supported on this platform');
      }
      return;
    }

    try {
      // Register file associations
      await _platformIntegration.registerFileAssociations();
      if (kDebugMode) {
        print('File associations registered successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to register file associations: $e');
      }
    }
  }

  /// Checks if the app was launched via file association
  Future<bool> isLaunchedViaFileAssociation() async {
    if (_platformIntegration == null) return false;

    final launchArgs = await _platformIntegration.getLaunchArguments();
    return launchArgs.isNotEmpty;
  }

  /// Gets the file path if launched via file association
  Future<String?> getLaunchedFilePath() async {
    if (_platformIntegration == null) return null;

    final launchArgs = await _platformIntegration.getLaunchArguments();
    return launchArgs.isNotEmpty ? launchArgs.first : null;
  }

  /// Extracts and displays EXIF data from an image
  Future<void> displayExifData(String filePath) async {
    if (_platformIntegration == null) {
      if (kDebugMode) {
        print('Platform integration not available');
      }
      return;
    }

    final exifData = await _platformIntegration.extractExifData(filePath);
    
    if (exifData == null) {
      if (kDebugMode) {
        print('No EXIF data found for: $filePath');
      }
      return;
    }

    if (kDebugMode) {
      print('EXIF data for $filePath:');
      exifData.forEach((key, value) {
        // ignore: avoid_print
        print('  $key: $value');
      });
    }
  }

  /// Sets the app as the default image viewer
  Future<void> setAsDefaultImageViewer() async {
    if (_platformIntegration == null) {
      if (kDebugMode) {
        print('Platform integration not supported on this platform');
      }
      return;
    }

    try {
      await _platformIntegration.setAsDefaultApp();
      if (kDebugMode) {
        print('Successfully set as default image viewer');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set as default app: $e');
      }
    }
  }

  /// Checks if platform integration is supported
  bool isSupported() {
    return PlatformIntegrationFactory.supportsFileAssociations();
  }
}

/// Example usage in main.dart:
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   final platformExample = PlatformIntegrationExample();
///   
///   // Initialize platform features
///   await platformExample.initialize();
///   
///   // Check if launched via file association
///   if (await platformExample.isLaunchedViaFileAssociation()) {
///     final filePath = await platformExample.getLaunchedFilePath();
///     print('Launched with file: $filePath');
///     
///     // Extract EXIF data
///     if (filePath != null) {
///       await platformExample.displayExifData(filePath);
///     }
///   }
///   
///   runApp(MyApp());
/// }
/// ```
