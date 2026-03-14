import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:awesome_galley/infrastructure/repositories/repositories.dart';

void main() {
  // Initialize sqflite_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('StateRepository', () {
    late StateRepository repository;
    late SharedPreferences prefs;

    setUp(() async {
      // Initialize SharedPreferences with empty values
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      
      // Create repository and initialize database with in-memory database
      repository = StateRepository(prefs);
      await repository.initialize(inMemory: true);
    });

    tearDown(() async {
      await repository.close();
    });

    group('SharedPreferences - Scroll Position', () {
      test('should save and retrieve scroll position', () async {
        const position = 123.45;
        
        await repository.saveScrollPosition(position);
        final retrieved = await repository.getScrollPosition();
        
        expect(retrieved, equals(position));
      });

      test('should return null when no scroll position is saved', () async {
        final retrieved = await repository.getScrollPosition();
        
        expect(retrieved, isNull);
      });

      test('should overwrite previous scroll position', () async {
        await repository.saveScrollPosition(100.0);
        await repository.saveScrollPosition(200.0);
        
        final retrieved = await repository.getScrollPosition();
        
        expect(retrieved, equals(200.0));
      });
    });

    group('SharedPreferences - Current Folder', () {
      test('should save and retrieve current folder path', () async {
        const folderPath = '/home/user/Pictures';
        
        await repository.saveCurrentFolder(folderPath);
        final retrieved = await repository.getCurrentFolder();
        
        expect(retrieved, equals(folderPath));
      });

      test('should return null when no current folder is saved', () async {
        final retrieved = await repository.getCurrentFolder();
        
        expect(retrieved, isNull);
      });

      test('should overwrite previous current folder', () async {
        await repository.saveCurrentFolder('/path/one');
        await repository.saveCurrentFolder('/path/two');
        
        final retrieved = await repository.getCurrentFolder();
        
        expect(retrieved, equals('/path/two'));
      });
    });

    group('SQLite - Recent Folders', () {
      test('should add and retrieve a recent folder', () async {
        const folderPath = '/home/user/Pictures';
        const imageCount = 42;
        
        await repository.addRecentFolder(folderPath, imageCount: imageCount);
        final folders = await repository.getRecentFolders();
        
        expect(folders.length, equals(1));
        expect(folders[0].folderPath, equals(folderPath));
        expect(folders[0].imageCount, equals(imageCount));
      });

      test('should maintain maximum of 10 recent folders', () async {
        // Add 15 folders
        for (int i = 0; i < 15; i++) {
          await repository.addRecentFolder('/path/folder$i');
          // Small delay to ensure different timestamps
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        final folders = await repository.getRecentFolders();
        
        // Should only have 10 folders
        expect(folders.length, equals(10));
        
        // Should have the 10 most recent folders (folder5 through folder14)
        expect(folders[0].folderPath, equals('/path/folder14'));
        expect(folders[9].folderPath, equals('/path/folder5'));
      });

      test('should order folders by last visited (most recent first)', () async {
        await repository.addRecentFolder('/path/first');
        await Future.delayed(const Duration(milliseconds: 10));
        await repository.addRecentFolder('/path/second');
        await Future.delayed(const Duration(milliseconds: 10));
        await repository.addRecentFolder('/path/third');
        
        final folders = await repository.getRecentFolders();
        
        expect(folders[0].folderPath, equals('/path/third'));
        expect(folders[1].folderPath, equals('/path/second'));
        expect(folders[2].folderPath, equals('/path/first'));
      });

      test('should update last visited time when adding existing folder', () async {
        await repository.addRecentFolder('/path/folder', imageCount: 10);
        await Future.delayed(const Duration(milliseconds: 10));
        
        final firstVisit = (await repository.getRecentFolders())[0].lastVisited;
        
        await Future.delayed(const Duration(milliseconds: 10));
        await repository.addRecentFolder('/path/folder', imageCount: 20);
        
        final folders = await repository.getRecentFolders();
        
        expect(folders.length, equals(1));
        expect(folders[0].folderPath, equals('/path/folder'));
        expect(folders[0].imageCount, equals(20));
        expect(folders[0].lastVisited.isAfter(firstVisit), isTrue);
      });

      test('should return empty list when no recent folders exist', () async {
        final folders = await repository.getRecentFolders();
        
        expect(folders, isEmpty);
      });

      test('should throw StateError when database not initialized', () async {
        final uninitializedRepo = StateRepository(prefs);
        
        expect(
          () => uninitializedRepo.addRecentFolder('/path'),
          throwsStateError,
        );
        
        expect(
          () => uninitializedRepo.getRecentFolders(),
          throwsStateError,
        );
      });
    });

    group('RecentFolder Model', () {
      test('should create from map correctly', () {
        final map = {
          'id': 1,
          'folder_path': '/test/path',
          'last_visited': 1234567890000,
          'image_count': 42,
        };
        
        final folder = RecentFolder.fromMap(map);
        
        expect(folder.id, equals(1));
        expect(folder.folderPath, equals('/test/path'));
        expect(folder.lastVisited.millisecondsSinceEpoch, equals(1234567890000));
        expect(folder.imageCount, equals(42));
      });

      test('should convert to map correctly', () {
        final folder = RecentFolder(
          id: 1,
          folderPath: '/test/path',
          lastVisited: DateTime.fromMillisecondsSinceEpoch(1234567890000),
          imageCount: 42,
        );
        
        final map = folder.toMap();
        
        expect(map['id'], equals(1));
        expect(map['folder_path'], equals('/test/path'));
        expect(map['last_visited'], equals(1234567890000));
        expect(map['image_count'], equals(42));
      });

      test('should handle null image count', () {
        final map = {
          'id': 1,
          'folder_path': '/test/path',
          'last_visited': 1234567890000,
          'image_count': null,
        };
        
        final folder = RecentFolder.fromMap(map);
        
        expect(folder.imageCount, isNull);
      });
    });
  });
}
