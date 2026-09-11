import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Design tokens derived from [FThemeData] / Prefs, plus Anx-specific surfaces.
///
/// Prefer reading these through [AnxTheme.of] so call sites stay library-agnostic.
class AnxColors {
  const AnxColors({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.foreground,
    required this.card,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.destructive,
    required this.onDestructive,
    required this.groupedBackground,
    required this.surfaceContainer,
    required this.eInkMode,
  });

  factory AnxColors.fromForui(
    FThemeData theme, {
    required Color groupedBackground,
    required Color surfaceContainer,
    required bool eInkMode,
  }) {
    final c = theme.colors;
    return AnxColors(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.primaryForeground,
      secondary: c.secondary,
      onSecondary: c.secondaryForeground,
      background: c.background,
      foreground: c.foreground,
      card: c.card,
      muted: c.muted,
      mutedForeground: c.mutedForeground,
      border: c.border,
      destructive: c.destructive,
      onDestructive: c.destructiveForeground,
      groupedBackground: groupedBackground,
      surfaceContainer: surfaceContainer,
      eInkMode: eInkMode,
    );
  }

  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color foreground;
  final Color card;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color destructive;
  final Color onDestructive;

  /// iOS-ish grouped list background (settings / home shell).
  final Color groupedBackground;

  /// Raised surface used for cards / nav chrome.
  final Color surfaceContainer;

  final bool eInkMode;

  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;

  BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
}
