import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/theme/anx_colors.dart';
import 'package:anx_reader/theme/anx_theme.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Builds Material [ThemeData] aligned with the active Forui-backed [AnxTheme].
///
/// Forui 0.26's [FThemeData.toApproximateMaterialTheme] returns
/// `package:material_ui` [ThemeData], which is a different type from
/// `package:flutter/material.dart` [ThemeData] used by this app. We therefore
/// map [AnxColors] into a Flutter [ColorScheme] and keep FlexColorScheme as the
/// Material builder so leftover Material widgets track Forui tokens without a
/// full `material_ui` migration.
ThemeData colorSchema(
  Prefs prefsNotifier,
  BuildContext context,
  Brightness brightness,
) {
  brightness = prefsNotifier.eInkMode
      ? Brightness.light
      : switch (prefsNotifier.themeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          ThemeMode.system => brightness,
        };

  final anx = AnxTheme.fromPrefs(prefsNotifier, brightness: brightness);
  final isEinkMode = prefsNotifier.eInkMode;
  final tokens = anx.colors;
  final isDark = tokens.brightness == Brightness.dark;

  final colorScheme = ColorScheme(
    brightness: tokens.brightness,
    primary: tokens.primary,
    onPrimary: tokens.onPrimary,
    secondary: tokens.secondary,
    onSecondary: tokens.onSecondary,
    error: tokens.destructive,
    onError: tokens.onDestructive,
    surface: tokens.groupedBackground,
    onSurface: tokens.foreground,
    surfaceContainer: tokens.surfaceContainer,
    surfaceContainerHighest: tokens.muted,
    outline: tokens.border,
  );

  ThemeData themeData = isEinkMode || !isDark
      ? FlexThemeData.light(
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
          colorScheme: colorScheme,
        )
      : FlexThemeData.dark(
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
          darkIsTrueBlack: prefsNotifier.trueDarkMode,
          colorScheme: colorScheme,
        );

  themeData = themeData.copyWith(
    scaffoldBackgroundColor: tokens.groupedBackground,
    bottomSheetTheme: const BottomSheetThemeData().copyWith(
      backgroundColor: tokens.groupedBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AnxColors.radiusLg),
        ),
      ),
    ),
    drawerTheme: const DrawerThemeData()
        .copyWith(backgroundColor: tokens.groupedBackground),
    dialogTheme: const DialogThemeData()
        .copyWith(backgroundColor: tokens.surfaceContainer),
    cardTheme: CardThemeData(
      color: tokens.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AnxColors.radiusMd),
        side: BorderSide(color: tokens.border.withValues(alpha: 0.6)),
      ),
    ),
    sliderTheme: const SliderThemeData(year2023: false),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(year2023: false),
    // #986: strip Material motion on e-ink to avoid ghosting / extra refreshes
    splashFactory: isEinkMode ? NoSplash.splashFactory : themeData.splashFactory,
    highlightColor:
        isEinkMode ? Colors.transparent : themeData.highlightColor,
    pageTransitionsTheme: isEinkMode
        ? PageTransitionsTheme(
            builders: {
              for (final platform in TargetPlatform.values)
                platform: const _NoAnimationPageTransitionsBuilder(),
            },
          )
        : themeData.pageTransitionsTheme,
  );

  return themeData.useSystemChineseFont(tokens.brightness);
}

class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
