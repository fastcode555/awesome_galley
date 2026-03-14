import 'dart:typed_data';

/// Represents the binary data of an image
class ImageData {
  /// Image bytes
  final Uint8List bytes;

  /// Width of the image in pixels
  final int width;

  /// Height of the image in pixels
  final int height;

  const ImageData({
    required this.bytes,
    required this.width,
    required this.height,
  });

  /// Calculate the aspect ratio (width / height)
  double get aspectRatio => width / height;

  /// Get the size of the image data in bytes
  int get sizeInBytes => bytes.length;
}
