import 'app_error.dart';

/// Errors that prevent the app from functioning normally
abstract class UnrecoverableError extends AppError {
  UnrecoverableError({
    required super.message,
    super.details,
    super.stackTrace,
  });

  @override
  bool get isRecoverable => false;
}

/// Out of memory error
class OutOfMemoryException extends UnrecoverableError {
  OutOfMemoryException()
      : super(
          message: '内存不足',
          details: '应用内存使用过高',
        );

  @override
  String get userMessage => '内存不足，请重启应用';
}

/// Database corruption error
class DatabaseCorruptedException extends UnrecoverableError {
  final String databasePath;

  DatabaseCorruptedException(this.databasePath)
      : super(
          message: '数据库损坏',
          details: '数据库路径: $databasePath',
        );

  @override
  String get userMessage => '数据库已损坏，将尝试重建';
}

/// Platform API failure error
class PlatformApiException extends UnrecoverableError {
  final String apiName;
  final Object? originalError;

  PlatformApiException({
    required this.apiName,
    this.originalError,
  }) : super(
          message: '平台API调用失败',
          details: 'API: $apiName, 错误: $originalError',
        );

  @override
  String get userMessage => '系统功能调用失败，部分功能可能不可用';
}

/// Critical initialization error
class InitializationException extends UnrecoverableError {
  final String component;

  InitializationException(this.component)
      : super(
          message: '初始化失败',
          details: '组件: $component',
        );

  @override
  String get userMessage => '应用初始化失败，请重启应用';
}

/// Fatal error that requires app restart
class FatalException extends UnrecoverableError {
  final Object originalError;

  FatalException(this.originalError)
      : super(
          message: '发生严重错误',
          details: originalError.toString(),
        );

  @override
  String get userMessage => '应用遇到严重错误，需要重启';
}
