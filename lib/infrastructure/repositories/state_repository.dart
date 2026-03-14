import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

/// Repository for persisting application state
/// 
/// Uses SharedPreferences for lightweight data (current folder, scroll position)
/// Uses SQLite for structured data (recent folders, browse history, cache metadata)
class StateRepository {
  final SharedPreferences _prefs;
  Database? _db;

  StateRepository(this._prefs);

  /// Initialize the database and create tables if needed
  /// 
  /// If [inMemory] is true, creates an in-memory database (useful for testing)
  Future<void> initialize({bool inMemory = false}) async {
    final String dbPath;
    
    if (inMemory) {
      dbPath = ':memory:';
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = path.join(databasesPath, 'image_gallery.db');
    }

    _db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS image_metadata (
              file_path TEXT PRIMARY KEY,
              width INTEGER NOT NULL,
              height INTEGER NOT NULL,
              file_size INTEGER NOT NULL,
              modified_time INTEGER NOT NULL,
              format TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Recent folders table
    await db.execute('''
      CREATE TABLE recent_folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_path TEXT NOT NULL UNIQUE,
        last_visited INTEGER NOT NULL,
        image_count INTEGER
      )
    ''');

    // Browse history table
    await db.execute('''
      CREATE TABLE browse_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        viewed_at INTEGER NOT NULL,
        duration_seconds INTEGER
      )
    ''');

    // Cache metadata table
    await db.execute('''
      CREATE TABLE cache_metadata (
        cache_key TEXT PRIMARY KEY,
        original_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        last_accessed INTEGER NOT NULL
      )
    ''');

    // Image metadata table - 缓存图片的宽高等信息，避免重复解析
    await db.execute('''
      CREATE TABLE image_metadata (
        file_path TEXT PRIMARY KEY,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        file_size INTEGER NOT NULL,
        modified_time INTEGER NOT NULL,
        format TEXT NOT NULL
      )
    ''');
  }

  // ========== SharedPreferences Methods ==========

  /// Save the current scroll position
  Future<void> saveScrollPosition(double position) async {
    await _prefs.setDouble('scroll_position', position);
  }

  /// Get the saved scroll position
  Future<double?> getScrollPosition() async {
    return _prefs.getDouble('scroll_position');
  }

  /// Save the current folder path
  Future<void> saveCurrentFolder(String folderPath) async {
    await _prefs.setString('current_folder', folderPath);
  }

  /// Get the saved current folder path
  Future<String?> getCurrentFolder() async {
    return _prefs.getString('current_folder');
  }

  // ========== SQLite Methods ==========

  /// Add a folder to the recent folders list
  /// Maintains a maximum of 10 recent folders
  Future<void> addRecentFolder(String folderPath, {int? imageCount}) async {
    if (_db == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // Insert or update the folder
    await _db!.insert(
      'recent_folders',
      {
        'folder_path': folderPath,
        'last_visited': now,
        'image_count': imageCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Keep only the 10 most recent folders
    await _db!.execute('''
      DELETE FROM recent_folders
      WHERE id NOT IN (
        SELECT id FROM recent_folders
        ORDER BY last_visited DESC
        LIMIT 10
      )
    ''');
  }

  /// Get the list of recent folders (up to 10)
  /// Returns folders ordered by last visited time (most recent first)
  Future<List<RecentFolder>> getRecentFolders() async {
    if (_db == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }

    final List<Map<String, dynamic>> maps = await _db!.query(
      'recent_folders',
      orderBy: 'last_visited DESC',
      limit: 10,
    );

    return maps.map((map) => RecentFolder.fromMap(map)).toList();
  }

  /// Close the database connection
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ========== Image Metadata Methods ==========

  /// 查询图片元数据缓存
  /// 
  /// 如果文件的 modifiedTime 与数据库记录一致，说明缓存有效
  Future<ImageMetadataCache?> getImageMetadata(
    String filePath,
    int modifiedTimeMs,
  ) async {
    if (_db == null) return null;
    final rows = await _db!.query(
      'image_metadata',
      where: 'file_path = ? AND modified_time = ?',
      whereArgs: [filePath, modifiedTimeMs],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ImageMetadataCache.fromMap(rows.first);
  }

  /// 批量查询图片元数据
  Future<Map<String, ImageMetadataCache>> getImageMetadataBatch(
    List<String> filePaths,
  ) async {
    if (_db == null || filePaths.isEmpty) return {};
    final placeholders = filePaths.map((_) => '?').join(',');
    final rows = await _db!.rawQuery(
      'SELECT * FROM image_metadata WHERE file_path IN ($placeholders)',
      filePaths,
    );
    return {
      for (final row in rows)
        row['file_path'] as String: ImageMetadataCache.fromMap(row)
    };
  }

  /// 保存图片元数据
  Future<void> saveImageMetadata(ImageMetadataCache meta) async {
    if (_db == null) return;
    await _db!.insert(
      'image_metadata',
      meta.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量保存图片元数据
  Future<void> saveImageMetadataBatch(List<ImageMetadataCache> metas) async {
    if (_db == null || metas.isEmpty) return;
    final batch = _db!.batch();
    for (final meta in metas) {
      batch.insert(
        'image_metadata',
        meta.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// 分页查询图片元数据（按 modified_time 倒序）
  Future<List<ImageMetadataCache>> getImageMetadataPage({
    required int limit,
    required int offset,
  }) async {
    if (_db == null) return [];
    final rows = await _db!.query(
      'image_metadata',
      orderBy: 'modified_time DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(ImageMetadataCache.fromMap).toList();
  }

  /// 查询数据库中图片总数
  Future<int> getImageMetadataCount() async {
    if (_db == null) return 0;
    final result = await _db!.rawQuery(
      'SELECT COUNT(*) as cnt FROM image_metadata',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// 批量删除不存在的文件记录
  Future<void> deleteImageMetadataBatch(List<String> filePaths) async {
    if (_db == null || filePaths.isEmpty) return;
    final placeholders = filePaths.map((_) => '?').join(',');
    await _db!.rawDelete(
      'DELETE FROM image_metadata WHERE file_path IN ($placeholders)',
      filePaths,
    );
  }

  /// 删除单条图片元数据
  Future<void> deleteImageMetadata(String filePath) async {
    if (_db == null) return;
    await _db!.delete(
      'image_metadata',
      where: 'file_path = ?',
      whereArgs: [filePath],
    );
  }

  /// 更新图片的真实宽高（UI 显示后回写，仅当当前值为占位值时）
  Future<void> updateImageSize(String filePath, int width, int height) async {
    if (_db == null) return;
    await _db!.rawUpdate(
      'UPDATE image_metadata SET width = ?, height = ? WHERE file_path = ? AND (width <= 1 OR height <= 1)',
      [width, height, filePath],
    );
  }
}

/// Model for a recent folder entry
class RecentFolder {
  final int id;
  final String folderPath;
  final DateTime lastVisited;
  final int? imageCount;

  RecentFolder({
    required this.id,
    required this.folderPath,
    required this.lastVisited,
    this.imageCount,
  });

  factory RecentFolder.fromMap(Map<String, dynamic> map) {
    return RecentFolder(
      id: map['id'] as int,
      folderPath: map['folder_path'] as String,
      lastVisited: DateTime.fromMillisecondsSinceEpoch(map['last_visited'] as int),
      imageCount: map['image_count'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folder_path': folderPath,
      'last_visited': lastVisited.millisecondsSinceEpoch,
      'image_count': imageCount,
    };
  }
}

/// 图片元数据缓存模型
class ImageMetadataCache {
  final String filePath;
  final int width;
  final int height;
  final int fileSize;
  final int modifiedTime; // milliseconds since epoch
  final String format;

  ImageMetadataCache({
    required this.filePath,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.modifiedTime,
    required this.format,
  });

  factory ImageMetadataCache.fromMap(Map<String, dynamic> map) {
    return ImageMetadataCache(
      filePath: map['file_path'] as String,
      width: map['width'] as int,
      height: map['height'] as int,
      fileSize: map['file_size'] as int,
      modifiedTime: map['modified_time'] as int,
      format: map['format'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'file_path': filePath,
        'width': width,
        'height': height,
        'file_size': fileSize,
        'modified_time': modifiedTime,
        'format': format,
      };
}
