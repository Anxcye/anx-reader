import 'dart:core';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/service/translate/google.dart';
import 'package:anx_reader/service/translate/microsoft.dart';

enum TranslateService {
  google('Google'),
  microsoft('Microsoft');

  const TranslateService(this.label);

  final String label;
}

TranslateService getTranslateService(String name) {
  return TranslateService.values.firstWhere((e) => e.name == name);
}

abstract class TranslateServiceProvider {
  Stream<String> translate(String text, LangListEnum from, LangListEnum to);
}

class TranslateFactory {
  static TranslateServiceProvider getProvider(TranslateService service) {
    switch (service) {
      case TranslateService.google:
        return GoogleTranslateProvider();
      case TranslateService.microsoft:
        return MicrosoftTranslateProvider();
    }
  }
}

Stream<String> translateText(String text, {TranslateService? service}) {
  service ??= Prefs().translateService;
  final from = Prefs().translateFrom;
  final to = Prefs().translateTo;

  return TranslateFactory.getProvider(service).translate(text, from, to);
}
