# Core Error Handling and Logging System

This directory contains the unified error handling and logging system for the Image Gallery Viewer application.

## Overview

The system provides:
- **Error Classification**: Recoverable vs Unrecoverable errors
- **Error Boundaries**: Flutter framework error capture
- **Crash Recovery**: Automatic crash detection and state recovery
- **Multi-level Logging**: Debug, Info, Warning, Error, Fatal
- **Log Persistence**: Console and file-based logging with rotation

## Architecture

### Error Handling (`lib/core/errors/`)

#### Error Types

**AppError** (Base class)
- Abstract base for all application errors
- Provides common properties: message, details, stackTrace, timestamp

**RecoverableError**
- Errors that don't affect overall functionality
- Examples: FileNotFoundException, PermissionDeniedException, CorruptedFileException
- Strategy: Show user-friendly message, log warning, continue execution

**UnrecoverableError**
- Errors that prevent normal operation
- Examples: OutOfMemoryException, DatabaseCorruptedException, PlatformApiException
- Strategy: Log error, attempt recovery, show error page if recovery fails

#### Components

**ErrorHandler**
- Global error handler singleton
- Captures Flutter framework errors via `FlutterError.onError`
- Provides error callbacks for custom handling
- Builds debug/release error widgets

**CrashRecoveryManager**
- Detects crashes from previous sessions
- Saves and recovers application state
- Tracks crash count and detects crash loops
- Handles crash loop recovery (clears data)

### Logging System (`lib/core/logging/`)

#### Log Levels

1. **DEBUG**: Development information (disabled in release)
2. **INFO**: General information
3. **WARNING**: Recoverable errors
4. **ERROR**: Unrecoverable errors
5. **FATAL**: Critical errors causing crashes

#### Components

**Logger**
- Singleton logger instance
- Multi-writer architecture (console, file, custom)
- Configurable minimum log level
- Thread-safe log queue

**LogWriter**
- Abstract interface for log output
- **ConsoleLogWriter**: Outputs to console
- **FileLogWriter**: Writes to rotating log files (10MB max, 5 files)

**LogEntry**
- Structured log entry with timestamp, level, message, error, stackTrace
- Formatted string output
- JSON serialization support

## Usage

### Error Handling

#### Throwing Errors

```dart
// Recoverable error
throw FileNotFoundException('/path/to/file.jpg');

// Unrecoverable error
throw DatabaseCorruptedException('/path/to/db');
```

#### Handling Errors

```dart
try {
  await loadImage(path);
} catch (e, stackTrace) {
  await ErrorHandler().handleError(e, stackTrace);
}
```

#### Registering Error Callbacks

```dart
ErrorHandler().registerErrorCallback((error, stackTrace) {
  // Custom error handling logic
  if (error is RecoverableError) {
    showSnackbar(error.userMessage);
  }
});
```

### Logging

#### Basic Logging

```dart
final logger = Logger();

logger.debug('Loading image: $path');
logger.info('Image loaded successfully');
logger.warning('Cache miss, generating thumbnail');
logger.error('Failed to decode image', error, stackTrace);
logger.fatal('Out of memory', error, stackTrace);
```

#### With Metadata

```dart
logger.info('Image loaded', null, null, {
  'path': imagePath,
  'size': fileSize,
  'duration': loadDuration.inMilliseconds,
});
```

#### Managing Log Files

```dart
// Get all log files
final files = await logger.fileWriter?.getLogFiles();

// Clear all logs
await logger.clearLogs();

// Flush logs to disk
await logger.flush();
```

### Crash Recovery

#### Initialization

```dart
final crashManager = CrashRecoveryManager();
await crashManager.initialize();

// Mark app started
await crashManager.markAppStarted();

// Check for crash
if (await crashManager.didCrashLastTime()) {
  final state = await crashManager.recoverLastState();
  // Restore state
}
```

#### Saving State

```dart
// Periodically save state
await crashManager.saveState({
  'folderPath': currentFolder,
  'scrollPosition': scrollPosition,
  'currentImage': currentImagePath,
});
```

#### Normal Shutdown

```dart
// On app lifecycle pause/detach
await crashManager.markAppClosedNormally();
```

## Integration

### main.dart

The error handling and logging system is integrated in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  final logger = Logger();
  await logger.initialize(
    enableConsole: true,
    enableFile: true,
  );

  // Initialize error handler
  final errorHandler = ErrorHandler();
  errorHandler.initialize();

  // Run app with error handling
  await runAppWithErrorHandling(MyApp());
}
```

### Error Boundaries

Errors are automatically captured at multiple levels:

1. **Flutter Framework Errors**: `FlutterError.onError`
2. **Async Errors**: `runZonedGuarded`
3. **Widget Build Errors**: Custom `ErrorWidget.builder`

### Crash Detection Flow

1. App starts → Set crash flag to `true`
2. App runs normally → Periodically save state
3. App closes normally → Set crash flag to `false`
4. App crashes → Crash flag remains `true`
5. Next launch → Detect crash flag, recover state

## Requirements Validation

This implementation validates the following requirements:

### Requirement 10.1 - File Not Found
- `FileNotFoundException` provides user-friendly message
- Shows placeholder icon in UI

### Requirement 10.2 - Corrupted File
- `CorruptedFileException` handles decode failures
- Shows error icon and message

### Requirement 10.3 - Load Timeout
- `LoadTimeoutException` with retry option
- Configurable timeout duration

### Requirement 10.4 - Disk Space Insufficient
- `DiskSpaceInsufficientException` for cache failures
- Falls back to loading original image
- Logs warning for monitoring

### Requirement 10.5 - Permission Denied
- `PermissionDeniedException` with authorization guidance
- Skips inaccessible files

### Requirement 10.6 - Crash Recovery
- `CrashRecoveryManager` detects crashes
- Recovers to last browsing position
- Handles crash loops

## File Structure

```
lib/core/
├── errors/
│   ├── app_error.dart              # Base error class
│   ├── recoverable_error.dart      # Recoverable error types
│   ├── unrecoverable_error.dart    # Unrecoverable error types
│   ├── error_handler.dart          # Global error handler
│   ├── crash_recovery_manager.dart # Crash detection and recovery
│   └── errors.dart                 # Export file
├── logging/
│   ├── log_level.dart              # Log level enum
│   ├── log_entry.dart              # Log entry model
│   ├── log_writer.dart             # Log writer implementations
│   ├── logger.dart                 # Main logger class
│   └── logging.dart                # Export file
└── README.md                       # This file
```

## Testing

### Unit Tests

Test error handling:
```dart
test('FileNotFoundException provides user message', () {
  final error = FileNotFoundException('/test/path.jpg');
  expect(error.isRecoverable, true);
  expect(error.userMessage, '文件未找到');
});
```

Test logging:
```dart
test('Logger writes to file', () async {
  final logger = Logger();
  await logger.initialize(enableFile: true);
  
  logger.info('Test message');
  await logger.flush();
  
  final files = await logger.fileWriter?.getLogFiles();
  expect(files, isNotEmpty);
});
```

### Integration Tests

Test crash recovery:
```dart
testWidgets('App recovers from crash', (tester) async {
  // Simulate crash
  final manager = CrashRecoveryManager();
  await manager.initialize();
  await manager.markAppStarted();
  
  // Restart app
  expect(await manager.didCrashLastTime(), true);
  
  // Verify state recovery
  final state = await manager.recoverLastState();
  expect(state, isNotNull);
});
```

## Performance Considerations

### Logging
- Asynchronous file writes (non-blocking)
- Write queue to batch operations
- Automatic log rotation to prevent disk overflow
- Configurable minimum log level

### Error Handling
- Minimal overhead for error capture
- Efficient error callback system
- Lazy initialization of error widgets

### Crash Recovery
- Fast crash detection (single SharedPreferences read)
- Incremental state saving
- Crash loop detection prevents infinite restart cycles

## Future Enhancements

1. **Remote Error Reporting**: Integration with error tracking services (Sentry, Firebase Crashlytics)
2. **Log Upload**: Automatic log upload in production for debugging
3. **Error Analytics**: Track error frequency and patterns
4. **Custom Recovery Strategies**: Per-error-type recovery actions
5. **Log Filtering**: Advanced log filtering and search
6. **Performance Metrics**: Log performance data alongside errors
