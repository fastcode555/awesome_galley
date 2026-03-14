import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../domain/models/image_data.dart';

/// Exception thrown when image decoding fails
class ImageDecodeException implements Exception {
  final String message;
  final String? filePath;

  ImageDecodeException(this.message, {this.filePath});

  @override
  String toString() {
    if (filePath != null) {
      return 'ImageDecodeException: $message (file: $filePath)';
    }
    return 'ImageDecodeException: $message';
  }
}

/// Generates high-quality thumbnails for images
class ThumbnailGenerator {
  /// Maximum width for generated thumbnails
  static const int maxThumbnailWidth = 400;

  /// JPEG quality for thumbnail encoding (0-100)
  static const int jpegQuality = 85;

  /// Generates a thumbnail for the image at the given file path
  ///
  /// The thumbnail will:
  /// - Maintain the original aspect ratio
  /// - Have a maximum width of 400 pixels
  /// - Use cubic interpolation for high-quality scaling
  /// - Be encoded as JPEG with quality 85
  ///
  /// Throws [ImageDecodeException] if the image cannot be decoded
  /// Throws [FileSystemException] if the file cannot be read
  Future<ImageData> generateThumbnail(String filePath) async {
    try {
      // 1. Read the image file
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File not found', filePath);
      }

      final bytes = await file.readAsBytes();

      // 2. Decode the image
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw ImageDecodeException(
          'Failed to decode image',
          filePath: filePath,
        );
      }

      // 3. Resize the image to thumbnail size
      final thumbnail = resizeImage(image, maxThumbnailWidth);

      // 4. Encode as JPEG
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: jpegQuality);

      return ImageData(
        bytes: Uint8List.fromList(thumbnailBytes),
        width: thumbnail.width,
        height: thumbnail.height,
      );
    } on FileSystemException {
      rethrow;
    } on ImageDecodeException {
      rethrow;
    } catch (e) {
      throw ImageDecodeException(
        'Unexpected error during thumbnail generation: $e',
        filePath: filePath,
      );
    }
  }

  /// Resizes an image while maintaining aspect ratio
  ///
  /// The image will be resized so that its width does not exceed [targetWidth].
  /// The height is calculated to maintain the original aspect ratio.
  /// Uses cubic interpolation for high-quality scaling.
  ///
  /// If the original image width is already smaller than or equal to [targetWidth],
  /// the original image is returned unchanged.
  img.Image resizeImage(img.Image original, int targetWidth) {
    // If the image is already smaller than the target width, return it as-is
    if (original.width <= targetWidth) {
      return original;
    }

    // Calculate the target height to maintain aspect ratio
    final aspectRatio = original.width / original.height;
    final targetHeight = (targetWidth / aspectRatio).round();

    // Resize using cubic interpolation for high quality
    return img.copyResize(
      original,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );
  }
}
