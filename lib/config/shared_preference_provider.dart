import 'dart:convert';
import 'dart:core';

import 'package:anx_reader/enums/ai_prompts.dart';
import 'package:anx_reader/enums/convert_chinese_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/font_model.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/models/reading_info.dart';
import 'package:anx_reader/models/reading_rules.dart';
import 'package:anx_reader/models/window_info.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/utils/get_current_language_code.dart';
import 'package:anx_reader/utils/tts_model_list.dart';
import 'package:anx_reader/widgets/reading_page/style_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs extends ChangeNotifier {
  late SharedPreferences prefs;
  static final Prefs _instance = Prefs._internal();

  factory Prefs() {
    return _instance;
  }

  Prefs._internal() {
    initPrefs();
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    saveBeginDate();
    notifyListeners();
  }

  Color get themeColor {
    int colorValue = prefs.getInt('themeColor') ?? Colors.blue.value;
    return Color(colorValue);
  }

  Future<void> saveThemeToPrefs(int colorValue) async {
    await prefs.setInt('themeColor', colorValue);
    notifyListeners();
  }

  Locale? get locale {
    String? localeCode = prefs.getString('locale');
    if (localeCode == null || localeCode == 'System') return null;
    if (localeCode.contains('-')) {
      List<String> codes = localeCode.split('-');
      return Locale(codes[0], codes[1]);
    }
    return Locale(localeCode);
  }

  Future<void> saveLocaleToPrefs(String localeCode) async {
    await prefs.setString('locale', localeCode);
    notifyListeners();
  }

  ThemeMode get themeMode {
    String themeMode = prefs.getString('themeMode') ?? 'system';
    switch (themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeModeToPrefs(String themeMode) async {
    await prefs.setString('themeMode', themeMode);
    notifyListeners();
  }

  Future<void> saveBookStyleToPrefs(BookStyle bookStyle) async {
    await prefs.setString('readStyle', bookStyle.toJson());
    notifyListeners();
  }

  BookStyle get bookStyle {
    String? bookStyleJson = prefs.getString('readStyle');
    if (bookStyleJson == null) return BookStyle();
    return BookStyle.fromJson(bookStyleJson);
  }

  void removeBookStyle() {
    prefs.remove('readStyle');
    notifyListeners();
  }

  void saveReadThemeToPrefs(ReadTheme readTheme) {
    prefs.setString('readTheme', readTheme.toJson());
    notifyListeners();
  }

  ReadTheme get readTheme {
    String? readThemeJson = prefs.getString('readTheme');
    if (readThemeJson == null) {
      return ReadTheme(
          backgroundColor: 'FFFBFBF3',
          textColor: 'FF343434',
          backgroundImagePath: '');
    }
    return ReadTheme.fromJson(readThemeJson);
  }

  void saveBeginDate() {
    String? beginDate = prefs.getString('beginDate');
    if (beginDate == null) {
      prefs.setString('beginDate', DateTime.now().toIso8601String());
    }
  }

  DateTime? get beginDate {
    String? beginDateStr = prefs.getString('beginDate');
    if (beginDateStr == null) return null;
    return DateTime.parse(beginDateStr);
  }

  void saveWebdavInfo(Map webdavInfo) {
    prefs.setString('webdavInfo', jsonEncode(webdavInfo));
    notifyListeners();
  }

  Map get webdavInfo {
    String? webdavInfoJson = prefs.getString('webdavInfo');
    if (webdavInfoJson == null) {
      return {};
    }
    return jsonDecode(webdavInfoJson);
  }

  void saveWebdavStatus(bool status) {
    prefs.setBool('webdavStatus', status);
    notifyListeners();
  }

  bool get webdavStatus {
    return prefs.getBool('webdavStatus') ?? false;
  }

  void saveClearLogWhenStart(bool status) {
    prefs.setBool('clearLogWhenStart', status);
    notifyListeners();
  }

  bool get clearLogWhenStart {
    return prefs.getBool('clearLogWhenStart') ?? true;
  }

  void saveHideStatusBar(bool status) {
    prefs.setBool('hideStatusBar', status);
    notifyListeners();
  }

  bool get hideStatusBar {
    return prefs.getBool('hideStatusBar') ?? true;
  }

  set awakeTime(int minutes) {
    prefs.setInt('awakeTime', minutes);
    notifyListeners();
  }

  int get awakeTime {
    return prefs.getInt('awakeTime') ?? 5;
  }

  set lastShowUpdate(DateTime time) {
    prefs.setString('lastShowUpdate', time.toIso8601String());
    notifyListeners();
  }

  DateTime get lastShowUpdate {
    String? lastShowUpdateStr = prefs.getString('lastShowUpdate');
    if (lastShowUpdateStr == null) return DateTime(1970, 1, 1);
    return DateTime.parse(lastShowUpdateStr);
  }

  set pageTurningType(int type) {
    prefs.setInt('pageTurningType', type);
    notifyListeners();
  }

  int get pageTurningType {
    return prefs.getInt('pageTurningType') ?? 0;
  }

  set annotationType(String style) {
    prefs.setString('annotationType', style);
    notifyListeners();
  }

  String get annotationType {
    return prefs.getString('annotationType') ?? 'highlight';
  }

  set annotationColor(String color) {
    prefs.setString('annotationColor', color);
    notifyListeners();
  }

  String get annotationColor {
    return prefs.getString('annotationColor') ?? '66CCFF';
  }

  set ttsVolume(double volume) {
    prefs.setDouble('ttsVolume', volume);
    notifyListeners();
  }

  double get ttsVolume {
    return prefs.getDouble('ttsVolume') ?? 1.0;
  }

  set ttsPitch(double pitch) {
    prefs.setDouble('ttsPitch', pitch);
    notifyListeners();
  }

  double get ttsPitch {
    return prefs.getDouble('ttsPitch') ?? 1.0;
  }

  set ttsRate(double rate) {
    prefs.setDouble('ttsRate', rate);
    notifyListeners();
  }

  double get ttsRate {
    return prefs.getDouble('ttsRate') ?? 1.0;
  }

  set ttsVoiceModel(String shortName) {
    prefs.setString('ttsVoiceModel', shortName);
    notifyListeners();
  }

  void removeTtsVoiceModel() {
    prefs.remove('ttsVoiceModel');
    notifyListeners();
  }

  String get ttsVoiceModel {
    String? model = prefs.getString('ttsVoiceModel');
    if (model == null) {
      final languageCode = getCurrentLanguageCode().toLowerCase();

      final data = ttsModelList;

      for (var voice in data) {
        String voiceLocale = voice['Locale'] as String;
        if (voiceLocale.toLowerCase().startsWith(languageCode.toLowerCase())) {
          model = voice['ShortName'] as String;
          break;
        }
      }

      if (model == null || model.isEmpty) {
        for (var voice in data) {
          String voiceLocale = voice['Locale'] as String;
          if (voiceLocale.startsWith('en-')) {
            model = voice['ShortName'] as String;
            break;
          }
        }
      }

      if (model == null || model.isEmpty) {
        model = 'en-US-JennyNeural';
      }
    }
    return model;
  }

  set pageTurnStyle(PageTurn style) {
    prefs.setString('pageTurnStyle', style.name);
    notifyListeners();
  }

  PageTurn get pageTurnStyle {
    String? style = prefs.getString('pageTurnStyle');
    if (style == null) return PageTurn.slide;
    return PageTurn.values.firstWhere((element) => element.name == style);
  }

  set font(FontModel font) {
    prefs.setString('font', font.toJson());
    notifyListeners();
  }

  FontModel get font {
    String? fontJson = prefs.getString('font');
    BuildContext context = navigatorKey.currentContext!;
    if (fontJson == null) {
      return FontModel(
          label: L10n.of(context).follow_book, name: 'book', path: '');
    }
    return FontModel.fromJson(fontJson);
  }

  set trueDarkMode(bool status) {
    prefs.setBool('trueDarkMode', status);
    notifyListeners();
  }

  bool get trueDarkMode {
    return prefs.getBool('trueDarkMode') ?? false;
  }

  set translateService(TranslateService service) {
    prefs.setString('translateService', service.name);
    notifyListeners();
  }

  TranslateService get translateService {
    return getTranslateService(
        prefs.getString('translateService') ?? 'microsoft');
  }

  set translateFrom(LangList from) {
    prefs.setString('translateFrom', from.code);
    notifyListeners();
  }

  LangList get translateFrom {
    return getLang(prefs.getString('translateFrom') ?? 'auto');
  }

  set translateTo(LangList to) {
    prefs.setString('translateTo', to.code);
    notifyListeners();
  }

  LangList get translateTo {
    return getLang(prefs.getString('translateTo') ?? 'en');
  }

  set autoTranslateSelection(bool status) {
    prefs.setBool('autoTranslateSelection', status);
    notifyListeners();
  }

  bool get autoTranslateSelection {
    return prefs.getBool('autoTranslateSelection') ?? true;
  }

  // set convertChineseMode(ConvertChineseMode mode) {
  //   prefs.setString('convertChineseMode', mode.name);
  //   notifyListeners();
  // }

  // ConvertChineseMode get convertChineseMode {
  //   return getConvertChineseMode(
  //       prefs.getString('convertChineseMode') ?? 'none');
  // }

  set readingRules(ReadingRules rules) {
    prefs.setString('readingRules', rules.toJson().toString());
    notifyListeners();
  }

  ReadingRules get readingRules {
    String? rulesJson = prefs.getString('readingRules');
    if (rulesJson == null) {
      return ReadingRules(
        convertChineseMode: ConvertChineseMode.none,
        bionicReading: false,
      );
    }
    return ReadingRules.fromJson(rulesJson);
  }

  set windowInfo(WindowInfo info) {
    prefs.setString('windowInfo', jsonEncode(info.toJson()));
    notifyListeners();
  }

  WindowInfo get windowInfo {
    String? windowInfoJson = prefs.getString('windowInfo');
    if (windowInfoJson == null) {
      return const WindowInfo(x: 0, y: 0, width: 0, height: 0);
    }
    return WindowInfo.fromJson(jsonDecode(windowInfoJson));
  }

  void saveAiConfig(String identifier, Map<String, String> config) {
    prefs.setString('aiConfig_$identifier', jsonEncode(config));
    notifyListeners();
  }

  Map<String, String> getAiConfig(String identifier) {
    String? aiConfigJson = prefs.getString('aiConfig_$identifier');
    if (aiConfigJson == null) {
      return {};
    }
    Map<String, dynamic> decoded = jsonDecode(aiConfigJson);
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  set selectedAiService(String identifier) {
    prefs.setString('selectedAiService', identifier);
    notifyListeners();
  }

  String get selectedAiService {
    return prefs.getString('selectedAiService') ?? 'openai';
  }

  void deleteAiConfig(String identifier) {
    prefs.remove('aiConfig_$identifier');
    notifyListeners();
  }

  void saveAiPrompt(AiPrompts identifier, String prompt) {
    prefs.setString('aiPrompt_${identifier.name}', prompt);
    notifyListeners();
  }

  String getAiPrompt(AiPrompts identifier) {
    String? aiPrompt = prefs.getString('aiPrompt_${identifier.name}');
    if (aiPrompt == null) {
      return identifier.getPrompt();
    }
    return aiPrompt;
  }

  void deleteAiPrompt(AiPrompts identifier) {
    prefs.remove('aiPrompt_${identifier.name}');
    notifyListeners();
  }

  set autoSummaryPreviousContent(bool status) {
    prefs.setBool('autoSummaryPreviousContent', status);
    notifyListeners();
  }

  bool get autoSummaryPreviousContent {
    return prefs.getBool('autoSummaryPreviousContent') ?? false;
  }

  set autoAdjustReadingTheme(bool status) {
    prefs.setBool('autoAdjustReadingTheme', status);
    notifyListeners();
  }

  bool get autoAdjustReadingTheme {
    return prefs.getBool('autoAdjustReadingTheme') ?? false;
  }

  set maxAiCacheCount(int count) {
    prefs.setInt('maxAiCacheCount', count);
    notifyListeners();
  }

  int get maxAiCacheCount {
    return prefs.getInt('maxAiCacheCount') ?? 300;
  }

  set volumeKeyTurnPage(bool status) {
    prefs.setBool('volumeKeyTurnPage', status);
    notifyListeners();
  }

  bool get volumeKeyTurnPage {
    return prefs.getBool('volumeKeyTurnPage') ?? false;
  }

  set bookCoverWidth(double width) {
    prefs.setDouble('bookCoverWidth', width);
    notifyListeners();
  }

  double get bookCoverWidth {
    return prefs.getDouble('bookCoverWidth') ?? 120;
  }

  set openBookAnimation(bool status) {
    prefs.setBool('openBookAnimation', status);
    notifyListeners();
  }

  bool get openBookAnimation {
    return prefs.getBool('openBookAnimation') ?? true;
  }

  set onlySyncWhenWifi(bool status) {
    prefs.setBool('onlySyncWhenWifi', status);
    notifyListeners();
  }

  bool get onlySyncWhenWifi {
    return prefs.getBool('onlySyncWhenWifi') ?? false;
  }

  set bottomNavigatorShowNote(bool status) {
    prefs.setBool('bottomNavigatorShowNote', status);
    notifyListeners();
  }

  bool get bottomNavigatorShowNote {
    return prefs.getBool('bottomNavigatorShowNote') ?? true;
  }

  set bottomNavigatorShowStatistics(bool status) {
    prefs.setBool('bottomNavigatorShowStatistics', status);
    notifyListeners();
  }

  bool get bottomNavigatorShowStatistics {
    return prefs.getBool('bottomNavigatorShowStatistics') ?? true;
  }

  set syncCompletedToast(bool status) {
    prefs.setBool('syncCompletedToast', status);
    notifyListeners();
  }

  bool get syncCompletedToast {
    return prefs.getBool('syncCompletedToast') ?? true;
  }

  set readingInfo(ReadingInfoModel info) {
    prefs.setString('readingInfo', jsonEncode(info.toJson()));
    notifyListeners();
  }

  ReadingInfoModel get readingInfo {
    String? readingInfoJson = prefs.getString('readingInfo');
    if (readingInfoJson == null) {
      return ReadingInfoModel();
    }
    return ReadingInfoModel.fromJson(jsonDecode(readingInfoJson));
  }
}
