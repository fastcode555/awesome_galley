import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:awesome_galley/domain/models/image_format.dart';
import 'package:awesome_galley/domain/models/image_item.dart';
import 'package:awesome_galley/infrastructure/repositories/state_repository.dart';
import 'package:awesome_galley/infrastructure/services/file_system_service.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'image_repository.dart';

// ---------------------------------------------------------------------------
// 常量
// ---------------------------------------------------------------------------

const int _systemImageLimit = 50000;
const int _folderImageLimit = 5000;

const Set<String> _skipDirNames = {
  'Library', 'System', 'Applications', '.Trash',
  'node_modules', '.git', '.cache', 'Cache', 'Caches',
  '.npm', '.gradle', '.m2', 'AppData', 'ProgramData',
  'Windows', 'Program Files', 'Program Files (x86)',
  'build',
};

const Set<String> _supportedExtensions = {
  '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp',
};

// ---------------------------------------------------------------------------
// Isolate 消息类型
// ---------------------------------------------------------------------------

class _ScanParams {
  final SendPort sendPort;
  final String rootDir;
  _ScanParams(this.sendPort, this.rootDir);
}

class _FileBatch {
  final List<Map<String, dynamic>> files;
  _FileBatch(this.files);
}

class _ScanDone {
  const _ScanDone();
}

// ---------------------------------------------------------------------------
// Isolate 入口（顶层函数）
// ---------------------------------------------------------------------------

Future<void> _scanIsolateEntry(_ScanParams params) async {
  await _scanDirRecursive(Directory(params.rootDir), params.sendPort, 0);
  params.sendPort.send(const _ScanDone());
}

bool _shouldSkipDir(String dirName) {
  if (dirName.startsWith('.')) return true;
  return _skipDirNames.contains(dirName);
}

Future<void> _scanDirRecursive(
  Directory dir,
  SendPort sendPort,
  int depth,
) async {
  if (depth > 10) return;
  if (_shouldSkipDir(path.basename(dir.path))) return;

  final batch = <Map<String, dynamic>>[];

  try {
    await for (final entity in dir.list(followLinks: false)) {
      try {
        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          if (_supportedExtensions.contains(ext)) {
            final stat = await entity.stat();
            batch.add({
              'filePath': entity.path,
              'fileName': path.basename(entity.path),
              'fileSize': stat.size,
              'modifiedTime': stat.modified.millisecondsSinceEpoch,
              'ext': ext,
            });
          }
        } else if (entity is Directory) {
          if (batch.isNotEmpty) {
            sendPort.send(_FileBatch(List.of(batch)));
            batch.clear();
          }
          await _scanDirRecursive(entity, sendPort, depth + 1);
        }
      } catch (_) {}
    }
  } catch (_) {}

  if (batch.isNotEmpty) {
    sendPort.send(_FileBatch(List.of(batch)));
  }
}

// ---------------------------------------------------------------------------
// 在独立 isolate 中解析图片宽高（只读头部，不完整解码）
// ---------------------------------------------------------------------------

Future<List<Map<String, dynamic>>> _decodeDimensionsBatch(
  List<Map<String, dynamic>> files,
) async {
  final result = <Map<String, dynamic>>[];
  for (final f in files) {
    try {
      final bytes = await File(f['filePath'] as String).readAsBytes();
      // findDecoderForData + startDecode 只解析头部，速度远快于完整解码
      final decoder = img.findDecoderForData(bytes);
      final info = decoder?.startDecode(bytes);
      result.add({
        ...f,
        'width': info?.width ?? 1,
        'height': info?.height ?? 1,
      });
    } catch (_) {
      result.add({...f, 'width': 1, 'height': 1});
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// Repository 实现
// ---------------------------------------------------------------------------

class ImageRepositoryImpl implements ImageRepository {
  final FileSystemService _fileSystem;
  final StateRepository _stateRepository;
  final _uuid = const Uuid();

  ImageRepositoryImpl({
    required FileSystemService fileSystemService,
    required StateRepository stateRepository,
  })  : _fileSystem = fileSystemService,
        _stateRepository = stateRepository;

  // ---------------------------------------------------------------------------
  // 扫描系统目录 → 写入数据库 → 流式返回给 UI
  // ---------------------------------------------------------------------------

  @override
  Stream<List<ImageItem>> scanSystemDirectoriesStream() async* {
    final dirs = await _fileSystem.getSystemImageDirectories();
    if (dirs.isEmpty) return;

    int totalCount = 0;

    for (final rootDir in dirs) {
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _scanIsolateEntry,
        _ScanParams(receivePort.sendPort, rootDir),
        errorsAreFatal: false,
      );

      await for (final msg in receivePort) {
        if (msg is _FileBatch) {
          final items = await _resolveAndSaveMetadata(msg.files);
          if (items.isNotEmpty) {
            totalCount += items.length;
            yield items;
          }
          if (totalCount >= _systemImageLimit) {
            isolate.kill(priority: Isolate.immediate);
            receivePort.close();
            return;
          }
        } else if (msg is _ScanDone) {
          receivePort.close();
          break;
        }
      }

      isolate.kill(priority: Isolate.immediate);
    }
  }

  // ---------------------------------------------------------------------------
  // 从数据库分页加载（校验文件存在性）
  // ---------------------------------------------------------------------------

  @override
  Future<List<ImageItem>> loadPageFromDb({
    required int limit,
    required int offset,
  }) async {
    // 多取一些，因为部分文件可能已不存在
    final rows = await _stateRepository.getImageMetadataPage(
      limit: limit + 20,
      offset: offset,
    );

    final valid = <ImageItem>[];
    final toDelete = <String>[];

    for (final row in rows) {
      final exists = await File(row.filePath).exists();
      if (!exists) {
        toDelete.add(row.filePath);
        continue;
      }
      valid.add(_buildItemFromCache(row));
      if (valid.length >= limit) break;
    }

    // 异步删除失效记录，不阻塞返回
    if (toDelete.isNotEmpty) {
      _stateRepository.deleteImageMetadataBatch(toDelete);
    }

    return valid;
  }

  @override
  Future<int> getDbImageCount() => _stateRepository.getImageMetadataCount();

  // ---------------------------------------------------------------------------
  // 解析元数据：先查 DB，没有的才解码；结果写入 DB
  // ---------------------------------------------------------------------------

  Future<List<ImageItem>> _resolveAndSaveMetadata(
    List<Map<String, dynamic>> files,
  ) async {
    if (files.isEmpty) return [];

    final filePaths = files.map((f) => f['filePath'] as String).toList();
    final cached = await _stateRepository.getImageMetadataBatch(filePaths);

    final needDecode = <Map<String, dynamic>>[];
    final result = <ImageItem>[];

    for (final f in files) {
      final fp = f['filePath'] as String;
      final modTime = f['modifiedTime'] as int;
      final dbEntry = cached[fp];

      if (dbEntry != null && dbEntry.modifiedTime == modTime) {
        result.add(_buildItemFromCache(dbEntry));
      } else {
        needDecode.add(f);
      }
    }

    if (needDecode.isNotEmpty) {
      // 使用 decodeImageHeader 只读取头部，速度远快于完整解码
      final decoded = await Isolate.run(() => _decodeDimensionsBatch(needDecode));

      final toSave = decoded.map((d) => ImageMetadataCache(
            filePath: d['filePath'] as String,
            width: d['width'] as int,
            height: d['height'] as int,
            fileSize: d['fileSize'] as int,
            modifiedTime: d['modifiedTime'] as int,
            format: d['ext'] as String,
          )).toList();
      await _stateRepository.saveImageMetadataBatch(toSave);

      for (final d in decoded) {
        result.add(_buildItem(d, d['width'] as int, d['height'] as int));
      }
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // 扫描指定文件夹
  // ---------------------------------------------------------------------------

  @override
  Future<List<ImageItem>> scanFolder(String folderPath) async {
    final fileInfoList = await _fileSystem.listImagesInFolder(folderPath);
    final supported = fileInfoList.where((f) => f.isSupported).toList();
    supported.sort((a, b) => a.name.compareTo(b.name));

    final limited = supported.length > _folderImageLimit
        ? supported.sublist(0, _folderImageLimit)
        : supported;

    final files = limited.map((f) => {
          'filePath': f.path,
          'fileName': f.name,
          'fileSize': f.size,
          'modifiedTime': f.modifiedTime.millisecondsSinceEpoch,
          'ext': path.extension(f.path).toLowerCase(),
        }).toList();

    return _resolveAndSaveMetadata(files);
  }

  /// 扫描文件夹但不写入数据库（open with 场景）
  @override
  Future<List<ImageItem>> scanFolderOnly(String folderPath) async {
    final fileInfoList = await _fileSystem.listImagesInFolder(folderPath);
    final supported = fileInfoList.where((f) => f.isSupported).toList();
    supported.sort((a, b) => a.name.compareTo(b.name));

    final limited = supported.length > _folderImageLimit
        ? supported.sublist(0, _folderImageLimit)
        : supported;

    // 直接从 DB 查缓存（只读，不写），没有缓存的用 1:1 占位
    final filePaths = limited.map((f) => f.path).toList();
    final cached = await _stateRepository.getImageMetadataBatch(filePaths);

    return limited.map((f) {
      final ext = path.extension(f.path).toLowerCase();
      final db = cached[f.path];
      final w = db?.width ?? 1;
      final h = db?.height ?? 1;
      return ImageItem(
        id: _uuid.v4(),
        filePath: f.path,
        fileName: f.name,
        width: w,
        height: h,
        fileSize: f.size,
        modifiedTime: f.modifiedTime,
        format: ImageFormat.fromExtension(ext),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Recent folders
  // ---------------------------------------------------------------------------

  @override
  Future<List<String>> getRecentFolders() async {
    final folders = await _stateRepository.getRecentFolders();
    return folders.map((f) => f.folderPath).toList();
  }

  @override
  Future<void> saveRecentFolder(String folderPath, {int? imageCount}) async {
    await _stateRepository.addRecentFolder(folderPath, imageCount: imageCount);
  }

  @override
  Future<void> deleteImage(String filePath) async {
    // 1. 删除数据库记录
    await _stateRepository.deleteImageMetadata(filePath);
    // 2. 删除文件
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> updateImageSize(String filePath, int width, int height) async {
    await _stateRepository.updateImageSize(filePath, width, height);
  }

  // ---------------------------------------------------------------------------
  // 构建 ImageItem
  // ---------------------------------------------------------------------------

  ImageItem _buildItemFromCache(ImageMetadataCache c) {
    return ImageItem(
      id: _uuid.v4(),
      filePath: c.filePath,
      fileName: path.basename(c.filePath),
      width: c.width,
      height: c.height,
      fileSize: c.fileSize,
      modifiedTime: DateTime.fromMillisecondsSinceEpoch(c.modifiedTime),
      format: ImageFormat.fromExtension(c.format),
    );
  }

  ImageItem _buildItem(Map<String, dynamic> f, int w, int h) {
    return ImageItem(
      id: _uuid.v4(),
      filePath: f['filePath'] as String,
      fileName: f['fileName'] as String,
      width: w,
      height: h,
      fileSize: f['fileSize'] as int,
      modifiedTime: DateTime.fromMillisecondsSinceEpoch(f['modifiedTime'] as int),
      format: ImageFormat.fromExtension(f['ext'] as String),
    );
  }
}
