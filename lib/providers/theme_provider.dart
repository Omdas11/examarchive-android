import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_themes.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'app_theme';
  AppThemeName _theme = AppThemeName.system;
  bool _loaded = false;

  AppThemeName get theme => _theme;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      _theme = AppThemeName.values.firstWhere(
        (t) => t.name == raw,
        orElse: () => AppThemeName.system,
      );
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setTheme(AppThemeName theme) async {
    _theme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
  }
}
