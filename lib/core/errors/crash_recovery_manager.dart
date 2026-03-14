import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../logging/logger.dart';

/// Manages crash detection and state recovery
class CrashRecoveryManager {
  static const String _crashFlagKey = 'app_crashed';
  static const String _lastStateKey = 'last_browse_state';
  static const String _crashCountKey = 'crash_count';
  static const String _lastCrashTimeKey = 'last_crash_time';

  final Logger _logger = Logger();
  late final SharedPreferences _prefs;

  /// Initialize the crash recovery manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Mark that the app has started
  Future<void> markAppStarted() async {
    await _prefs.setBool(_crashFlagKey, true);
    _logger.debug('App marked as started');
  }

  /// Mark that the app closed normally
  Future<void> markAppClosedNormally() async {
    await _prefs.setBool(_crashFlagKey, false);
    _logger.debug('App marked as closed normally');
  }

  /// Check if the app crashed last time
  Future<bool> didCrashLastTime() async {
    final crashed = _prefs.getBool(_crashFlagKey) ?? false;
    
    if (crashed) {
      _logger.warning('Detected crash from previous session');
      await _incrementCrashCount();
    }
    
    return crashed;
  }

  /// Get the number of consecutive crashes
  Future<int> getCrashCount() async {
    return _prefs.getInt(_crashCountKey) ?? 0;
  }

  /// Increment crash count
  Future<void> _incrementCrashCount() async {
    final count = await getCrashCount();
    await _prefs.setInt(_crashCountKey, count + 1);
    await _prefs.setInt(
      _lastCrashTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Reset crash count
  Future<void> resetCrashCount() async {
    await _prefs.setInt(_crashCountKey, 0);
    _logger.info('Crash count reset');
  }

  /// Save current browse state
  Future<void> saveState(Map<String, dynamic> state) async {
    try {
      final stateJson = jsonEncode(state);
      await _prefs.setString(_lastStateKey, stateJson);
      _logger.debug('Browse state saved');
    } catch (e, stackTrace) {
      _logger.error('Failed to save state', e, stackTrace);
    }
  }

  /// Recover last browse state
  Future<Map<String, dynamic>?> recoverLastState() async {
    try {
      if (await didCrashLastTime()) {
        final stateJson = _prefs.getString(_lastStateKey);
        if (stateJson != null && stateJson.isNotEmpty) {
          _logger.info('Recovering state from previous session');
          return jsonDecode(stateJson) as Map<String, dynamic>;
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to recover state', e, stackTrace);
    }
    return null;
  }

  /// Clear saved state
  Future<void> clearSavedState() async {
    await _prefs.remove(_lastStateKey);
    _logger.debug('Saved state cleared');
  }

  /// Get last crash time
  Future<DateTime?> getLastCrashTime() async {
    final timestamp = _prefs.getInt(_lastCrashTimeKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Check if app is in crash loop (multiple crashes in short time)
  Future<bool> isInCrashLoop() async {
    final crashCount = await getCrashCount();
    if (crashCount < 3) return false;

    final lastCrashTime = await getLastCrashTime();
    if (lastCrashTime == null) return false;

    // Consider it a crash loop if 3+ crashes within 5 minutes
    final timeSinceLastCrash = DateTime.now().difference(lastCrashTime);
    return timeSinceLastCrash.inMinutes < 5;
  }

  /// Handle crash loop situation
  Future<void> handleCrashLoop() async {
    _logger.fatal('App is in crash loop, clearing all data');
    
    // Clear all saved state
    await clearSavedState();
    
    // Clear crash tracking
    await resetCrashCount();
    
    // Additional recovery actions can be added here
    // e.g., clear cache, reset settings, etc.
  }
}
