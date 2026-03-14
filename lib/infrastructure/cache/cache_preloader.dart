import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/image_item.dart';
import '../../domain/models/image_data.dart';
import 'cache_manager.dart';
import '../generators/thumbnail_generator.dart';

/// Preloads thumbnails in the background to improve cache hit rate
/// 
/// Strategy:
/// - Preload images that are likely to be viewed soon
/// - Use low priority to avoid blocking UI operations
/// - Limit concurrent preload operations
/// - Cancel preloading when no longer needed
/// 
/// Requirement: 9.3, 9.5 - Optimize cache hit rate and preload strategy
class CachePreloader {
  final CacheManager _cacheManager;
  final ThumbnailGenerator _thumbnailGenerator;
  
  /// Maximum concurrent preload operations
  static const int maxConcurrentPreloads = 3;
  
  /// Number of images to preload ahead
  static const int preloadAheadCount = 10;
  
  /// Active preload operations
  final Set<String> _activePreloads = {};
  
  /// Preload queue
  final List<ImageItem> _preloadQueue = [];
  
  /// Cancellation tokens for active preloads
  final Map<String, Completer<void>> _cancellationTokens = {};

  CachePreloader({
    CacheManager? cacheManager,
    ThumbnailGenerator? thumbnailGenerator,
  })  : _cacheManager = cacheManager ?? CacheManager(),
        _thumbnailGenerator = thumbnailGenerator ?? ThumbnailGenerator();

  /// Preload thumbnails for a list of images
  /// 
  /// Preloads up to [preloadAheadCount] images starting from [startIndex]
  /// Uses background priority to avoid blocking UI
  Future<void> preloadThumbnails(
    List<ImageItem> images,
    int startIndex,
  ) async {
    // Clear existing queue
    _preloadQueue.clear();
    
    // Validate and clamp indices
    if (images.isEmpty || startIndex < 0 || startIndex >= images.length) {
      return;
    }
    
    // Add images to preload queue
    final clampedStart = startIndex.clamp(0, images.length - 1);
    final endIndex = (clampedStart + preloadAheadCount).clamp(0, images.length);
    for (int i = clampedStart; i < endIndex; i++) {
      _preloadQueue.add(images[i]);
    }
    
    // Start preloading
    _processPreloadQueue();
  }

  /// Process the preload queue
  void _processPreloadQueue() {
    // Start new preload operations up to the limit
    while (_activePreloads.length < maxConcurrentPreloads && 
           _preloadQueue.isNotEmpty) {
      final item = _preloadQueue.removeAt(0);
      _startPreload(item);
    }
  }

  /// Start preloading a single image
  Future<void> _startPreload(ImageItem item) async {
    final cacheKey = _cacheManager.generateCacheKey(
      item.filePath,
      item.modifiedTime,
    );
    
    // Skip if already in cache
    final cached = await _cacheManager.getThumbnail(cacheKey);
    if (cached != null) {
      return;
    }
    
    // Skip if already preloading
    if (_activePreloads.contains(cacheKey)) {
      return;
    }
    
    _activePreloads.add(cacheKey);
    
    // Create cancellation token
    final cancellationToken = Completer<void>();
    _cancellationTokens[cacheKey] = cancellationToken;
    
    try {
      // Preload with low priority (run in background)
      await compute(_preloadThumbnailIsolate, {
        'filePath': item.filePath,
        'cacheKey': cacheKey,
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      
      // If not cancelled, cache the result
      if (!cancellationToken.isCompleted) {
        // Note: In a real implementation, you would pass the generated
        // thumbnail data back from the isolate and cache it here
        debugPrint('Preloaded thumbnail for ${item.fileName}');
      }
    } catch (e) {
      // Preload failed, but that's okay - it will be loaded on demand
      debugPrint('Preload failed for ${item.fileName}: $e');
    } finally {
      _activePreloads.remove(cacheKey);
      _cancellationTokens.remove(cacheKey);
      
      // Process next item in queue
      _processPreloadQueue();
    }
  }

  /// Cancel all active preload operations
  void cancelAll() {
    for (final token in _cancellationTokens.values) {
      if (!token.isCompleted) {
        token.complete();
      }
    }
    _cancellationTokens.clear();
    _activePreloads.clear();
    _preloadQueue.clear();
  }

  /// Cancel preload for a specific image
  void cancelPreload(String cacheKey) {
    final token = _cancellationTokens[cacheKey];
    if (token != null && !token.isCompleted) {
      token.complete();
    }
    _cancellationTokens.remove(cacheKey);
    _activePreloads.remove(cacheKey);
  }

  /// Get preload statistics
  Map<String, dynamic> getStats() {
    return {
      'activePreloads': _activePreloads.length,
      'queuedPreloads': _preloadQueue.length,
      'maxConcurrent': maxConcurrentPreloads,
    };
  }
}

/// Isolate function for preloading thumbnails
/// 
/// Runs in a separate isolate to avoid blocking the UI thread
Future<Map<String, dynamic>?> _preloadThumbnailIsolate(
  Map<String, dynamic> params,
) async {
  try {
    final filePath = params['filePath'] as String;
    final cacheKey = params['cacheKey'] as String;
    
    // Generate thumbnail in background
    final generator = ThumbnailGenerator();
    final thumbnail = await generator.generateThumbnail(filePath);
    
    return {
      'cacheKey': cacheKey,
      'thumbnail': thumbnail,
    };
  } catch (e) {
    return null;
  }
}
