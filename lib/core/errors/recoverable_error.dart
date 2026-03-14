import 'app_error.dart';

/// Errors that don't affect the overall functionality and can be gracefully degraded
abstract class RecoverableError extends AppError {
  final Function()? retryAction;

  RecoverableError({
    required super.message,
    super.details,
    super.stackTrace,
    this.retryAction,
  });

  @override
  bool get isRecoverable => true;
}

/// File not found error
class FileNotFoundException extends RecoverableError {
  final String filePath;

  FileNotFoundException(this.filePath)
      : super(
          message: '文件未找到',
          details: '文件路径: $filePath',
        );

  @override
  String get userMessage => '文件未找到';
}

/// Permission denied error
class PermissionDeniedException extends RecoverableError {
  final String resource;

  PermissionDeniedException(this.resource)
      : super(
          message: '权限不足',
          details: '无法访问: $resource',
        );

  @override
  String get userMessage => '权限不足，请授予应用访问权限';
}

/// Corrupted file error
class CorruptedFileException extends RecoverableError {
  final String filePath;

  CorruptedFileException(this.filePath)
      : super(
          message: '图片损坏',
          details: '无法解码图片: $filePath',
        );

  @override
  String get userMessage => '图片文件已损坏，无法显示';
}

/// Load timeout error
class LoadTimeoutException extends RecoverableError {
  final String resource;
  final Duration timeout;

  LoadTimeoutException(this.resource, this.timeout)
      : super(
          message: '加载超时',
          details: '资源: $resource, 超时时间: ${timeout.inSeconds}秒',
        );

  @override
  String get userMessage => '加载超时，请检查网络连接或重试';
}

/// Disk space insufficient error
class DiskSpaceInsufficientException extends RecoverableError {
  final int requiredBytes;
  final int availableBytes;

  DiskSpaceInsufficientException({
    required this.requiredBytes,
    required this.availableBytes,
  }) : super(
          message: '磁盘空间不足',
          details: '需要: ${requiredBytes ~/ 1024}KB, 可用: ${availableBytes ~/ 1024}KB',
        );

  @override
  String get userMessage => '磁盘空间不足，将跳过缓存生成';
}

/// Image decode error
class ImageDecodeException extends RecoverableError {
  final String filePath;

  ImageDecodeException(this.filePath)
      : super(
          message: '图片解码失败',
          details: '文件: $filePath',
        );

  @override
  String get userMessage => '无法解码图片';
}

/// Unsupported format error
class UnsupportedFormatException extends RecoverableError {
  final String format;

  UnsupportedFormatException(this.format)
      : super(
          message: '不支持的图片格式',
          details: '格式: $format',
        );

  @override
  String get userMessage => '不支持的图片格式: $format';
}
