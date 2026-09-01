import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;
  bool _initialized = false;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.themeKey);
    if (saved == 'light') {
      _mode = ThemeMode.light;
    } else {
      _mode = ThemeMode.dark; // Default to the brand's dark theme
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.themeKey, mode.name);
    notifyListeners();
  }

  Future<void> toggle() =>
      setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
