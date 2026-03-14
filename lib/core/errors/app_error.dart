/// Base class for all application errors
abstract class AppError implements Exception {
  final String message;
  final String? details;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  AppError({
    required this.message,
    this.details,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  /// Whether this error can be recovered from
  bool get isRecoverable;

  /// User-friendly error message
  String get userMessage => message;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    return buffer.toString();
  }
}
