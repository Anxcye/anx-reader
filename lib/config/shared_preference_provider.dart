import 'dart:convert';
import 'dart:core';

import 'package:anx_reader/enums/ai_prompts.dart';
import 'package:anx_reader/enums/bgimg_alignment.dart';
import 'package:anx_reader/enums/bgimg_type.dart';
import 'package:anx_reader/enums/convert_chinese_mode.dart';
import 'package:anx_reader/enums/excerpt_share_template.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/enums/sort_field.dart';
import 'package:anx_reader/enums/sort_order.dart';
import 'package:anx_reader/enums/sync_protocol.dart';
import 'package:anx_reader/enums/translation_mode.dart';
import 'package:anx_reader/enums/writing_mode.dart';
import 'package:anx_reader/enums/text_alignment.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/bgimg.dart';
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

  // void saveWebdavInfo(Map webdavInfo) {
  //   prefs.setString('webdavInfo', jsonEncode(webdavInfo));
  //   notifyListeners();
  // }

  // Map get webdavInfo {
  //   String? webdavInfoJson = prefs.getString('webdavInfo');
  //   if (webdavInfoJson == null) {
  //     return {};
  //   }
  //   return jsonDecode(webdavInfoJson);
  // }

  // Sync protocol selection
  String? get syncProtocol {
    return prefs.getString('syncProtocol');
  }

  set syncProtocol(String? protocol) {
    if (protocol != null) {
      prefs.setString('syncProtocol', protocol);
    } else {
      prefs.remove('syncProtocol');
    }
    notifyListeners();
  }

  Map<String, dynamic> getSyncInfo(SyncProtocol protocol) {
    String? syncInfoJson = prefs.getString('${protocol.name}Info');
    if (syncInfoJson == null) return {};
    return Map<String, dynamic>.from(jsonDecode(syncInfoJson));
  }

  setSyncInfo(SyncProtocol protocol, Map<String, dynamic>? info) {
    if (info != null) {
      prefs.setString('${protocol.name}Info', jsonEncode(info));
    } else {
      prefs.remove('${protocol.name}Info');
    }
    notifyListeners();
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
    return prefs.getDouble('ttsRate') ?? 0.6;
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
          label: L10n.of(context).followBook, name: 'book', path: '');
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

  set eInkMode(bool status) {
    prefs.setBool('eInkMode', status);
    notifyListeners();
  }

  bool get eInkMode {
    return prefs.getBool('eInkMode') ?? false;
  }

  set translateService(TranslateService service) {
    prefs.setString('translateService', service.name);
    notifyListeners();
  }

  TranslateService get translateService {
    return getTranslateService(
        prefs.getString('translateService') ?? 'microsoft');
  }

  set translateFrom(LangListEnum from) {
    prefs.setString('translateFrom', from.code);
    notifyListeners();
  }

  LangListEnum get translateFrom {
    return getLang(prefs.getString('translateFrom') ?? 'auto');
  }

  set translateTo(LangListEnum to) {
    prefs.setString('translateTo', to.code);
    notifyListeners();
  }

  LangListEnum get translateTo {
    return getLang(prefs.getString('translateTo') ?? getCurrentLanguageCode());
  }

  set autoTranslateSelection(bool status) {
    prefs.setBool('autoTranslateSelection', status);
    notifyListeners();
  }

  bool get autoTranslateSelection {
    return prefs.getBool('autoTranslateSelection') ?? true;
  }

  set fullTextTranslateService(TranslateService service) {
    prefs.setString('fullTextTranslateService', service.name);
    notifyListeners();
  }

  TranslateService get fullTextTranslateService {
    return getTranslateService(
        prefs.getString('fullTextTranslateService') ?? 'microsoft');
  }

  set fullTextTranslateFrom(LangListEnum from) {
    prefs.setString('fullTextTranslateFrom', from.code);
    notifyListeners();
  }

  LangListEnum get fullTextTranslateFrom {
    return getLang(prefs.getString('fullTextTranslateFrom') ?? 'auto');
  }

  set fullTextTranslateTo(LangListEnum to) {
    prefs.setString('fullTextTranslateTo', to.code);
    notifyListeners();
  }

  LangListEnum get fullTextTranslateTo {
    return getLang(prefs.getString('fullTextTranslateTo') ?? getCurrentLanguageCode());
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

  set swapPageTurnArea(bool status) {
    prefs.setBool('swapPageTurnArea', status);
  }

  bool get swapPageTurnArea {
    return prefs.getBool('swapPageTurnArea') ?? false;
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

  set autoSync(bool status) {
    prefs.setBool('autoSync', status);
    notifyListeners();
  }

  bool get autoSync {
    return prefs.getBool('autoSync') ?? true;
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

  bool get isSystemTts {
    return prefs.getBool('isSystemTts') ?? false;
  }

  set isSystemTts(bool status) {
    prefs.setBool('isSystemTts', status);
    notifyListeners();
  }

  bool get showTextUnderIconButton {
    return prefs.getBool('showTextUnderIconButton') ?? true;
  }

  set showTextUnderIconButton(bool show) {
    prefs.setBool('showTextUnderIconButton', show);
    notifyListeners();
  }

  DateTime? get lastUploadBookDate {
    String? lastUploadBookDateStr = prefs.getString('lastUploadBookDate');
    if (lastUploadBookDateStr == null) return null;
    return DateTime.parse(lastUploadBookDateStr);
  }

  set lastUploadBookDate(DateTime? date) {
    if (date == null) {
      prefs.remove('lastUploadBookDate');
    } else {
      prefs.setString('lastUploadBookDate', date.toIso8601String());
    }
    notifyListeners();
  }

  int get lastServerPort {
    return prefs.getInt('lastServerPort') ?? 0;
  }

  set lastServerPort(int port) {
    prefs.setInt('lastServerPort', port);
    notifyListeners();
  }

  SortFieldEnum get sortField {
    return SortFieldEnum.values.firstWhere(
      (element) => element.name == prefs.getString('sortField'),
      orElse: () => SortFieldEnum.lastReadTime,
    );
  }

  set sortField(SortFieldEnum field) {
    prefs.setString('sortField', field.name);
    notifyListeners();
  }

  SortOrderEnum get sortOrder {
    return SortOrderEnum.values.firstWhere(
      (element) => element.name == prefs.getString('sortOrder'),
      orElse: () => SortOrderEnum.descending,
    );
  }

  set sortOrder(SortOrderEnum order) {
    prefs.setString('sortOrder', order.name);
    notifyListeners();
  }

  ExcerptShareTemplateEnum get excerptShareTemplate {
    return ExcerptShareTemplateEnum.values.firstWhere(
      (element) => element.name == prefs.getString('excerptShareTemplate'),
      orElse: () => ExcerptShareTemplateEnum.defaultTemplate,
    );
  }

  set excerptShareTemplate(ExcerptShareTemplateEnum template) {
    prefs.setString('excerptShareTemplate', template.name);
    notifyListeners();
  }

  FontModel get excerptShareFont {
    String? fontJson = prefs.getString('excerptShareFont');
    if (fontJson == null) {
      return FontModel(
          label: L10n.of(navigatorKey.currentContext!).systemFont,
          name: 'customFont0',
          path: 'SourceHanSerifSC-Regular.otf');
    }
    return FontModel.fromJson(fontJson);
  }

  set excerptShareFont(FontModel font) {
    prefs.setString('excerptShareFont', font.toJson());
    notifyListeners();
  }

  int get excerptShareColorIndex {
    return prefs.getInt('excerptShareColorIndex') ?? 0;
  }

  set excerptShareColorIndex(int index) {
    prefs.setInt('excerptShareColorIndex', index);
    notifyListeners();
  }

  int get excerptShareBgimgIndex {
    return prefs.getInt('excerptShareBgimgIndex') ?? 1;
  }

  set excerptShareBgimgIndex(int index) {
    prefs.setInt('excerptShareBgimgIndex', index);
    notifyListeners();
  }

  bool get notShowReleaseLocalSpaceDialog {
    return prefs.getBool('notShowReleaseLocalSpaceDialog') ?? false;
  }

  set notShowReleaseLocalSpaceDialog(bool status) {
    prefs.setBool('notShowReleaseLocalSpaceDialog', status);
    notifyListeners();
  }

  void saveTranslateServiceConfig(
      TranslateService service, Map<String, dynamic> config) {
    prefs.setString(
        'translateServiceConfig_${service.name}', jsonEncode(config));
    notifyListeners();
  }

  Map<String, dynamic>? getTranslateServiceConfig(TranslateService service) {
    String? configJson =
        prefs.getString('translateServiceConfig_${service.name}');
    if (configJson == null) {
      return null;
    }
    return jsonDecode(configJson) as Map<String, dynamic>;
  }

  set iapPurchaseStatus(bool isPurchased) {
    prefs.setBool('iapPurchaseStatus', isPurchased);
    // notifyListeners();
  }

  bool get iapPurchaseStatus {
    return prefs.getBool('iapPurchaseStatus') ?? false;
  }

  set iapLastCheckTime(DateTime checkTime) {
    prefs.setString('iapLastCheckTime', checkTime.toIso8601String());
    // notifyListeners();
  }

  DateTime get iapLastCheckTime {
    String? lastCheckTimeStr = prefs.getString('iapLastCheckTime');
    if (lastCheckTimeStr == null) {
      return DateTime(1970, 1, 1);
    }
    return DateTime.parse(lastCheckTimeStr);
  }

  WritingModeEnum get writingMode {
    return WritingModeEnum.fromCode(prefs.getString('writingMode') ?? 'auto');
  }

  set writingMode(WritingModeEnum mode) {
    prefs.setString('writingMode', mode.code);
    notifyListeners();
  }

  TranslationModeEnum get translationMode {
    return TranslationModeEnum.fromCode(prefs.getString('translationMode') ?? 'off');
  }

  set translationMode(TranslationModeEnum mode) {
    prefs.setString('translationMode', mode.code);
    notifyListeners();
  }

  BgimgModel get bgimg {
    String? bgimgJson = prefs.getString('bgimg');
    if (bgimgJson == null) {
      return BgimgModel(
          type: BgimgType.none, path: 'none', alignment: BgimgAlignment.center);
    }
    return BgimgModel.fromJson(jsonDecode(bgimgJson));
  }

  set bgimg(BgimgModel bgimg) {
    prefs.setString('bgimg', jsonEncode(bgimg.toJson()));
    notifyListeners();
  }

  bool get enableJsForEpub {
    return prefs.getBool('enableJsForEpub') ?? false;
  }

  set enableJsForEpub(bool enable) {
    prefs.setBool('enableJsForEpub', enable);
    notifyListeners();
  }

  double get pageHeaderMargin {
    return prefs.getDouble('pageHeaderMargin') ??
        MediaQuery.of(navigatorKey.currentContext!).padding.bottom;
  }

  set pageHeaderMargin(double margin) {
    prefs.setDouble('pageHeaderMargin', margin);
    notifyListeners();
  }

  double get pageFooterMargin {
    return prefs.getDouble('pageFooterMargin') ??
        MediaQuery.of(navigatorKey.currentContext!).padding.bottom;
  }

  set pageFooterMargin(double margin) {
    prefs.setDouble('pageFooterMargin', margin);
    notifyListeners();
  }

  String? get lastAppVersion {
    return prefs.getString('lastAppVersion');
  }

  set lastAppVersion(String? version) {
    if (version != null) {
      prefs.setString('lastAppVersion', version);
    } else {
      prefs.remove('lastAppVersion');
    }
    notifyListeners();
  }

  set customCSSEnabled(bool enabled) {
    prefs.setBool('customCSSEnabled', enabled);
    notifyListeners();
  }

  bool get customCSSEnabled {
    return prefs.getBool('customCSSEnabled') ?? false;
  }

  set customCSS(String css) {
    prefs.setString('customCSS', css);
    notifyListeners();
  }

  String get customCSS {
    return prefs.getString('customCSS') ?? '';
  }

  Map<String, TranslationModeEnum> get bookTranslationModes {
    String? modesJson = prefs.getString('bookTranslationModes');
    if (modesJson == null) return {};
    
    Map<String, dynamic> decoded = jsonDecode(modesJson);
    return decoded.map((key, value) => 
      MapEntry(key, TranslationModeEnum.fromCode(value as String)));
  }

  set bookTranslationModes(Map<String, TranslationModeEnum> modes) {
    Map<String, String> encoded = modes.map((key, value) => 
      MapEntry(key, value.code));
    prefs.setString('bookTranslationModes', jsonEncode(encoded));
    notifyListeners();
  }

  TranslationModeEnum getBookTranslationMode(int bookId) {
    return bookTranslationModes[bookId.toString()] ?? TranslationModeEnum.off;
  }

  void setBookTranslationMode(int bookId, TranslationModeEnum mode) {
    Map<String, TranslationModeEnum> modes = bookTranslationModes;
    String bookIdStr = bookId.toString();
    
    if (mode == TranslationModeEnum.off) {
      modes.remove(bookIdStr); // 默认状态不保存，节省空间
    } else {
      modes[bookIdStr] = mode;
    }
    bookTranslationModes = modes;
  }

  bool get allowMixWithOtherAudio {
    return prefs.getBool('allowMixWithOtherAudio') ?? false;
  }

  set allowMixWithOtherAudio(bool allow) {
    prefs.setBool('allowMixWithOtherAudio', allow);
    notifyListeners();
  }

  TextAlignmentEnum get textAlignment {
    return TextAlignmentEnum.fromCode(prefs.getString('textAlignment') ?? 'auto');
  }

  set textAlignment(TextAlignmentEnum alignment) {
    prefs.setString('textAlignment', alignment.code);
    notifyListeners();
  }
}
