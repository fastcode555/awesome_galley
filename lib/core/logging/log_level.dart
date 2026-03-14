/// Log level enumeration
enum LogLevel {
  /// Debug information (development only)
  debug(0, 'DEBUG'),
  
  /// General information
  info(1, 'INFO'),
  
  /// Warning messages (recoverable errors)
  warning(2, 'WARNING'),
  
  /// Error messages (unrecoverable errors)
  error(3, 'ERROR'),
  
  /// Fatal errors (causes crash)
  fatal(4, 'FATAL');

  const LogLevel(this.value, this.label);

  final int value;
  final String label;

  /// Check if this level is enabled for a given minimum level
  bool isEnabled(LogLevel minimumLevel) {
    return value >= minimumLevel.value;
  }
}
