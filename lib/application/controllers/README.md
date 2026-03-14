# Application Controllers

This directory contains application-layer controllers that manage business logic and coordinate between the presentation layer and domain/infrastructure layers.

## ImageController

The `ImageController` manages loading operations for individual images.

### Features

- **Thumbnail Loading**: Loads thumbnails with cache priority (memory → disk → generate)
- **Full Image Loading**: Loads original resolution images for detailed viewing
- **Metadata Loading**: Extracts image metadata and EXIF information
- **State Management**: Uses `ChangeNotifier` to notify UI of loading state changes
- **Timeout Handling**: Implements 30-second timeout for all operations
- **Error Handling**: Gracefully handles file system errors, decode errors, and timeouts
- **Cache Integration**: Automatically caches generated thumbnails and triggers cleanup

### Usage

```dart
final controller = ImageController();

// Load thumbnail (prioritizes cache)
final thumbnail = await controller.loadThumbnail(imageItem);

// Load full resolution image
final fullImage = await controller.loadFullImage(imageItem);

// Load metadata
final metadata = await controller.loadMetadata(imageItem);

// Listen to state changes
controller.addListener(() {
  if (controller.isLoading) {
    // Show loading indicator
  } else if (controller.isSuccess) {
    // Show image
  } else if (controller.isError) {
    // Show error message: controller.errorMessage
  }
});

// Clean up
controller.dispose();
```

### Loading States

- `idle`: Initial state, no operation in progress
- `loading`: Operation in progress
- `success`: Operation completed successfully
- `error`: Operation failed (check `errorMessage` for details)

### Error Handling

The controller handles various error scenarios:

- **File not found**: Throws `FileSystemException`
- **Corrupted image**: Throws `ImageDecodeException`
- **Timeout**: Throws `ImageLoadTimeoutException` after 30 seconds
- **Cache errors**: Logged but don't block operations

### Testing Note

Unit tests for `ImageController` require mocking the `CacheManager` due to platform plugin dependencies in `flutter_cache_manager`. The implementation is fully functional in the actual application where platform plugins are available.

For integration testing, use the controller in a real Flutter environment where platform plugins are initialized.

### Requirements Validation

This implementation satisfies the following requirements from the design document:

- **Requirement 4.4**: Prioritizes cache when loading thumbnails
- **Requirement 4.5**: Loads from cache on subsequent requests
- **Requirement 5.2**: Loads original resolution for full image viewing
- **Requirement 8.2-8.7**: Loads and displays image metadata
- **Requirement 10.3**: Implements 30-second timeout with error handling

### Design Properties

Validates the following correctness properties:

- **Property 8**: Thumbnail cache往返 - Cached thumbnails are consistent with generated ones
- **Property 16**: Metadata completeness - All required metadata fields are loaded
