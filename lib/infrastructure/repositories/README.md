# Repositories

This directory contains repository implementations for data persistence.

## StateRepository

The `StateRepository` class manages application state persistence using two storage mechanisms:

### SharedPreferences (Lightweight Data)
- **Current folder path**: The folder currently being browsed
- **Scroll position**: The scroll position in the waterfall view

### SQLite (Structured Data)
- **Recent folders**: List of recently browsed folders (max 10)
- **Browse history**: History of viewed images
- **Cache metadata**: Metadata about cached thumbnails

## Database Schema

### recent_folders
```sql
CREATE TABLE recent_folders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  folder_path TEXT NOT NULL UNIQUE,
  last_visited INTEGER NOT NULL,
  image_count INTEGER
)
```

### browse_history
```sql
CREATE TABLE browse_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  image_path TEXT NOT NULL,
  viewed_at INTEGER NOT NULL,
  duration_seconds INTEGER
)
```

### cache_metadata
```sql
CREATE TABLE cache_metadata (
  cache_key TEXT PRIMARY KEY,
  original_path TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  last_accessed INTEGER NOT NULL
)
```

## Usage

```dart
// Initialize SharedPreferences
final prefs = await SharedPreferences.getInstance();

// Create repository
final repository = StateRepository(prefs);

// Initialize database
await repository.initialize();

// Save scroll position
await repository.saveScrollPosition(123.45);

// Get scroll position
final position = await repository.getScrollPosition();

// Save current folder
await repository.saveCurrentFolder('/home/user/Pictures');

// Get current folder
final folder = await repository.getCurrentFolder();

// Add recent folder
await repository.addRecentFolder('/home/user/Pictures', imageCount: 42);

// Get recent folders (max 10, ordered by last visited)
final recentFolders = await repository.getRecentFolders();

// Close database when done
await repository.close();
```

## Testing

For testing, use the in-memory database option:

```dart
await repository.initialize(inMemory: true);
```

This creates a temporary database that is automatically cleaned up when the connection is closed.

## Requirements Validation

This implementation satisfies the following requirements:

- **11.1**: Save current browsing folder path
- **11.2**: Save current scroll position
- **11.3**: Restore to last browsed folder on app restart
- **11.4**: Restore to last scroll position on app restart
- **11.5**: Save recent 10 folder paths
- **11.6**: Display recent browsed folders list
