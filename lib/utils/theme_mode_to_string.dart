import 'package:flutter/material.dart';

String themeModeToString(ThemeMode themeMode) {
  print(themeMode.toString());
  switch (themeMode) {
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.light:
      return 'light';
    case ThemeMode.system:
      return 'auto';
    default:
      return 'auto';
  }
}
