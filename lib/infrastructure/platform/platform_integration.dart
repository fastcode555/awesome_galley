/// Abstract interface for platform-specific functionality.
///
/// This interface defines the contract for platform-specific operations
/// including file associations, launch arguments, and EXIF data extraction.
abstract class PlatformIntegration {
  /// Registers file associations for supported image formats.
  ///
  /// This method registers the application to handle image file types
  /// in the operating system's "Open With" menu.
  ///
  /// Supported formats: .jpg, .jpeg, .png, .gif, .webp, .bmp
  Future<void> registerFileAssociations();

  /// Sets this application as the default app for image files.
  ///
  /// This method calls the operating system API to register the application
  /// as the default handler for all supported image formats.
  Future<void> setAsDefaultApp();

  /// Gets the launch arguments passed to the application.
  ///
  /// Returns a list of file paths if the application was launched via
  /// file association, or an empty list if launched normally.
  Future<List<String>> getLaunchArguments();

  /// Extracts EXIF metadata from an image file.
  ///
  /// Returns EXIF data including date taken, camera model, GPS location, etc.
  /// Returns null if the file doesn't contain EXIF data or if extraction fails.
  Future<Map<String, dynamic>?> extractExifData(String filePath);
}
