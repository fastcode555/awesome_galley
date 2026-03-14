import 'package:flutter/foundation.dart';
import 'log_level.dart';
import 'log_entry.dart';
import 'log_writer.dart';

/// Main logger class
class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  final List<LogWriter> _writers = [];
  LogLevel _minimumLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Initialize the logger
  Future<void> initialize({
    LogLevel? minimumLevel,
    bool enableConsole = true,
    bool enableFile = true,
  }) async {
    if (minimumLevel != null) {
      _minimumLevel = minimumLevel;
    }

    // Add console writer
    if (enableConsole) {
      _writers.add(ConsoleLogWriter());
    }

    // Add file writer
    if (enableFile) {
      _writers.add(FileLogWriter());
    }
  }

  /// Add a custom log writer
  void addWriter(LogWriter writer) {
    _writers.add(writer);
  }

  /// Remove a log writer
  void removeWriter(LogWriter writer) {
    _writers.remove(writer);
  }

  /// Set minimum log level
  void setMinimumLevel(LogLevel level) {
    _minimumLevel = level;
  }

  /// Log a debug message
  void debug(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    _log(LogLevel.debug, message, error, stackTrace, metadata);
  }

  /// Log an info message
  void info(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    _log(LogLevel.info, message, error, stackTrace, metadata);
  }

  /// Log a warning message
  void warning(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    _log(LogLevel.warning, message, error, stackTrace, metadata);
  }

  /// Log an error message
  void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    _log(LogLevel.error, message, error, stackTrace, metadata);
  }

  /// Log a fatal message
  void fatal(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    _log(LogLevel.fatal, message, error, stackTrace, metadata);
  }

  /// Internal log method
  void _log(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ) {
    // Check if this level should be logged
    if (!level.isEnabled(_minimumLevel)) {
      return;
    }

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );

    // Write to all writers
    for (final writer in _writers) {
      writer.write(entry);
    }
  }

  /// Flush all writers
  Future<void> flush() async {
    for (final writer in _writers) {
      await writer.flush();
    }
  }

  /// Close all writers
  Future<void> close() async {
    for (final writer in _writers) {
      await writer.close();
    }
    _writers.clear();
  }

  /// Get file log writer if available
  FileLogWriter? get fileWriter {
    for (final writer in _writers) {
      if (writer is FileLogWriter) {
        return writer;
      }
    }
    return null;
  }

  /// Clear all log files
  Future<void> clearLogs() async {
    final fileWriter = this.fileWriter;
    if (fileWriter != null) {
      await fileWriter.clearLogs();
    }
  }
}
