import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesProvider extends ChangeNotifier {
  late SharedPreferences prefs;
  static final SharedPreferencesProvider _instance =
      SharedPreferencesProvider._internal();

  factory SharedPreferencesProvider() {
    return _instance;
  }

  SharedPreferencesProvider._internal() {
    initPrefs();
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    notifyListeners();
  }

  Color get themeColor {
    int colorValue = prefs.getInt('themeColor') ?? Colors.green.value;
    return Color(colorValue);
  }

  Future<void> saveThemeToPrefs(int colorValue) async {
    await prefs.setInt('themeColor', colorValue);
    notifyListeners();
  }

  Locale? get locale {
    String? localeCode = prefs.getString('locale');
    if (localeCode == null) return null;
    return Locale(localeCode);
  }

  Future<void> saveLocaleToPrefs(String localeCode) async {
    await prefs.setString('locale', localeCode);
    notifyListeners();
  }

  ThemeMode get themeMode {
    String themeMode = prefs.getString('themeMode') ?? 'system';
    switch (themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeModeToPrefs(String themeMode) async {
    await prefs.setString('themeMode', themeMode);
    notifyListeners();
  }
}
