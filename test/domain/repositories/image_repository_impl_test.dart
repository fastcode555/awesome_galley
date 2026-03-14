import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_galley/domain/repositories/image_repository_impl.dart';
import 'package:awesome_galley/domain/models/file_info.dart';
import 'package:awesome_galley/domain/models/image_format.dart';
import 'package:awesome_galley/infrastructure/services/file_system_service.dart';
import 'package:awesome_galley/infrastructure/repositories/state_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Mock FileSystemService for testing
class MockFileSystemService implements FileSystemService {
  final List<String> mockDirectories;
  final Map<String, List<FileInfo>> mockFiles;

  MockFileSystemService({
    this.mockDirectories = const [],
    this.mockFiles = const {},
  });

  @override
  Future<List<String>> getSystemImageDirectories() async {
    return mockDirectories;
  }

  @override
  Future<List<FileInfo>> listImagesInFolder(String folderPath) async {
    return mockFiles[folderPath] ?? [];
  }

  @override
  Future<bool> fileExists(String filePath) async {
    return true;
  }

  @override
  Future<DateTime> getModifiedTime(String filePath) async {
    return DateTime.now();
  }

  @override
  Future<int> getFileSize(String filePath) async {
    return 1024;
  }
}

void main() {
  // Initialize sqflite_common_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ImageRepositoryImpl', () {
    late ImageRepositoryImpl repository;
    late MockFileSystemService mockFileSystem;
    late StateRepository stateRepository;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Create StateRepository and initialize it with in-memory database
      stateRepository = StateRepository(prefs);
      await stateRepository.initialize(inMemory: true);

      // Create mock file system
      mockFileSystem = MockFileSystemService();

      // Create repository
      repository = ImageRepositoryImpl(
        fileSystemService: mockFileSystem,
        stateRepository: stateRepository,
      );
    });

    tearDown(() async {
      await stateRepository.close();
    });

    test('scanSystemDirectories returns empty list when no directories', () async {
      mockFileSystem = MockFileSystemService(mockDirectories: []);
      repository = ImageRepositoryImpl(
        fileSystemService: mockFileSystem,
        stateRepository: stateRepository,
      );

      final result = await repository.scanSystemDirectories();

      expect(result, isEmpty);
    });

    test('scanFolder returns empty list for empty folder', () async {
      mockFileSystem = MockFileSystemService(
        mockFiles: {'/test/folder': []},
      );
      repository = ImageRepositoryImpl(
        fileSystemService: mockFileSystem,
        stateRepository: stateRepository,
      );

      final result = await repository.scanFolder('/test/folder');

      expect(result, isEmpty);
    });

    test('scanFolder filters and sorts images correctly', () async {
      final now = DateTime.now();
      mockFileSystem = MockFileSystemService(
        mockFiles: {
          '/test/folder': [
            FileInfo(
              path: '/test/folder/zebra.jpg',
              name: 'zebra.jpg',
              size: 1024,
              modifiedTime: now,
              format: ImageFormat.jpeg,
            ),
            FileInfo(
              path: '/test/folder/apple.png',
              name: 'apple.png',
              size: 2048,
              modifiedTime: now,
              format: ImageFormat.png,
            ),
            FileInfo(
              path: '/test/folder/banana.gif',
              name: 'banana.gif',
              size: 512,
              modifiedTime: now,
              format: ImageFormat.gif,
            ),
          ],
        },
      );
      repository = ImageRepositoryImpl(
        fileSystemService: mockFileSystem,
        stateRepository: stateRepository,
      );

      final result = await repository.scanFolder('/test/folder');

      // Should be sorted alphabetically by filename
      expect(result.length, 3);
      expect(result[0].fileName, 'apple.png');
      expect(result[1].fileName, 'banana.gif');
      expect(result[2].fileName, 'zebra.jpg');
    });

    test('saveRecentFolder and getRecentFolders work correctly', () async {
      await repository.saveRecentFolder('/test/folder1', imageCount: 10);
      await repository.saveRecentFolder('/test/folder2', imageCount: 20);

      final recentFolders = await repository.getRecentFolders();

      expect(recentFolders.length, 2);
      expect(recentFolders[0], '/test/folder2'); // Most recent first
      expect(recentFolders[1], '/test/folder1');
    });

    test('scanFolder limits results to 1000 images', () async {
      final now = DateTime.now();
      final manyFiles = List.generate(
        1500,
        (i) => FileInfo(
          path: '/test/folder/image_$i.jpg',
          name: 'image_$i.jpg',
          size: 1024,
          modifiedTime: now,
          format: ImageFormat.jpeg,
        ),
      );

      mockFileSystem = MockFileSystemService(
        mockFiles: {'/test/folder': manyFiles},
      );
      repository = ImageRepositoryImpl(
        fileSystemService: mockFileSystem,
        stateRepository: stateRepository,
      );

      final result = await repository.scanFolder('/test/folder');

      // Should be limited to 1000 images
      expect(result.length, 1000);
    });
  });
}
