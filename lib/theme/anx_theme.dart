import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/theme/anx_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// Builds Forui [FThemeData] from Anx [Prefs] (seed color, dark / true-black, e-ink).
class AnxTheme {
  const AnxTheme._({
    required this.forui,
    required this.colors,
    required this.eInkMode,
  });

  final FThemeData forui;
  final AnxColors colors;
  final bool eInkMode;

  static AnxTheme of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_AnxThemeScope>();
    if (inherited != null) return inherited.theme;
    // Fallback when outside the app root (tests / early frames).
    return fromPrefs(
      Prefs(),
      brightness: Theme.brightnessOf(context),
    );
  }

  static AnxTheme fromPrefs(
    Prefs prefs, {
    required Brightness brightness,
    bool? touch,
  }) {
    final eInk = prefs.eInkMode;
    final effectiveBrightness = eInk ? Brightness.light : brightness;
    final isDark = effectiveBrightness == Brightness.dark;
    final useTouch = touch ??
        const {
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.fuchsia,
        }.contains(defaultTargetPlatform);

    final grouped = _groupedBackground(
      isDark: isDark,
      eInk: eInk,
      trueDark: prefs.trueDarkMode,
    );
    final surfaceContainer = _surfaceContainer(
      isDark: isDark,
      eInk: eInk,
      trueDark: prefs.trueDarkMode,
    );

    final fColors = _buildColors(
      seed: prefs.themeColor,
      isDark: isDark,
      eInk: eInk,
      trueDark: prefs.trueDarkMode,
      grouped: grouped,
      surfaceContainer: surfaceContainer,
    );

    final forui = FThemeData(
      touch: useTouch,
      debugLabel: eInk
          ? 'Anx E-Ink'
          : (isDark ? 'Anx Dark' : 'Anx Light'),
      colors: fColors,
    );

    return AnxTheme._(
      forui: forui,
      colors: AnxColors.fromForui(
        forui,
        groupedBackground: grouped,
        surfaceContainer: surfaceContainer,
        eInkMode: eInk,
      ),
      eInkMode: eInk,
    );
  }

  static Color _groupedBackground({
    required bool isDark,
    required bool eInk,
    required bool trueDark,
  }) {
    if (eInk) return Colors.white;
    if (isDark) {
      return trueDark ? const Color(0xFF000000) : const Color(0xFF1C1C1E);
    }
    return const Color(0xFFF2F2F7);
  }

  static Color _surfaceContainer({
    required bool isDark,
    required bool eInk,
    required bool trueDark,
  }) {
    if (eInk) return Colors.white;
    if (isDark) {
      return trueDark ? const Color(0xFF0A0A0A) : const Color(0xFF2C2C2E);
    }
    return const Color(0xFFFFFFFF);
  }

  static FColors _buildColors({
    required Color seed,
    required bool isDark,
    required bool eInk,
    required bool trueDark,
    required Color grouped,
    required Color surfaceContainer,
  }) {
    if (eInk) {
      return FColors.neutralLight.copyWith(
        brightness: Brightness.light,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        barrier: const Color(0x33000000),
        background: Colors.white,
        foreground: Colors.black,
        primary: Colors.black,
        primaryForeground: Colors.white,
        secondary: const Color(0xFFE8E8E8),
        secondaryForeground: Colors.black,
        muted: const Color(0xFFF0F0F0),
        mutedForeground: const Color(0xFF444444),
        destructive: Colors.black,
        destructiveForeground: Colors.white,
        error: Colors.black,
        errorForeground: Colors.white,
        card: Colors.white,
        border: Colors.black,
      );
    }

    final onSeed = _onColor(seed);
    if (isDark) {
      final base = FColors.neutralDark;
      return base.copyWith(
        background: trueDark ? const Color(0xFF000000) : grouped,
        foreground: base.foreground,
        primary: seed,
        primaryForeground: onSeed,
        secondary: surfaceContainer,
        secondaryForeground: base.foreground,
        muted: surfaceContainer,
        card: surfaceContainer,
        border: base.border,
      );
    }

    final base = FColors.neutralLight;
    return base.copyWith(
      background: grouped,
      foreground: base.foreground,
      primary: seed,
      primaryForeground: onSeed,
      secondary: const Color(0xFFEFEFF4),
      secondaryForeground: base.foreground,
      muted: const Color(0xFFEFEFF4),
      card: surfaceContainer,
      border: base.border,
    );
  }

  static Color _onColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}

/// Places [AnxTheme] in the tree next to [FTheme] so facades can read tokens.
class AnxThemeProvider extends StatelessWidget {
  const AnxThemeProvider({
    super.key,
    required this.theme,
    required this.child,
  });

  final AnxTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _AnxThemeScope(
      theme: theme,
      child: FTheme(
        data: theme.forui,
        child: child,
      ),
    );
  }
}

class _AnxThemeScope extends InheritedWidget {
  const _AnxThemeScope({
    required this.theme,
    required super.child,
  });

  final AnxTheme theme;

  @override
  bool updateShouldNotify(_AnxThemeScope oldWidget) =>
      theme.forui != oldWidget.theme.forui ||
      theme.eInkMode != oldWidget.theme.eInkMode;
}
