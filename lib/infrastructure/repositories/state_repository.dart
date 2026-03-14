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
      version: 1,
      onCreate: _createTables,
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
