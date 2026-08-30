import 'dart:async';
import 'dart:math' as math;

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/dao/theme.dart';
import 'package:anx_reader/enums/ai_panel_position.dart';
import 'package:anx_reader/enums/ai_chat_display_mode.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/enums/sync_trigger.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/ai_quick_prompt_chip.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/page/book_detail.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/ui/status_bar.dart';
import 'package:anx_reader/widgets/ai/ai_chat_stream.dart';
import 'package:anx_reader/widgets/ai/ai_stream.dart';
import 'package:anx_reader/widgets/reading_page/notes_widget.dart';
import 'package:anx_reader/models/reading_time.dart';
import 'package:anx_reader/widgets/reading_page/progress_widget.dart';
import 'package:anx_reader/widgets/reading_page/tts_fab.dart';
import 'package:anx_reader/widgets/reading_page/tts_widget.dart';
import 'package:anx_reader/widgets/reading_page/style_widget.dart';
import 'package:anx_reader/widgets/reading_page/toc_widget.dart';
import 'package:anx_reader/widgets/common/axis_flex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart'
// show debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ReadingPage extends ConsumerStatefulWidget {
  const ReadingPage({
    super.key,
    required this.book,
    this.cfi,
    required this.initialThemes,
    this.heroTag,
  });

  final Book book;
  final String? cfi;
  final List<ReadTheme> initialThemes;
  final String? heroTag;

  @override
  ConsumerState<ReadingPage> createState() => ReadingPageState();
}

final GlobalKey<ReadingPageState> readingPageKey =
    GlobalKey<ReadingPageState>();
final epubPlayerKey = GlobalKey<EpubPlayerState>();

class ReadingPageState extends ConsumerState<ReadingPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const empty = SizedBox.shrink();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Book _book;
  late Widget _currentPage = empty;
  final Stopwatch _readTimeWatch = Stopwatch();
  DateTime? _sessionStart;
  Timer? _awakeTimer;
  bool bottomBarOffstage = true;
  late String heroTag;
  Widget? _aiChat;
  final aiChatKey = GlobalKey<AiChatStreamState>();
  static const double _aiChatMinWidth = 240;
  late double _aiChatWidth;
  static const double _aiChatMinHeight = 200;
  late double _aiChatHeight;
  bool _isResizingAiChat = false;
  bool bookmarkExists = false;

  late final FocusNode _readerFocusNode;
  // late final VolumeKeyBoard _volumeKeyBoard;
  // bool _volumeKeyListenerAttached = false;

  @override
  void initState() {
    _readerFocusNode = FocusNode(debugLabel: 'reading_page_focus');

    // Initialize AI panel sizes from persistent storage
    _aiChatWidth = Prefs().aiPanelWidth;
    _aiChatHeight = Prefs().aiPanelHeight;

    if (widget.book.isDeleted) {
      Navigator.pop(context);
      AnxToast.show(L10n.of(context).bookDeleted);
      return;
    }
    if (Prefs().hideStatusBar) {
      hideStatusBar();
    }

    WidgetsBinding.instance.addObserver(this);
    _readTimeWatch.start();
    _sessionStart = DateTime.now();
    setAwakeTimer(Prefs().awakeTime);

    _book = widget.book;
    heroTag = widget.heroTag ?? 'preventHeroWhenStart';
    // _volumeKeyBoard = VolumeKeyBoard.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestReaderFocus();
        // _attachVolumeKeyListener();
      }
    });
    // delay 1000ms to prevent hero animation
    if (widget.heroTag == null) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            heroTag = _book.coverFullPath;
          });
        }
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    Sync().syncData(SyncDirection.upload, ref, trigger: SyncTrigger.auto);
    _readTimeWatch.stop();
    _awakeTimer?.cancel();
    WakelockPlus.disable();
    showStatusBar();
    WidgetsBinding.instance.removeObserver(this);
    readingTimeDao.insertReadingTime(
      ReadingTime(
        bookId: _book.id,
        readingTime: _readTimeWatch.elapsed.inSeconds,
      ),
      startedAt: _sessionStart,
    );
    _sessionStart = null;
    audioHandler.stop();
    // if (_volumeKeyListenerAttached) {
    //   unawaited(_volumeKeyBoard.removeListener());
    // }
    _readerFocusNode.dispose();
    super.dispose();
  }

  void _requestReaderFocus() {
    if (bottomBarOffstage && !_readerFocusNode.hasFocus) {
      _readerFocusNode.requestFocus();
    }
  }

  void _releaseReaderFocus() {
    if (_readerFocusNode.hasFocus) {
      _readerFocusNode.unfocus();
    }
  }

  // Future<void> _attachVolumeKeyListener() async {
  //   if (defaultTargetPlatform != TargetPlatform.iOS ||
  //       _volumeKeyListenerAttached) {
  //     return;
  //   }

  //   try {
  //     await _volumeKeyBoard.addListener(_handleVolumeKeyEvent);
  //     _volumeKeyListenerAttached = true;
  //   } catch (error) {
  //     debugPrint('Failed to attach volume key listener: $error');
  //   }
  // }

  // void _handleVolumeKeyEvent(VolumeKey key) {
  //   if (!Prefs().volumeKeyTurnPage || !_readerFocusNode.hasFocus) {
  //     return;
  //   }

  //   if (key == VolumeKey.up) {
  //     epubPlayerKey.currentState?.prevPage();
  //   } else if (key == VolumeKey.down) {
  //     epubPlayerKey.currentState?.nextPage();
  //   }
  // }

  KeyEventResult _handleReaderKeyEvent(FocusNode node, KeyEvent event) {
    if (!_readerFocusNode.hasFocus) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final logicalKey = event.logicalKey;

    if (logicalKey == LogicalKeyboardKey.arrowRight ||
        logicalKey == LogicalKeyboardKey.arrowDown ||
        logicalKey == LogicalKeyboardKey.pageDown ||
        logicalKey == LogicalKeyboardKey.space) {
      epubPlayerKey.currentState?.nextPage();
      return KeyEventResult.handled;
    }

    if (logicalKey == LogicalKeyboardKey.arrowLeft ||
        logicalKey == LogicalKeyboardKey.arrowUp ||
        logicalKey == LogicalKeyboardKey.pageUp) {
      epubPlayerKey.currentState?.prevPage();
      return KeyEventResult.handled;
    }

    if (logicalKey == LogicalKeyboardKey.enter) {
      showOrHideAppBarAndBottomBar(true);
      return KeyEventResult.handled;
    }

    // Handle Ctrl+[ and Ctrl+] for page turning when keyboard shortcut is enabled
    if (Prefs().keyboardShortcutTurnPage) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed;
      if (isControlPressed && logicalKey == LogicalKeyboardKey.bracketLeft) {
        epubPlayerKey.currentState?.prevPage();
        return KeyEventResult.handled;
      }
      if (isControlPressed && logicalKey == LogicalKeyboardKey.bracketRight) {
        epubPlayerKey.currentState?.nextPage();
        return KeyEventResult.handled;
      }
      final bool isSimulatedCtrlLeft = event.character == '\u001b';
      final bool isSimulatedCtrlRight = event.character == '\u001d';
      if (isSimulatedCtrlLeft) {
        epubPlayerKey.currentState?.prevPage();
        return KeyEventResult.handled;
      }
      if (isSimulatedCtrlRight) {
        epubPlayerKey.currentState?.nextPage();
        return KeyEventResult.handled;
      }
    }

    if (Prefs().volumeKeyTurnPage) {
      if (event.physicalKey == PhysicalKeyboardKey.audioVolumeUp) {
        epubPlayerKey.currentState?.prevPage();
        return KeyEventResult.handled;
      }
      if (event.physicalKey == PhysicalKeyboardKey.audioVolumeDown) {
        epubPlayerKey.currentState?.nextPage();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_readTimeWatch.isRunning) {
          _readTimeWatch.start();
        }
        _sessionStart ??= DateTime.now();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_readTimeWatch.isRunning) {
          _readTimeWatch.stop();
        }
        if (state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.detached) {
          final elapsedSeconds = _readTimeWatch.elapsed.inSeconds;
          if (elapsedSeconds > 5) {
            epubPlayerKey.currentState?.saveReadingProgress();
            readingTimeDao.insertReadingTime(
              ReadingTime(
                bookId: _book.id,
                readingTime: elapsedSeconds,
              ),
              startedAt: _sessionStart,
            );
          }
          _readTimeWatch.reset();
          _sessionStart = null;
        }
        break;
    }
  }

  Future<void> setAwakeTimer(int minutes) async {
    _awakeTimer?.cancel();
    _awakeTimer = null;
    WakelockPlus.enable();
    _awakeTimer = Timer.periodic(Duration(minutes: minutes), (timer) {
      WakelockPlus.disable();
      _awakeTimer?.cancel();
      _awakeTimer = null;
    });
  }

  void resetAwakeTimer() {
    setAwakeTimer(Prefs().awakeTime);
  }

  void showBottomBar() {
    setState(() {
      showStatusBarWithoutResize();
      bottomBarOffstage = false;
      _releaseReaderFocus();
    });
  }

  void hideBottomBar() {
    setState(() {
      _currentPage = empty;
      bottomBarOffstage = true;
      if (Prefs().hideStatusBar) {
        hideStatusBar();
      }
      _requestReaderFocus();
    });
  }

  void showOrHideAppBarAndBottomBar(bool show) {
    if (show) {
      showBottomBar();
    } else {
      hideBottomBar();
    }
  }

  Future<void> tocHandler() async {
    hideBottomBar();
    _scaffoldKey.currentState?.openDrawer();
  }

  void noteHandler() {
    setState(() {
      _currentPage = ReadingNotes(book: _book);
    });
  }

  void progressHandler() {
    setState(() {
      _currentPage = ProgressWidget(
        epubPlayerKey: epubPlayerKey,
        showOrHideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
      );
    });
  }

  Future<void> styleHandler(StateSetter modalSetState) async {
    List<ReadTheme> themes = await themeDao.selectThemes();
    setState(() {
      _currentPage = StyleWidget(
        themes: themes,
        epubPlayerKey: epubPlayerKey,
        setCurrentPage: (Widget page) {
          modalSetState(() {
            _currentPage = page;
          });
        },
        hideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
      );
    });
  }

  Future<void> ttsHandler() async {
    setState(() {
      _currentPage = TtsWidget(
        epubPlayerKey: epubPlayerKey,
      );
    });
  }

  double _aiChatMaxWidth(BuildContext context) {
    final totalWidth = MediaQuery.of(context).size.width;
    final maxByPercentage = totalWidth * 0.65;
    final maxByRemaining = totalWidth - 320;
    final maxWidth = math.min(maxByPercentage, maxByRemaining);
    return math.max(_aiChatMinWidth, maxWidth);
  }

  double _aiChatMaxHeight(BuildContext context) {
    final totalHeight = MediaQuery.of(context).size.height;
    final maxByPercentage = totalHeight * 0.60;
    final maxByRemaining = totalHeight - 320;
    final maxHeight = math.min(maxByPercentage, maxByRemaining);
    return math.max(_aiChatMinHeight, maxHeight);
  }

  void _beginAiChatResize(double globalDx) {
    setState(() {
      _isResizingAiChat = true;
    });
  }

  void _applyAiChatResizeDelta(double delta, BuildContext context) {
    final maxWidth = _aiChatMaxWidth(context);
    final updated =
        (_aiChatWidth - delta).clamp(_aiChatMinWidth, maxWidth).toDouble();
    if (updated != _aiChatWidth) {
      setState(() {
        _aiChatWidth = updated;
      });
    }
  }

  void _endAiChatResize() {
    if (_isResizingAiChat) {
      setState(() {
        _isResizingAiChat = false;
      });
      // Save the panel sizes to persistent storage
      Prefs().aiPanelWidth = _aiChatWidth;
      Prefs().aiPanelHeight = _aiChatHeight;
    }
  }

  void _beginAiChatResizeVertical(double globalDy) {
    setState(() {
      _isResizingAiChat = true;
    });
  }

  void _applyAiChatResizeDeltaVertical(double delta, BuildContext context) {
    final maxHeight = _aiChatMaxHeight(context);
    final updated =
        (_aiChatHeight - delta).clamp(_aiChatMinHeight, maxHeight).toDouble();
    if (updated != _aiChatHeight) {
      setState(() {
        _aiChatHeight = updated;
      });
    }
  }

  Future<void> onLoadEnd() async {
    if (Prefs().autoSummaryPreviousContent) {
      final delayLevel = Prefs().autoSummaryDelayLevel;
      final now = DateTime.now();

      if (delayLevel > 0) {
        final lastTimestamp = Prefs().getLastAutoSummaryTimestamp(_book.id);
        if (lastTimestamp != null) {
          bool shouldTrigger;
          switch (delayLevel) {
            case 1: // 30 minutes
              shouldTrigger =
                  now.difference(lastTimestamp).inMinutes >= 30;
              break;
            case 2: // 3 hours
              shouldTrigger =
                  now.difference(lastTimestamp).inHours >= 3;
              break;
            case 3: // Next day (cross midnight)
              shouldTrigger = now.year != lastTimestamp.year ||
                  now.month != lastTimestamp.month ||
                  now.day != lastTimestamp.day;
              break;
            case 4: // 3 days
              shouldTrigger =
                  now.difference(lastTimestamp).inDays >= 3;
              break;
            case 5: // 1 week
              shouldTrigger =
                  now.difference(lastTimestamp).inDays >= 7;
              break;
            default:
              shouldTrigger = true;
          }
          if (!shouldTrigger) return;
        }
      }

      Prefs().setLastAutoSummaryTimestamp(_book.id, now);

      final previousContent =
          await epubPlayerKey.currentState!.previousContent(2000);
      final prompt = generatePromptSummaryThePreviousContent(previousContent);
      SmartDialog.show(
        builder: (context) => AlertDialog(
          title: Text(L10n.of(context).readingPageSummaryPreviousContent),
          content: AiStream(
            prompt: prompt,
          ),
        ),
        onDismiss: () {
          cancelActiveAiRequest();
        },
      );
    }
  }

  List<Widget> _buildAiChatTrailing(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          setState(() {
            Prefs().aiPanelPosition =
                Prefs().aiPanelPosition == AiPanelPositionEnum.right
                    ? AiPanelPositionEnum.bottom
                    : AiPanelPositionEnum.right;
            // Rebuild the _aiChat widget to update the button
            _rebuildAiChat();
          });
        },
        icon: Icon(
          Prefs().aiPanelPosition == AiPanelPositionEnum.right
              ? Icons.arrow_downward
              : Icons.arrow_forward,
        ),
        tooltip: Prefs().aiPanelPosition == AiPanelPositionEnum.right
            ? L10n.of(context).aiShowAtBottom
            : L10n.of(context).aiShowAtRight,
      ),
      IconButton(
        onPressed: () {
          setState(() {
            _aiChat = null;
          });
        },
        icon: const Icon(Icons.close),
      ),
    ];
  }

  void _rebuildAiChat() {
    if (_aiChat == null) return;
    final maxWidth = _aiChatMaxWidth(context);
    final maxHeight = _aiChatMaxHeight(context);
    _aiChatWidth = _aiChatWidth.clamp(_aiChatMinWidth, maxWidth);
    _aiChatHeight = _aiChatHeight.clamp(_aiChatMinHeight, maxHeight);
    _aiChat = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AiChatStream(
            key: aiChatKey,
            initialMessage: null,
            sendImmediate: false,
            quickPromptChips: _getAiQuickPromptChips(),
            trailing: _buildAiChatTrailing(context),
          ),
        ),
      ],
    );
  }

  List<AiQuickPromptChip> _getAiQuickPromptChips() {
    return [
      AiQuickPromptChip(
        icon: EvaIcons.book,
        label: L10n.of(context).settingsAiPromptSummaryTheChapter,
        prompt: generatePromptSummaryTheChapter().buildString(),
      ),
      AiQuickPromptChip(
        icon: Icons.menu_book_rounded,
        label: L10n.of(context).settingsAiPromptSummaryTheBook,
        prompt: generatePromptSummaryTheBook().buildString(),
      ),
      AiQuickPromptChip(
        icon: Icons.account_tree_outlined,
        label: L10n.of(context).settingsAiPromptMindmap,
        prompt: generatePromptMindmap().buildString(),
      ),
      // User custom prompts (enabled only)
      ...Prefs()
          .userPrompts
          .where((p) => p.enabled)
          .map((userPrompt) => AiQuickPromptChip(
                icon: Icons.person_outline,
                label: userPrompt.name,
                prompt: userPrompt.content,
              )),
    ];
  }

  Future<void> showAiChat({
    String? content,
    bool sendImmediate = false,
  }) async {
    List<AiQuickPromptChip> quickPrompts = _getAiQuickPromptChips();

    // Determine display mode
    final displayMode = Prefs().aiChatDisplayMode;
    final screenWidth = MediaQuery.of(navigatorKey.currentContext!).size.width;

    bool shouldShowAsPopup = false;

    switch (displayMode) {
      case AiChatDisplayMode.adaptive:
        // Show as popup if width < 600
        shouldShowAsPopup = screenWidth < 600;
        break;
      case AiChatDisplayMode.popup:
        // Always show as popup
        shouldShowAsPopup = true;
        break;
      case AiChatDisplayMode.split:
        // Always show as split screen
        shouldShowAsPopup = false;
        break;
    }

    if (shouldShowAsPopup) {
      showModalBottomSheet(
          context: navigatorKey.currentContext!,
          isScrollControlled: true,
          showDragHandle: false,
          clipBehavior: Clip.hardEdge,
          builder: (context) => PointerInterceptor(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: AiChatStream(
                      key: aiChatKey,
                      initialMessage: content,
                      sendImmediate: sendImmediate,
                      quickPromptChips: quickPrompts,
                    ),
                  ),
                ),
              ));
    } else {
      setState(() {
        final maxWidth = _aiChatMaxWidth(navigatorKey.currentContext!);
        final maxHeight = _aiChatMaxHeight(navigatorKey.currentContext!);
        _aiChatWidth = _aiChatWidth.clamp(_aiChatMinWidth, maxWidth);
        _aiChatHeight = _aiChatHeight.clamp(_aiChatMinHeight, maxHeight);
        _aiChat = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AiChatStream(
                key: aiChatKey,
                initialMessage: content,
                sendImmediate: sendImmediate,
                quickPromptChips: quickPrompts,
                trailing: _buildAiChatTrailing(navigatorKey.currentContext!),
              ),
            ),
          ],
        );
      });
    }
  }

  void updateState() {
    if (mounted) {
      setState(() {
        bookmarkExists = epubPlayerKey.currentState!.bookmarkExists;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var aiButton = IconButton(
      tooltip: L10n.of(context).aiChat,
      icon: const Icon(Icons.auto_awesome),
      onPressed: () async {
        // Determine if should show as split based on display mode
        final displayMode = Prefs().aiChatDisplayMode;
        final screenWidth = MediaQuery.of(context).size.width;

        bool shouldShowAsSplit = false;
        switch (displayMode) {
          case AiChatDisplayMode.adaptive:
            shouldShowAsSplit = screenWidth >= 600;
            break;
          case AiChatDisplayMode.split:
            shouldShowAsSplit = true;
            break;
          case AiChatDisplayMode.popup:
            shouldShowAsSplit = false;
            break;
        }

        if (shouldShowAsSplit && _aiChat != null) {
          setState(() {
            _aiChat = null;
          });
          return;
        }

        showOrHideAppBarAndBottomBar(false);
        showAiChat();
      },
    );
    Offstage controller = Offstage(
      offstage: bottomBarOffstage,
      child: PointerInterceptor(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                  onTap: () {
                    showOrHideAppBarAndBottomBar(false);
                  },
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {},
                  onVerticalDragEnd: (details) {},
                  child: Container(
                    color: Colors.black.withAlpha(30),
                  )),
            ),
            Column(
              children: [
                AppBar(
                  title: Text(_book.title, overflow: TextOverflow.ellipsis),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      // close reading page
                      Navigator.pop(context);
                    },
                  ),
                  actions: [
                    if (EnvVar.enableAIFeature) aiButton,
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: L10n.of(context).readingPageCopyChapterContent,
                      onPressed: () async {
                        try {
                          var content = await epubPlayerKey.currentState
                              ?.theChapterContent();
                          var len = content?.length ?? 0;
                          if (len > 0) {
                            await Clipboard.setData(
                                ClipboardData(text: content!));
                          }
                          AnxToast.show(L10n.of(context)
                              .readingPageCopiedCharacters(len));
                        } catch (e) {
                          AnxToast.show(
                              L10n.of(context).readingPageErrorCopyingContent);
                        }
                      },
                    ),
                    IconButton(
                        tooltip: L10n.of(context).readingPageBookmark,
                        onPressed: () {
                          if (bookmarkExists) {
                            epubPlayerKey.currentState!.removeAnnotation(
                              epubPlayerKey.currentState!.bookmarkCfi,
                            );
                          } else {
                            epubPlayerKey.currentState!.addBookmarkHere();
                          }
                        },
                        icon: bookmarkExists
                            ? const Icon(Icons.bookmark)
                            : const Icon(Icons.bookmark_border)),
                    IconButton(
                      tooltip: L10n.of(context).readingPageBookDetails,
                      icon: const Icon(EvaIcons.more_vertical),
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => BookDetail(book: widget.book),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Spacer(),
                BottomSheet(
                  onClosing: () {},
                  enableDrag: false,
                  builder: (context) => SafeArea(
                    top: false,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          final hasContent = !identical(_currentPage, empty);
                          return IntrinsicHeight(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasContent)
                                  Expanded(
                                    child: _currentPage,
                                  ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.toc),
                                      onPressed: tocHandler,
                                    ),
                                    IconButton(
                                      icon: const Icon(EvaIcons.edit),
                                      onPressed: noteHandler,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.data_usage),
                                      onPressed: progressHandler,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.color_lens),
                                      onPressed: () {
                                        styleHandler(setState);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(EvaIcons.headphones),
                                      onPressed: ttsHandler,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Hero(
        tag: widget.heroTag ??
            (Prefs().openBookAnimation ? _book.coverFullPath : heroTag),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Scaffold(
              key: _scaffoldKey,
              resizeToAvoidBottomInset: false,
              drawer: PointerInterceptor(
                child: Drawer(
                  width: math.min(
                    MediaQuery.of(context).size.width * 0.8,
                    420,
                  ),
                  child: SafeArea(
                    child: TocWidget(
                      epubPlayerKey: epubPlayerKey,
                      hideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
                      closeDrawer: () {
                        _scaffoldKey.currentState?.closeDrawer();
                      },
                    ),
                  ),
                ),
              ),
              body: Stack(
                children: [
                  AxisFlex(
                    axis: Prefs().aiPanelPosition == AiPanelPositionEnum.right
                        ? Axis.horizontal
                        : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: MouseRegion(
                          onHover: (PointerHoverEvent detail) {
                            if (!Prefs().showMenuOnHover) return;
                            var y = detail.position.dy;
                            if (y < 30 ||
                                y > MediaQuery.of(context).size.height - 30) {
                              showOrHideAppBarAndBottomBar(true);
                            }
                          },
                          child: Focus(
                            focusNode: _readerFocusNode,
                            onKeyEvent: _handleReaderKeyEvent,
                            child: Stack(
                              children: [
                                EpubPlayer(
                                  key: epubPlayerKey,
                                  book: _book,
                                  cfi: widget.cfi,
                                  showOrHideAppBarAndBottomBar:
                                      showOrHideAppBarAndBottomBar,
                                  onLoadEnd: onLoadEnd,
                                  initialThemes: widget.initialThemes,
                                  updateParent: updateState,
                                ),
                                if (_isResizingAiChat)
                                  SizedBox.expand(
                                    child: Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withAlpha(1),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_aiChat != null)
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragStart: Prefs().aiPanelPosition ==
                                  AiPanelPositionEnum.right
                              ? (details) {
                                  _beginAiChatResize(details.globalPosition.dx);
                                }
                              : null,
                          onHorizontalDragUpdate: Prefs().aiPanelPosition ==
                                  AiPanelPositionEnum.right
                              ? (details) {
                                  _applyAiChatResizeDelta(
                                    details.delta.dx,
                                    context,
                                  );
                                }
                              : null,
                          onHorizontalDragEnd: Prefs().aiPanelPosition ==
                                  AiPanelPositionEnum.right
                              ? (_) {
                                  _endAiChatResize();
                                }
                              : null,
                          onHorizontalDragCancel: Prefs().aiPanelPosition ==
                                  AiPanelPositionEnum.right
                              ? () {
                                  _endAiChatResize();
                                }
                              : null,
                          onVerticalDragStart: Prefs().aiPanelPosition ==
                                  AiPanelPositionEnum.bottom
                              ? (details) {
                                  _beginAiChatResizeVertical(
                                      details.globalPosition.dy);
                                }
                              : null,
                          onVerticalDragUpdate: Prefs().aiPanelPosition ==
                                  AiPanelPositionEnum.bottom
                              ? (details) {
                                  _applyAiChatResizeDeltaVertical(
                                    details.delta.dy,
                                    context,
                                  );
                                }
                              : null,
                          onVerticalDragEnd: Prefs().aiPanelPosition ==
                                  AiPanelPositionEnum.bottom
                              ? (_) {
                                  _endAiChatResize();
                                }
                              : null,
                          onVerticalDragCancel: Prefs().aiPanelPosition ==
                                  AiPanelPositionEnum.bottom
                              ? () {
                                  _endAiChatResize();
                                }
                              : null,
                          child: MouseRegion(
                            cursor: Prefs().aiPanelPosition ==
                                    AiPanelPositionEnum.right
                                ? SystemMouseCursors.resizeColumn
                                : SystemMouseCursors.resizeRow,
                            child: Prefs().aiPanelPosition ==
                                    AiPanelPositionEnum.right
                                ? VerticalDivider(
                                    width: 2,
                                    thickness: 1,
                                  )
                                : Divider(
                                    height: 2,
                                    thickness: 1,
                                  ),
                          ),
                        ),
                      if (_aiChat != null)
                        SizedBox(
                          key: const ValueKey('ai-chat-panel'),
                          width: Prefs().aiPanelPosition ==
                                  AiPanelPositionEnum.right
                              ? _aiChatWidth
                              : null,
                          height: Prefs().aiPanelPosition ==
                                  AiPanelPositionEnum.bottom
                              ? _aiChatHeight
                              : null,
                          child: _aiChat,
                        )
                    ],
                  ),
                  controller,
                  // TTS floating action button: always in the tree when toolbar
                  // is hidden; TtsFab handles its own show/hide internally so
                  // its State (expanded flag) is never destroyed mid-session.
                  if (bottomBarOffstage)
                    const Positioned(
                      right: 16,
                      bottom: 24,
                      child: TtsFab(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
