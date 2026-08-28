import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

ThemeData colorSchema(
  Prefs prefsNotifier,
  BuildContext context,
  Brightness brightness,
) {
  brightness = prefsNotifier.isEInkMode
      ? Brightness.light
      : switch (prefsNotifier.themeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          ThemeMode.system => MediaQuery.platformBrightnessOf(context),
        };
  Color seedColor = prefsNotifier.themeColor;
  final isDark = brightness == Brightness.dark;
  final isEinkMode = prefsNotifier.isEInkMode;

  final lightGropedBackground = const Color(0xFFF2F2F7);
  final darkGropedBackground = prefsNotifier.effectiveTrueDarkMode
      ? Color(0xFF000000)
      : Color(0xFF1C1C1E);
  final gropedBackgroundColor = isEinkMode
      ? Colors.white
      : isDark
          ? darkGropedBackground
          : lightGropedBackground;

  final colorScheme = isEinkMode
      ? const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          primaryContainer: Colors.black,
          onPrimaryContainer: Colors.black,
          secondary: Colors.black,
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFE0E0E0),
          onSecondaryContainer: Colors.black,
          surface: Colors.white,
          onSurface: Colors.black,
        )
      : switch (brightness) {
          Brightness.light => ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.light,
              surfaceContainer: Color(0xFFFFFFFF),
              surface: lightGropedBackground,
            ),
          Brightness.dark => ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
              surfaceContainer: Color(0xFF2C2C2E),
              surface: darkGropedBackground,
            ),
        };

  ThemeData themeData = isEinkMode
      ? FlexThemeData.light(
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
          colorScheme: colorScheme)
      : switch (brightness) {
          Brightness.light => FlexThemeData.light(
              useMaterial3: true,
              swapLegacyOnMaterial3: true,
              colorScheme: colorScheme,
            ),
          Brightness.dark => FlexThemeData.dark(
              useMaterial3: true,
              swapLegacyOnMaterial3: true,
              darkIsTrueBlack: prefsNotifier.effectiveTrueDarkMode,
              colorScheme: colorScheme,
            )
        };

  return themeData
      .copyWith(
          splashFactory: isEinkMode ? NoSplash.splashFactory : null,
          splashColor: isEinkMode ? Colors.transparent : null,
          highlightColor: isEinkMode ? Colors.transparent : null,
          hoverColor: isEinkMode ? Colors.transparent : null,
          shadowColor: isEinkMode ? Colors.transparent : null,
          canvasColor: isEinkMode ? Colors.white : null,
          cardColor: isEinkMode ? Colors.white : null,
          dividerColor: isEinkMode ? Colors.black54 : null,
          disabledColor: isEinkMode ? const Color(0xFF757575) : null,
          pageTransitionsTheme: isEinkMode
              ? const PageTransitionsTheme(builders: {
                  TargetPlatform.android: _NoPageTransitionsBuilder(),
                  TargetPlatform.iOS: _NoPageTransitionsBuilder(),
                  TargetPlatform.macOS: _NoPageTransitionsBuilder(),
                  TargetPlatform.windows: _NoPageTransitionsBuilder(),
                  TargetPlatform.linux: _NoPageTransitionsBuilder(),
                })
              : null,
          appBarTheme: isEinkMode
              ? const AppBarTheme(
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  surfaceTintColor: Colors.transparent,
                )
              : null,
          cardTheme: isEinkMode
              ? CardThemeData(
                  elevation: 0,
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.black54),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : null,
          sliderTheme: const SliderThemeData(year2023: false),
          progressIndicatorTheme:
              const ProgressIndicatorThemeData(year2023: false),
          scaffoldBackgroundColor: gropedBackgroundColor,
          bottomSheetTheme: BottomSheetThemeData()
              .copyWith(backgroundColor: gropedBackgroundColor),
          drawerTheme: DrawerThemeData()
              .copyWith(backgroundColor: gropedBackgroundColor),
          dialogTheme: DialogThemeData().copyWith(
            backgroundColor: gropedBackgroundColor,
            elevation: isEinkMode ? 0 : null,
            surfaceTintColor: isEinkMode ? Colors.transparent : null,
            shape: isEinkMode
                ? RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
          ))
      .useSystemChineseFont(brightness);
}

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}
