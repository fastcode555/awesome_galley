/// Cache management module
/// 
/// Provides two-level caching strategy for thumbnails:
/// - L1: Memory cache (LRU, max 100 thumbnails)
/// - L2: Disk cache (max 500MB)
/// - Preloader: Background preloading for improved cache hit rate
library cache;

export 'cache_manager.dart';
export 'cache_preloader.dart';
