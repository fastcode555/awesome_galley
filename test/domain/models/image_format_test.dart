import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_galley/domain/models/models.dart';

void main() {
  group('ImageFormat', () {
    group('fromExtension', () {
      test('should return jpeg for .jpg extension', () {
        expect(ImageFormat.fromExtension('.jpg'), ImageFormat.jpeg);
      });

      test('should return jpeg for .jpeg extension', () {
        expect(ImageFormat.fromExtension('.jpeg'), ImageFormat.jpeg);
      });

      test('should return png for .png extension', () {
        expect(ImageFormat.fromExtension('.png'), ImageFormat.png);
      });

      test('should return gif for .gif extension', () {
        expect(ImageFormat.fromExtension('.gif'), ImageFormat.gif);
      });

      test('should return webp for .webp extension', () {
        expect(ImageFormat.fromExtension('.webp'), ImageFormat.webp);
      });

      test('should return bmp for .bmp extension', () {
        expect(ImageFormat.fromExtension('.bmp'), ImageFormat.bmp);
      });

      test('should return unknown for unsupported extension', () {
        expect(ImageFormat.fromExtension('.txt'), ImageFormat.unknown);
        expect(ImageFormat.fromExtension('.pdf'), ImageFormat.unknown);
      });

      test('should be case insensitive', () {
        expect(ImageFormat.fromExtension('.JPG'), ImageFormat.jpeg);
        expect(ImageFormat.fromExtension('.PNG'), ImageFormat.png);
        expect(ImageFormat.fromExtension('.GIF'), ImageFormat.gif);
      });
    });

    test('supportedExtensions should contain all supported formats', () {
      expect(ImageFormat.supportedExtensions, [
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.webp',
        '.bmp',
      ]);
    });
  });
}
