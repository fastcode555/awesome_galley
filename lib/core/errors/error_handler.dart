import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_error.dart';
import 'recoverable_error.dart';
import 'unrecoverable_error.dart';
import '../logging/logger.dart';

/// Global error handler for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final Logger _logger = Logger();
  final List<ErrorCallback> _errorCallbacks = [];

  /// Initialize error handling
  void initialize() {
    // Capture Flutter framework errors
    FlutterError.onError = _handleFlutterError;

    // Capture errors in debug mode
    if (kDebugMode) {
      // In debug mode, show detailed error information
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return _buildDebugErrorWidget(details);
      };
    } else {
      // In release mode, show user-friendly error page
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return _buildReleaseErrorWidget(details);
      };
    }
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    _logger.error(
      'Flutter framework error',
      details.exception,
      details.stack,
    );

    // Notify error callbacks
    for (final callback in _errorCallbacks) {
      callback(details.exception, details.stack);
    }

    // In debug mode, also print to console
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  /// Handle application errors
  Future<void> handleError(
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    if (error is AppError) {
      if (error.isRecoverable) {
        await _handleRecoverableError(error as RecoverableError);
      } else {
        await _handleUnrecoverableError(error as UnrecoverableError);
      }
    } else {
      // Unknown error, treat as fatal
      await _handleUnknownError(error, stackTrace);
    }
  }

  /// Handle recoverable errors
  Future<void> _handleRecoverableError(RecoverableError error) async {
    // Log warning
    _logger.warning(
      'Recoverable error: ${error.message}',
      error,
      error.stackTrace,
    );

    // Notify callbacks
    for (final callback in _errorCallbacks) {
      callback(error, error.stackTrace);
    }

    // Error will be handled by UI layer (showing snackbar, etc.)
  }

  /// Handle unrecoverable errors
  Future<void> _handleUnrecoverableError(UnrecoverableError error) async {
    // Log error
    _logger.error(
      'Unrecoverable error: ${error.message}',
      error,
      error.stackTrace,
    );

    // Notify callbacks
    for (final callback in _errorCallbacks) {
      callback(error, error.stackTrace);
    }

    // Attempt recovery based on error type
    if (error is OutOfMemoryException) {
      await _handleOutOfMemory();
    } else if (error is DatabaseCorruptedException) {
      await _handleDatabaseCorruption(error);
    }
  }

  /// Handle unknown errors
  Future<void> _handleUnknownError(
    Object error,
    StackTrace? stackTrace,
  ) async {
    _logger.fatal(
      'Unknown error',
      error,
      stackTrace,
    );

    // Notify callbacks
    for (final callback in _errorCallbacks) {
      callback(error, stackTrace);
    }
  }

  /// Handle out of memory situation
  Future<void> _handleOutOfMemory() async {
    _logger.info('Attempting to recover from out of memory');
    // Clear memory cache
    // Reduce concurrent image loading
    // This will be implemented by the cache manager
  }

  /// Handle database corruption
  Future<void> _handleDatabaseCorruption(
    DatabaseCorruptedException error,
  ) async {
    _logger.info('Attempting to rebuild database');
    // Try to rebuild database
    // This will be implemented by the state repository
  }

  /// Register error callback
  void registerErrorCallback(ErrorCallback callback) {
    _errorCallbacks.add(callback);
  }

  /// Unregister error callback
  void unregisterErrorCallback(ErrorCallback callback) {
    _errorCallbacks.remove(callback);
  }

  /// Build debug error widget
  Widget _buildDebugErrorWidget(FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ERROR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    details.exception.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (details.stack != null) ...[
                    const Text(
                      'Stack Trace:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.stack.toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build release error widget
  Widget _buildReleaseErrorWidget(FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  '发生错误',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '应用遇到了一个问题，请重启应用',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Error callback type
typedef ErrorCallback = void Function(Object error, StackTrace? stackTrace);

/// Run app with error handling
Future<void> runAppWithErrorHandling(Widget app) async {
  // Initialize error handler
  ErrorHandler().initialize();

  // Run app in guarded zone - binding must be initialized inside the zone
  // to avoid zone mismatch warnings
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(app);
    },
    (error, stackTrace) {
      ErrorHandler().handleError(error, stackTrace);
    },
  );
}
