import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

ThemeData colorSchema(
    Prefs prefsNotifier, BuildContext context, Brightness brightness) {
    brightness = prefsNotifier.eInkMode
        ? Brightness.light
        : switch (prefsNotifier.themeMode) {
            ThemeMode.light => Brightness.light,
            ThemeMode.dark => Brightness.dark,
            ThemeMode.system => MediaQuery.platformBrightnessOf(context),
          };
    Color seedColor = prefsNotifier.themeColor;

  final colorScheme = prefsNotifier.eInkMode
      ? const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.grey,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        )
      : switch (brightness) {
          Brightness.light => ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.light,
              surfaceContainer: Color(0xFFFFFFFF),
              surface: Color(0xFFF2F2F7),
            ),
          Brightness.dark => ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
              surfaceContainer: Color(0xFF2C2C2E),
              surface: Color(0xFF1C1C1E),
            ),
        };

  ThemeData themeData = prefsNotifier.eInkMode
      ? FlexThemeData.light(
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
          colorScheme: colorScheme)
      : switch (brightness) {
          Brightness.light => FlexThemeData.light(
              useMaterial3: true,
              swapLegacyOnMaterial3: true,
              colorScheme: colorScheme,
            ).copyWith(
              scaffoldBackgroundColor: Color(0xFFF2F2F7),
            ),
          Brightness.dark => FlexThemeData.dark(
              useMaterial3: true,
              swapLegacyOnMaterial3: true,
              darkIsTrueBlack: prefsNotifier.trueDarkMode,
              colorScheme: colorScheme,
            ).copyWith(
              scaffoldBackgroundColor: prefsNotifier.trueDarkMode
                  ? Color(0xFF000000)
                  : Color(0xFF1C1C1E),
            ),
        };

  return themeData
      .copyWith(
        sliderTheme: const SliderThemeData(year2023: false),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(year2023: false),
      )
      .useSystemChineseFont(brightness);
}
