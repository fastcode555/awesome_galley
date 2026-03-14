import '../errors/errors.dart';
import '../logging/logging.dart';

/// Example demonstrating error handling and logging
class ErrorHandlingExample {
  final Logger _logger = Logger();

  /// Example: Handle file not found error
  Future<void> handleFileNotFound() async {
    try {
      throw FileNotFoundException('/path/to/missing/file.jpg');
    } catch (e, stackTrace) {
      await ErrorHandler().handleError(e, stackTrace);
      _logger.warning('File not found error handled');
    }
  }

  /// Example: Handle corrupted file error
  Future<void> handleCorruptedFile() async {
    try {
      throw CorruptedFileException('/path/to/corrupted/file.jpg');
    } catch (e, stackTrace) {
      await ErrorHandler().handleError(e, stackTrace);
      _logger.warning('Corrupted file error handled');
    }
  }

  /// Example: Handle unrecoverable error
  Future<void> handleUnrecoverableError() async {
    try {
      throw OutOfMemoryException();
    } catch (e, stackTrace) {
      await ErrorHandler().handleError(e, stackTrace);
      _logger.error('Out of memory error handled');
    }
  }

  /// Example: Logging at different levels
  void demonstrateLogging() {
    _logger.debug('This is a debug message');
    _logger.info('This is an info message');
    _logger.warning('This is a warning message');
    _logger.error('This is an error message');
    _logger.fatal('This is a fatal message');
  }
}
