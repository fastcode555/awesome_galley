import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:awesome_galley/infrastructure/generators/thumbnail_generator.dart';

void main() {
  late ThumbnailGenerator generator;
  late Directory tempDir;

  setUp(() {
    generator = ThumbnailGenerator();
  });

  setUpAll(() async {
    // Create a temporary directory for test files
    tempDir = await Directory.systemTemp.createTemp('thumbnail_test_');
  });

  tearDownAll(() async {
    // Clean up temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ThumbnailGenerator', () {
    group('generateThumbnail', () {
      test('should generate thumbnail with correct width constraint', () async {
        // Create a test image (800x600)
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
        final testImageBytes = img.encodeJpg(testImage);

        // Save to temp file
        final testFile = File(path.join(tempDir.path, 'test_800x600.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        // Generate thumbnail
        final thumbnail = await generator.generateThumbnail(testFile.path);

        // Verify width is at most 400px
        expect(thumbnail.width, lessThanOrEqualTo(400));
        expect(thumbnail.width, equals(400));

        // Verify aspect ratio is maintained (within 1% tolerance)
        final originalAspectRatio = 800 / 600;
        final thumbnailAspectRatio = thumbnail.aspectRatio;
        final aspectRatioDiff =
            (thumbnailAspectRatio - originalAspectRatio).abs() /
                originalAspectRatio;
        expect(aspectRatioDiff, lessThan(0.01));
      });

      test('should maintain aspect ratio for portrait images', () async {
        // Create a portrait test image (600x800)
        final testImage = img.Image(width: 600, height: 800);
        img.fill(testImage, color: img.ColorRgb8(0, 255, 0));
        final testImageBytes = img.encodeJpg(testImage);

        // Save to temp file
        final testFile = File(path.join(tempDir.path, 'test_600x800.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        // Generate thumbnail
        final thumbnail = await generator.generateThumbnail(testFile.path);

        // Verify width is at most 400px
        expect(thumbnail.width, lessThanOrEqualTo(400));

        // Verify aspect ratio is maintained (within 1% tolerance)
        final originalAspectRatio = 600 / 800;
        final thumbnailAspectRatio = thumbnail.aspectRatio;
        final aspectRatioDiff =
            (thumbnailAspectRatio - originalAspectRatio).abs() /
                originalAspectRatio;
        expect(aspectRatioDiff, lessThan(0.01));
      });

      test('should not upscale images smaller than max width', () async {
        // Create a small test image (200x150)
        final testImage = img.Image(width: 200, height: 150);
        img.fill(testImage, color: img.ColorRgb8(0, 0, 255));
        final testImageBytes = img.encodeJpg(testImage);

        // Save to temp file
        final testFile = File(path.join(tempDir.path, 'test_200x150.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        // Generate thumbnail
        final thumbnail = await generator.generateThumbnail(testFile.path);

        // Verify image is not upscaled
        expect(thumbnail.width, equals(200));
        expect(thumbnail.height, equals(150));
      });

      test('should throw ImageDecodeException for corrupted files', () async {
        // Create a corrupted file (not a valid image)
        final corruptedFile =
            File(path.join(tempDir.path, 'corrupted.jpg'));
        await corruptedFile.writeAsBytes(
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00, 0x00]),
        );

        // Attempt to generate thumbnail
        expect(
          () => generator.generateThumbnail(corruptedFile.path),
          throwsA(isA<ImageDecodeException>()),
        );
      });

      test('should throw FileSystemException for non-existent files',
          () async {
        final nonExistentPath =
            path.join(tempDir.path, 'non_existent.jpg');

        // Attempt to generate thumbnail
        expect(
          () => generator.generateThumbnail(nonExistentPath),
          throwsA(isA<FileSystemException>()),
        );
      });

      test('should handle PNG format', () async {
        // Create a test PNG image
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(255, 255, 0));
        final testImageBytes = img.encodePng(testImage);

        // Save to temp file
        final testFile = File(path.join(tempDir.path, 'test.png'));
        await testFile.writeAsBytes(testImageBytes);

        // Generate thumbnail
        final thumbnail = await generator.generateThumbnail(testFile.path);

        // Verify thumbnail was generated successfully
        expect(thumbnail.width, lessThanOrEqualTo(400));
        expect(thumbnail.bytes.isNotEmpty, isTrue);
      });

      test('should return ImageData with correct properties', () async {
        // Create a test image
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(128, 128, 128));
        final testImageBytes = img.encodeJpg(testImage);

        // Save to temp file
        final testFile = File(path.join(tempDir.path, 'test_props.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        // Generate thumbnail
        final thumbnail = await generator.generateThumbnail(testFile.path);

        // Verify ImageData properties
        expect(thumbnail.bytes, isA<Uint8List>());
        expect(thumbnail.bytes.isNotEmpty, isTrue);
        expect(thumbnail.width, isA<int>());
        expect(thumbnail.height, isA<int>());
        expect(thumbnail.width, greaterThan(0));
        expect(thumbnail.height, greaterThan(0));
        expect(thumbnail.sizeInBytes, equals(thumbnail.bytes.length));
      });
    });

    group('resizeImage', () {
      test('should resize image to target width maintaining aspect ratio', () {
        // Create a test image (800x600)
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(255, 0, 0));

        // Resize to 400px width
        final resized = generator.resizeImage(testImage, 400);

        // Verify dimensions
        expect(resized.width, equals(400));
        expect(resized.height, equals(300)); // 600 * (400/800) = 300

        // Verify aspect ratio is maintained
        final originalAspectRatio = testImage.width / testImage.height;
        final resizedAspectRatio = resized.width / resized.height;
        expect(
          (resizedAspectRatio - originalAspectRatio).abs(),
          lessThan(0.01),
        );
      });

      test('should not upscale images smaller than target width', () {
        // Create a small test image (200x150)
        final testImage = img.Image(width: 200, height: 150);
        img.fill(testImage, color: img.ColorRgb8(0, 255, 0));

        // Attempt to resize to 400px width
        final resized = generator.resizeImage(testImage, 400);

        // Verify image is not upscaled
        expect(resized.width, equals(200));
        expect(resized.height, equals(150));
      });

      test('should handle portrait images correctly', () {
        // Create a portrait test image (600x800)
        final testImage = img.Image(width: 600, height: 800);
        img.fill(testImage, color: img.ColorRgb8(0, 0, 255));

        // Resize to 400px width
        final resized = generator.resizeImage(testImage, 400);

        // Verify dimensions
        expect(resized.width, equals(400));
        // Height should be approximately 533 (800 * 400/600)
        expect(resized.height, closeTo(533, 1));

        // Verify aspect ratio is maintained
        final originalAspectRatio = testImage.width / testImage.height;
        final resizedAspectRatio = resized.width / resized.height;
        expect(
          (resizedAspectRatio - originalAspectRatio).abs(),
          lessThan(0.01),
        );
      });

      test('should handle square images correctly', () {
        // Create a square test image (800x800)
        final testImage = img.Image(width: 800, height: 800);
        img.fill(testImage, color: img.ColorRgb8(128, 128, 128));

        // Resize to 400px width
        final resized = generator.resizeImage(testImage, 400);

        // Verify dimensions (should be 400x400)
        expect(resized.width, equals(400));
        expect(resized.height, equals(400));
      });

      test('should return original image if width equals target', () {
        // Create a test image exactly at target width (400x300)
        final testImage = img.Image(width: 400, height: 300);
        img.fill(testImage, color: img.ColorRgb8(255, 255, 255));

        // Resize to 400px width
        final resized = generator.resizeImage(testImage, 400);

        // Verify dimensions remain the same
        expect(resized.width, equals(400));
        expect(resized.height, equals(300));
      });
    });

    group('ImageDecodeException', () {
      test('should format message correctly with file path', () {
        final exception = ImageDecodeException(
          'Test error',
          filePath: '/path/to/file.jpg',
        );

        expect(
          exception.toString(),
          equals(
              'ImageDecodeException: Test error (file: /path/to/file.jpg)'),
        );
      });

      test('should format message correctly without file path', () {
        final exception = ImageDecodeException('Test error');

        expect(
          exception.toString(),
          equals('ImageDecodeException: Test error'),
        );
      });
    });
  });
}
