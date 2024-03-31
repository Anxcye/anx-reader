import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension LocalizationExtension on BuildContext {
  String get appName => AppLocalizations.of(this)?.appName ?? '';

  String get navBarBookshelf =>
      AppLocalizations.of(this)?.navBar_bookshelf ?? '';

  String get navBarStatistics =>
      AppLocalizations.of(this)?.navBar_statistics ?? '';

  String get navBarNotes => AppLocalizations.of(this)?.navBar_notes ?? '';

  String get navBarSettings => AppLocalizations.of(this)?.navBar_settings ?? '';

  String get settingsDarkMode =>
      AppLocalizations.of(this)?.settings_darkMode ?? '';

  String get settingsMoreSettings =>
      AppLocalizations.of(this)?.settings_moreSettings ?? '';

  String get appearance =>
      AppLocalizations.of(this)?.settings_appearance ?? '';

  String get appearanceTheme =>
      AppLocalizations.of(this)?.settings_appearance_theme ?? '';

  String get appearanceThemeColor =>
      AppLocalizations.of(this)?.settings_appearance_themeColor ?? '';

  String get appearanceDisplay =>
      AppLocalizations.of(this)?.settings_appearance_display ?? '';

  String get appearanceLanguage =>
      AppLocalizations.of(this)?.settings_appearance_language ?? '';
}