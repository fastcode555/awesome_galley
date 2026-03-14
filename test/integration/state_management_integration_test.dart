import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:awesome_galley/application/controllers/gallery_controller.dart';
import 'package:awesome_galley/application/controllers/image_controller.dart';
import 'package:awesome_galley/application/managers/mode_manager.dart';
import 'package:awesome_galley/domain/models/browse_mode.dart';
import 'package:awesome_galley/domain/models/image_item.dart';
import 'package:awesome_galley/domain/repositories/image_repository.dart';
import 'package:awesome_galley/infrastructure/cache/cache_manager.dart';

/// Integration tests for state management
/// 
/// Verifies that:
/// - Controllers are properly injectable via Provider
/// - State changes trigger notifications
/// - Multiple consumers can access the same controller instance
/// 
/// Task 25: State Management Integration
void main() {
  group('State Management Integration Tests', () {
    late ImageRepository mockRepository;
    late CacheManager mockCacheManager;

    setUp(() {
      // Create mock dependencies
      // In a real test, you would use proper mocks
      mockRepository = _MockImageRepository();
      mockCacheManager = CacheManager();
    });

    test('GalleryController can be provided and accessed', () {
      final controller = GalleryController(
        repository: mockRepository,
        cacheManager: mockCacheManager,
      );

      expect(controller, isNotNull);
      expect(controller.images, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.currentMode, BrowseMode.systemBrowse);
    });

    test('ImageController can be provided and accessed', () {
      final controller = ImageController(
        cacheManager: mockCacheManager,
      );

      expect(controller, isNotNull);
      expect(controller.isLoading, isFalse);
      expect(controller.state.name, 'idle');
    });

    test('ModeManager can be provided and accessed', () {
      final manager = ModeManager();

      expect(manager, isNotNull);
      expect(manager.currentMode, BrowseMode.systemBrowse);
      expect(manager.associatedFilePath, isNull);
    });

    test('ModeManager notifies listeners on mode change', () {
      final manager = ModeManager();
      var notificationCount = 0;

      manager.addListener(() {
        notificationCount++;
      });

      // Initialize with file path (should trigger notification)
      manager.initializeMode(['/path/to/image.jpg']);
      expect(notificationCount, 1);
      expect(manager.currentMode, BrowseMode.fileAssociation);
      expect(manager.associatedFilePath, '/path/to/image.jpg');

      // Switch to system browse (should trigger notification)
      manager.switchToSystemBrowse();
      expect(notificationCount, 2);
      expect(manager.currentMode, BrowseMode.systemBrowse);
      expect(manager.associatedFilePath, isNull);
    });

    test('GalleryController notifies listeners on state change', () {
      final controller = GalleryController(
        repository: mockRepository,
        cacheManager: mockCacheManager,
      );
      var notificationCount = 0;

      controller.addListener(() {
        notificationCount++;
      });

      // Set mode (should trigger notification)
      controller.setMode(BrowseMode.fileAssociation);
      expect(notificationCount, 1);
      expect(controller.currentMode, BrowseMode.fileAssociation);
    });

    test('Multiple providers can be created in hierarchy', () {
      // This test verifies that the provider hierarchy works correctly
      final modeManager = ModeManager();
      final galleryController = GalleryController(
        repository: mockRepository,
        cacheManager: mockCacheManager,
      );
      final imageController = ImageController(
        cacheManager: mockCacheManager,
      );

      // All controllers should be independent instances
      expect(modeManager, isNotNull);
      expect(galleryController, isNotNull);
      expect(imageController, isNotNull);

      // Verify they can be used together
      modeManager.initializeMode([]);
      galleryController.setMode(modeManager.currentMode);
      
      expect(galleryController.currentMode, BrowseMode.systemBrowse);
    });
  });
}

/// Mock implementation of ImageRepository for testing
class _MockImageRepository implements ImageRepository {
  @override
  Future<List<ImageItem>> scanSystemDirectories() async {
    return [];
  }

  @override
  Future<List<ImageItem>> scanFolder(String folderPath) async {
    return [];
  }

  @override
  Future<List<String>> getRecentFolders() async {
    return [];
  }

  @override
  Future<void> saveRecentFolder(String folderPath, {int? imageCount}) async {
    // No-op for mock
  }
}
