import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:anx_reader/config/feature_flags.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/dao/reading_agent_sync.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/enums/page_turn_mode.dart';
import 'package:anx_reader/enums/reading_info.dart';
import 'package:anx_reader/enums/translation_mode.dart';
import 'package:anx_reader/enums/writing_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_load_state.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/bookmark.dart';
import 'package:anx_reader/models/font_model.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/models/reading_rules.dart';
import 'package:anx_reader/models/reading_agent_sync.dart';
import 'package:anx_reader/models/search_result_model.dart';
import 'package:anx_reader/models/selection_snapshot.dart';
import 'package:anx_reader/models/toc_item.dart';
import 'package:anx_reader/page/book_player/image_viewer.dart';
import 'package:anx_reader/page/home_page.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/providers/book_toc.dart';
import 'package:anx_reader/providers/bookmark.dart';
import 'package:anx_reader/providers/chapter_content_bridge.dart';
import 'package:anx_reader/providers/current_reading.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:anx_reader/service/ai/reading_device_identity.dart';
import 'package:anx_reader/service/dictionary/chinese_dictionary.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/providers/toc_search.dart';
import 'package:anx_reader/service/tts/base_tts.dart';
import 'package:anx_reader/service/tts/models/tts_sentence.dart';
import 'package:anx_reader/service/tts/tts_handler.dart';
import 'package:anx_reader/utils/coordinates_to_part.dart';
import 'package:anx_reader/utils/js/convert_dart_color_to_js.dart';
import 'package:anx_reader/utils/platform_utils.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/get_path/log_file.dart';
import 'package:anx_reader/utils/share_file.dart';
import 'package:anx_reader/utils/webView/gererate_url.dart';
import 'package:anx_reader/utils/webView/webview_console_message.dart';
import 'package:anx_reader/widgets/bookshelf/book_cover.dart';
import 'package:anx_reader/widgets/context_menu/context_menu.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/page_turning/diagram.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/page_turning/types_and_icons.dart';
import 'package:anx_reader/widgets/reading_page/style_widget.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';

import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';

import 'minute_clock.dart';

class ReadingAgentChapterManifestItem {
  const ReadingAgentChapterManifestItem({
    required this.href,
    required this.title,
    required this.startPercentage,
    required this.textLength,
    required this.isNavigation,
  });

  final String href;
  final String title;
  final double startPercentage;
  final int textLength;
  final bool isNavigation;

  factory ReadingAgentChapterManifestItem.fromJson(Map<String, dynamic> json) =>
      ReadingAgentChapterManifestItem(
        href: json['href']?.toString() ?? '',
        title: json['title']?.toString().trim() ?? '',
        startPercentage:
            (json['startPercentage'] as num?)?.toDouble().clamp(0, 1) ?? 0,
        textLength: (json['textLength'] as num?)?.toInt() ?? 0,
        isNavigation: json['isNavigation'] == true,
      );
}

class EpubPlayer extends ConsumerStatefulWidget {
  final Book book;
  final String? cfi;
  final Function showOrHideAppBarAndBottomBar;
  final Function onLoadEnd;
  final List<ReadTheme> initialThemes;
  final Function updateParent;
  final void Function({
    required String previousHref,
    required String previousTitle,
    required double highestProgress,
    required String currentHref,
  })? onChapterChanged;
  final void Function({
    required String cfi,
    required String chapterHref,
    required String chapterTitle,
    required double totalProgress,
    required double chapterProgress,
  })? onReadingLocationChanged;
  final void Function(SelectionSnapshot selection)? onSelectionCreated;
  final VoidCallback? onSelectionCleared;

  const EpubPlayer(
      {super.key,
      required this.showOrHideAppBarAndBottomBar,
      required this.book,
      this.cfi,
      required this.onLoadEnd,
      required this.initialThemes,
      required this.updateParent,
      this.onChapterChanged,
      this.onReadingLocationChanged,
      this.onSelectionCreated,
      this.onSelectionCleared});

  @override
  ConsumerState<EpubPlayer> createState() => EpubPlayerState();
}

class EpubPlayerState extends ConsumerState<EpubPlayer>
    with TickerProviderStateMixin {
  late InAppWebViewController webViewController;
  late ContextMenu contextMenu;
  String cfi = '';
  double percentage = 0.0;
  String chapterTitle = '';
  String chapterHref = '';
  String _trackedChapterHref = '';
  String _trackedChapterTitle = '';
  double _trackedChapterProgress = 0;
  BookLoadState _bookLoadState = const BookLoadState();
  Timer? _slowLoadTimer;
  Timer? _loadTimeoutTimer;
  int _webViewGeneration = 0;
  bool _hasMovedFromInitialTarget = false;
  BookResourceHandle? _bookResource;
  int chapterCurrentPage = 0;
  int chapterTotalPages = 0;
  OverlayEntry? contextMenuEntry;
  AnimationController? _animationController;
  Animation<double>? _animation;
  bool showHistory = false;
  bool canGoBack = false;
  bool canGoForward = false;
  late Book book;
  String? backgroundColor;
  String? textColor;
  Timer? styleTimer;
  String bookmarkCfi = '';
  bool bookmarkExists = false;
  WritingModeEnum writingMode = WritingModeEnum.horizontalTb;
  String? _lastSelectionContextText;
  BookNote? _selectionAutoMarkNote;
  int? _selectionAutoMarkSessionId;
  Future<void> _selectionAutoMarkMutation = Future<void>.value();
  bool _selectionClearLocked = false;
  bool _selectionClearPending = false;
  int _selectionMenuGeneration = 0;
  late TranslationModeEnum _activeTranslationMode;
  String? _translationTextCacheStorageKey;
  Map<String, dynamic> _translationTextCache = {};
  Timer? _translationTextCacheFlushTimer;
  bool _translationTextCacheDirty = false;
  int _translationTextCachePendingChanges = 0;
  String? _activeTranslationDomCacheNamespace;
  Timer? _translationSettingsRefreshTimer;
  int _translationProgressCompleted = 0;
  int _translationProgressTotal = 0;
  int _translationProgressFailed = 0;
  bool _translationProgressActive = false;
  Timer? _currentPageTranslationTimer;
  bool _webViewReady = false;

  Future<void> configureSelection() async {
    if (!_webViewReady) return;
    await webViewController.evaluateJavascript(source: '''
      window.configureSelection && window.configureSelection({
        longPressMode: ${jsonEncode(Prefs().longPressSelectionMode.name)},
        eInkMode: ${Prefs().eInkMode},
        platform: ${jsonEncode(AnxPlatform.type.name)}
      });
    ''');
  }

  Future<void> changeSelectionRange(SelectionRangeType type) async {
    await webViewController.evaluateJavascript(
      source:
          'window.changeSelectionRange && window.changeSelectionRange(${jsonEncode(type.name)});',
    );
  }

  Future<void> moveSelectionSentence(int direction) async {
    await webViewController.evaluateJavascript(
      source:
          'window.moveSelectionSentence && window.moveSelectionSentence(${direction < 0 ? -1 : 1});',
    );
  }

  Future<int?> upsertSelectionAutoMark(SelectionSnapshot snapshot) async {
    if (!Prefs().autoMarkSelection || !snapshot.supportsRangeSelection) {
      return null;
    }
    int? result;
    _selectionAutoMarkMutation = _selectionAutoMarkMutation.then((_) async {
      if (_selectionAutoMarkSessionId != snapshot.sessionId) {
        _selectionAutoMarkNote = null;
        _selectionAutoMarkSessionId = snapshot.sessionId;
      }
      final previous = _selectionAutoMarkNote;
      final note = BookNote(
        id: previous?.id,
        bookId: widget.book.id,
        content: snapshot.text,
        cfi: snapshot.cfi,
        chapter: chapterTitle,
        type: previous?.type ?? Prefs().annotationType,
        color: previous?.color ?? Prefs().annotationColor,
        createTime: previous?.createTime ?? DateTime.now(),
        updateTime: DateTime.now(),
      );
      try {
        if (previous != null && previous.cfi != note.cfi) {
          removeAnnotation(previous.cfi);
        }
        final id = await bookNoteDao.save(note);
        note.setId(id);
        _selectionAutoMarkNote = note;
        addAnnotation(note);
        result = id;
      } catch (error, stack) {
        AnxLog.warning('Failed to update temporary auto mark: $error\n$stack');
        if (previous != null) addAnnotation(previous);
        result = previous?.id;
      }
    });
    await _selectionAutoMarkMutation;
    return result;
  }

  void finalizeSelectionAutoMark() {
    _selectionAutoMarkNote = null;
    _selectionAutoMarkSessionId = null;
  }

  late bool _lastEInkMode;

  // Scroll wheel debounce
  Timer? _scrollDebounceTimer;
  double _accumulatedScrollDelta = 0;
  static const double _scrollThreshold = 50.0;

  // to know anytime if we are on top of navigation stack
  bool get _isTopOfNavigationStack =>
      ModalRoute.of(context)?.isCurrent ?? false;

  void prevPage() {
    webViewController.evaluateJavascript(source: 'prevPage()');
  }

  void nextPage() {
    webViewController.evaluateJavascript(source: 'nextPage()');
  }

  void prevChapter() {
    webViewController.evaluateJavascript(source: '''
      prevSection()
      ''');
  }

  void nextChapter() {
    webViewController.evaluateJavascript(source: '''
      nextSection()
      ''');
  }

  Future<void> setTranslationMode(
    TranslationModeEnum mode, {
    bool restoreProgress = true,
  }) async {
    if (mode != _activeTranslationMode) {
      await saveReadingProgress();
    }

    _activeTranslationMode = mode;
    _resetTranslationProgress();

    await _applyTranslationModeToWebView(mode);

    if (!restoreProgress || widget.cfi != null) return;

    final savedCfi = _savedCfiForMode(mode);
    if (savedCfi == null || savedCfi == cfi) return;

    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    goToCfi(savedCfi);
  }

  Future<void> _applyTranslationModeToWebView(
    TranslationModeEnum mode,
  ) async {
    final jsMode = jsonEncode(mode.code);

    for (var attempt = 0; attempt < 30; attempt++) {
      final applied = await webViewController.evaluateJavascript(source: '''
        (function() {
          if (
            window.reader &&
            window.reader.view &&
            typeof window.reader.view.setTranslationMode === 'function'
          ) {
            window.reader.view.setTranslationMode($jsMode);
            return true;
          }
          return false;
        })();
      ''');

      if (applied == true || applied?.toString() == 'true') {
        return;
      }

      await Future.delayed(const Duration(milliseconds: 120));
    }

    AnxLog.warning(
      'Timed out applying translation mode ${mode.code} for book ${widget.book.id}',
    );
  }

  void _triggerCurrentPageTranslation() {
    webViewController.evaluateJavascript(source: '''
      if (window.translator && typeof window.translator.translateCurrentPage === 'function') {
        window.translator.translateCurrentPage();
      }
      ''');
  }

  void _handleTranslationPrefsChanged() {
    final nextEInkMode = Prefs().isEInkMode;
    if (nextEInkMode != _lastEInkMode) {
      _lastEInkMode = nextEInkMode;
      if (_webViewReady) {
        getThemeColor();
        changeTheme(Prefs().effectiveReadTheme);
        changeStyle(null);
        changePageTurnStyle(Prefs().effectivePageTurnStyle);
      }
      if (mounted) setState(() {});
    }
    final nextNamespace = _translationDomCacheStorageKey();
    final namespaceChanged =
        nextNamespace != _activeTranslationDomCacheNamespace;
    _activeTranslationDomCacheNamespace = nextNamespace;

    if (!namespaceChanged || !_webViewReady) return;
    _scheduleTranslationSettingsRefresh();
  }

  void _scheduleTranslationSettingsRefresh() {
    _translationSettingsRefreshTimer?.cancel();
    _translationSettingsRefreshTimer = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(_refreshTranslationForSettingsChange()),
    );
  }

  Future<void> _refreshTranslationForSettingsChange() async {
    _translationSettingsRefreshTimer?.cancel();
    _translationSettingsRefreshTimer = null;

    if (!mounted || !_webViewReady) return;
    if (_activeTranslationMode == TranslationModeEnum.off) return;

    _resetTranslationProgress();

    try {
      await webViewController.evaluateJavascript(source: '''
        (async function() {
          if (
            window.translator &&
            typeof window.translator.setRootMargin === 'function'
          ) {
            window.translator.setRootMargin('${Prefs().translationMargin}px');
          }
          if (
            window.translator &&
            typeof window.translator.refreshCache === 'function'
          ) {
            await window.translator.refreshCache();
          }
          if (
            window.translator &&
            typeof window.translator.translateCurrentPage === 'function'
          ) {
            await window.translator.translateCurrentPage();
          }
          return true;
        })();
      ''');
    } catch (e) {
      AnxLog.warning('Failed to refresh translation after settings change: $e');
    }
  }

  void _scheduleCurrentPageTranslation({required String expectedCfi}) {
    _currentPageTranslationTimer?.cancel();

    _currentPageTranslationTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_activeTranslationMode == TranslationModeEnum.off) return;
      if (cfi != expectedCfi) return;
      _triggerCurrentPageTranslation();
    });
  }

  Future<void> translateSelectedParagraph({required String cfi}) async {
    // Use JSON encoding for proper escaping of all special characters
    final jsCfi = jsonEncode(cfi);
    await webViewController.evaluateJavascript(source: '''
      (function() {
        var cfiStr = $jsCfi;
        if (window.reader && window.reader.view && typeof window.reader.view.translateSelectedParagraph === 'function') {
          window.reader.view.translateSelectedParagraph(cfiStr);
        } else {
          console.warn('reader.view.translateSelectedParagraph not available');
        }
      })();
      ''');
  }

  Future<void> goToPercentage(double value) async {
    await webViewController.evaluateJavascript(source: '''
      goToPercent($value); 
      ''');
  }

  void setSelectionClearLocked(bool locked) {
    _selectionClearLocked = locked;
    if (!locked && _selectionClearPending) {
      _selectionClearPending = false;
      _lastSelectionContextText = null;
      removeOverlay();
    }
  }

  void changeTheme(ReadTheme readTheme) {
    if (Prefs().isEInkMode) readTheme = Prefs().effectiveReadTheme;
    textColor = readTheme.textColor;
    backgroundColor = readTheme.backgroundColor;

    String bc = convertDartColorToJs(readTheme.backgroundColor);
    String tc = convertDartColorToJs(readTheme.textColor);

    webViewController.evaluateJavascript(source: '''
      changeStyle({
        backgroundColor: '#$bc',
        fontColor: '#$tc',
      })
      ''');
  }

  void changeStyle(BookStyle? bookStyle) {
    styleTimer?.cancel();
    String bgimgUrl = Prefs().isEInkMode
        ? ''
        : Prefs().bgimg.getEffectiveUrl(
              isDarkMode: isDarkMode,
              autoAdjust: Prefs().autoAdjustReadingTheme,
            );

    styleTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      BookStyle style = bookStyle ?? Prefs().bookStyle;
      webViewController.evaluateJavascript(source: '''
      changeStyle({
        fontSize: ${style.fontSize},
        spacing: ${style.lineHeight},
        fontWeight: ${style.fontWeight},
        paragraphSpacing: ${style.paragraphSpacing},
        topMargin: ${style.topMargin},
        bottomMargin: ${style.bottomMargin},
        sideMargin: ${style.sideMargin},
        letterSpacing: ${style.letterSpacing},
        textIndent: ${style.indent},
        maxColumnCount: ${style.maxColumnCount},
        columnThreshold: ${style.columnThreshold},
        writingMode: '${Prefs().writingMode.code}',
        textAlign: '${Prefs().textAlignment.code}',
        backgroundImage: '$bgimgUrl',
        bgimgBlur: ${Prefs().bgimg.blur},
        bgimgOpacity: ${Prefs().bgimg.opacity},
        bgimgFit: '${Prefs().bgimgFit.code}',
        customCSS: `${Prefs().customCSS.replaceAll('`', '\\`')}`,
        customCSSEnabled: ${Prefs().customCSSEnabled},
        useBookStyles: ${Prefs().useBookStyles},
        headingFontSize: ${style.headingFontSize},
        codeHighlightTheme: '${Prefs().effectiveCodeHighlightTheme.code}',
        eInkMode: ${Prefs().isEInkMode},
      })
      ''');
    });
  }

  void changeBgimgEffect() {
    if (!mounted) return;
    final bgimg = Prefs().bgimg;
    final bgimgUrl = bgimg.getEffectiveUrl(
      isDarkMode: isDarkMode,
      autoAdjust: Prefs().autoAdjustReadingTheme,
    );
    webViewController.evaluateJavascript(source: '''
      changeStyle({
        backgroundImage: '$bgimgUrl',
        bgimgBlur: ${bgimg.blur},
        bgimgOpacity: ${bgimg.opacity},
        bgimgFit: '${Prefs().bgimgFit.code}',
      })
    ''');
  }

  void changeReadingRules(ReadingRules readingRules) {
    webViewController.evaluateJavascript(source: '''
      readingFeatures({
        convertChineseMode: '${readingRules.convertChineseMode.name}',
        bionicReadingMode: ${readingRules.bionicReading},
      })
    ''');
  }

  void changeFont(FontModel font) {
    webViewController.evaluateJavascript(source: '''
      changeStyle({
        fontName: '${font.name}',
        fontPath: '${font.path}',
      })
    ''');
  }

  void changePageTurnStyle(PageTurn pageTurnStyle) {
    pageTurnStyle =
        Prefs().isEInkMode ? Prefs().effectivePageTurnStyle : pageTurnStyle;
    webViewController.evaluateJavascript(source: '''
      changeStyle({
        pageTurnStyle: '${pageTurnStyle.name}',
      })
    ''');
  }

  void goToHref(String href) =>
      webViewController.evaluateJavascript(source: "goToHref('$href')");

  void goToCfi(String cfi) =>
      webViewController.evaluateJavascript(source: "goToCfi('$cfi')");

  void addAnnotation(BookNote bookNote) {
    final noteContent =
        (bookNote.content).replaceAll('\n', ' ').replaceAll("'", "\\'");
    webViewController.evaluateJavascript(source: '''
      addAnnotation({
        id: ${bookNote.id},
        type: '${bookNote.type}',
        value: '${bookNote.cfi}',
        color: '#${bookNote.color}',
        note: '$noteContent',
      })
      ''');
  }

  void addBookmark(BookmarkModel bookmark) {
    webViewController.evaluateJavascript(source: '''
      addAnnotation({
        id: ${bookmark.id},
        type: 'bookmark',
        value: '${bookmark.cfi}',
        color: '#000000',
        note: 'None',
      })
      ''');
  }

  void addBookmarkHere() {
    webViewController.evaluateJavascript(source: '''
      addBookmarkHere()
      ''');
  }

  void removeAnnotation(String annotationKey) => webViewController
      .evaluateJavascript(source: "removeAnnotation('$annotationKey')");

  void addDifficultyAnnotation({
    required String id,
    required String cfi,
  }) {
    final encodedId = jsonEncode(id);
    final encodedKey = jsonEncode('difficulty:$id');
    final encodedCfi = jsonEncode(cfi);
    webViewController.evaluateJavascript(source: '''
      addAnnotation({
        id: $encodedId,
        annotationKey: $encodedKey,
        type: 'underline',
        value: $encodedCfi,
        color: '#000000',
        note: 'reading-difficulty',
      })
    ''');
  }

  void clearSearch() {
    ref.read(tocSearchProvider.notifier).clear();
    _clearSearchHighlights();
  }

  void search(String text) {
    final sanitized = text.trim();
    if (sanitized.isEmpty) {
      clearSearch();
      return;
    }
    _clearSearchHighlights();
    ref.read(tocSearchProvider.notifier).start(sanitized);
    webViewController.evaluateJavascript(source: '''
      search('$sanitized', {
        'scope': 'book',
        'matchCase': false,
        'matchDiacritics': false,
        'matchWholeWords': false,
      })
    ''');
  }

  void _clearSearchHighlights() {
    webViewController.evaluateJavascript(source: "clearSearch()");
  }

  Future<void> initTts({String? fromCfi}) async {
    if (fromCfi != null && fromCfi.isNotEmpty) {
      await webViewController.evaluateJavascript(
          source: "window.ttsFromCfi('$fromCfi')");
    } else {
      await webViewController.evaluateJavascript(source: "window.ttsHere()");
    }
  }

  void ttsStop() => webViewController.evaluateJavascript(source: "ttsStop()");

  Future<String> ttsNext() async => (await webViewController
          .callAsyncJavaScript(functionBody: "return await ttsNext()"))
      ?.value;

  Future<String> ttsPrev() async => (await webViewController
          .callAsyncJavaScript(functionBody: "return await ttsPrev()"))
      ?.value;

  Future<String> ttsPrevSection() async => (await webViewController
          .callAsyncJavaScript(functionBody: "return await ttsPrevSection()"))
      ?.value;

  Future<String> ttsNextSection() async => (await webViewController
          .callAsyncJavaScript(functionBody: "return await ttsNextSection()"))
      ?.value;

  Future<String> ttsPrepare() async =>
      (await webViewController.evaluateJavascript(source: "ttsPrepare()"));

  TtsSentence? _parseTtsSentence(dynamic value) {
    if (value is Map<dynamic, dynamic>) {
      try {
        return TtsSentence.fromMap(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  List<TtsSentence> _parseTtsSentences(dynamic value) {
    if (value is! List) return const [];

    final sentences = <TtsSentence>[];
    for (final item in value) {
      final sentence = _parseTtsSentence(item);
      if (sentence != null) {
        sentences.add(sentence);
      }
    }
    return sentences;
  }

  Future<TtsSentence?> ttsCurrentDetail() async {
    final result = await webViewController.callAsyncJavaScript(
      functionBody: 'return ttsCurrentDetail()',
    );
    return _parseTtsSentence(result?.value);
  }

  Future<List<TtsSentence>> ttsCollectDetails({
    required int count,
    bool includeCurrent = false,
    int offset = 1,
  }) async {
    final result = await webViewController.callAsyncJavaScript(
      functionBody:
          'return ttsCollectDetails($count, ${includeCurrent ? 'true' : 'false'}, $offset)',
    );
    return _parseTtsSentences(result?.value);
  }

  Future<void> ttsHighlightByCfi(String cfi) async {
    await webViewController.callAsyncJavaScript(
      functionBody: 'return ttsHighlightByCfi(${jsonEncode(cfi)})',
    );
  }

  Future<bool> isFootNoteOpen() async => (await webViewController
      .evaluateJavascript(source: "window.isFootNoteOpen()"));

  void backHistory() {
    webViewController.evaluateJavascript(source: "back()");
  }

  void forwardHistory() {
    webViewController.evaluateJavascript(source: "forward()");
  }

  void refreshToc() {
    webViewController.evaluateJavascript(source: "refreshToc()");
  }

  Future<String> theChapterContent() async =>
      await webViewController.evaluateJavascript(
        source: "theChapterContent()",
      );

  Future<String> previousContent(int count) async =>
      await webViewController.evaluateJavascript(
        source: "previousContent($count)",
      );

  Future<String> _getCurrentChapterContent({int? maxCharacters}) async {
    final raw = await theChapterContent();
    return _normalizeChapterContent(raw, maxCharacters);
  }

  Future<String> _getChapterContentByHref(
    String href, {
    int? maxCharacters,
  }) async {
    if (href.isEmpty) {
      return '';
    }

    final result = await webViewController.callAsyncJavaScript(
      functionBody:
          'return await getChapterContentByHref("${href.replaceAll('"', '\\"')}")',
    );

    final value = result?.value;
    if (value is String) {
      return _normalizeChapterContent(value, maxCharacters);
    }
    return '';
  }

  Future<String> chapterContentByHref(
    String href, {
    int? maxCharacters,
  }) =>
      _getChapterContentByHref(href, maxCharacters: maxCharacters);

  Future<List<ReadingAgentChapterManifestItem>>
      readingAgentChapterManifest() async {
    final result = await webViewController.callAsyncJavaScript(
      functionBody: 'return await getReadingAgentChapterManifest()',
    );
    final value = result?.value;
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => ReadingAgentChapterManifestItem.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((item) =>
            item.href.isNotEmpty &&
            (item.textLength > 100 || item.isNavigation))
        .toList(growable: false);
  }

  String _normalizeChapterContent(String? content, int? maxCharacters) {
    if (content == null || content.isEmpty) {
      return '';
    }
    final trimmed = content.trim();
    if (maxCharacters != null &&
        maxCharacters > 0 &&
        trimmed.length > maxCharacters) {
      return trimmed.substring(0, maxCharacters);
    }
    return trimmed;
  }

  void _registerChapterContentBridge() {
    ref.read(chapterContentBridgeProvider.notifier).state =
        ChapterContentHandlers(
      fetchCurrentChapter: ({int? maxCharacters}) =>
          _getCurrentChapterContent(maxCharacters: maxCharacters),
      fetchChapterByHref: (href, {int? maxCharacters}) =>
          _getChapterContentByHref(href, maxCharacters: maxCharacters),
    );
  }

  Future<void> _handleExternalLink(dynamic rawLink) async {
    String? normalizeExternalLink(dynamic raw) {
      if (raw == null) {
        return null;
      }
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
      if (raw is Map && raw['href'] is String) {
        final href = raw['href'].toString().trim();
        return href.isEmpty ? null : href;
      }
      return null;
    }

    final link = normalizeExternalLink(rawLink);
    if (!mounted || link == null) {
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null || uri.scheme.isEmpty || uri.scheme == 'javascript') {
      AnxLog.warning('Ignored invalid external link: $link');
      return;
    }

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = L10n.of(dialogContext);
        return AlertDialog(
          title: Text(l10n.readingPageOpenExternalLinkTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.readingPageOpenExternalLinkMessage),
              const SizedBox(height: 8),
              SelectableText(link),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.readingPageOpenExternalLinkAction),
            ),
          ],
        );
      },
    );

    if (shouldOpen != true) {
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      AnxLog.warning('Failed to open external link: $link');
    }
  }

  void onClick(Map<String, dynamic> location) {
    readingPageKey.currentState?.resetAwakeTimer();
    if (contextMenuEntry != null) {
      removeOverlay();
      return;
    }
    final x = location['x'];
    final y = location['y'];
    final part = coordinatesToPart(x, y);

    PageTurningType action;
    final pageTurnMode = PageTurnMode.fromCode(Prefs().pageTurnMode);

    if (pageTurnMode == PageTurnMode.simple) {
      // Use predefined page turning types
      final currentPageTurningType = Prefs().pageTurningType;
      final pageTurningType = pageTurningTypes[currentPageTurningType];
      action = pageTurningType[part];

      // Apply swap if enabled
      if (Prefs().swapPageTurnArea) {
        if (action == PageTurningType.prev) {
          action = PageTurningType.next;
        } else if (action == PageTurningType.next) {
          action = PageTurningType.prev;
        }
      }
    } else {
      // Use custom configuration
      final customConfig = Prefs().customPageTurnConfig;
      action = PageTurningType.values[customConfig[part]];
    }

    // Disable mouse/touch page turning when keyboard shortcuts are enabled
    if (Prefs().keyboardShortcutTurnPage) {
      // Only allow menu action, disable prev/next page turning
      if (action == PageTurningType.prev || action == PageTurningType.next) {
        return;
      }
    }

    switch (action) {
      case PageTurningType.prev:
        prevPage();
        break;
      case PageTurningType.next:
        nextPage();
        break;
      case PageTurningType.menu:
        widget.showOrHideAppBarAndBottomBar(true);
        break;
      case PageTurningType.none:
        break;
    }
  }

  Future<void> renderAnnotations(InAppWebViewController controller) async {
    List<BookNote> annotationList =
        await bookNoteDao.selectBookNotesByBookId(widget.book.id);
    String allAnnotations =
        jsonEncode(annotationList.map((e) => e.toJson()).toList())
            .replaceAll('\'', '\\\'');
    controller.evaluateJavascript(source: '''
     const allAnnotations = $allAnnotations
     renderAnnotations()
    ''');
  }

  void getThemeColor() {
    if (Prefs().isEInkMode) {
      backgroundColor = Prefs().effectiveReadTheme.backgroundColor;
      textColor = Prefs().effectiveReadTheme.textColor;
      return;
    }
    if (Prefs().autoAdjustReadingTheme) {
      List<ReadTheme> themes = widget.initialThemes;
      final isDayMode =
          Theme.of(navigatorKey.currentContext!).brightness == Brightness.light;
      backgroundColor =
          isDayMode ? themes[0].backgroundColor : themes[1].backgroundColor;
      textColor = isDayMode ? themes[0].textColor : themes[1].textColor;
    } else {
      backgroundColor = Prefs().readTheme.backgroundColor;
      textColor = Prefs().readTheme.textColor;
    }
  }

  Future<void> setHandler(InAppWebViewController controller) async {
    controller.addJavaScriptHandler(
        handlerName: 'onLoadEnd',
        callback: (args) async {
          _completeBookLoad();
          widget.onLoadEnd();
          final savedMode = Prefs().getBookTranslationMode(widget.book.id);
          if (savedMode != TranslationModeEnum.off) {
            await setTranslationMode(savedMode, restoreProgress: false);
          }
        });

    controller.addJavaScriptHandler(
      handlerName: 'onBookLoadStage',
      callback: (args) {
        if (args.isEmpty || args.first is! Map) return null;
        final payload = Map<String, dynamic>.from(args.first as Map);
        final stage = BookLoadStage.values.firstWhere(
          (value) => value.name == payload['stage']?.toString(),
          orElse: () => _bookLoadState.stage,
        );
        if (!mounted || _bookLoadState.hasFailed) return null;
        setState(() {
          _bookLoadState = _bookLoadState.copyWith(
            stage: stage,
            elapsedMs: (payload['elapsedMs'] as num?)?.toInt() ?? 0,
            format: payload['format']?.toString(),
          );
        });
        AnxLog.info(
          'BookLoad[${widget.book.id}] stage=${stage.name} '
          'elapsedMs=${payload['elapsedMs']} format=${payload['format']}',
        );
        return null;
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'onBookLoadError',
      callback: (args) {
        final payload = args.isNotEmpty && args.first is Map
            ? Map<String, dynamic>.from(args.first as Map)
            : <String, dynamic>{'message': 'Unknown reader error'};
        _failBookLoad(BookLoadFailure.fromJson(payload));
        return null;
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'onBookSectionError',
      callback: (args) {
        final payload = args.isNotEmpty && args.first is Map
            ? Map<String, dynamic>.from(args.first as Map)
            : const <String, dynamic>{};
        AnxLog.warning(
          'BookLoad[${widget.book.id}] recoverable section error '
          'code=${payload['code']} index=${payload['sectionIndex']} '
          'message=${payload['message']}',
        );
        return null;
      },
    );

    controller.addJavaScriptHandler(
        handlerName: 'onRelocated',
        callback: (args) {
          Map<String, dynamic> location = args[0];
          final nextHref = location['chapterHref']?.toString() ?? '';
          final nextTitle = location['chapterTitle']?.toString() ?? '';
          final nextCfi = location['cfi']?.toString() ?? '';
          if (widget.cfi != null &&
              nextCfi.isNotEmpty &&
              nextCfi != widget.cfi) {
            _hasMovedFromInitialTarget = true;
          }
          if (nextCfi.isNotEmpty && cfi == nextCfi && chapterHref == nextHref) {
            return;
          }
          final nextCurrentPage =
              (location['chapterCurrentPage'] as num?)?.toInt() ?? 0;
          final nextTotalPages =
              (location['chapterTotalPages'] as num?)?.toInt() ?? 0;
          final nextProgress = nextTotalPages <= 0
              ? 0.0
              : (nextCurrentPage / nextTotalPages).clamp(0.0, 1.0);
          if (_trackedChapterHref.isNotEmpty &&
              nextHref.isNotEmpty &&
              nextHref != _trackedChapterHref) {
            widget.onChapterChanged?.call(
              previousHref: _trackedChapterHref,
              previousTitle: _trackedChapterTitle,
              highestProgress: _trackedChapterProgress,
              currentHref: nextHref,
            );
            _trackedChapterProgress = 0;
          }
          if (nextHref.isNotEmpty) {
            _trackedChapterHref = nextHref;
            _trackedChapterTitle = nextTitle;
            if (nextProgress > _trackedChapterProgress) {
              _trackedChapterProgress = nextProgress;
            }
          }
          // if (chapterHref != location['chapterHref']) {
          //   refreshToc();
          // }
          setState(() {
            cfi = nextCfi;
            percentage =
                double.tryParse(location['percentage'].toString()) ?? 0.0;
            chapterTitle = location['chapterTitle'] ?? '';
            chapterHref = location['chapterHref'] ?? '';
            chapterCurrentPage = nextCurrentPage;
            chapterTotalPages = nextTotalPages;
            bookmarkExists = location['bookmark']['exists'] ?? false;
            bookmarkCfi = location['bookmark']['cfi'] ?? '';
            writingMode =
                WritingModeEnum.fromCode(location['writingMode'] ?? '');
          });
          ref.read(currentReadingProvider.notifier).update(
                cfi: cfi,
                percentage: percentage,
                chapterTitle: chapterTitle,
                chapterHref: chapterHref,
                chapterCurrentPage: chapterCurrentPage,
                chapterTotalPages: chapterTotalPages,
              );
          widget.onReadingLocationChanged?.call(
            cfi: cfi,
            chapterHref: chapterHref,
            chapterTitle: chapterTitle,
            totalProgress: percentage,
            chapterProgress: nextProgress,
          );
          widget.updateParent();
          saveReadingProgress();
          readingPageKey.currentState?.resetAwakeTimer();

          // Auto-translate visible elements on page/chapter change if translation mode is enabled
          final currentMode = Prefs().getBookTranslationMode(widget.book.id);
          if (currentMode != TranslationModeEnum.off) {
            _scheduleCurrentPageTranslation(expectedCfi: cfi);
          }
        });
    controller.addJavaScriptHandler(
        handlerName: 'onClick',
        callback: (args) {
          Map<String, dynamic> location = args[0];
          onClick(location);
        });
    controller.addJavaScriptHandler(
      handlerName: 'onExternalLink',
      callback: (args) async {
        final payload = args.isNotEmpty ? args.first : null;
        await _handleExternalLink(payload);
      },
    );
    controller.addJavaScriptHandler(
        handlerName: 'onSetToc',
        callback: (args) {
          List<dynamic> t = args[0];
          final toc = t.map((i) => TocItem.fromJson(i)).toList();
          ref.read(bookTocProvider.notifier).setToc(toc);
        });
    controller.addJavaScriptHandler(
        handlerName: 'onSelectionEnd',
        callback: (args) {
          final menuGeneration = ++_selectionMenuGeneration;
          removeOverlay(preserveAutoMarkSession: true);
          if (args.isEmpty || args.first is! Map) {
            AnxLog.warning('Selection menu ignored: invalid WebView payload');
            return;
          }
          final location = Map<String, dynamic>.from(args.first as Map);
          final snapshot = SelectionSnapshot.fromJson(location);
          final cfi = snapshot.cfi;
          final text = snapshot.text;
          final footnote = location['footnote'] == true;
          final rawPosition = location['pos'];
          if (cfi.isEmpty || text.isEmpty || rawPosition is! Map) {
            AnxLog.warning(
              'Selection menu ignored: missing text, CFI, or position',
            );
            return;
          }
          final position = Map<String, dynamic>.from(rawPosition);
          final left = (position['left'] as num?)?.toDouble();
          final top = (position['top'] as num?)?.toDouble();
          final right = (position['right'] as num?)?.toDouble();
          final bottom = (position['bottom'] as num?)?.toDouble();
          if (left == null || top == null || right == null || bottom == null) {
            AnxLog.warning('Selection menu ignored: invalid position');
            return;
          }
          _lastSelectionContextText = snapshot.contextText;
          widget.onSelectionCreated?.call(snapshot);
          unawaited(
            showContextMenu(
              context,
              left,
              top,
              right,
              bottom,
              text,
              cfi,
              null,
              footnote,
              writingMode.isVertical ? Axis.vertical : Axis.horizontal,
              contextText: _lastSelectionContextText,
              selectionSnapshot: snapshot,
              isCurrentRequest: () =>
                  mounted && menuGeneration == _selectionMenuGeneration,
            ).catchError((Object error, StackTrace stack) {
              AnxLog.warning('Failed to show selection menu: $error\n$stack');
            }),
          );
        });
    controller.addJavaScriptHandler(
      handlerName: 'onWordBoundaryRequest',
      callback: (args) async {
        if (args.isEmpty || args.first is! Map) return false;
        final request = Map<String, dynamic>.from(args.first as Map);
        final sessionId = (request['sessionId'] as num?)?.toInt();
        final text = request['text']?.toString() ?? '';
        final offset = (request['offset'] as num?)?.toInt();
        if (sessionId == null || text.isEmpty || offset == null) return false;
        final boundary = await ChineseDictionaryService.resolveBoundary(
          text,
          offset,
        );
        if (!_webViewReady) return false;
        await webViewController.evaluateJavascript(source: '''
          window.applyResolvedWord && window.applyResolvedWord({
            sessionId: $sessionId,
            startOffset: ${boundary.startOffset},
            endOffset: ${boundary.endOffset}
          });
        ''');
        return true;
      },
    );
    controller.addJavaScriptHandler(
        handlerName: 'onSelectionCleared',
        callback: (args) {
          if (_selectionClearLocked) {
            _selectionClearPending = true;
            return;
          }
          _lastSelectionContextText = null;
          _selectionMenuGeneration++;
          widget.onSelectionCleared?.call();
          removeOverlay();
        });
    controller.addJavaScriptHandler(
        handlerName: 'onAnnotationClick',
        callback: (args) {
          final menuGeneration = ++_selectionMenuGeneration;
          Map<String, dynamic> annotation = args[0];

          if (annotation['annotation'] == null) {
            // Check if TTS is active and the click is on the currently read text
            final currentTtsState = TtsHandler().ttsStateNotifier.value;
            if (currentTtsState == TtsStateEnum.playing ||
                currentTtsState == TtsStateEnum.paused) {
              if (currentTtsState == TtsStateEnum.playing) {
                audioHandler.pause();
              } else {
                audioHandler.play();
              }
            }
            return;
          }

          if (annotation['annotation']['note'] == 'reading-difficulty') {
            if (FeatureFlags.readingCoach) {
              readingPageKey.currentState?.showReadingCoach();
            }
            return;
          }

          int id = annotation['annotation']['id'];
          String cfi = annotation['annotation']['value'];
          String note = annotation['annotation']['note'];
          final rawContextText = annotation['contextText']?.toString();
          _lastSelectionContextText =
              (rawContextText?.trim().isEmpty ?? true) ? null : rawContextText;
          double left = (annotation['pos']['left'] as num).toDouble();
          double top = (annotation['pos']['top'] as num).toDouble();
          double right = (annotation['pos']['right'] as num).toDouble();
          double bottom = (annotation['pos']['bottom'] as num).toDouble();
          showContextMenu(
            context,
            left,
            top,
            right,
            bottom,
            note,
            cfi,
            id,
            false,
            writingMode.isVertical ? Axis.vertical : Axis.horizontal,
            contextText: _lastSelectionContextText,
            isCurrentRequest: () =>
                mounted && menuGeneration == _selectionMenuGeneration,
          );
        });
    controller.addJavaScriptHandler(
      handlerName: 'onSearch',
      callback: (args) {
        Map<String, dynamic> search = args[0];
        setState(() {
          final tocSearch = ref.read(tocSearchProvider.notifier);
          if (search['process'] != null) {
            final progress = search['process'].toDouble();
            tocSearch.updateProgress(progress);
          } else {
            tocSearch.addResult(SearchResultModel.fromJson(search));
          }
        });
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'renderAnnotations',
      callback: (args) {
        renderAnnotations(controller);
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'onPushState',
      callback: (args) {
        Map<String, dynamic> state = args[0];
        if (!mounted) return;
        setState(() {
          canGoBack = state['canGoBack'];
          canGoForward = state['canGoForward'];
          showHistory = canGoBack || canGoForward;
        });
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'onImageClick',
      callback: (args) {
        String image = args[0];
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ImageViewer(
                      image: image,
                      bookName: widget.book.title,
                    )));
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'onFootnoteClose',
      callback: (args) {
        removeOverlay();
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'onPullUp',
      callback: (args) {
        widget.showOrHideAppBarAndBottomBar(true);
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'handleBookmark',
      callback: (args) async {
        Map<String, dynamic> detail = args[0]['detail'];
        bool remove = args[0]['remove'];
        String cfi = detail['cfi'] ?? '';
        double percentage = double.parse(detail['percentage'].toString());
        String content = detail['content'];

        if (remove) {
          ref.read(bookmarkProvider(widget.book.id).notifier).removeBookmark(
                cfi: cfi,
              );
          bookmarkCfi = '';
          bookmarkExists = false;
        } else {
          BookmarkModel bookmark = await ref
              .read(BookmarkProvider(widget.book.id).notifier)
              .addBookmark(
                BookmarkModel(
                  bookId: widget.book.id,
                  cfi: cfi,
                  percentage: percentage,
                  content: content,
                  chapter: chapterTitle,
                  updateTime: DateTime.now(),
                  createTime: DateTime.now(),
                ),
              );
          bookmarkCfi = cfi;
          bookmarkExists = true;
          addBookmark(bookmark);
        }
        widget.updateParent();
        setState(() {});
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'translateText',
      callback: (args) async {
        final text = args[0] as String;
        final service = Prefs().fullTextTranslateService;
        final from = Prefs().fullTextTranslateFrom;
        final to = Prefs().fullTextTranslateTo;
        final normalizedText = _normalizeTranslationText(text);

        try {
          final cached = await _getCachedTranslationText(
            service: service,
            from: from,
            to: to,
            text: normalizedText,
          );
          if (cached != null) {
            return cached;
          }

          final translatedText = await translateTextOnlyWithFallback(
            text,
            from,
            to,
            service: service,
            isFullText: true,
          );
          await _setCachedTranslationText(
            service: service,
            from: from,
            to: to,
            text: normalizedText,
            translatedText: translatedText,
          );
          return translatedText;
        } catch (e) {
          AnxLog.severe('Translation failed: $e');
          return 'Translation error: $e';
        }
      },
    );
    // Translation cache handlers
    controller.addJavaScriptHandler(
      handlerName: 'saveTranslationCache',
      callback: (args) async {
        try {
          final payload = args[0];
          String cacheJson;
          String cacheKey;

          if (payload is Map) {
            cacheJson = payload['cacheJson']?.toString() ?? '';
            cacheKey = payload['namespace']?.toString() ??
                _translationDomCacheStorageKey();
          } else {
            cacheJson = payload?.toString() ?? '';
            cacheKey = _translationDomCacheStorageKey();
          }

          Prefs().prefs.setString(cacheKey, cacheJson);
        } catch (e) {
          AnxLog.warning('Failed to save translation cache: $e');
        }
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'loadTranslationCache',
      callback: (args) async {
        try {
          final cacheKey = _translationDomCacheStorageKey();
          final cacheJson = Prefs().prefs.getString(cacheKey);
          return {
            'namespace': cacheKey,
            'cacheJson': cacheJson ?? '',
          };
        } catch (e) {
          AnxLog.warning('Failed to load translation cache: $e');
          return {
            'namespace': _translationDomCacheStorageKey(),
            'cacheJson': '',
          };
        }
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'onTranslationProgress',
      callback: (args) {
        if (args.isEmpty || !mounted) return;
        final progress = args[0] as Map;
        setState(() {
          _translationProgressActive = progress['active'] == true;
          _translationProgressCompleted =
              int.tryParse(progress['completed']?.toString() ?? '') ?? 0;
          _translationProgressTotal =
              int.tryParse(progress['total']?.toString() ?? '') ?? 0;
          _translationProgressFailed =
              int.tryParse(progress['failed']?.toString() ?? '') ?? 0;
        });
      },
    );
  }

  String _translationDomCacheStorageKey() {
    final service = Prefs().fullTextTranslateService;
    final from = Prefs().fullTextTranslateFrom;
    final to = Prefs().fullTextTranslateTo;
    final scope = translationServiceCacheScope(service);
    return 'translationDomCache_${widget.book.id}_${service.name}_${from.code}_${to.code}_$scope';
  }

  String _translationTextCacheKey(
    TranslateService service,
    LangListEnum from,
    LangListEnum to,
  ) {
    final scope = translationServiceCacheScope(service);
    return 'translationTextCache_${widget.book.id}_${service.name}_${from.code}_${to.code}_$scope';
  }

  Future<void> _ensureTranslationTextCacheLoaded(
    String storageKey,
  ) async {
    if (_translationTextCacheStorageKey == storageKey) return;

    await _flushTranslationTextCacheNow();
    _translationTextCacheStorageKey = storageKey;
    final cacheJson = Prefs().prefs.getString(storageKey);
    if (cacheJson == null || cacheJson.isEmpty) {
      _translationTextCache = {};
      _translationTextCacheDirty = false;
      _translationTextCachePendingChanges = 0;
      return;
    }

    try {
      final decoded = jsonDecode(cacheJson);
      _translationTextCache = decoded is Map<String, dynamic> ? decoded : {};
      _translationTextCacheDirty = false;
      _translationTextCachePendingChanges = 0;
    } catch (e) {
      AnxLog.warning('Failed to load translation text cache: $e');
      _translationTextCache = {};
      _translationTextCacheDirty = false;
      _translationTextCachePendingChanges = 0;
    }
  }

  Future<String?> _getCachedTranslationText({
    required TranslateService service,
    required LangListEnum from,
    required LangListEnum to,
    required String text,
  }) async {
    final storageKey = _translationTextCacheKey(service, from, to);
    await _ensureTranslationTextCacheLoaded(storageKey);

    final entry = _translationTextCache[_stableTranslationTextKey(text)];
    if (entry is! Map) return null;
    if (entry['text'] != text) return null;

    final translation = entry['translation']?.toString();
    if (translation == null || translation.trim().isEmpty) return null;
    if (_isFailedTranslationText(translation)) {
      _translationTextCache.remove(_stableTranslationTextKey(text));
      _scheduleTranslationTextCacheFlush();
      return null;
    }
    return translation;
  }

  Future<void> _setCachedTranslationText({
    required TranslateService service,
    required LangListEnum from,
    required LangListEnum to,
    required String text,
    required String translatedText,
  }) async {
    if (text.isEmpty || translatedText.trim().isEmpty) return;
    if (_isFailedTranslationText(translatedText)) return;

    final storageKey = _translationTextCacheKey(service, from, to);
    await _ensureTranslationTextCacheLoaded(storageKey);

    _translationTextCache[_stableTranslationTextKey(text)] = {
      'text': text,
      'translation': translatedText,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    const maxCacheSize = 5000;
    final keys = _translationTextCache.keys.toList(growable: false);
    if (keys.length > maxCacheSize) {
      for (final key in keys.take(keys.length - maxCacheSize)) {
        _translationTextCache.remove(key);
      }
    }

    _scheduleTranslationTextCacheFlush();
  }

  void _scheduleTranslationTextCacheFlush() {
    if (_translationTextCacheStorageKey == null) return;

    _translationTextCacheDirty = true;
    _translationTextCachePendingChanges += 1;

    const flushThreshold = 25;
    if (_translationTextCachePendingChanges >= flushThreshold) {
      _translationTextCacheFlushTimer?.cancel();
      _translationTextCacheFlushTimer = null;
      unawaited(_flushTranslationTextCacheNow());
      return;
    }

    _translationTextCacheFlushTimer?.cancel();
    _translationTextCacheFlushTimer = Timer(
      const Duration(milliseconds: 800),
      () => unawaited(_flushTranslationTextCacheNow()),
    );
  }

  Future<void> _flushTranslationTextCacheNow() async {
    _translationTextCacheFlushTimer?.cancel();
    _translationTextCacheFlushTimer = null;

    final storageKey = _translationTextCacheStorageKey;
    if (storageKey == null || !_translationTextCacheDirty) return;

    final cacheJson = jsonEncode(_translationTextCache);
    _translationTextCacheDirty = false;
    _translationTextCachePendingChanges = 0;

    try {
      await Prefs().prefs.setString(storageKey, cacheJson);
    } catch (e) {
      AnxLog.warning('Failed to flush translation text cache: $e');
      _translationTextCacheDirty = true;
      _scheduleTranslationTextCacheFlush();
    }
  }

  String _normalizeTranslationText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isFailedTranslationText(String text) {
    return isFailedTranslationResult(text);
  }

  String _stableTranslationTextKey(String text) {
    const int fnvPrime = 0x01000193;
    int hash = 0x811c9dc5;
    for (final codeUnit in text.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  Future<void> onWebViewCreated(InAppWebViewController controller) async {
    try {
      _bookResource ??=
          await Server().registerBookResource(File(widget.book.fileFullPath));
    } catch (error, stackTrace) {
      AnxLog.severe('Failed to register book resource', error, stackTrace);
      _failBookLoad(BookLoadFailure(
        code: 'resource_registration_failed',
        message: error.toString(),
        stage: BookLoadStage.bootstrap,
      ));
      return;
    }
    if (!mounted) {
      _bookResource?.revoke();
      _bookResource = null;
      return;
    }
    final url = _readerUrl(context, _bookResource!);
    if (AnxPlatform.isAndroid &&
        (kDebugMode || Prefs().developerOptionsEnabled)) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
    webViewController = controller;
    await setHandler(controller);
    _registerChapterContentBridge();
    _webViewReady = true;

    _startBookLoadTimers();
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));

    // Initialize translation mode based on book-specific settings
    Future.delayed(const Duration(milliseconds: 300), () async {
      // Load translation cache from persistent storage
      await webViewController.evaluateJavascript(source: '''
        (async function() {
          if (window.translator && typeof window.translator.loadCache === 'function') {
            await window.translator.loadCache();
          }
          if (window.translator && typeof window.translator.setRootMargin === 'function') {
            window.translator.setRootMargin('${Prefs().translationMargin}px');
          }
        })();
      ''');
      await setTranslationMode(
        Prefs().getBookTranslationMode(widget.book.id),
        restoreProgress: false,
      );
      _activeTranslationDomCacheNamespace = _translationDomCacheStorageKey();
      await configureSelection();
    });
  }

  void removeOverlay({bool preserveAutoMarkSession = false}) {
    _selectionClearLocked = false;
    _selectionClearPending = false;
    if (!preserveAutoMarkSession) finalizeSelectionAutoMark();
    if (contextMenuEntry == null || contextMenuEntry?.mounted == false) return;
    contextMenuEntry?.remove();
    contextMenuEntry = null;
  }

  Future<void> _showSelectionContextMenuFromWebView() async {
    if (!AnxPlatform.isAndroid) return;

    try {
      await webViewController.evaluateJavascript(source: '''
        (function() {
          if (typeof window.showContextMenu !== 'function') return;
          if (window.showContextMenu()) return;
          window.setTimeout(function() {
            window.showContextMenu();
          }, 250);
        })();
      ''');
    } catch (e) {
      AnxLog.warning('Failed to show Android selection context menu: $e');
    }
  }

  Future<void> _handlePointerEvents(PointerEvent event) async {
    if (await isFootNoteOpen() || Prefs().pageTurnStyle == PageTurn.scroll) {
      return;
    }
    // Disable scroll wheel page turning when keyboard shortcuts are enabled
    if (Prefs().keyboardShortcutTurnPage) {
      return;
    }
    if (event is PointerScrollEvent) {
      _accumulatedScrollDelta += event.scrollDelta.dy;

      _scrollDebounceTimer?.cancel();
      _scrollDebounceTimer = Timer(const Duration(milliseconds: 80), () {
        if (_accumulatedScrollDelta.abs() >= _scrollThreshold) {
          if (_accumulatedScrollDelta > 0) {
            nextPage();
          } else {
            prevPage();
          }
        }
        _accumulatedScrollDelta = 0;
      });
    }
  }

  @override
  void initState() {
    book = widget.book;
    unawaited(_seedDeviceReadingPosition());
    _activeTranslationMode = Prefs().getBookTranslationMode(widget.book.id);
    _activeTranslationDomCacheNamespace = _translationDomCacheStorageKey();
    _lastEInkMode = Prefs().isEInkMode;
    Prefs().addListener(_handleTranslationPrefsChanged);
    getThemeColor();

    contextMenu = ContextMenu(
      settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
      onCreateContextMenu: (hitTestResult) async {
        await _showSelectionContextMenuFromWebView();
      },
      onHideContextMenu: () {
        // removeOverlay();
      },
    );
    if (Prefs().openBookAnimation && !Prefs().reduceMotion) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _animation =
          Tween<double>(begin: 1.0, end: 0.0).animate(_animationController!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animationController!.forward();
      });
    }
    super.initState();
  }

  Future<void> _seedDeviceReadingPosition() async {
    if (widget.book.lastReadPosition.isEmpty &&
        widget.book.readingPercentage <= 0) {
      return;
    }
    final deviceId = await ReadingDeviceIdentity().getOrCreate();
    final existing =
        await readingAgentSyncDao.position(widget.book.id, deviceId);
    if (existing != null) return;
    await readingAgentSyncDao.savePosition(BookDeviceReadingPosition(
      bookId: widget.book.id,
      deviceId: deviceId,
      cfi: widget.book.lastReadPosition,
      progress: widget.book.readingPercentage,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> saveReadingProgress() async {
    if (cfi == '' || (widget.cfi != null && !_hasMovedFromInitialTarget)) {
      return;
    }

    Prefs().setBookTranslationProgress(
      widget.book.id,
      _activeTranslationMode,
      cfi: cfi,
      percentage: percentage,
    );

    final book = widget.book;
    if (_activeTranslationMode == TranslationModeEnum.off) {
      book.lastReadPosition = cfi;
    }
    book.readingPercentage = percentage;
    await bookDao.updateBook(book);
    final deviceId = await ReadingDeviceIdentity().getOrCreate();
    await readingAgentSyncDao.savePosition(BookDeviceReadingPosition(
      bookId: book.id,
      deviceId: deviceId,
      cfi: cfi,
      progress: percentage,
      chapterHref: chapterHref,
      chapterTitle: chapterTitle,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    if (mounted) {
      ref.read(bookListProvider.notifier).refresh();
    }
  }

  String? _savedCfiForMode(TranslationModeEnum mode) {
    final savedProgress = Prefs().getBookTranslationProgress(
      widget.book.id,
      mode,
    );
    if (savedProgress != null) return savedProgress.cfi;

    if (mode == TranslationModeEnum.off &&
        widget.book.lastReadPosition.isNotEmpty) {
      return widget.book.lastReadPosition;
    }

    return null;
  }

  void _resetTranslationProgress() {
    _currentPageTranslationTimer?.cancel();

    if (!mounted) return;
    setState(() {
      _translationProgressActive = false;
      _translationProgressCompleted = 0;
      _translationProgressTotal = 0;
      _translationProgressFailed = 0;
    });
  }

  @override
  void dispose() {
    Prefs().removeListener(_handleTranslationPrefsChanged);
    unawaited(_flushTranslationTextCacheNow());
    _translationSettingsRefreshTimer?.cancel();
    _currentPageTranslationTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    _slowLoadTimer?.cancel();
    _loadTimeoutTimer?.cancel();
    if (_webViewReady) {
      unawaited(webViewController.evaluateJavascript(
        source: 'window.disposeReader && window.disposeReader()',
      ));
    }
    _bookResource?.revoke();
    _bookResource = null;
    _animationController?.dispose();
    saveReadingProgress();
    removeOverlay();
    super.dispose();
  }

  InAppWebViewSettings initialSettings = InAppWebViewSettings(
    supportZoom: false,
    transparentBackground: true,
    isInspectable: kDebugMode,
    useHybridComposition: true,
  );

  bool get isDarkMode =>
      Theme.of(navigatorKey.currentContext!).brightness == Brightness.dark;

  void changeReadingInfo() {
    setState(() {});
  }

  Widget _buildHistoryCapsule() {
    final l10n = L10n.of(context);
    final buttonColor = Color(int.parse('0x$textColor')).withAlpha(200);

    // Common button style for all history navigation buttons
    final buttonStyle = TextButton.styleFrom(
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
    );

    // Helper method to create history navigation buttons
    Widget createHistoryButton(
        IconData icon, String label, VoidCallback onPressed) {
      return TextButton.icon(
        icon: Icon(icon, size: 18, color: buttonColor),
        label: Text(label, style: TextStyle(color: buttonColor, fontSize: 14)),
        onPressed: onPressed,
        style: buttonStyle,
      );
    }

    // Build buttons list
    final List<Widget> buttons = [];

    if (canGoBack) {
      buttons.add(createHistoryButton(
        Icons.arrow_back,
        l10n.historyBack,
        backHistory,
      ));
    }

    buttons.add(createHistoryButton(
      Icons.close,
      l10n.historyClose,
      () => setState(() => showHistory = false),
    ));

    if (canGoForward) {
      buttons.add(createHistoryButton(
        Icons.arrow_forward,
        l10n.historyForward,
        forwardHistory,
      ));
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainer
                    .withAlpha(123),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: buttons,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _readerUrl(BuildContext context, BookResourceHandle resource) {
    final initialMode = Prefs().getBookTranslationMode(widget.book.id);
    final initialCfi = widget.cfi ??
        _savedCfiForMode(initialMode) ??
        widget.book.lastReadPosition;
    return generateUrl(
      resource.url,
      initialCfi,
      backgroundColor: backgroundColor,
      textColor: textColor,
      isDarkMode: Theme.of(context).brightness == Brightness.dark,
      i18n: {
        'translateError': L10n.of(context).translateError,
        'retry': L10n.of(context).commonRetry,
        'retrying': '${L10n.of(context).commonRetry}...',
      },
    );
  }

  void _startBookLoadTimers() {
    _slowLoadTimer?.cancel();
    _loadTimeoutTimer?.cancel();
    if (mounted) {
      setState(() => _bookLoadState = const BookLoadState());
    }
    _slowLoadTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || _bookLoadState.isReady || _bookLoadState.hasFailed) {
        return;
      }
      setState(() {
        _bookLoadState = _bookLoadState.copyWith(isSlow: true);
      });
      AnxLog.warning(
        'BookLoad[${widget.book.id}] slow stage=${_bookLoadState.stage.name}',
      );
    });
    _loadTimeoutTimer = Timer(const Duration(seconds: 120), () {
      if (_bookLoadState.isReady || _bookLoadState.hasFailed) return;
      _failBookLoad(BookLoadFailure(
        code: 'reader_timeout',
        message: 'Reader initialization timed out',
        stage: _bookLoadState.stage,
      ));
    });
  }

  void _completeBookLoad() {
    _slowLoadTimer?.cancel();
    _loadTimeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _bookLoadState = _bookLoadState.copyWith(
        stage: BookLoadStage.ready,
        isSlow: false,
      );
    });
    AnxLog.info('BookLoad[${widget.book.id}] stage=ready');
  }

  void _failBookLoad(BookLoadFailure failure) {
    _slowLoadTimer?.cancel();
    _loadTimeoutTimer?.cancel();
    AnxLog.severe(
      'BookLoad[${widget.book.id}] failed code=${failure.code} '
      'stage=${failure.stage.name} message=${failure.message}',
    );
    if (!mounted) return;
    setState(() {
      _bookLoadState = BookLoadState(
        stage: BookLoadStage.failed,
        failure: failure,
      );
    });
  }

  void _retryBookLoad() {
    _slowLoadTimer?.cancel();
    _loadTimeoutTimer?.cancel();
    if (_webViewReady) {
      unawaited(webViewController.evaluateJavascript(
        source: 'window.disposeReader && window.disposeReader()',
      ));
    }
    setState(() {
      _webViewReady = false;
      _bookLoadState = const BookLoadState();
      _webViewGeneration++;
    });
  }

  Future<void> _exportReaderLog() async {
    final logFile = await getLogFile();
    await shareFile(file: logFile, title: 'Anx Reader log');
  }

  Widget _buildBookLoadOverlay() {
    final failure = _bookLoadState.failure;
    final isFailed = failure != null;
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: ColoredBox(
        color: colorScheme.surface,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFailed ? Icons.error_outline : Icons.menu_book_outlined,
                      size: 44,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isFailed
                          ? L10n.of(context).bookLoadFailedTitle
                          : _bookLoadState.isSlow
                              ? L10n.of(context).bookLoadSlowTitle
                              : L10n.of(context).bookLoadOpeningTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFailed
                          ? '${failure.code}: ${failure.message}'
                          : _bookLoadState.isSlow
                              ? L10n.of(context).bookLoadSlowMessage
                              : L10n.of(context).bookLoadCurrentStage(
                                  _bookLoadState.stage.name,
                                ),
                      textAlign: TextAlign.center,
                    ),
                    if (!isFailed && !_bookLoadState.isSlow) ...[
                      const SizedBox(height: 20),
                      const LinearProgressIndicator(),
                    ],
                    if (isFailed || _bookLoadState.isSlow) ...[
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (isFailed)
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back),
                              label: Text(L10n.of(context).bookLoadBackToShelf),
                            ),
                          OutlinedButton.icon(
                            onPressed: _exportReaderLog,
                            icon: const Icon(Icons.description_outlined),
                            label: Text(L10n.of(context).bookLoadExportLog),
                          ),
                          FilledButton.icon(
                            onPressed: _retryBookLoad,
                            icon: const Icon(Icons.refresh),
                            label: Text(L10n.of(context).commonRetry),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget readingInfoWidget() {
    if (chapterCurrentPage == 0 && percentage == 0.0) {
      return const SizedBox();
    }

    final readingInfoColor = Color(int.parse('0x$textColor')).withAlpha(150);
    final iconColor = Color(int.parse('0x$textColor'));

    Widget getWidget(ReadingInfoEnum readingInfoEnum, TextStyle textStyle) {
      final batteryTextStyle = TextStyle(
        color: iconColor,
        fontSize: (textStyle.fontSize ?? 10) - 1,
      );
      final batteryIconSize = (textStyle.fontSize ?? 10) * 2.7;

      final chapterTitleWidget = Text(
        (chapterCurrentPage == 1 ? widget.book.title : chapterTitle),
        style: textStyle,
      );

      final chapterProgressWidget = Text(
        '$chapterCurrentPage/$chapterTotalPages',
        style: textStyle,
      );

      final bookProgressWidget =
          Text('${(percentage * 100).toStringAsFixed(2)}%', style: textStyle);

      final timeWidget = MinuteClock(textStyle: textStyle);

      final batteryWidget = FutureBuilder(
          future: Battery().batteryLevel,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        0, (textStyle.fontSize ?? 10) * 0.08, 2, 0),
                    child: Text('${snapshot.data}', style: batteryTextStyle),
                  ),
                  Icon(
                    HeroIcons.battery_0,
                    size: batteryIconSize,
                    color: iconColor,
                  ),
                ],
              );
            } else {
              return const SizedBox();
            }
          });

      Widget batteryAndTimeWidget() => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              batteryWidget,
              const SizedBox(width: 5),
              timeWidget,
            ],
          );

      switch (readingInfoEnum) {
        case ReadingInfoEnum.chapterTitle:
          return chapterTitleWidget;
        case ReadingInfoEnum.chapterProgress:
          return chapterProgressWidget;
        case ReadingInfoEnum.bookProgress:
          return bookProgressWidget;
        case ReadingInfoEnum.battery:
          return batteryWidget;
        case ReadingInfoEnum.time:
          return timeWidget;
        case ReadingInfoEnum.batteryAndTime:
          return batteryAndTimeWidget();
        case ReadingInfoEnum.none:
          return const SizedBox(width: 30);
      }
    }

    final readingInfo = Prefs().readingInfo;

    final headerTextStyle = TextStyle(
      color: readingInfoColor,
      fontSize: readingInfo.header.fontSize,
    );
    final footerTextStyle = TextStyle(
      color: readingInfoColor,
      fontSize: readingInfo.footer.fontSize,
    );

    List<Widget> headerWidgets = [
      getWidget(readingInfo.header.left, headerTextStyle),
      getWidget(readingInfo.header.center, headerTextStyle),
      getWidget(readingInfo.header.right, headerTextStyle),
    ];

    List<Widget> footerWidgets = [
      getWidget(readingInfo.footer.left, footerTextStyle),
      getWidget(readingInfo.footer.center, footerTextStyle),
      getWidget(readingInfo.footer.right, footerTextStyle),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: readingInfo.header.verticalMargin,
            left: readingInfo.header.leftMargin,
            right: readingInfo.header.rightMargin,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: headerWidgets,
          ),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.only(
            bottom: readingInfo.footer.verticalMargin,
            left: readingInfo.footer.leftMargin,
            right: readingInfo.footer.rightMargin,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: footerWidgets,
          ),
        ),
      ],
    );
  }

  Widget translationProgressWidget() {
    if (!_translationProgressActive || _translationProgressTotal <= 0) {
      return const SizedBox.shrink();
    }

    final progress = (_translationProgressCompleted / _translationProgressTotal)
        .clamp(0.0, 1.0);
    final label =
        '${L10n.of(context).translationProgress} $_translationProgressCompleted/$_translationProgressTotal';
    final top = MediaQuery.paddingOf(context).top + 8;

    return Positioned(
      top: top,
      right: 12,
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              constraints: const BoxConstraints(minWidth: 132),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainer
                    .withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  if (_translationProgressFailed > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${L10n.of(context).translationProgressFailed}: $_translationProgressFailed',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildWebviewWithIOSWorkaround(BuildContext context) {
    final webView = InAppWebView(
      key: ValueKey('reader-webview-$_webViewGeneration'),
      webViewEnvironment: webViewEnvironment,
      initialSettings: initialSettings,
      contextMenu: contextMenu,
      onWebViewCreated: onWebViewCreated,
      onReceivedError: (controller, request, error) {
        if (request.isForMainFrame == false) return;
        _failBookLoad(BookLoadFailure(
          code: 'webview_load_error_${error.type.toNativeValue()}',
          message: error.description,
          stage: _bookLoadState.stage,
        ));
      },
      onReceivedHttpError: (controller, request, response) {
        if (request.isForMainFrame == false) return;
        final statusCode = response.statusCode ?? 0;
        _failBookLoad(BookLoadFailure(
          code: 'http_$statusCode',
          message: response.reasonPhrase ?? 'HTTP $statusCode',
          stage: _bookLoadState.stage,
        ));
      },
      onConsoleMessage: webviewConsoleMessage,
    );

    if (!AnxPlatform.isIOS) {
      return SizedBox.expand(child: webView);
    }

    return SizedBox.expand(
      child: Stack(
        children: [
          webView,
          Positioned.fill(
            child: PointerInterceptor(
              intercepting: !_isTopOfNavigationStack,
              debug: false,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        _handlePointerEvents(event);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            buildWebviewWithIOSWorkaround(context),
            if (!_bookLoadState.isReady) _buildBookLoadOverlay(),
            readingInfoWidget(),
            translationProgressWidget(),
            if (showHistory) _buildHistoryCapsule(),
            if (Prefs().openBookAnimation && !Prefs().reduceMotion)
              SizedBox.expand(
                  child: IgnorePointer(
                ignoring: true,
                child: FadeTransition(
                    opacity: _animation!, child: BookCover(book: widget.book)),
              )),
          ],
        ),
      ),
    );
  }
}
