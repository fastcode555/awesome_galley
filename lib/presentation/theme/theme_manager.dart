import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages application theme mode (light/dark)
/// 
/// Provides theme switching functionality and persists user preference.
/// 
/// Requirements: Task 24.1
class ThemeManager extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  final SharedPreferences _prefs;

  ThemeManager(this._prefs) {
    _loadThemeMode();
  }

  /// Current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Check if dark mode is active
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Check if light mode is active
  bool get isLightMode => _themeMode == ThemeMode.light;

  /// Check if system mode is active
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Load theme mode from preferences
  Future<void> _loadThemeMode() async {
    final modeString = _prefs.getString(_themeModeKey);
    if (modeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == modeString,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  /// Set theme mode and persist preference
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _prefs.setString(_themeModeKey, mode.toString());
    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// Set to light mode
  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Set to dark mode
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Set to system mode (follow system theme)
  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }
}
