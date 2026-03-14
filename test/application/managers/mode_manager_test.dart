import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_galley/application/managers/mode_manager.dart';
import 'package:awesome_galley/domain/models/browse_mode.dart';

void main() {
  group('ModeManager', () {
    test('should initialize with default systemBrowse mode', () {
      final manager = ModeManager();

      expect(manager.currentMode, BrowseMode.systemBrowse);
      expect(manager.associatedFilePath, isNull);
      expect(manager.isFileAssociationMode(), isFalse);
    });

    test('should initialize with specified mode and file path', () {
      final manager = ModeManager(
        initialMode: BrowseMode.fileAssociation,
        associatedFilePath: '/path/to/image.jpg',
      );

      expect(manager.currentMode, BrowseMode.fileAssociation);
      expect(manager.associatedFilePath, '/path/to/image.jpg');
      expect(manager.isFileAssociationMode(), isTrue);
    });

    group('initializeMode', () {
      test('should enter systemBrowse mode when launchArgs is empty', () {
        final manager = ModeManager();
        manager.initializeMode([]);

        expect(manager.currentMode, BrowseMode.systemBrowse);
        expect(manager.associatedFilePath, isNull);
        expect(manager.isFileAssociationMode(), isFalse);
      });

      test('should enter systemBrowse mode when launchArgs contains only flags',
          () {
        final manager = ModeManager();
        manager.initializeMode(['--verbose', '--debug']);

        expect(manager.currentMode, BrowseMode.systemBrowse);
        expect(manager.associatedFilePath, isNull);
        expect(manager.isFileAssociationMode(), isFalse);
      });

      test('should enter fileAssociation mode when launchArgs contains file path',
          () {
        final manager = ModeManager();
        manager.initializeMode(['/path/to/image.jpg']);

        expect(manager.currentMode, BrowseMode.fileAssociation);
        expect(manager.associatedFilePath, '/path/to/image.jpg');
        expect(manager.isFileAssociationMode(), isTrue);
      });

      test(
          'should use first valid argument as file path when multiple args provided',
          () {
        final manager = ModeManager();
        manager.initializeMode([
          '/path/to/image.jpg',
          '/another/path.png',
        ]);

        expect(manager.currentMode, BrowseMode.fileAssociation);
        expect(manager.associatedFilePath, '/path/to/image.jpg');
      });

      test('should ignore empty strings in launchArgs', () {
        final manager = ModeManager();
        manager.initializeMode(['', '', '/path/to/image.jpg']);

        expect(manager.currentMode, BrowseMode.fileAssociation);
        expect(manager.associatedFilePath, '/path/to/image.jpg');
      });

      test('should ignore flags but use file path when both present', () {
        final manager = ModeManager();
        manager.initializeMode(['--verbose', '/path/to/image.jpg', '--debug']);

        expect(manager.currentMode, BrowseMode.fileAssociation);
        expect(manager.associatedFilePath, '/path/to/image.jpg');
      });

      test('should notify listeners when mode is initialized', () {
        final manager = ModeManager();
        var notified = false;
        manager.addListener(() {
          notified = true;
        });

        manager.initializeMode(['/path/to/image.jpg']);

        expect(notified, isTrue);
      });
    });

    group('switchToSystemBrowse', () {
      test('should switch from fileAssociation to systemBrowse mode', () {
        final manager = ModeManager(
          initialMode: BrowseMode.fileAssociation,
          associatedFilePath: '/path/to/image.jpg',
        );

        manager.switchToSystemBrowse();

        expect(manager.currentMode, BrowseMode.systemBrowse);
        expect(manager.associatedFilePath, isNull);
        expect(manager.isFileAssociationMode(), isFalse);
      });

      test('should do nothing when already in systemBrowse mode', () {
        final manager = ModeManager(initialMode: BrowseMode.systemBrowse);
        var notificationCount = 0;
        manager.addListener(() {
          notificationCount++;
        });

        manager.switchToSystemBrowse();

        expect(manager.currentMode, BrowseMode.systemBrowse);
        expect(notificationCount, 0); // Should not notify if no change
      });

      test('should notify listeners when switching modes', () {
        final manager = ModeManager(
          initialMode: BrowseMode.fileAssociation,
          associatedFilePath: '/path/to/image.jpg',
        );
        var notified = false;
        manager.addListener(() {
          notified = true;
        });

        manager.switchToSystemBrowse();

        expect(notified, isTrue);
      });

      test('should clear associated file path when switching', () {
        final manager = ModeManager(
          initialMode: BrowseMode.fileAssociation,
          associatedFilePath: '/path/to/image.jpg',
        );

        expect(manager.associatedFilePath, isNotNull);

        manager.switchToSystemBrowse();

        expect(manager.associatedFilePath, isNull);
      });
    });

    group('isFileAssociationMode', () {
      test('should return true when in fileAssociation mode', () {
        final manager = ModeManager(initialMode: BrowseMode.fileAssociation);

        expect(manager.isFileAssociationMode(), isTrue);
      });

      test('should return false when in systemBrowse mode', () {
        final manager = ModeManager(initialMode: BrowseMode.systemBrowse);

        expect(manager.isFileAssociationMode(), isFalse);
      });

      test('should return false after switching to systemBrowse', () {
        final manager = ModeManager(initialMode: BrowseMode.fileAssociation);

        expect(manager.isFileAssociationMode(), isTrue);

        manager.switchToSystemBrowse();

        expect(manager.isFileAssociationMode(), isFalse);
      });
    });

    group('edge cases', () {
      test('should handle Windows-style file paths', () {
        final manager = ModeManager();
        manager.initializeMode([r'C:\Users\User\Pictures\image.jpg']);

        expect(manager.currentMode, BrowseMode.fileAssociation);
        expect(manager.associatedFilePath, r'C:\Users\User\Pictures\image.jpg');
      });

      test('should handle paths with spaces', () {
        final manager = ModeManager();
        manager.initializeMode(['/path/to/my image.jpg']);

        expect(manager.currentMode, BrowseMode.fileAssociation);
        expect(manager.associatedFilePath, '/path/to/my image.jpg');
      });

      test('should handle paths with special characters', () {
        final manager = ModeManager();
        manager.initializeMode(['/path/to/图片.jpg']);

        expect(manager.currentMode, BrowseMode.fileAssociation);
        expect(manager.associatedFilePath, '/path/to/图片.jpg');
      });

      test('should handle relative paths', () {
        final manager = ModeManager();
        manager.initializeMode(['./images/photo.jpg']);

        expect(manager.currentMode, BrowseMode.fileAssociation);
        expect(manager.associatedFilePath, './images/photo.jpg');
      });
    });
  });
}
