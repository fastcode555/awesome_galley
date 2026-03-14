import 'package:flutter/material.dart';
import '../../domain/models/image_metadata.dart';
import '../../domain/models/image_format.dart';
import '../../domain/models/exif_data.dart';
import '../../domain/models/gps_location.dart';
import 'metadata_panel.dart';

/// Example usage of the MetadataPanel widget
class MetadataPanelExample extends StatelessWidget {
  const MetadataPanelExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metadata Panel Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showMetadataWithoutExif(context),
              child: const Text('Show Metadata (No EXIF)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showMetadataWithExif(context),
              child: const Text('Show Metadata (With EXIF)'),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows metadata panel without EXIF data
  void _showMetadataWithoutExif(BuildContext context) {
    final metadata = ImageMetadata(
      fileName: 'sample_image.jpg',
      filePath: '/path/to/sample_image.jpg',
      width: 1920,
      height: 1080,
      fileSize: 2457600, // 2.4 MB
      format: ImageFormat.jpeg,
      modifiedTime: DateTime.now().subtract(const Duration(days: 7)),
    );

    MetadataPanel.show(context, metadata);
  }

  /// Shows metadata panel with EXIF data
  void _showMetadataWithExif(BuildContext context) {
    final metadata = ImageMetadata(
      fileName: 'photo_with_exif.jpg',
      filePath: '/path/to/photo_with_exif.jpg',
      width: 4032,
      height: 3024,
      fileSize: 5242880, // 5 MB
      format: ImageFormat.jpeg,
      modifiedTime: DateTime.now().subtract(const Duration(days: 30)),
      exifData: ExifData(
        dateTaken: DateTime(2024, 1, 15, 14, 30, 0),
        cameraMake: 'Canon',
        cameraModel: 'EOS R5',
        gpsLocation: const GpsLocation(
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        focalLength: 50.0,
        aperture: 2.8,
        iso: '400',
        exposureTime: '1/250',
      ),
    );

    MetadataPanel.show(context, metadata);
  }
}
