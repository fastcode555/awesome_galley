import 'exif_data.dart';
import 'image_format.dart';

/// Represents complete metadata for an image file
class ImageMetadata {
  /// File name of the image
  final String fileName;

  /// Full file path to the image
  final String filePath;

  /// Width of the image in pixels
  final int width;

  /// Height of the image in pixels
  final int height;

  /// File size in bytes
  final int fileSize;

  /// Image format
  final ImageFormat format;

  /// Last modified time of the file
  final DateTime modifiedTime;

  /// Optional EXIF data extracted from the image
  final ExifData? exifData;

  ImageMetadata({
    required this.fileName,
    required this.filePath,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.format,
    required this.modifiedTime,
    this.exifData,
  });

  /// Get formatted resolution string (e.g., "1920 × 1080")
  String get resolutionString => '$width × $height';

  /// Get formatted file size string (e.g., "2.5 MB")
  String get fileSizeString => _formatFileSize(fileSize);

  /// Format file size in human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
