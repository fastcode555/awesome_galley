# Performance Optimization Guide

This document describes the performance optimizations implemented in the Image Gallery Viewer application.

## Overview

The application implements multiple layers of performance optimization to ensure smooth scrolling and fast image loading, maintaining at least 30 FPS during operation.

## Optimization Strategies

### 1. Lazy Loading and Preloading (Task 22.1)

**Requirements**: 9.1, 9.5

#### Lazy Loading
- **Implementation**: `LazyImageLoader` widget with `VisibilityDetector`
- **Strategy**: Only load images when they become visible in the viewport
- **Benefits**: Reduces memory usage and initial load time

**Key Features**:
- Viewport detection with configurable threshold (default 50%)
- Automatic memory release when images scroll out of view
- Delayed cleanup (2 seconds) to avoid thrashing

#### Preloading
- **Implementation**: `CachePreloader` service
- **Strategy**: Preload images that are about to become visible
- **Benefits**: Improves perceived performance and cache hit rate

**Key Features**:
- Preloads up to 10 images ahead of current position
- Limits concurrent preloads to 3 to avoid blocking
- Uses background priority (compute isolates)
- Cancels preloading during active scrolling
- Resumes preloading when scroll ends

#### Memory Management
- Images are released 2 seconds after scrolling out of view
- Memory cache limited to 100 thumbnails (LRU eviction)
- Disk cache limited to 500MB (LRU eviction)

### 2. Scroll Performance Optimization (Task 22.2)

**Requirements**: 9.1

#### RepaintBoundary
- **Implementation**: `OptimizedImageItem` wraps each image with `RepaintBoundary`
- **Strategy**: Isolate repaints to individual images
- **Benefits**: Prevents cascade repaints during scroll

**Usage**:
```dart
RepaintBoundary(
  child: LazyImageLoader(item: item),
)
```

#### Const Constructors
- All stateless widgets use const constructors where possible
- Reduces widget rebuilds during scroll
- Examples: `OptimizedImageItem`, `_WaterfallImageItem`

#### Optimized Scroll Physics
- **Implementation**: `OptimizedScrollPhysics`
- **Strategy**: Reduces friction during fast scrolling
- **Benefits**: Smoother scroll experience

**Features**:
- Reduced friction for velocities > 100 pixels/second
- Optimized fling velocity range (100-5000)
- Minimal bounce effect

#### Scroll Event Optimization
- **Implementation**: `ScrollPerformanceOptimizer`
- **Strategy**: Debounces scroll events and monitors velocity
- **Benefits**: Reduces unnecessary rebuilds

**Features**:
- Detects scroll start/end
- Monitors scroll velocity
- Pauses preloading during active scroll
- Resumes preloading when scroll ends

#### FPS Monitoring
- **Implementation**: `PerformanceMonitor` widget
- **Strategy**: Tracks frame timing and calculates FPS
- **Benefits**: Identifies performance issues in development

**Features**:
- Samples last 60 frames
- Calculates average FPS
- Logs warnings when FPS drops below 30
- Optional overlay display for debugging

### 3. Image Loading Performance (Task 22.3)

**Requirements**: 9.2, 9.3, 9.4, 10.3

#### Thumbnail-First Strategy
- **Implementation**: `ImageController.loadThumbnail()`
- **Strategy**: Always load thumbnails before full images
- **Benefits**: Fast initial display, progressive enhancement

**Cache Priority**:
1. Check memory cache (L1) - ~1ms
2. Check disk cache (L2) - ~10ms
3. Generate thumbnail - ~100-500ms
4. Cache for future use

#### Cache Optimization
- **Implementation**: `CacheManager` with two-level cache
- **Strategy**: LRU eviction with size limits
- **Benefits**: High cache hit rate, controlled memory usage

**Cache Statistics**:
- Tracks cache hits and misses
- Calculates hit rate percentage
- Monitors memory cache utilization
- Available via `getCacheStats()` method

**Cache Cleanup**:
- Triggered when disk cache exceeds 500MB
- Removes oldest files first (LRU)
- Reduces cache to 400MB target
- Runs asynchronously without blocking

#### Timeout and Retry
- **Implementation**: `ImageController._withTimeout()` and `_withRetry()`
- **Strategy**: 30-second timeout with 3 retry attempts
- **Benefits**: Handles slow networks and temporary failures

**Retry Logic**:
- Exponential backoff (500ms, 1s, 2s)
- Maximum 3 attempts
- Throws exception after max retries
- User can manually retry from UI

**Timeout Handling**:
- 30-second timeout for all operations
- Throws `ImageLoadTimeoutException`
- Provides retry option in UI
- Logs timeout events for debugging

## Performance Metrics

### Target Metrics
- **Scroll FPS**: ≥ 30 FPS (Requirement 9.1)
- **Thumbnail Load Time**: ≤ 100ms (cached) (Requirement 9.3)
- **Single Image Open Time**: ≤ 500ms (Requirement 9.2)
- **Scroll Transition Time**: ≤ 300ms (Requirement 9.4)
- **Initial Load Time**: ≤ 2 seconds (Requirement 9.5)

### Cache Performance
- **Memory Cache**: 100 thumbnails max
- **Disk Cache**: 500MB max
- **Target Hit Rate**: ≥ 80%
- **Cleanup Threshold**: 500MB → 400MB

## Usage Examples

### Enable FPS Monitoring (Debug Mode)
```dart
PerformanceMonitor(
  showOverlay: true, // Show FPS overlay
  child: WaterfallView(),
)
```

### Check Cache Statistics
```dart
final cacheManager = CacheManager();
final stats = cacheManager.getCacheStats();
print('Cache hit rate: ${stats['hitRatePercent']}%');
print('Total requests: ${stats['totalRequests']}');
```

### Manual Cache Cleanup
```dart
final cacheManager = CacheManager();
await cacheManager.clearOldCache();
```

### Preload Images Manually
```dart
final preloader = CachePreloader();
await preloader.preloadThumbnails(images, startIndex: 0);
```

## Best Practices

### For Developers

1. **Always use const constructors** for stateless widgets
2. **Wrap expensive widgets** with `RepaintBoundary`
3. **Monitor FPS** during development with `PerformanceMonitor`
4. **Test with large datasets** (1000+ images)
5. **Profile memory usage** regularly

### For Performance Testing

1. **Test scroll performance** with FPS monitoring enabled
2. **Measure cache hit rate** after typical usage
3. **Test timeout handling** with slow network simulation
4. **Verify memory cleanup** after extended scrolling
5. **Test on low-end devices** to ensure 30 FPS minimum

## Troubleshooting

### Low FPS During Scroll
- Check if RepaintBoundary is applied to image items
- Verify const constructors are used
- Monitor memory usage (may need cleanup)
- Reduce preload count if device is slow

### High Memory Usage
- Check memory cache size (should be ≤ 100 items)
- Verify images are released when scrolled out
- Trigger manual cache cleanup if needed
- Reduce preload ahead count

### Low Cache Hit Rate
- Increase memory cache size (if memory allows)
- Increase preload ahead count
- Check if cache cleanup is too aggressive
- Verify cache keys are consistent

### Slow Image Loading
- Check network connection (for remote images)
- Verify thumbnail generation is working
- Check disk cache is not full
- Monitor timeout/retry statistics

## Future Optimizations

Potential areas for further optimization:

1. **Progressive JPEG loading** - Load images progressively
2. **WebP format support** - Smaller file sizes
3. **GPU acceleration** - Use shaders for image processing
4. **Adaptive quality** - Reduce quality during fast scroll
5. **Predictive preloading** - ML-based preload prediction
6. **Background cache warming** - Preload during idle time
7. **Image format conversion** - Convert to optimal format on cache

## References

- Flutter Performance Best Practices: https://flutter.dev/docs/perf/best-practices
- Image Caching Strategies: https://flutter.dev/docs/cookbook/images/cached-images
- Scroll Performance: https://flutter.dev/docs/perf/rendering-performance
