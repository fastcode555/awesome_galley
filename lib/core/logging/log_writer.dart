import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'log_entry.dart';

/// Abstract log writer interface
abstract class LogWriter {
  Future<void> write(LogEntry entry);
  Future<void> flush();
  Future<void> close();
}

/// Console log writer
class ConsoleLogWriter implements LogWriter {
  @override
  Future<void> write(LogEntry entry) async {
    // ignore: avoid_print
    print(entry.toFormattedString());
  }

  @override
  Future<void> flush() async {
    // Console doesn't need flushing
  }

  @override
  Future<void> close() async {
    // Console doesn't need closing
  }
}

/// File log writer
class FileLogWriter implements LogWriter {
  final String fileName;
  final int maxFileSize;
  final int maxFiles;
  
  File? _currentFile;
  IOSink? _sink;
  int _currentFileSize = 0;
  final _writeQueue = <LogEntry>[];
  bool _isWriting = false;

  FileLogWriter({
    this.fileName = 'app.log',
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.maxFiles = 5,
  });

  @override
  Future<void> write(LogEntry entry) async {
    _writeQueue.add(entry);
    await _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isWriting || _writeQueue.isEmpty) return;
    
    _isWriting = true;
    
    try {
      while (_writeQueue.isNotEmpty) {
        final entry = _writeQueue.removeAt(0);
        await _writeEntry(entry);
      }
    } finally {
      _isWriting = false;
    }
  }

  Future<void> _writeEntry(LogEntry entry) async {
    try {
      await _ensureFileOpen();
      
      final line = '${entry.toFormattedString()}\n';
      final bytes = line.length;
      
      // Check if we need to rotate the log file
      if (_currentFileSize + bytes > maxFileSize) {
        await _rotateLogFile();
      }
      
      _sink?.write(line);
      _currentFileSize += bytes;
    } catch (e) {
      // If file writing fails, fall back to console
      // ignore: avoid_print
      print('Failed to write to log file: $e');
      // ignore: avoid_print
      print(entry.toFormattedString());
    }
  }

  Future<void> _ensureFileOpen() async {
    if (_currentFile != null && _sink != null) return;
    
    final directory = await _getLogDirectory();
    _currentFile = File('${directory.path}/$fileName');
    
    // Get current file size if it exists
    if (await _currentFile!.exists()) {
      _currentFileSize = await _currentFile!.length();
    } else {
      _currentFileSize = 0;
    }
    
    _sink = _currentFile!.openWrite(mode: FileMode.append);
  }

  Future<Directory> _getLogDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${appDir.path}/logs');
    
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    
    return logDir;
  }

  Future<void> _rotateLogFile() async {
    await flush();
    await close();
    
    final directory = await _getLogDirectory();
    
    // Rotate existing log files
    for (int i = maxFiles - 1; i > 0; i--) {
      final oldFile = File('${directory.path}/$fileName.$i');
      final newFile = File('${directory.path}/$fileName.${i + 1}');
      
      if (await oldFile.exists()) {
        if (i == maxFiles - 1) {
          // Delete the oldest file
          await oldFile.delete();
        } else {
          await oldFile.rename(newFile.path);
        }
      }
    }
    
    // Rename current log file
    final currentFile = File('${directory.path}/$fileName');
    if (await currentFile.exists()) {
      await currentFile.rename('${directory.path}/$fileName.1');
    }
    
    // Reset for new file
    _currentFile = null;
    _sink = null;
    _currentFileSize = 0;
  }

  @override
  Future<void> flush() async {
    await _sink?.flush();
  }

  @override
  Future<void> close() async {
    await flush();
    await _sink?.close();
    _sink = null;
    _currentFile = null;
  }

  /// Get all log files
  Future<List<File>> getLogFiles() async {
    final directory = await _getLogDirectory();
    final files = <File>[];
    
    // Add current log file
    final currentFile = File('${directory.path}/$fileName');
    if (await currentFile.exists()) {
      files.add(currentFile);
    }
    
    // Add rotated log files
    for (int i = 1; i <= maxFiles; i++) {
      final file = File('${directory.path}/$fileName.$i');
      if (await file.exists()) {
        files.add(file);
      }
    }
    
    return files;
  }

  /// Clear all log files
  Future<void> clearLogs() async {
    await close();
    
    final files = await getLogFiles();
    for (final file in files) {
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    _currentFileSize = 0;
  }
}
