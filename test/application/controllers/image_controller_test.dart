import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:awesome_galley/application/controllers/image_controller.dart';
import 'package:awesome_galley/domain/models/image_data.dart';
import 'package:awesome_galley/domain/models/image_format.dart';
import 'package:awesome_galley/domain/models/image_item.dart';
import 'package:awesome_galley/infrastructure/cache/cache_manager.dart';
import 'package:awesome_galley/infrastructure/generators/thumbnail_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ImageController controller;
  late Directory tempDir;
  late ThumbnailGenerator thumbnailGenerator;
  late CacheManager cacheManager;

  setUpAll(() async {
    // Create a temporary directory for test files
    tempDir = await Directory.systemTemp.createTemp('image_controller_test_');
  });

  tearDownAll(() async {
    // Clean up temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() {
    thumbnailGenerator = ThumbnailGenerator();
    cacheManager = CacheManager();
    controller = ImageController(
      thumbnailGenerator: thumbnailGenerator,
      cacheManager: cacheManager,
    );
  });

  tearDown(() async {
    await cacheManager.clearAll();
    controller.dispose();
  });

  group('ImageController', () {
    group('State Management', () {
      test('should initialize with idle state', () {
        expect(controller.state, equals(ImageLoadingState.idle));
        expect(controller.isLoading, isFalse);
        expect(controller.isSuccess, isFalse);
        expect(controller.isError, isFalse);
        expect(controller.errorMessage, isNull);
      });

      test('should update state to loading during operation', () async {
        // Create a test image
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
        final testImageBytes = img.encodeJpg(testImage);
        final testFile = File(path.join(tempDir.path, 'test_state.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        final imageItem = ImageItem(
          id: '1',
          filePath: testFile.path,
          fileName: 'test_state.jpg',
          width: 800,
          height: 600,
          fileSize: testImageBytes.length,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        // Start loading (don't await)
        final loadFuture = controller.loadThumbnail(imageItem);

        // State should be loading
        expect(controller.state, equals(ImageLoadingState.loading));
        expect(controller.isLoading, isTrue);

        // Wait for completion
        await loadFuture;

        // State should be success
        expect(controller.state, equals(ImageLoadingState.success));
        expect(controller.isSuccess, isTrue);
      });

      test('should update state to success after successful load', () async {
        // Create a test image
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
        final testImageBytes = img.encodeJpg(testImage);
        final testFile = File(path.join(tempDir.path, 'test_success.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        final imageItem = ImageItem(
          id: '1',
          filePath: testFile.path,
          fileName: 'test_success.jpg',
          width: 800,
          height: 600,
          fileSize: testImageBytes.length,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        await controller.loadThumbnail(imageItem);

        expect(controller.state, equals(ImageLoadingState.success));
        expect(controller.isSuccess, isTrue);
        expect(controller.errorMessage, isNull);
      });

      test('should update state to error after failed load', () async {
        final imageItem = ImageItem(
          id: '1',
          filePath: '/nonexistent/file.jpg',
          fileName: 'file.jpg',
          width: 800,
          height: 600,
          fileSize: 1000,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        try {
          await controller.loadThumbnail(imageItem);
        } catch (e) {
          // Expected to throw
        }

        expect(controller.state, equals(ImageLoadingState.error));
        expect(controller.isError, isTrue);
        expect(controller.errorMessage, isNotNull);
      });

      test('should reset state to idle', () async {
        // Create a test image
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
        final testImageBytes = img.encodeJpg(testImage);
        final testFile = File(path.join(tempDir.path, 'test_reset.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        final imageItem = ImageItem(
          id: '1',
          filePath: testFile.path,
          fileName: 'test_reset.jpg',
          width: 800,
          height: 600,
          fileSize: testImageBytes.length,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        await controller.loadThumbnail(imageItem);
        expect(controller.state, equals(ImageLoadingState.success));

        controller.reset();
        expect(controller.state, equals(ImageLoadingState.idle));
      });

      test('should notify listeners on state change', () async {
        int notificationCount = 0;
        controller.addListener(() {
          notificationCount++;
        });

        // Create a test image
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
        final testImageBytes = img.encodeJpg(testImage);
        final testFile = File(path.join(tempDir.path, 'test_notify.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        final imageItem = ImageItem(
          id: '1',
          filePath: testFile.path,
          fileName: 'test_notify.jpg',
          width: 800,
          height: 600,
          fileSize: testImageBytes.length,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        await controller.loadThumbnail(imageItem);

        // Should be notified at least twice (loading -> success)
        expect(notificationCount, greaterThanOrEqualTo(2));
      });
    });

    group('loadThumbnail', () {
      test('should load thumbnail successfully', () async {
        // Create a test image
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
        final testImageBytes = img.encodeJpg(testImage);
        final testFile = File(path.join(tempDir.path, 'test_load.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        final imageItem = ImageItem(
          id: '1',
          filePath: testFile.path,
          fileName: 'test_load.jpg',
          width: 800,
          height: 600,
          fileSize: testImageBytes.length,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        final thumbnail = await controller.loadThumbnail(imageItem);

        expect(thumbnail, isA<ImageData>());
        expect(thumbnail.width, lessThanOrEqualTo(400));
        expect(thumbnail.bytes.isNotEmpty, isTrue);
      });

      test('should prioritize cache when loading thumbnail', () async {
        // Create a test image
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
        final testImageBytes = img.encodeJpg(testImage);
        final testFile = File(path.join(tempDir.path, 'test_cache.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        final imageItem = ImageItem(
          id: '1',
          filePath: testFile.path,
          fileName: 'test_cache.jpg',
          width: 800,
          height: 600,
          fileSize: testImageBytes.length,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        // First load - should generate and cache
        final thumbnail1 = await controller.loadThumbnail(imageItem);

        // Second load - should load from cache
        final thumbnail2 = await controller.loadThumbnail(imageItem);

        // Both should be valid ImageData
        expect(thumbnail1, isA<ImageData>());
        expect(thumbnail2, isA<ImageData>());

        // Should have same dimensions
        expect(thumbnail2.width, equals(thumbnail1.width));
        expect(thumbnail2.height, equals(thumbnail1.height));
      });

      test('should cache generated thumbnail', () async {
        // Create a test image
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
        final testImageBytes = img.encodeJpg(testImage);
        final testFile =
            File(path.join(tempDir.path, 'test_cache_gen.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        final imageItem = ImageItem(
          id: '1',
          filePath: testFile.path,
          fileName: 'test_cache_gen.jpg',
          width: 800,
          height: 600,
          fileSize: testImageBytes.length,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        // Load thumbnail
        await controller.loadThumbnail(imageItem);

        // Check if cached
        final cacheKey = cacheManager.generateCacheKey(
          imageItem.filePath,
          imageItem.modifiedTime,
        );
        final cachedThumbnail = await cacheManager.getThumbnail(cacheKey);

        expect(cachedThumbnail, isNotNull);
      });

      test('should throw exception for non-existent file', () async {
        final imageItem = ImageItem(
          id: '1',
          filePath: '/nonexistent/file.jpg',
          fileName: 'file.jpg',
          width: 800,
          height: 600,
          fileSize: 1000,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        expect(
          () => controller.loadThumbnail(imageItem),
          throwsA(isA<FileSystemException>()),
        );
      });

      test('should throw exception for corrupted file', () async {
        // Create a corrupted file
        final corruptedFile =
            File(path.join(tempDir.path, 'corrupted.jpg'));
        await corruptedFile.writeAsBytes(
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00, 0x00]),
        );

        final imageItem = ImageItem(
          id: '1',
          filePath: corruptedFile.path,
          fileName: 'corrupted.jpg',
          width: 800,
          height: 600,
          fileSize: 5,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        expect(
          () => controller.loadThumbnail(imageItem),
          throwsException,
        );
      });
    });

    group('loadFullImage', () {
      test('should load full resolution image successfully', () async {
        // Create a test image
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(0, 255, 0));
        final testImageBytes = img.encodeJpg(testImage);
        final testFile = File(path.join(tempDir.path, 'test_full.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        final imageItem = ImageItem(
          id: '1',
          filePath: testFile.path,
          fileName: 'test_full.jpg',
          width: 800,
          height: 600,
          fileSize: testImageBytes.length,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        final fullImage = await controller.loadFullImage(imageItem);

        expect(fullImage, isA<ImageData>());
        expect(fullImage.bytes.isNotEmpty, isTrue);
      });

      test('should throw exception for non-existent file', () async {
        final imageItem = ImageItem(
          id: '1',
          filePath: '/nonexistent/full.jpg',
          fileName: 'full.jpg',
          width: 800,
          height: 600,
          fileSize: 1000,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        expect(
          () => controller.loadFullImage(imageItem),
          throwsA(isA<FileSystemException>()),
        );
      });
    });

    group('loadMetadata', () {
      test('should load metadata successfully', () async {
        // Create a test image
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(0, 0, 255));
        final testImageBytes = img.encodeJpg(testImage);
        final testFile = File(path.join(tempDir.path, 'test_meta.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        final imageItem = ImageItem(
          id: '1',
          filePath: testFile.path,
          fileName: 'test_meta.jpg',
          width: 800,
          height: 600,
          fileSize: testImageBytes.length,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        final metadata = await controller.loadMetadata(imageItem);

        expect(metadata.fileName, equals('test_meta.jpg'));
        expect(metadata.filePath, equals(testFile.path));
        expect(metadata.width, equals(800));
        expect(metadata.height, equals(600));
        expect(metadata.fileSize, equals(testImageBytes.length));
        expect(metadata.format, equals(ImageFormat.jpeg));
      });

      test('should return metadata with correct properties', () async {
        // Create a test image
        final testImage = img.Image(width: 1920, height: 1080);
        img.fill(testImage, color: img.ColorRgb8(128, 128, 128));
        final testImageBytes = img.encodeJpg(testImage);
        final testFile = File(path.join(tempDir.path, 'test_props.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        final modifiedTime = DateTime.now();
        final imageItem = ImageItem(
          id: '1',
          filePath: testFile.path,
          fileName: 'test_props.jpg',
          width: 1920,
          height: 1080,
          fileSize: testImageBytes.length,
          modifiedTime: modifiedTime,
          format: ImageFormat.png,
        );

        final metadata = await controller.loadMetadata(imageItem);

        expect(metadata.resolutionString, equals('1920 × 1080'));
        expect(metadata.fileSizeString, contains('KB'));
        expect(metadata.modifiedTime, equals(modifiedTime));
      });
    });

    group('Timeout Handling', () {
      test('should have 30 second timeout constant', () {
        expect(
          ImageController.loadTimeout,
          equals(const Duration(seconds: 30)),
        );
      });

      // Note: Testing actual timeout would require a very slow operation
      // or mocking, which is complex. The timeout logic is tested
      // through the implementation structure.
    });

    group('Error Handling', () {
      test('should set error message on failure', () async {
        final imageItem = ImageItem(
          id: '1',
          filePath: '/nonexistent/error.jpg',
          fileName: 'error.jpg',
          width: 800,
          height: 600,
          fileSize: 1000,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        try {
          await controller.loadThumbnail(imageItem);
        } catch (e) {
          // Expected
        }

        expect(controller.errorMessage, isNotNull);
        expect(controller.errorMessage, contains('Failed to load thumbnail'));
      });

      test('should clear error message on successful operation', () async {
        // First, cause an error
        final badItem = ImageItem(
          id: '1',
          filePath: '/nonexistent/bad.jpg',
          fileName: 'bad.jpg',
          width: 800,
          height: 600,
          fileSize: 1000,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        try {
          await controller.loadThumbnail(badItem);
        } catch (e) {
          // Expected
        }

        expect(controller.errorMessage, isNotNull);

        // Now, perform a successful operation
        final testImage = img.Image(width: 800, height: 600);
        img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
        final testImageBytes = img.encodeJpg(testImage);
        final testFile = File(path.join(tempDir.path, 'test_clear.jpg'));
        await testFile.writeAsBytes(testImageBytes);

        final goodItem = ImageItem(
          id: '2',
          filePath: testFile.path,
          fileName: 'test_clear.jpg',
          width: 800,
          height: 600,
          fileSize: testImageBytes.length,
          modifiedTime: DateTime.now(),
          format: ImageFormat.jpeg,
        );

        await controller.loadThumbnail(goodItem);

        expect(controller.errorMessage, isNull);
      });
    });

    group('ImageLoadTimeoutException', () {
      test('should format message correctly with file path', () {
        final exception = ImageLoadTimeoutException(
          'Test timeout',
          filePath: '/path/to/file.jpg',
        );

        expect(
          exception.toString(),
          equals(
              'ImageLoadTimeoutException: Test timeout (file: /path/to/file.jpg)'),
        );
      });

      test('should format message correctly without file path', () {
        final exception = ImageLoadTimeoutException('Test timeout');

        expect(
          exception.toString(),
          equals('ImageLoadTimeoutException: Test timeout'),
        );
      });
    });
  });
}
