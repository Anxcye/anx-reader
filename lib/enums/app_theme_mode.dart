import 'package:flutter/material.dart';

enum AppThemeMode {
  system('auto'),
  dark('dark'),
  light('light'),
  // Kept only while old preferences and callers migrate to the independent
  // device display profile. New UI must not offer this as a color theme.
  eInk('eInk');

  const AppThemeMode(this.code);

  final String code;

  static AppThemeMode fromCode(String? code) => switch (code) {
        'dark' => dark,
        'light' => light,
        'eInk' => eInk,
        _ => system,
      };

  ThemeMode get effectiveThemeMode => switch (this) {
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.light || AppThemeMode.eInk => ThemeMode.light,
        AppThemeMode.system => ThemeMode.system,
      };
}
