import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/browse_mode.dart';
import '../../domain/models/image_item.dart';
import '../../domain/repositories/image_repository.dart';
import '../../infrastructure/cache/cache_manager.dart';
import '../../infrastructure/generators/thumbnail_generator.dart';

/// Controller for managing the gallery's image collection and state
///
/// Responsibilities:
/// - Load images in system browse mode (scan system directories)
/// - Load images in folder browse mode (scan specific folder)
/// - Implement pagination for loading more images
/// - Switch between browse modes
/// - Publish image list updates via Stream
/// - Integrate with ImageRepository and CacheManager
///
/// Uses ChangeNotifier for state management and StreamController for
/// reactive image list updates.
class GalleryController extends ChangeNotifier {
  final ImageRepository _repository;
  final CacheManager _cacheManager;

  /// Stream controller for publishing image list updates
  final _imageStreamController = StreamController<List<ImageItem>>.broadcast();

  /// Current list of loaded images
  List<ImageItem> _images = [];

  /// Current browse mode
  BrowseMode _currentMode = BrowseMode.systemBrowse;

  /// Current folder path (for folder browse mode)
  String? _currentFolderPath;

  /// Loading state flag
  bool _isLoading = false;

  /// Error message if loading failed
  String? _errorMessage;

  /// Pagination state
  int _currentPage = 0;
  static const int _pageSize = 50;
  bool _hasMoreImages = true;

  /// All available images (for pagination)
  List<ImageItem> _allImages = [];

  GalleryController({
    required ImageRepository repository,
    required CacheManager cacheManager,
  })  : _repository = repository,
        _cacheManager = cacheManager;

  /// Get stream of image list updates
  Stream<List<ImageItem>> get imageStream => _imageStreamController.stream;

  /// Get current browse mode
  BrowseMode get currentMode => _currentMode;

  /// Get current folder path (null if in system browse mode)
  String? get currentFolderPath => _currentFolderPath;

  /// Check if currently loading
  bool get isLoading => _isLoading;

  /// Get error message (null if no error)
  String? get errorMessage => _errorMessage;

  /// Check if more images are available for pagination
  bool get hasMoreImages => _hasMoreImages;

  /// Get current list of loaded images
  List<ImageItem> get images => List.unmodifiable(_images);

  /// Load images in system browse mode
  ///
  /// Scans system directories (Pictures, Desktop, Downloads, etc.)
  /// Loads images in pages of 50 items
  /// Publishes updates via imageStream
  ///
  /// Requirements: 12.1, 12.2, 12.3
  Future<void> loadSystemImages() async {
    if (_isLoading) return;

    print('[GalleryController] Loading system images...');
    _setLoading(true);
    _currentMode = BrowseMode.systemBrowse;
    _currentFolderPath = null;
    _currentPage = 0;
    _images = [];
    _allImages = [];
    _hasMoreImages = true;

    try {
      // Scan system directories
      print('[GalleryController] Scanning system directories...');
      _allImages = await _repository.scanSystemDirectories();
      print('[GalleryController] Found ${_allImages.length} images');

      // Load first page
      _loadPage();

      _setLoading(false);
      _publishImages();
      print('[GalleryController] Published ${_images.length} images');
    } catch (e) {
      print('[GalleryController] Error loading system images: $e');
      _setError('Failed to load system images: $e');
      _setLoading(false);
    }
  }

  /// Load images from a specific folder
  ///
  /// Scans the specified folder for supported image formats
  /// Loads images in pages of 50 items
  /// Publishes updates via imageStream
  ///
  /// [folderPath] Path to the folder to scan
  ///
  /// Requirements: 13.2, 13.3
  Future<void> loadFolderImages(String folderPath) async {
    if (_isLoading) return;

    _setLoading(true);
    _currentMode = BrowseMode.fileAssociation;
    _currentFolderPath = folderPath;
    _currentPage = 0;
    _images = [];
    _allImages = [];
    _hasMoreImages = true;

    try {
      // Scan folder
      _allImages = await _repository.scanFolder(folderPath);

      // Save to recent folders
      await _repository.saveRecentFolder(
        folderPath,
        imageCount: _allImages.length,
      );

      // Load first page
      _loadPage();

      _setLoading(false);
      _publishImages();
    } catch (e) {
      _setError('Failed to load folder images: $e');
      _setLoading(false);
    }
  }

  /// Load more images (pagination)
  ///
  /// Loads the next page of images from the current collection
  /// Called when user scrolls to the bottom of the waterfall view
  ///
  /// Requirement: 3.4
  Future<void> loadMoreImages() async {
    if (_isLoading || !_hasMoreImages) return;

    _setLoading(true);

    try {
      // Load next page
      _currentPage++;
      _loadPage();

      _setLoading(false);
      _publishImages();
    } catch (e) {
      _setError('Failed to load more images: $e');
      _setLoading(false);
    }
  }

  /// Set the browse mode
  ///
  /// Switches between system browse and folder browse modes
  /// Does not reload images - use loadSystemImages() or loadFolderImages()
  /// to actually load images in the new mode
  ///
  /// [mode] The browse mode to set
  void setMode(BrowseMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }

  /// Load a page of images from the all images list
  void _loadPage() {
    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, _allImages.length);

    if (startIndex >= _allImages.length) {
      _hasMoreImages = false;
      return;
    }

    // Add page to loaded images
    final pageImages = _allImages.sublist(startIndex, endIndex);
    _images.addAll(pageImages);

    // Check if more images are available
    _hasMoreImages = endIndex < _allImages.length;

    // Preload thumbnails for the current page in the background
    _preloadThumbnails(pageImages);
  }

  /// Preload thumbnails for a list of images in the background
  ///
  /// This improves perceived performance by caching thumbnails
  /// before they are actually displayed.
  /// 
  /// Implements thumbnail-first loading strategy:
  /// - Prioritizes images that are likely to be viewed soon
  /// - Loads in batches to avoid overwhelming the system
  /// 
  /// Requirement: 9.2, 9.3 - Optimize cache hit rate and loading performance
  void _preloadThumbnails(List<ImageItem> items) {
    // Run preloading asynchronously without blocking
    Future.microtask(() async {
      // Process in batches of 5 to avoid overwhelming the system
      const batchSize = 5;
      
      for (int i = 0; i < items.length; i += batchSize) {
        final batch = items.skip(i).take(batchSize).toList();
        
        // Preload batch in parallel
        await Future.wait(
          batch.map((item) => _preloadSingleThumbnail(item)),
          eagerError: false, // Continue even if some fail
        );
        
        // Small delay between batches to avoid blocking UI
        await Future.delayed(const Duration(milliseconds: 50));
      }
    });
  }

  /// Preload a single thumbnail
  Future<void> _preloadSingleThumbnail(ImageItem item) async {
    try {
      final cacheKey = _cacheManager.generateCacheKey(
        item.filePath,
        item.modifiedTime,
      );

      // Check if already cached
      final cached = await _cacheManager.getThumbnail(cacheKey);
      if (cached != null) {
        return; // Already cached
      }

      // Generate and cache thumbnail
      final thumbnail = await ThumbnailGenerator().generateThumbnail(item.filePath);
      await _cacheManager.cacheThumbnail(cacheKey, thumbnail);
    } catch (e) {
      // Preload failed for this item, continue with others
      debugPrint('Thumbnail preload failed for ${item.fileName}: $e');
    }
  }

  /// Publish current image list to stream
  void _publishImages() {
    if (!_imageStreamController.isClosed) {
      _imageStreamController.add(List.unmodifiable(_images));
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Set error state with message
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  /// Reset controller state
  void reset() {
    _images = [];
    _allImages = [];
    _currentPage = 0;
    _hasMoreImages = true;
    _currentMode = BrowseMode.systemBrowse;
    _currentFolderPath = null;
    _isLoading = false;
    _errorMessage = null;
    _publishImages();
    notifyListeners();
  }

  @override
  void dispose() {
    _imageStreamController.close();
    super.dispose();
  }
}
