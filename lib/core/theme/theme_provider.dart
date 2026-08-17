import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes the user's preferred [ThemeMode].
///
/// Light mode is the SkillCubes default.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs) {
    final raw = _prefs.getString(_key);
    _mode = switch (raw) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  static const _key = 'theme_mode';

  final SharedPreferences _prefs;
  late ThemeMode _mode;

  ThemeMode get themeMode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    await _prefs.setString(
      _key,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
      },
    );
    notifyListeners();
  }

  Future<void> toggleDarkLight() async {
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
