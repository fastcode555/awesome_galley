import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_galley/domain/models/models.dart';

void main() {
  group('GpsLocation', () {
    test('should format coordinates string correctly', () {
      const location = GpsLocation(
        latitude: 37.7749,
        longitude: -122.4194,
      );

      expect(location.coordinatesString, '37.774900, -122.419400');
    });

    test('should handle negative coordinates', () {
      const location = GpsLocation(
        latitude: -33.8688,
        longitude: 151.2093,
      );

      expect(location.coordinatesString, '-33.868800, 151.209300');
    });
  });

  group('ExifData', () {
    test('should create with all fields', () {
      final dateTaken = DateTime(2024, 1, 15, 10, 30);
      const location = GpsLocation(latitude: 37.7749, longitude: -122.4194);

      final exifData = ExifData(
        dateTaken: dateTaken,
        cameraModel: 'iPhone 15 Pro',
        cameraMake: 'Apple',
        gpsLocation: location,
        focalLength: 24.0,
        aperture: 1.8,
        iso: '100',
        exposureTime: '1/120',
      );

      expect(exifData.dateTaken, dateTaken);
      expect(exifData.cameraModel, 'iPhone 15 Pro');
      expect(exifData.cameraMake, 'Apple');
      expect(exifData.gpsLocation, location);
      expect(exifData.focalLength, 24.0);
      expect(exifData.aperture, 1.8);
      expect(exifData.iso, '100');
      expect(exifData.exposureTime, '1/120');
    });

    test('should create with optional fields as null', () {
      final exifData = ExifData();

      expect(exifData.dateTaken, isNull);
      expect(exifData.cameraModel, isNull);
      expect(exifData.cameraMake, isNull);
      expect(exifData.gpsLocation, isNull);
      expect(exifData.focalLength, isNull);
      expect(exifData.aperture, isNull);
      expect(exifData.iso, isNull);
      expect(exifData.exposureTime, isNull);
    });
  });

  group('ImageMetadata', () {
    test('should create with all required fields', () {
      final modifiedTime = DateTime(2024, 1, 15);
      final metadata = ImageMetadata(
        fileName: 'photo.jpg',
        filePath: '/path/to/photo.jpg',
        width: 1920,
        height: 1080,
        fileSize: 2500000,
        format: ImageFormat.jpeg,
        modifiedTime: modifiedTime,
      );

      expect(metadata.fileName, 'photo.jpg');
      expect(metadata.filePath, '/path/to/photo.jpg');
      expect(metadata.width, 1920);
      expect(metadata.height, 1080);
      expect(metadata.fileSize, 2500000);
      expect(metadata.format, ImageFormat.jpeg);
      expect(metadata.modifiedTime, modifiedTime);
      expect(metadata.exifData, isNull);
    });

    test('should format resolution string correctly', () {
      final metadata = ImageMetadata(
        fileName: 'photo.jpg',
        filePath: '/path/to/photo.jpg',
        width: 1920,
        height: 1080,
        fileSize: 1000,
        format: ImageFormat.jpeg,
        modifiedTime: DateTime.now(),
      );

      expect(metadata.resolutionString, '1920 × 1080');
    });

    test('should format file size in bytes', () {
      final metadata = ImageMetadata(
        fileName: 'photo.jpg',
        filePath: '/path/to/photo.jpg',
        width: 100,
        height: 100,
        fileSize: 512,
        format: ImageFormat.jpeg,
        modifiedTime: DateTime.now(),
      );

      expect(metadata.fileSizeString, '512 B');
    });

    test('should format file size in KB', () {
      final metadata = ImageMetadata(
        fileName: 'photo.jpg',
        filePath: '/path/to/photo.jpg',
        width: 100,
        height: 100,
        fileSize: 2048,
        format: ImageFormat.jpeg,
        modifiedTime: DateTime.now(),
      );

      expect(metadata.fileSizeString, '2.0 KB');
    });

    test('should format file size in MB', () {
      final metadata = ImageMetadata(
        fileName: 'photo.jpg',
        filePath: '/path/to/photo.jpg',
        width: 1920,
        height: 1080,
        fileSize: 2500000,
        format: ImageFormat.jpeg,
        modifiedTime: DateTime.now(),
      );

      expect(metadata.fileSizeString, '2.4 MB');
    });

    test('should include EXIF data when provided', () {
      final exifData = ExifData(
        dateTaken: DateTime(2024, 1, 15),
        cameraModel: 'Canon EOS R5',
        cameraMake: 'Canon',
      );

      final metadata = ImageMetadata(
        fileName: 'photo.jpg',
        filePath: '/path/to/photo.jpg',
        width: 1920,
        height: 1080,
        fileSize: 2500000,
        format: ImageFormat.jpeg,
        modifiedTime: DateTime.now(),
        exifData: exifData,
      );

      expect(metadata.exifData, isNotNull);
      expect(metadata.exifData?.cameraModel, 'Canon EOS R5');
      expect(metadata.exifData?.cameraMake, 'Canon');
    });
  });
}
