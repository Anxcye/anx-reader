import 'dart:core';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/translate/google.dart';
import 'package:anx_reader/service/translate/microsoft.dart';
import 'package:flutter/material.dart';

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

enum LangList {
  auto('Auto', 'Auto'),
  english('en', 'English'),
  simplifiedChinese('zh-CN', '简体中文'),
  traditionalChinese('zh-TW', '繁體中文'),
  arabic('ar', 'العربية'),
  bulgarian('bg', 'Български'),
  catalan('ca', 'Català'),
  croatian('hr', 'Hrvatski'),
  czech('cs', 'Čeština'),
  danish('da', 'Dansk'),
  dutch('nl', 'Nederlands'),
  finnish('fi', 'Suomi'),
  french('fr', 'Français'),
  german('de', 'Deutsch'),
  greek('el', 'Ελληνικά'),
  hindi('hi', 'हिन्दी'),
  hungarian('hu', 'Magyar'),
  indonesian('id', 'Indonesia'),
  italian('it', 'Italiano'),
  japanese('ja', '日本語'),
  korean('ko', '한국어'),
  malay('ms', 'Melayu'),
  maltese('mt', 'Malti'),
  norwegian('nb', 'Norsk Bokmål'),
  polish('pl', 'Polski'),
  portuguese('pt', 'Português'),
  romanian('ro', 'Română'),
  russian('ru', 'Русский'),
  slovak('sk', 'Slovenčina'),
  slovenian('sl', 'Slovenščina'),
  spanish('es', 'Español'),
  swedish('sv', 'Svenska'),
  tamil('ta', 'தமிழ்'),
  telugu('te', 'తెలుగు'),
  thai('th', 'ไทย'),
  turkish('tr', 'Türkçe'),
  ukrainian('uk', 'Українська'),
  vietnamese('vi', 'Tiếng Việt');

  const LangList(this.code, this.nativeName);

  final String code;
  final String nativeName;

  String getNative(BuildContext context) => this == LangList.auto
      ? L10n.of(context).settings_translate_auto
      : nativeName;
}

LangList getLang(String code) {
  return LangList.values
      .firstWhere((e) => e.code == code, orElse: () => LangList.english);
}

Future<String> translateText(String text, {TranslateService? service}) async {
  service ??= Prefs().translateService;
  LangList from = Prefs().translateFrom;
  LangList to = Prefs().translateTo;

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
    default:
      throw Exception('Unsupported translate service: $service');
  }
}
