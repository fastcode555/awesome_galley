import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_galley/infrastructure/cache/cache_manager.dart' as app_cache;
import 'package:awesome_galley/domain/models/image_data.dart';

void main() {
  // Initialize Flutter bindings for platform channel tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheManager', () {
    late app_cache.CacheManager cacheManager;

    setUp(() {
      cacheManager = app_cache.CacheManager();
    });

    tearDown(() async {
      await cacheManager.clearAll();
    });

    group('generateCacheKey', () {
      test('should generate consistent cache key for same input', () {
        final filePath = '/test/image.jpg';
        final modifiedTime = DateTime(2024, 1, 1, 12, 0, 0);

        final key1 = cacheManager.generateCacheKey(filePath, modifiedTime);
        final key2 = cacheManager.generateCacheKey(filePath, modifiedTime);

        expect(key1, equals(key2));
      });

      test('should generate different keys for different file paths', () {
        final modifiedTime = DateTime(2024, 1, 1, 12, 0, 0);

        final key1 = cacheManager.generateCacheKey('/test/image1.jpg', modifiedTime);
        final key2 = cacheManager.generateCacheKey('/test/image2.jpg', modifiedTime);

        expect(key1, isNot(equals(key2)));
      });

      test('should generate different keys for different modified times', () {
        final filePath = '/test/image.jpg';

        final key1 = cacheManager.generateCacheKey(
          filePath,
          DateTime(2024, 1, 1, 12, 0, 0),
        );
        final key2 = cacheManager.generateCacheKey(
          filePath,
          DateTime(2024, 1, 2, 12, 0, 0),
        );

        expect(key1, isNot(equals(key2)));
      });

      test('should include MD5 hash and timestamp in key format', () {
        final filePath = '/test/image.jpg';
        final modifiedTime = DateTime(2024, 1, 1, 12, 0, 0);

        final key = cacheManager.generateCacheKey(filePath, modifiedTime);

        // Key format: MD5_timestamp
        expect(key, contains('_'));
        final parts = key.split('_');
        expect(parts.length, equals(2));
        expect(parts[0].length, equals(32)); // MD5 hash length
        expect(int.tryParse(parts[1]), isNotNull); // timestamp is numeric
      });
    });

    group('Memory Cache', () {
      test('should cache thumbnail in memory', () async {
        final imageData = ImageData(
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          width: 100,
          height: 100,
        );
        final cacheKey = 'test_key_1';

        await cacheManager.cacheThumbnail(cacheKey, imageData);
        final cached = await cacheManager.getThumbnail(cacheKey);

        expect(cached, isNotNull);
        expect(cached!.width, equals(100));
        expect(cached.height, equals(100));
        expect(cached.bytes, equals(imageData.bytes));
      });

      test('should return null for non-existent cache key', () async {
        final cached = await cacheManager.getThumbnail('non_existent_key');
        expect(cached, isNull);
      });

      test('should implement LRU eviction when exceeding max size', () async {
        // Add 101 items (max is 100)
        for (int i = 0; i < 101; i++) {
          final imageData = ImageData(
            bytes: Uint8List.fromList([i]),
            width: 100,
            height: 100,
          );
          await cacheManager.cacheThumbnail('key_$i', imageData);
        }

        // First item should be evicted
        final firstItem = await cacheManager.getThumbnail('key_0');
        expect(firstItem, isNull);

        // Last item should still be in cache
        final lastItem = await cacheManager.getThumbnail('key_100');
        expect(lastItem, isNotNull);

        // Check cache stats
        final stats = cacheManager.getMemoryCacheStats();
        expect(stats['size'], equals(100));
      });

      test('should update access order when accessing cached item', () async {
        // Add 100 items
        for (int i = 0; i < 100; i++) {
          final imageData = ImageData(
            bytes: Uint8List.fromList([i]),
            width: 100,
            height: 100,
          );
          await cacheManager.cacheThumbnail('key_$i', imageData);
        }

        // Access the first item to move it to the end
        await cacheManager.getThumbnail('key_0');

        // Add one more item (should evict key_1, not key_0)
        final newImageData = ImageData(
          bytes: Uint8List.fromList([255]),
          width: 100,
          height: 100,
        );
        await cacheManager.cacheThumbnail('key_new', newImageData);

        // key_0 should still be in cache (recently accessed)
        final key0 = await cacheManager.getThumbnail('key_0');
        expect(key0, isNotNull);

        // key_1 should be evicted (oldest unaccessed)
        final key1 = await cacheManager.getThumbnail('key_1');
        expect(key1, isNull);
      });
    });

    group('Cache Statistics', () {
      test('should report correct memory cache statistics', () async {
        // Add 50 items
        for (int i = 0; i < 50; i++) {
          final imageData = ImageData(
            bytes: Uint8List.fromList([i]),
            width: 100,
            height: 100,
          );
          await cacheManager.cacheThumbnail('key_$i', imageData);
        }

        final stats = cacheManager.getMemoryCacheStats();
        expect(stats['size'], equals(50));
        expect(stats['maxSize'], equals(100));
        expect(stats['utilizationPercent'], equals('50.0'));
      });

      test('should report 100% utilization when cache is full', () async {
        // Fill cache to max
        for (int i = 0; i < 100; i++) {
          final imageData = ImageData(
            bytes: Uint8List.fromList([i]),
            width: 100,
            height: 100,
          );
          await cacheManager.cacheThumbnail('key_$i', imageData);
        }

        final stats = cacheManager.getMemoryCacheStats();
        expect(stats['size'], equals(100));
        expect(stats['utilizationPercent'], equals('100.0'));
      });
    });

    group('Clear Operations', () {
      test('should clear all caches', () async {
        // Add items to memory cache
        for (int i = 0; i < 10; i++) {
          final imageData = ImageData(
            bytes: Uint8List.fromList([i]),
            width: 100,
            height: 100,
          );
          await cacheManager.cacheThumbnail('key_$i', imageData);
        }

        await cacheManager.clearAll();

        // All items should be gone
        for (int i = 0; i < 10; i++) {
          final cached = await cacheManager.getThumbnail('key_$i');
          expect(cached, isNull);
        }

        // Cache stats should show empty
        final stats = cacheManager.getMemoryCacheStats();
        expect(stats['size'], equals(0));
      });
    });

    group('Edge Cases', () {
      test('should handle empty image data', () async {
        final emptyData = ImageData(
          bytes: Uint8List(0),
          width: 0,
          height: 0,
        );

        final cacheKey = 'empty_test';
        await cacheManager.cacheThumbnail(cacheKey, emptyData);

        final retrieved = await cacheManager.getThumbnail(cacheKey);

        expect(retrieved, isNotNull);
        expect(retrieved!.width, equals(0));
        expect(retrieved.height, equals(0));
        expect(retrieved.bytes.length, equals(0));
      });

      test('should handle special characters in cache key', () async {
        final imageData = ImageData(
          bytes: Uint8List.fromList([1, 2, 3]),
          width: 100,
          height: 100,
        );

        final specialPaths = [
          '/path/with spaces/image.jpg',
          '/path/with-dashes/image.jpg',
          '/path/with_underscores/image.jpg',
          '/path/with.dots/image.jpg',
          '/path/with(parentheses)/image.jpg',
        ];

        for (final path in specialPaths) {
          final cacheKey = cacheManager.generateCacheKey(
            path,
            DateTime.now(),
          );
          await cacheManager.cacheThumbnail(cacheKey, imageData);

          final retrieved = await cacheManager.getThumbnail(cacheKey);
          expect(retrieved, isNotNull);
        }
      });

      test('should handle concurrent cache operations', () async {
        final futures = <Future>[];

        // Perform 50 concurrent cache operations
        for (int i = 0; i < 50; i++) {
          final imageData = ImageData(
            bytes: Uint8List.fromList([i]),
            width: 100,
            height: 100,
          );
          futures.add(cacheManager.cacheThumbnail('concurrent_$i', imageData));
        }

        await Future.wait(futures);

        // Verify all items were cached
        int cachedCount = 0;
        for (int i = 0; i < 50; i++) {
          final cached = await cacheManager.getThumbnail('concurrent_$i');
          if (cached != null) {
            cachedCount++;
          }
        }

        expect(cachedCount, equals(50));
      });

      test('should handle large image data', () async {
        // Create a large image (1MB)
        final largeData = ImageData(
          bytes: Uint8List.fromList(List.generate(1024 * 1024, (i) => i % 256)),
          width: 1920,
          height: 1080,
        );

        final cacheKey = 'large_image_test';
        await cacheManager.cacheThumbnail(cacheKey, largeData);

        final retrieved = await cacheManager.getThumbnail(cacheKey);

        expect(retrieved, isNotNull);
        expect(retrieved!.width, equals(1920));
        expect(retrieved.height, equals(1080));
        expect(retrieved.bytes.length, equals(1024 * 1024));
      });

      test('should handle edge case dimensions', () async {
        final testCases = [
          ImageData(bytes: Uint8List.fromList([1]), width: 1, height: 1),
          ImageData(bytes: Uint8List.fromList([1, 2]), width: 10000, height: 10000),
          ImageData(bytes: Uint8List.fromList([1, 2, 3]), width: 1, height: 10000),
          ImageData(bytes: Uint8List.fromList([1, 2, 3, 4]), width: 10000, height: 1),
        ];

        for (int i = 0; i < testCases.length; i++) {
          final cacheKey = 'edge_case_$i';
          await cacheManager.cacheThumbnail(cacheKey, testCases[i]);

          final retrieved = await cacheManager.getThumbnail(cacheKey);

          expect(retrieved, isNotNull);
          expect(retrieved!.width, equals(testCases[i].width));
          expect(retrieved.height, equals(testCases[i].height));
        }
      });
    });
  });
}
