/// Supported image formats for the gallery viewer
enum ImageFormat {
  jpeg,
  png,
  gif,
  webp,
  bmp,
  unknown;

  /// List of supported file extensions
  static const List<String> supportedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
  ];

  /// Convert a file extension to an ImageFormat
  /// 
  /// Returns [ImageFormat.unknown] if the extension is not supported
  static ImageFormat fromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return ImageFormat.jpeg;
      case '.png':
        return ImageFormat.png;
      case '.gif':
        return ImageFormat.gif;
      case '.webp':
        return ImageFormat.webp;
      case '.bmp':
        return ImageFormat.bmp;
      default:
        return ImageFormat.unknown;
    }
  }
}
