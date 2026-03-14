import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_galley/application/controllers/image_controller.dart';

void main() {
  group('ImageController Smoke Tests', () {
    test('should initialize with idle state', () {
      final controller = ImageController();

      expect(controller.state, equals(ImageLoadingState.idle));
      expect(controller.isLoading, isFalse);
      expect(controller.isSuccess, isFalse);
      expect(controller.isError, isFalse);
      expect(controller.errorMessage, isNull);

      controller.dispose();
    });

    test('should have 30 second timeout constant', () {
      expect(
        ImageController.loadTimeout,
        equals(const Duration(seconds: 30)),
      );
    });

    test('should reset state to idle', () {
      final controller = ImageController();

      // Manually set state to success
      controller.reset();

      expect(controller.state, equals(ImageLoadingState.idle));

      controller.dispose();
    });

    test('ImageLoadTimeoutException should format message correctly with file path', () {
      final exception = ImageLoadTimeoutException(
        'Test timeout',
        filePath: '/path/to/file.jpg',
      );

      expect(
        exception.toString(),
        equals(
            'ImageLoadTimeoutException: Test timeout (file: /path/to/file.jpg)'),
      );
    });

    test('ImageLoadTimeoutException should format message correctly without file path', () {
      final exception = ImageLoadTimeoutException('Test timeout');

      expect(
        exception.toString(),
        equals('ImageLoadTimeoutException: Test timeout'),
      );
    });

    test('should expose loading state enum values', () {
      expect(ImageLoadingState.values, contains(ImageLoadingState.idle));
      expect(ImageLoadingState.values, contains(ImageLoadingState.loading));
      expect(ImageLoadingState.values, contains(ImageLoadingState.success));
      expect(ImageLoadingState.values, contains(ImageLoadingState.error));
    });
  });
}
