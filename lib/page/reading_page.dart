import 'dart:async';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/dao/theme.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/page/book_detail.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/providers/ai_chat.dart';
import 'package:anx_reader/providers/anx_webdav.dart';
import 'package:anx_reader/service/ai/ai_dio.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/ui/status_bar.dart';
import 'package:anx_reader/widgets/ai_chat_stream.dart';
import 'package:anx_reader/widgets/ai_stream.dart';
import 'package:anx_reader/widgets/reading_page/notes_widget.dart';
import 'package:anx_reader/models/reading_time.dart';
import 'package:anx_reader/widgets/reading_page/progress_widget.dart';
import 'package:anx_reader/widgets/reading_page/tts_widget.dart';
import 'package:anx_reader/widgets/reading_page/style_widget.dart';
import 'package:anx_reader/widgets/reading_page/toc_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ReadingPage extends ConsumerStatefulWidget {
  const ReadingPage({super.key, required this.book, this.cfi});

  final Book book;
  final String? cfi;

  @override
  ConsumerState<ReadingPage> createState() => ReadingPageState();
}

final GlobalKey<ReadingPageState> readingPageKey =
    GlobalKey<ReadingPageState>();
final epubPlayerKey = GlobalKey<EpubPlayerState>();

class ReadingPageState extends ConsumerState<ReadingPage>
    with WidgetsBindingObserver {
  late Book _book;
  Widget _currentPage = const SizedBox(height: 1);
  final Stopwatch _readTimeWatch = Stopwatch();
  Timer? _awakeTimer;
  bool bottomBarOffstage = true;
  bool tocOffstage = true;
  Widget? _tocWidget;
  String heroTag = 'preventHeroWhenStart';
  Widget? _aiChat;
  final aiChatKey = GlobalKey<AiChatStreamState>();

  late FocusOnKeyEventCallback _handleKeyEvent;

  @override
  void initState() {
    if (widget.book.isDeleted) {
      Navigator.pop(context);
      AnxToast.show(L10n.of(context).book_deleted);
      return;
    }
    if (Prefs().hideStatusBar) {
      hideStatusBar();
    }
    WidgetsBinding.instance.addObserver(this);
    _readTimeWatch.start();
    setAwakeTimer(Prefs().awakeTime);

    _book = widget.book;
    _addKeyboardListener();
    // delay 1000ms to prevent hero animation
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          heroTag = _book.coverFullPath;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    AnxWebdav().syncData(SyncDirection.upload, ref);
    _readTimeWatch.stop();
    _awakeTimer?.cancel();
    WakelockPlus.disable();
    showStatusBar();
    WidgetsBinding.instance.removeObserver(this);
    insertReadingTime(ReadingTime(
        bookId: _book.id, readingTime: _readTimeWatch.elapsed.inSeconds));
    audioHandler.stop();
    _removeKeyboardListener();
    super.dispose();
  }

  void _addKeyboardListener() {
    _handleKeyEvent = (FocusNode node, KeyEvent event) {
      if (!Prefs().volumeKeyTurnPage) {
        return KeyEventResult.ignored;
      }

      if (event is KeyDownEvent) {
        if (event.physicalKey == PhysicalKeyboardKey.audioVolumeUp) {
          epubPlayerKey.currentState?.prevPage();
          return KeyEventResult.handled;
        } else if (event.physicalKey == PhysicalKeyboardKey.audioVolumeDown) {
          epubPlayerKey.currentState?.nextPage();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  void _removeKeyboardListener() {
    _handleKeyEvent = (FocusNode node, KeyEvent event) {
      return KeyEventResult.ignored;
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      epubPlayerKey.currentState!.saveReadingProgress();
      _readTimeWatch.stop();
    } else if (state == AppLifecycleState.resumed) {
      _readTimeWatch.start();
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
      _removeKeyboardListener();
    });
  }

  void hideBottomBar() {
    setState(() {
      tocOffstage = true;
      _currentPage = const SizedBox(height: 1);
      bottomBarOffstage = true;
      if (Prefs().hideStatusBar) {
        hideStatusBar();
      }
      _addKeyboardListener();
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
    setState(() {
      _tocWidget = TocWidget(
        tocItems: epubPlayerKey.currentState!.toc,
        epubPlayerKey: epubPlayerKey,
        hideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
      );
      _currentPage = const SizedBox(height: 1);
      tocOffstage = false;
    });
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
    List<ReadTheme> themes = await selectThemes();
    setState(() {
      _currentPage = StyleWidget(
        themes: themes,
        epubPlayerKey: epubPlayerKey,
        setCurrentPage: (Widget page) {
          modalSetState(() {
            _currentPage = page;
          });
        },
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

  void onLoadEnd() {
    if (Prefs().autoSummaryPreviousContent) {
      SmartDialog.show(
        builder: (context) => AlertDialog(
          title: Text(L10n.of(context).reading_page_summary_previous_content),
          content: FutureBuilder(
            future: epubPlayerKey.currentState!.theChapterContent(),
            builder: (context, snapshot) {
              return AiStream(
                  prompt: generatePromptSummaryThePreviousContent(
                snapshot.data ?? '',
              ));
            },
          ),
        ),
        onDismiss: () {
          AiDio.instance.cancel();
        },
      );
    }
  }

  Future<void> showAiChat({
    String? content,
    bool sendImmediate = false,
  }) async {
    if (MediaQuery.of(navigatorKey.currentContext!).size.width < 600) {
      showModalBottomSheet(
          context: navigatorKey.currentContext!,
          isScrollControlled: true,
          showDragHandle: true,
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
                      ),
                    
                  ),
                ),
          ));
    } else {
      setState(() {
        _aiChat = SizedBox(
          width: 300,
          child: AiChatStream(
            key: aiChatKey,
            initialMessage: content,
            sendImmediate: sendImmediate,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var aiButton = IconButton(
      icon: const Icon(Icons.auto_awesome),
      onPressed: () async {
        if (MediaQuery.of(context).size.width > 600 && _aiChat != null) {
          setState(() {
            _aiChat = null;
          });
          return;
        }

        showOrHideAppBarAndBottomBar(false);
        final String chapterContent =
            await epubPlayerKey.currentState!.theChapterContent();
        final sendImmediate = (ref.read(aiChatProvider).value?.isEmpty ?? true);
        final content = generatePromptSummaryTheChapter(chapterContent);
        showAiChat(
            content: sendImmediate ? content : null,
            sendImmediate: sendImmediate);
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
                  child: Container(
                    color: Colors.black.withAlpha(30),
                  )),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
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
                    aiButton,
                    IconButton(
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
                          return IntrinsicHeight(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(child: _currentPage),
                                Offstage(
                                  offstage:
                                      tocOffstage || _currentPage is! SizedBox,
                                  child: _tocWidget,
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

    return Hero(
      tag: Prefs().openBookAnimation ? _book.coverFullPath : heroTag,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: MouseRegion(
          onHover: (PointerHoverEvent detail) {
            var y = detail.position.dy;
            if (y < 30 || y > MediaQuery.of(context).size.height - 30) {
              showOrHideAppBarAndBottomBar(true);
            }
          },
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Focus(
                      focusNode: FocusNode(),
                      onKeyEvent: _handleKeyEvent,
                      child: EpubPlayer(
                        key: epubPlayerKey,
                        book: _book,
                        cfi: widget.cfi,
                        showOrHideAppBarAndBottomBar:
                            showOrHideAppBarAndBottomBar,
                        onLoadEnd: onLoadEnd,
                      ),
                    ),
                  ),
                  _aiChat != null
                      ? const VerticalDivider(width: 1)
                      : const SizedBox.shrink(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _aiChat,
                  ),
                ],
              ),
              controller,
            ],
          ),
        ),
      ),
    );
  }
}
