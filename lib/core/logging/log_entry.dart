import 'log_level.dart';

/// Represents a single log entry
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.metadata,
  });

  /// Convert to formatted string
  String toFormattedString() {
    final buffer = StringBuffer();
    
    // Timestamp and level
    buffer.write('[${_formatTimestamp(timestamp)}] ');
    buffer.write('[${level.label}] ');
    
    // Message
    buffer.write(message);
    
    // Error
    if (error != null) {
      buffer.write('\nError: $error');
    }
    
    // Stack trace
    if (stackTrace != null) {
      buffer.write('\nStack trace:\n$stackTrace');
    }
    
    // Metadata
    if (metadata != null && metadata!.isNotEmpty) {
      buffer.write('\nMetadata: $metadata');
    }
    
    return buffer.toString();
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.label,
      'message': message,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Format timestamp
  String _formatTimestamp(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}.${_padMillis(dt.millisecond)}';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
  String _padMillis(int value) => value.toString().padLeft(3, '0');
}
