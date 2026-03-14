import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

/// Web-specific file picker for selecting image files.
///
/// This service provides file selection functionality on web platform,
/// replacing system directory scanning which is not available in browsers.
class WebFilePicker {
  /// Supported image MIME types
  static const List<String> _supportedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/bmp',
  ];

  /// Opens a file picker dialog for selecting image files.
  ///
  /// Parameters:
  /// - [multiple]: Whether to allow multiple file selection (default: true)
  ///
  /// Returns a list of [WebImageFile] objects containing file data.
  Future<List<WebImageFile>> pickImages({bool multiple = true}) async {
    final completer = Completer<List<WebImageFile>>();
    
    // Create file input element
    final input = html.FileUploadInputElement()
      ..accept = _supportedMimeTypes.join(',')
      ..multiple = multiple;
    
    // Track if the input was used
    bool hasCompleted = false;
    
    // Listen for file selection
    input.onChange.listen((event) async {
      if (hasCompleted) return;
      hasCompleted = true;
      
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete([]);
        return;
      }
      
      final webFiles = <WebImageFile>[];
      
      for (final file in files) {
        // Check if file type is supported
        if (!_supportedMimeTypes.contains(file.type)) {
          if (kDebugMode) {
            print('Skipping unsupported file type: ${file.type}');
          }
          continue;
        }
        
        // Read file as bytes
        final reader = html.FileReader();
        final readCompleter = Completer<Uint8List>();
        
        reader.onLoadEnd.listen((event) {
          final result = reader.result;
          if (result is Uint8List) {
            readCompleter.complete(result);
          } else {
            readCompleter.completeError('Failed to read file');
          }
        });
        
        reader.onError.listen((event) {
          readCompleter.completeError('Error reading file');
        });
        
        reader.readAsArrayBuffer(file);
        
        try {
          final bytes = await readCompleter.future;
          
          // Create blob URL for displaying the image
          final blob = html.Blob([bytes], file.type);
          final blobUrl = html.Url.createObjectUrlFromBlob(blob);
          
          webFiles.add(WebImageFile(
            name: file.name,
            bytes: bytes,
            size: file.size,
            mimeType: file.type,
            blobUrl: blobUrl,
            lastModified: DateTime.fromMillisecondsSinceEpoch(
              file.lastModified ?? DateTime.now().millisecondsSinceEpoch,
            ),
          ));
        } catch (e) {
          if (kDebugMode) {
            print('Error reading file ${file.name}: $e');
          }
        }
      }
      
      completer.complete(webFiles);
    });
    
    // Trigger file picker
    input.click();
    
    // Set a timeout to handle cancel case
    Future.delayed(const Duration(seconds: 1), () {
      if (!hasCompleted) {
        // Check if window has focus - if not, user might be in file picker
        // We'll wait a bit more
        Future.delayed(const Duration(seconds: 30), () {
          if (!hasCompleted) {
            hasCompleted = true;
            completer.complete([]);
          }
        });
      }
    });
    
    return completer.future;
  }

  /// Opens a directory picker dialog (if supported by the browser).
  ///
  /// Note: This uses the File System Access API which is only available
  /// in Chromium-based browsers. Falls back to regular file picker if not supported.
  ///
  /// Returns a list of [WebImageFile] objects from the selected directory.
  Future<List<WebImageFile>> pickDirectory() async {
    // For now, fall back to regular file picker with multiple selection
    // File System Access API has limited browser support
    if (kDebugMode) {
      print('Directory picker not fully implemented, using file picker instead');
    }
    return pickImages(multiple: true);
  }

  /// Revokes a blob URL to free memory.
  void revokeBlobUrl(String blobUrl) {
    html.Url.revokeObjectUrl(blobUrl);
  }
}

/// Represents an image file selected on the web platform.
class WebImageFile {
  /// File name
  final String name;

  /// File content as bytes
  final Uint8List bytes;

  /// File size in bytes
  final int size;

  /// MIME type (e.g., 'image/jpeg')
  final String mimeType;

  /// Blob URL for displaying the image
  final String blobUrl;

  /// Last modified timestamp
  final DateTime lastModified;

  WebImageFile({
    required this.name,
    required this.bytes,
    required this.size,
    required this.mimeType,
    required this.blobUrl,
    required this.lastModified,
  });

  /// Gets the file extension from the name.
  String get extension {
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1) return '';
    return name.substring(lastDot);
  }

  /// Checks if this is a supported image format.
  bool get isSupported {
    const supportedMimeTypes = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'image/bmp',
    ];
    return supportedMimeTypes.contains(mimeType);
  }
}
