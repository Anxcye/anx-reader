import 'dart:core';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/service/translate/google.dart';
import 'package:anx_reader/service/translate/microsoft.dart';

enum TranslateService {
  google('Google'),
  microsoft('Microsoft');
  // baidu('Baidu'),
  // tencent('Tencent'),
  // deepl('Deepl'),
  // openai('OpenAI');

  const TranslateService(this.label);

  final String label;
}

TranslateService getTranslateService(String name) {
  return TranslateService.values.firstWhere((e) => e.name == name);
}



Future<String> translateText(String text, {TranslateService? service}) async {
  service ??= Prefs().translateService;
  LangListEnum from = Prefs().translateFrom;
  LangListEnum to = Prefs().translateTo;

  switch (service) {
    case TranslateService.google:
      return await googleTranslateService(text, from, to);
    case TranslateService.microsoft:
      return await microsoftTranslateService(text, from, to);
    // case TranslateService.baidu:
    // return TranslateApi().baidu(text);
    // case TranslateService.tencent:
    // return TranslateApi().tencent(text);
    // case TranslateService.deepl:
    // return TranslateApi().deepl(text);
    // case TranslateService.openai:
    // return TranslateApi().openai(text);
  }
}
