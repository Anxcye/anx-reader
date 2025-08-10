import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:flutter/material.dart';

enum LangListEnum {
  auto('Auto', 'Auto'),
  english('en', 'English'),
  simplifiedChinese('zh-CN', '简体中文'),
  traditionalChinese('zh-TW', '繁體中文'),
  arabic('ar', 'العربية'),
  bulgarian('bg', 'Български'),
  catalan('ca', 'Català'),
  crimeanTatarLatin('crh-Latn', 'Qırımtatarca'),
  crimeanTatarCyrillic('crh', 'Къырымтатарджа'),
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

  const LangListEnum(this.code, this.nativeName);

  final String code;
  final String nativeName;

  String getNative(BuildContext context) => this == LangListEnum.auto
      ? L10n.of(context).settingsTranslateAuto
      : nativeName;
}

LangListEnum getLang(String code) {
  if (code == 'auto') return LangListEnum.auto;

  return LangListEnum.values
      .firstWhere((e) => e.code == code, orElse: () => LangListEnum.english);
}
