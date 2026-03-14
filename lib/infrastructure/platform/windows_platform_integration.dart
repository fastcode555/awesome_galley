import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'platform_integration.dart';

/// Windows-specific implementation of PlatformIntegration.
///
/// Uses MethodChannel to communicate with native Windows code for
/// file association registration via Windows Registry.
class WindowsPlatformIntegration implements PlatformIntegration {
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
    try {
      await _channel.invokeMethod('registerFileAssociations', {
        'extensions': _supportedExtensions,
        'appName': 'Image Gallery Viewer',
        'appPath': Platform.resolvedExecutable,
      });
    } on PlatformException catch (e) {
      throw Exception(
          'Failed to register file associations on Windows: ${e.message}');
    }
  }

  @override
  Future<void> setAsDefaultApp() async {
    try {
      await _channel.invokeMethod('setAsDefaultApp', {
        'extensions': _supportedExtensions,
      });
    } on PlatformException catch (e) {
      throw Exception(
          'Failed to set as default app on Windows: ${e.message}');
    }
  }

  @override
  Future<List<String>> getLaunchArguments() async {
    // On Windows, command line arguments are available via Platform.executableArguments
    // Filter out Flutter-specific arguments and return only file paths
    final args = Platform.executableArguments;
    return args.where((arg) {
      // Filter out arguments that start with -- (Flutter flags)
      if (arg.startsWith('--')) return false;
      // Check if the argument is a file path with supported extension
      final lowerArg = arg.toLowerCase();
      return _supportedExtensions.any((ext) => lowerArg.endsWith(ext));
    }).toList();
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
