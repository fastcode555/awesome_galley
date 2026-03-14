import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_galley/domain/models/models.dart';

void main() {
  group('ImageData', () {
    test('should create ImageData with all required fields', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final imageData = ImageData(
        bytes: bytes,
        width: 100,
        height: 50,
      );

      expect(imageData.bytes, bytes);
      expect(imageData.width, 100);
      expect(imageData.height, 50);
    });

    test('aspectRatio should return width divided by height', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final imageData = ImageData(
        bytes: bytes,
        width: 1920,
        height: 1080,
      );

      expect(imageData.aspectRatio, 1920 / 1080);
    });

    test('sizeInBytes should return the length of bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      final imageData = ImageData(
        bytes: bytes,
        width: 100,
        height: 50,
      );

      expect(imageData.sizeInBytes, 10);
    });

    test('sizeInBytes should return 0 for empty bytes', () {
      final bytes = Uint8List.fromList([]);
      final imageData = ImageData(
        bytes: bytes,
        width: 0,
        height: 0,
      );

      expect(imageData.sizeInBytes, 0);
    });
  });
}
