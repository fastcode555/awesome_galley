import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Stub implementation for non-web platforms
class WebFilePicker {
  Future<List<WebImageFile>> pickImages({bool multiple = true}) async {
    throw UnsupportedError('WebFilePicker is only available on web platform');
  }

  Future<List<WebImageFile>> pickDirectory() async {
    throw UnsupportedError('WebFilePicker is only available on web platform');
  }

  void revokeBlobUrl(String blobUrl) {
    throw UnsupportedError('WebFilePicker is only available on web platform');
  }
}

/// Represents an image file selected on the web platform.
class WebImageFile {
  final String name;
  final Uint8List bytes;
  final int size;
  final String mimeType;
  final String blobUrl;
  final DateTime lastModified;

  WebImageFile({
    required this.name,
    required this.bytes,
    required this.size,
    required this.mimeType,
    required this.blobUrl,
    required this.lastModified,
  });

  String get extension {
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1) return '';
    return name.substring(lastDot);
  }

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
