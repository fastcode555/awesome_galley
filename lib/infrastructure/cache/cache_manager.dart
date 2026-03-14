import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../domain/models/image_data.dart';

/// Manages thumbnail caching with two-level cache strategy:
/// - L1: Memory cache (LRU, max 100 thumbnails)
/// - L2: Disk cache (max 500MB)
class CacheManager {
  /// Maximum number of thumbnails in memory cache
  static const int maxMemoryCacheSize = 100;

  /// Maximum disk cache size in bytes (500MB)
  static const int maxDiskCacheSize = 500 * 1024 * 1024;

  /// Target disk cache size after cleanup (400MB)
  static const int targetDiskCacheSize = 400 * 1024 * 1024;

  /// Memory cache using LRU strategy
  final _memoryCache = <String, _CacheEntry>{};

  /// Access order for LRU eviction
  final _accessOrder = <String>[];

  /// Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;

  /// Disk cache manager
  final BaseCacheManager _diskCache;

  CacheManager({BaseCacheManager? diskCache})
      : _diskCache = diskCache ?? DefaultCacheManager();

  /// Get thumbnail from cache (memory first, then disk)
  /// Returns null if not found in cache
  Future<ImageData?> getThumbnail(String cacheKey) async {
    // Check memory cache first
    final memoryEntry = _memoryCache[cacheKey];
    if (memoryEntry != null) {
      _cacheHits++;
      _updateAccessOrder(cacheKey);
      return memoryEntry.imageData;
    }

    // Check disk cache
    try {
      final fileInfo = await _diskCache.getFileFromCache(cacheKey);
      if (fileInfo != null && fileInfo.file.existsSync()) {
        final bytes = await fileInfo.file.readAsBytes();
        
        // Parse the cached data (format: width|height|imageBytes)
        final imageData = _deserializeImageData(bytes);
        
        // Promote to memory cache
        _addToMemoryCache(cacheKey, imageData);
        
        _cacheHits++;
        return imageData;
      }
    } catch (e) {
      // Disk cache miss or error, return null
    }

    _cacheMisses++;
    return null;
  }

  /// Cache thumbnail to both memory and disk
  Future<void> cacheThumbnail(String cacheKey, ImageData thumbnail) async {
    // Add to memory cache
    _addToMemoryCache(cacheKey, thumbnail);

    // Add to disk cache
    try {
      final serialized = _serializeImageData(thumbnail);
      await _diskCache.putFile(
        cacheKey,
        serialized,
        maxAge: const Duration(days: 30),
      );
    } catch (e) {
      // Disk cache write failed, but memory cache is still available
      // Log warning but don't throw
    }
  }

  /// Clear old cache entries using LRU strategy
  /// Triggered when cache size exceeds maxDiskCacheSize
  /// Reduces cache to targetDiskCacheSize
  Future<void> clearOldCache() async {
    try {
      final cacheSize = await getCacheSize();
      
      if (cacheSize > maxDiskCacheSize) {
        // Get all cached files sorted by last access time
        final cacheFiles = <FileInfo>[];
        await for (final file in _diskCache.getFileStream(
          '',
          withProgress: false,
        )) {
          if (file is FileInfo) {
            cacheFiles.add(file);
          }
        }

        // Sort by last modified time (oldest first)
        cacheFiles.sort((a, b) {
          final aTime = a.file.lastModifiedSync();
          final bTime = b.file.lastModifiedSync();
          return aTime.compareTo(bTime);
        });

        // Remove oldest files until we reach target size
        int currentSize = cacheSize;
        for (final fileInfo in cacheFiles) {
          if (currentSize <= targetDiskCacheSize) {
            break;
          }

          final fileSize = await fileInfo.file.length();
          await _diskCache.removeFile(fileInfo.originalUrl);
          currentSize -= fileSize;
        }
      }
    } catch (e) {
      // Cache cleanup failed, log but don't throw
    }
  }

  /// Get current cache size in bytes
  Future<int> getCacheSize() async {
    try {
      int totalSize = 0;
      
      await for (final file in _diskCache.getFileStream(
        '',
        withProgress: false,
      )) {
        if (file is FileInfo && file.file.existsSync()) {
          totalSize += await file.file.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Generate cache key based on file path and modified time
  /// Format: MD5(filePath)_timestamp
  String generateCacheKey(String filePath, DateTime modifiedTime) {
    final pathHash = md5.convert(utf8.encode(filePath)).toString();
    final timestamp = modifiedTime.millisecondsSinceEpoch.toString();
    return '${pathHash}_$timestamp';
  }

  /// Add entry to memory cache with LRU eviction
  void _addToMemoryCache(String key, ImageData imageData) {
    // Remove if already exists to update access order
    if (_memoryCache.containsKey(key)) {
      _accessOrder.remove(key);
    }

    // Add to cache
    _memoryCache[key] = _CacheEntry(imageData);
    _accessOrder.add(key);

    // Evict oldest if cache is full
    if (_memoryCache.length > maxMemoryCacheSize) {
      final oldestKey = _accessOrder.removeAt(0);
      _memoryCache.remove(oldestKey);
    }
  }

  /// Update access order for LRU
  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  /// Serialize ImageData for disk storage
  /// Format: 4 bytes width | 4 bytes height | image bytes
  Uint8List _serializeImageData(ImageData imageData) {
    final buffer = BytesBuilder();
    
    // Write width (4 bytes, big endian)
    buffer.add(_intToBytes(imageData.width));
    
    // Write height (4 bytes, big endian)
    buffer.add(_intToBytes(imageData.height));
    
    // Write image bytes
    buffer.add(imageData.bytes);
    
    return buffer.toBytes();
  }

  /// Deserialize ImageData from disk storage
  ImageData _deserializeImageData(Uint8List bytes) {
    // Read width (first 4 bytes)
    final width = _bytesToInt(bytes.sublist(0, 4));
    
    // Read height (next 4 bytes)
    final height = _bytesToInt(bytes.sublist(4, 8));
    
    // Read image bytes (remaining bytes)
    final imageBytes = bytes.sublist(8);
    
    return ImageData(
      bytes: imageBytes,
      width: width,
      height: height,
    );
  }

  /// Convert int to 4 bytes (big endian)
  Uint8List _intToBytes(int value) {
    return Uint8List(4)
      ..buffer.asByteData().setInt32(0, value, Endian.big);
  }

  /// Convert 4 bytes to int (big endian)
  int _bytesToInt(Uint8List bytes) {
    return bytes.buffer.asByteData().getInt32(0, Endian.big);
  }

  /// Clear all caches (for testing or manual cleanup)
  Future<void> clearAll() async {
    _memoryCache.clear();
    _accessOrder.clear();
    await _diskCache.emptyCache();
  }

  /// Get memory cache statistics
  Map<String, dynamic> getMemoryCacheStats() {
    return {
      'size': _memoryCache.length,
      'maxSize': maxMemoryCacheSize,
      'utilizationPercent': (_memoryCache.length / maxMemoryCacheSize * 100).toStringAsFixed(1),
    };
  }

  /// Get cache hit rate statistics
  /// 
  /// Returns cache hit rate as a percentage
  /// Requirement: 9.3 - Optimize cache hit rate
  Map<String, dynamic> getCacheStats() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 
        ? (_cacheHits / totalRequests * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'hits': _cacheHits,
      'misses': _cacheMisses,
      'totalRequests': totalRequests,
      'hitRatePercent': hitRate,
      'memoryCache': getMemoryCacheStats(),
    };
  }

  /// Reset cache statistics
  void resetStats() {
    _cacheHits = 0;
    _cacheMisses = 0;
  }
}

/// Internal cache entry wrapper
class _CacheEntry {
  final ImageData imageData;
  final DateTime cachedAt;

  _CacheEntry(this.imageData) : cachedAt = DateTime.now();
}
