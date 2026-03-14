import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'platform_integration.dart';

/// Linux-specific implementation of PlatformIntegration.
///
/// Uses .desktop files and MIME type registration for file associations.
class LinuxPlatformIntegration implements PlatformIntegration {
  /// Supported image file extensions
  static const List<String> _supportedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
  ];

  /// MIME types for supported image formats
  static const Map<String, String> _mimeTypes = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
    '.bmp': 'image/bmp',
  };

  @override
  Future<void> registerFileAssociations() async {
    try {
      // Create .desktop file in ~/.local/share/applications/
      await _createDesktopFile();
      
      // Register MIME types
      await _registerMimeTypes();
      
      // Update desktop database
      await _updateDesktopDatabase();
    } catch (e) {
      throw Exception('Failed to register file associations on Linux: $e');
    }
  }

  @override
  Future<void> setAsDefaultApp() async {
    try {
      // Use xdg-mime to set default application for each MIME type
      for (final mimeType in _mimeTypes.values.toSet()) {
        final result = await Process.run('xdg-mime', [
          'default',
          'image-gallery-viewer.desktop',
          mimeType,
        ]);
        
        if (result.exitCode != 0) {
          if (kDebugMode) {
            print('Warning: Failed to set default for $mimeType: ${result.stderr}');
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to set as default app on Linux: $e');
    }
  }

  @override
  Future<List<String>> getLaunchArguments() async {
    // On Linux, command line arguments are available via Platform.executableArguments
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
      // Try to use exiftool if available
      final result = await Process.run('exiftool', ['-json', filePath]);
      
      if (result.exitCode == 0) {
        // Parse JSON output from exiftool
        // This is a simplified implementation
        // In production, you'd want to parse the JSON properly
        return {'raw': result.stdout};
      }
      
      return null;
    } catch (e) {
      // exiftool not available or extraction failed
      if (kDebugMode) {
        print('Failed to extract EXIF data: $e');
      }
      return null;
    }
  }

  /// Creates a .desktop file for the application
  Future<void> _createDesktopFile() async {
    final homeDir = Platform.environment['HOME'];
    if (homeDir == null) {
      throw Exception('HOME environment variable not set');
    }

    final desktopDir = Directory(path.join(
      homeDir,
      '.local',
      'share',
      'applications',
    ));

    // Create directory if it doesn't exist
    if (!await desktopDir.exists()) {
      await desktopDir.create(recursive: true);
    }

    final desktopFile = File(path.join(
      desktopDir.path,
      'image-gallery-viewer.desktop',
    ));

    final executablePath = Platform.resolvedExecutable;
    final desktopContent = '''
[Desktop Entry]
Version=1.0
Type=Application
Name=Image Gallery Viewer
Comment=View and browse images
Exec=$executablePath %f
Icon=image-viewer
Terminal=false
Categories=Graphics;Viewer;
MimeType=${_mimeTypes.values.toSet().join(';')};
''';

    await desktopFile.writeAsString(desktopContent);
  }

  /// Registers MIME types for the application
  Future<void> _registerMimeTypes() async {
    // This is typically handled by the .desktop file
    // Additional MIME type registration can be done here if needed
  }

  /// Updates the desktop database
  Future<void> _updateDesktopDatabase() async {
    try {
      await Process.run('update-desktop-database', [
        path.join(
          Platform.environment['HOME']!,
          '.local',
          'share',
          'applications',
        ),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to update desktop database: $e');
      }
    }
  }
}
