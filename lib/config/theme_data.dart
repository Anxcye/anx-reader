import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  Color _themeColor = Colors.green;

  Color get themeColor => _themeColor;

  set themeColor(Color value) {
    _themeColor = value;
    notifyListeners();
  }

  Future<void> loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('themeColor') ?? Colors.green.value;
    themeColor = Color(colorValue);
  }

  Future<void> saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeColor', _themeColor.value);
  }
}