import 'dart:io';
import 'package:anx_reader/config/shared_preference_provider.dart';

String getCurrentLanguageCode() {
  String? locale = Prefs().locale?.languageCode;

  if (locale == null) {
    return Platform.localeName.split('_')[0];
  }
  return locale;
}

