import 'image_format.dart';

/// Represents a single image item in the gallery
class ImageItem {
  /// Unique identifier for the image
  final String id;

  /// Full file path to the image
  final String filePath;

  /// File name of the image
  final String fileName;

  /// Original width of the image in pixels
  final int width;

  /// Original height of the image in pixels
  final int height;

  /// File size in bytes
  final int fileSize;

  /// Last modified time of the file
  final DateTime modifiedTime;

  /// Image format
  final ImageFormat format;

  const ImageItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.modifiedTime,
    required this.format,
  });

  /// Calculate the aspect ratio (width / height)
  double get aspectRatio => width / height;

  ImageItem copyWith({int? width, int? height}) {
    return ImageItem(
      id: id,
      filePath: filePath,
      fileName: fileName,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize,
      modifiedTime: modifiedTime,
      format: format,
    );
  }
}
