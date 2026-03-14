import 'image_format.dart';

/// Represents file system information for an image file
class FileInfo {
  /// Full path to the file
  final String path;

  /// Name of the file
  final String name;

  /// Size of the file in bytes
  final int size;

  /// Last modified time of the file
  final DateTime modifiedTime;

  /// Image format of the file
  final ImageFormat format;

  const FileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.modifiedTime,
    required this.format,
  });

  /// Check if the file format is supported
  bool get isSupported => format != ImageFormat.unknown;
}
