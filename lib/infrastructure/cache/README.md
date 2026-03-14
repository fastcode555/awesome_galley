# Cache Module

## Overview

The Cache module provides a two-level caching strategy for thumbnail images in the Image Gallery Viewer application.

## Architecture

### Two-Level Cache Strategy

1. **L1: Memory Cache**
   - Type: LRU (Least Recently Used)
   - Capacity: 100 thumbnails maximum
   - Purpose: Fast access to recently viewed images
   - Eviction: Automatic LRU eviction when capacity is exceeded

2. **L2: Disk Cache**
   - Type: Persistent file-based cache
   - Capacity: 500MB maximum
   - Implementation: flutter_cache_manager
   - Purpose: Long-term storage of thumbnails
   - Cleanup: Reduces to 400MB when 500MB limit is exceeded

## Components

### CacheManager

Main class that manages both memory and disk caching.

#### Key Methods

- `getThumbnail(String cacheKey)`: Retrieves thumbnail from cache (memory first, then disk)
- `cacheThumbnail(String cacheKey, ImageData thumbnail)`: Stores thumbnail in both caches
- `clearOldCache()`: Removes old cache entries using LRU strategy
- `getCacheSize()`: Returns current disk cache size in bytes
- `generateCacheKey(String filePath, DateTime modifiedTime)`: Generates MD5-based cache key
- `getMemoryCacheStats()`: Returns memory cache statistics

#### Cache Key Format

Cache keys are generated using the format: `MD5(filePath)_timestamp`

Example: `a1b2c3d4e5f6...789_1704110400000`

This ensures:
- Unique keys for different files
- Cache invalidation when files are modified
- Collision-free storage

## Usage

```dart
import 'package:awesome_galley/infrastructure/cache/cache.dart';
import 'package:awesome_galley/domain/models/image_data.dart';

// Create cache manager
final cacheManager = CacheManager();

// Generate cache key
final cacheKey = cacheManager.generateCacheKey(
  '/path/to/image.jpg',
  DateTime(2024, 1, 1),
);

// Cache a thumbnail
final thumbnail = ImageData(
  bytes: thumbnailBytes,
  width: 400,
  height: 300,
);
await cacheManager.cacheThumbnail(cacheKey, thumbnail);

// Retrieve from cache
final cached = await cacheManager.getThumbnail(cacheKey);
if (cached != null) {
  // Use cached thumbnail
}

// Get cache statistics
final stats = cacheManager.getMemoryCacheStats();
print('Memory cache: ${stats['size']}/${stats['maxSize']}');
print('Utilization: ${stats['utilizationPercent']}%');

// Clear old cache entries
await cacheManager.clearOldCache();

// Clear all caches
await cacheManager.clearAll();
```

## Performance Characteristics

### Memory Cache
- Access time: O(1) for lookup
- Insertion time: O(1) amortized
- Space complexity: O(n) where n ≤ 100

### Disk Cache
- Access time: O(1) for lookup + file I/O
- Insertion time: O(1) + file I/O
- Space complexity: O(m) where m ≤ 500MB

## Error Handling

The CacheManager is designed to be resilient:

- **Disk cache failures**: Silently caught, memory cache continues to work
- **Memory cache full**: Automatic LRU eviction
- **Invalid cache keys**: Returns null
- **Corrupted cache files**: Skipped during retrieval

## Requirements Satisfied

This implementation satisfies the following requirements from the design document:

- **Requirement 4.4**: Caching thumbnails to local storage
- **Requirement 4.5**: Reading thumbnails from cache on subsequent loads
- **Requirement 4.6**: Deleting least recently used cache items when exceeding 500MB

## Testing

Unit tests are provided in `test/infrastructure/cache/cache_manager_test.dart`.

Note: Disk cache tests require platform plugins and are best run as integration tests. Unit tests focus on memory cache functionality and cache key generation.

## Dependencies

- `crypto`: For MD5 hash generation
- `flutter_cache_manager`: For disk cache management
- `dart:typed_data`: For binary data handling

## Future Enhancements

Potential improvements for future versions:

1. Configurable cache sizes
2. Cache warming strategies
3. Prefetching based on scroll position
4. Cache compression
5. Cache analytics and monitoring
