import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_galley/domain/models/models.dart';

void main() {
  group('FileInfo', () {
    test('should create FileInfo with all required fields', () {
      final now = DateTime.now();
      final fileInfo = FileInfo(
        path: '/path/to/image.jpg',
        name: 'image.jpg',
        size: 1024000,
        modifiedTime: now,
        format: ImageFormat.jpeg,
      );

      expect(fileInfo.path, '/path/to/image.jpg');
      expect(fileInfo.name, 'image.jpg');
      expect(fileInfo.size, 1024000);
      expect(fileInfo.modifiedTime, now);
      expect(fileInfo.format, ImageFormat.jpeg);
    });

    test('isSupported should return true for supported formats', () {
      final fileInfo = FileInfo(
        path: '/path/to/image.jpg',
        name: 'image.jpg',
        size: 1024000,
        modifiedTime: DateTime.now(),
        format: ImageFormat.jpeg,
      );

      expect(fileInfo.isSupported, true);
    });

    test('isSupported should return false for unknown format', () {
      final fileInfo = FileInfo(
        path: '/path/to/file.txt',
        name: 'file.txt',
        size: 1024,
        modifiedTime: DateTime.now(),
        format: ImageFormat.unknown,
      );

      expect(fileInfo.isSupported, false);
    });

    test('isSupported should return true for all supported formats', () {
      final supportedFormats = [
        ImageFormat.jpeg,
        ImageFormat.png,
        ImageFormat.gif,
        ImageFormat.webp,
        ImageFormat.bmp,
      ];

      for (final format in supportedFormats) {
        final fileInfo = FileInfo(
          path: '/path/to/image',
          name: 'image',
          size: 1024,
          modifiedTime: DateTime.now(),
          format: format,
        );

        expect(fileInfo.isSupported, true,
            reason: 'Format $format should be supported');
      }
    });
  });
}
