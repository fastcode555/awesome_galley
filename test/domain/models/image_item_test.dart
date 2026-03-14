import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_galley/domain/models/models.dart';

void main() {
  group('ImageItem', () {
    test('should create an ImageItem with all required fields', () {
      final now = DateTime.now();
      final item = ImageItem(
        id: 'test-id',
        filePath: '/path/to/image.jpg',
        fileName: 'image.jpg',
        width: 1920,
        height: 1080,
        fileSize: 1024000,
        modifiedTime: now,
        format: ImageFormat.jpeg,
      );

      expect(item.id, 'test-id');
      expect(item.filePath, '/path/to/image.jpg');
      expect(item.fileName, 'image.jpg');
      expect(item.width, 1920);
      expect(item.height, 1080);
      expect(item.fileSize, 1024000);
      expect(item.modifiedTime, now);
      expect(item.format, ImageFormat.jpeg);
    });

    test('aspectRatio should return width divided by height', () {
      final item = ImageItem(
        id: 'test-id',
        filePath: '/path/to/image.jpg',
        fileName: 'image.jpg',
        width: 1920,
        height: 1080,
        fileSize: 1024000,
        modifiedTime: DateTime.now(),
        format: ImageFormat.jpeg,
      );

      expect(item.aspectRatio, 1920 / 1080);
    });

    test('aspectRatio should handle portrait images', () {
      final item = ImageItem(
        id: 'test-id',
        filePath: '/path/to/image.jpg',
        fileName: 'image.jpg',
        width: 1080,
        height: 1920,
        fileSize: 1024000,
        modifiedTime: DateTime.now(),
        format: ImageFormat.jpeg,
      );

      expect(item.aspectRatio, 1080 / 1920);
    });

    test('aspectRatio should handle square images', () {
      final item = ImageItem(
        id: 'test-id',
        filePath: '/path/to/image.jpg',
        fileName: 'image.jpg',
        width: 1000,
        height: 1000,
        fileSize: 1024000,
        modifiedTime: DateTime.now(),
        format: ImageFormat.jpeg,
      );

      expect(item.aspectRatio, 1.0);
    });
  });
}
