import 'dart:convert';
import 'dart:core';

import 'package:anx_reader/enums/convert_chinese_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/font_model.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/service/translate/index.dart';
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
    if (localeCode == null || localeCode == '') return null;
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
    return prefs.getDouble('ttsVolume') ?? 0.5;
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
    return prefs.getDouble('ttsRate') ?? 0.8;
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

  set convertChineseMode(ConvertChineseMode mode) {
    prefs.setString('convertChineseMode', mode.name);
    notifyListeners();
  }

  ConvertChineseMode get convertChineseMode {
    return getConvertChineseMode(
        prefs.getString('convertChineseMode') ?? 'none');
  }
}
