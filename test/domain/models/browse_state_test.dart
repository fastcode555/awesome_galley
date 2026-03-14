import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_galley/domain/models/models.dart';

void main() {
  group('BrowseMode', () {
    test('should have systemBrowse value', () {
      expect(BrowseMode.systemBrowse, isNotNull);
    });

    test('should have fileAssociation value', () {
      expect(BrowseMode.fileAssociation, isNotNull);
    });
  });

  group('BrowseState', () {
    test('should create with required mode', () {
      const state = BrowseState(mode: BrowseMode.systemBrowse);
      
      expect(state.mode, BrowseMode.systemBrowse);
      expect(state.currentFolderPath, isNull);
      expect(state.scrollPosition, 0.0);
      expect(state.currentImagePath, isNull);
    });

    test('should create with all fields', () {
      const state = BrowseState(
        mode: BrowseMode.fileAssociation,
        currentFolderPath: '/test/folder',
        scrollPosition: 123.45,
        currentImagePath: '/test/folder/image.jpg',
      );
      
      expect(state.mode, BrowseMode.fileAssociation);
      expect(state.currentFolderPath, '/test/folder');
      expect(state.scrollPosition, 123.45);
      expect(state.currentImagePath, '/test/folder/image.jpg');
    });

    test('should default scrollPosition to 0.0', () {
      const state = BrowseState(
        mode: BrowseMode.systemBrowse,
        currentFolderPath: '/test',
      );
      
      expect(state.scrollPosition, 0.0);
    });

    group('toJson', () {
      test('should serialize to JSON with all fields', () {
        const state = BrowseState(
          mode: BrowseMode.fileAssociation,
          currentFolderPath: '/test/folder',
          scrollPosition: 123.45,
          currentImagePath: '/test/folder/image.jpg',
        );
        
        final json = state.toJson();
        
        expect(json['mode'], 'fileAssociation');
        expect(json['currentFolderPath'], '/test/folder');
        expect(json['scrollPosition'], 123.45);
        expect(json['currentImagePath'], '/test/folder/image.jpg');
      });

      test('should serialize to JSON with null optional fields', () {
        const state = BrowseState(mode: BrowseMode.systemBrowse);
        
        final json = state.toJson();
        
        expect(json['mode'], 'systemBrowse');
        expect(json['currentFolderPath'], isNull);
        expect(json['scrollPosition'], 0.0);
        expect(json['currentImagePath'], isNull);
      });
    });

    group('fromJson', () {
      test('should deserialize from JSON with all fields', () {
        final json = {
          'mode': 'fileAssociation',
          'currentFolderPath': '/test/folder',
          'scrollPosition': 123.45,
          'currentImagePath': '/test/folder/image.jpg',
        };
        
        final state = BrowseState.fromJson(json);
        
        expect(state.mode, BrowseMode.fileAssociation);
        expect(state.currentFolderPath, '/test/folder');
        expect(state.scrollPosition, 123.45);
        expect(state.currentImagePath, '/test/folder/image.jpg');
      });

      test('should deserialize from JSON with null optional fields', () {
        final json = {
          'mode': 'systemBrowse',
        };
        
        final state = BrowseState.fromJson(json);
        
        expect(state.mode, BrowseMode.systemBrowse);
        expect(state.currentFolderPath, isNull);
        expect(state.scrollPosition, 0.0);
        expect(state.currentImagePath, isNull);
      });

      test('should default to systemBrowse when mode is missing', () {
        final json = <String, dynamic>{};
        
        final state = BrowseState.fromJson(json);
        
        expect(state.mode, BrowseMode.systemBrowse);
      });

      test('should default to systemBrowse when mode is invalid', () {
        final json = {
          'mode': 'invalidMode',
        };
        
        final state = BrowseState.fromJson(json);
        
        expect(state.mode, BrowseMode.systemBrowse);
      });

      test('should default scrollPosition to 0.0 when missing', () {
        final json = {
          'mode': 'systemBrowse',
          'currentFolderPath': '/test',
        };
        
        final state = BrowseState.fromJson(json);
        
        expect(state.scrollPosition, 0.0);
      });

      test('should handle integer scrollPosition', () {
        final json = {
          'mode': 'systemBrowse',
          'scrollPosition': 100,
        };
        
        final state = BrowseState.fromJson(json);
        
        expect(state.scrollPosition, 100.0);
      });
    });

    group('JSON round-trip', () {
      test('should maintain state through serialization and deserialization', () {
        const original = BrowseState(
          mode: BrowseMode.fileAssociation,
          currentFolderPath: '/test/folder',
          scrollPosition: 123.45,
          currentImagePath: '/test/folder/image.jpg',
        );
        
        final json = original.toJson();
        final restored = BrowseState.fromJson(json);
        
        expect(restored.mode, original.mode);
        expect(restored.currentFolderPath, original.currentFolderPath);
        expect(restored.scrollPosition, original.scrollPosition);
        expect(restored.currentImagePath, original.currentImagePath);
      });

      test('should maintain state with null fields through round-trip', () {
        const original = BrowseState(
          mode: BrowseMode.systemBrowse,
          scrollPosition: 50.0,
        );
        
        final json = original.toJson();
        final restored = BrowseState.fromJson(json);
        
        expect(restored.mode, original.mode);
        expect(restored.currentFolderPath, original.currentFolderPath);
        expect(restored.scrollPosition, original.scrollPosition);
        expect(restored.currentImagePath, original.currentImagePath);
      });
    });
  });
}
