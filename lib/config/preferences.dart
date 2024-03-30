import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static late SharedPreferences _preferences;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static SharedPreferences get instance => _preferences;
}

class PrefsKeys {
  static const String themeColor = 'THEME_COLOR';
  static const String string2 = 'String 2';
  static const String string3 = 'String 3';
}
