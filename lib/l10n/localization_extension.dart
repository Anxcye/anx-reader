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
      AppLocalizations.of(this)?.settings_dark_mode ?? '';

  String get settingsSystemMode =>
      AppLocalizations.of(this)?.settings_system_mode ?? '';

  String get settingsLightMode =>
      AppLocalizations.of(this)?.settings_light_mode ?? '';

  String get settingsMoreSettings =>
      AppLocalizations.of(this)?.settings_moreSettings ?? '';

  String get appearance => AppLocalizations.of(this)?.settings_appearance ?? '';

  String get appearanceTheme =>
      AppLocalizations.of(this)?.settings_appearance_theme ?? '';

  String get appearanceThemeColor =>
      AppLocalizations.of(this)?.settings_appearance_themeColor ?? '';

  String get appearanceDisplay =>
      AppLocalizations.of(this)?.settings_appearance_display ?? '';

  String get appearanceLanguage =>
      AppLocalizations.of(this)?.settings_appearance_language ?? '';

  String get readingContents =>
      AppLocalizations.of(this)?.reading_contents ?? '';

  String get statisticToPresent =>
      AppLocalizations.of(this)?.statistic_to_present ?? '';

  String get statisticBooksRead =>
      AppLocalizations.of(this)?.statistic_books_read ?? '';

  String get statisticDaysOfReading =>
      AppLocalizations.of(this)?.statistic_days_of_reading ?? '';

  String get statisticNotes => AppLocalizations.of(this)?.statistic_notes ?? '';

  String get statisticWeek => AppLocalizations.of(this)?.statistic_week ?? '';

  String get statisticMonth => AppLocalizations.of(this)?.statistic_month ?? '';

  String get statisticYear => AppLocalizations.of(this)?.statistic_year ?? '';

  String get statisticHours => AppLocalizations.of(this)?.statistic_hours ?? '';

  String get statisticMinutes =>
      AppLocalizations.of(this)?.statistic_minutes ?? '';

  String get statisticThisWeek =>
      AppLocalizations.of(this)?.statistic_this_week ?? '';

  String get statisticMonday => AppLocalizations.of(this)?.statistic_monday ?? '';

  String get statisticTuesday =>
      AppLocalizations.of(this)?.statistic_tuesday ?? '';

  String get statisticWednesday =>
      AppLocalizations.of(this)?.statistic_wednesday ?? '';

  String get statisticThursday =>
      AppLocalizations.of(this)?.statistic_thursday ?? '';

  String get statisticFriday =>
      AppLocalizations.of(this)?.statistic_friday ?? '';

  String get statisticSaturday =>
      AppLocalizations.of(this)?.statistic_saturday ?? '';

  String get statisticSunday =>
      AppLocalizations.of(this)?.statistic_sunday ?? '';
}

