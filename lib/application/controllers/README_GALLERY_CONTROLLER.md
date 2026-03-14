# GalleryController Implementation

## Overview

The `GalleryController` class has been successfully implemented as part of task 13.1 of the image-gallery-viewer spec. This controller manages the loading and state of image collections in the application.

## Implementation Details

### Location
- **File**: `lib/application/controllers/gallery_controller.dart`
- **Export**: Added to `lib/application/controllers/controllers.dart`

### Key Features

#### 1. System Browse Mode (Requirements 12.1, 12.2, 12.3)
- `loadSystemImages()` method scans system directories
- Uses `ImageRepository.scanSystemDirectories()` to fetch images
- Implements pagination with 50 images per page
- Publishes updates via Stream

#### 2. Folder Browse Mode (Requirements 13.2, 13.3)
- `loadFolderImages(String folderPath)` method scans specific folder
- Uses `ImageRepository.scanFolder()` to fetch images
- Automatically saves folder to recent folders list
- Implements pagination with 50 images per page

#### 3. Pagination (Requirement 3.4)
- `loadMoreImages()` method loads next page of images
- Page size: 50 images
- Tracks `hasMoreImages` flag for UI
- Prevents duplicate loading with `_isLoading` flag

#### 4. Mode Management
- `setMode(BrowseMode mode)` switches between modes
- Tracks current mode with `_currentMode` property
- Notifies listeners on mode change

#### 5. Stream-based Updates
- Uses `StreamController<List<ImageItem>>` for reactive updates
- `imageStream` getter provides broadcast stream
- Publishes immutable copies of image list

#### 6. Integration
- **ImageRepository**: For scanning and loading images
- **CacheManager**: For thumbnail preloading and cache key generation

### Architecture

```
GalleryController
├── Dependencies
│   ├── ImageRepository (domain layer)
│   └── CacheManager (infrastructure layer)
├── State Management
│   ├── ChangeNotifier (for UI updates)
│   └── StreamController (for reactive image list)
├── Public API
│   ├── loadSystemImages()
│   ├── loadFolderImages(String)
│   ├── loadMoreImages()
│   ├── setMode(BrowseMode)
│   └── imageStream getter
└── Internal Logic
    ├── Pagination (_loadPage)
    ├── Thumbnail preloading (_preloadThumbnails)
    └── State management (_setLoading, _setError)
```

### State Properties

- `_images`: Currently loaded images (paginated)
- `_allImages`: All available images (for pagination)
- `_currentMode`: Current browse mode
- `_currentFolderPath`: Current folder (null in system mode)
- `_isLoading`: Loading state flag
- `_errorMessage`: Error message if loading failed
- `_currentPage`: Current page number (0-indexed)
- `_hasMoreImages`: Flag indicating more images available

### Error Handling

- Catches exceptions during image loading
- Sets error state with descriptive message
- Continues operation after errors (doesn't crash)
- Notifies listeners of error state

### Performance Optimizations

1. **Pagination**: Loads images in chunks of 50 to avoid memory issues
2. **Thumbnail Preloading**: Asynchronously checks cache for upcoming images
3. **Immutable Lists**: Returns unmodifiable copies to prevent external modification
4. **Broadcast Stream**: Allows multiple listeners without duplication

## Usage Example

```dart
// Create controller
final controller = GalleryController(
  repository: imageRepository,
  cacheManager: cacheManager,
);

// Listen to image updates
controller.imageStream.listen((images) {
  print('Loaded ${images.length} images');
});

// Load system images
await controller.loadSystemImages();

// Load more images when scrolling
if (controller.hasMoreImages) {
  await controller.loadMoreImages();
}

// Switch to folder mode
await controller.loadFolderImages('/path/to/folder');

// Clean up
controller.dispose();
```

## Testing Recommendations

### Unit Tests
- Test pagination logic with various image counts
- Test mode switching behavior
- Test error handling for repository failures
- Test stream publishing and disposal

### Integration Tests
- Test with real ImageRepository implementation
- Test cache integration
- Test concurrent loading requests
- Test memory usage with large image sets

### Property Tests (Task 13.2)
- **Property 23**: File association mode folder consistency
- Verify loaded images match folder contents

## Requirements Satisfied

- ✅ **12.1**: System browse mode initialization
- ✅ **12.2**: Scan system directories
- ✅ **12.3**: Display all found images in waterfall
- ✅ **13.2**: Load folder images in file association mode
- ✅ **13.3**: Load images from target file's folder
- ✅ **3.4**: Load more images when scrolling to bottom

## Dependencies

### Direct Dependencies
- `dart:async` - StreamController
- `package:flutter/foundation.dart` - ChangeNotifier, debugPrint
- `../../domain/models/browse_mode.dart` - BrowseMode enum
- `../../domain/models/image_item.dart` - ImageItem model
- `../../domain/repositories/image_repository.dart` - ImageRepository interface
- `../../infrastructure/cache/cache_manager.dart` - CacheManager

### Indirect Dependencies
- ImageRepository implementation (ImageRepositoryImpl)
- FileSystemService (via ImageRepository)
- ThumbnailGenerator (via CacheManager)

## Future Enhancements

1. **Smart Preloading**: Predict scroll direction and preload accordingly
2. **Priority Queue**: Load visible images first, then preload
3. **Memory Management**: Unload images that are far from viewport
4. **Cancellation**: Cancel in-progress loads when switching modes
5. **Progress Tracking**: Report loading progress percentage
6. **Retry Logic**: Automatic retry for failed image loads

## Notes

- The controller uses a page size of 50 images, which balances memory usage and user experience
- Thumbnail preloading is opportunistic - it checks cache but doesn't generate thumbnails
- The controller is designed to be used with Provider or Riverpod for dependency injection
- Stream is broadcast to allow multiple listeners (e.g., UI + analytics)
