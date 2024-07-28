import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/dao/theme.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/utils/ui/status_bar.dart';
import 'package:anx_reader/widgets/reading_page/notes_widget.dart';
import 'package:anx_reader/models/reading_time.dart';
import 'package:anx_reader/models/toc_item.dart';
import 'package:anx_reader/utils/generate_index_html.dart';
import 'package:anx_reader/widgets/reading_page/progress_widget.dart';
import 'package:anx_reader/widgets/reading_page/style_widget.dart';
import 'package:anx_reader/widgets/reading_page/theme_widget.dart';
import 'package:anx_reader/widgets/reading_page/toc_widget.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ReadingPage extends StatefulWidget {
  final Book book;

  const ReadingPage({super.key, required this.book});

  @override
  State<ReadingPage> createState() => ReadingPageState();
}

final GlobalKey<ReadingPageState> readingPageKey =
    GlobalKey<ReadingPageState>();
final epubPlayerKey = GlobalKey<EpubPlayerState>();

class ReadingPageState extends State<ReadingPage> with WidgetsBindingObserver {
  late Book _book;
  String? _content;
  late BookStyle _bookStyle;
  late ReadTheme _readTheme;

  double readProgress = 0.0;
  List<TocItem> _tocItems = [];
  Widget _currentPage = const SizedBox(height: 1);
  final Stopwatch _readTimeWatch = Stopwatch();
  Timer? _awakeTimer;

  @override
  void initState() {
    if (Prefs().hideStatusBar) {
      hideStatusBar();
    }
    WidgetsBinding.instance.addObserver(this);
    _readTimeWatch.start();
    setAwakeTimer(Prefs().awakeTime);

    _book = widget.book;
    _bookStyle = Prefs().bookStyle;
    _readTheme = Prefs().readTheme;
    loadContent();
    super.initState();
  }

  @override
  void dispose() {
    _readTimeWatch.stop();
    _awakeTimer?.cancel();
    WakelockPlus.disable();
    showStatusBar();
    WidgetsBinding.instance.removeObserver(this);
    insertReadingTime(ReadingTime(
        bookId: _book.id, readingTime: _readTimeWatch.elapsed.inSeconds));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
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

  void loadContent() {
    var content = generateIndexHtml(
        widget.book, _bookStyle, _readTheme, widget.book.lastReadPosition);
    setState(() {
      _content = content;
    });
  }

  void showOrHideAppBarAndBottomBar(bool show) {
    if (show) {
      showBottomBar(context);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> tocHandler() async {
    String toc = await epubPlayerKey.currentState!.getToc();
    setState(() {
      _tocItems =
          (json.decode(toc) as List).map((i) => TocItem.fromJson(i)).toList();
      _currentPage = TocWidget(
          tocItems: _tocItems,
          epubPlayerKey: epubPlayerKey,
          hideAppBarAndBottomBar: showOrHideAppBarAndBottomBar);
    });
  }

  void noteHandler() {
    setState(() {
      _currentPage = ReadingNotes(book: _book);
    });
  }

  void progressHandler() {
    readProgress = epubPlayerKey.currentState!.progress;
    setState(() {
      _currentPage = ProgressWidget(
        epubPlayerKey: epubPlayerKey,
        showOrHideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
        readProgress: readProgress,
      );
    });
  }

  Future<void> themeHandler(StateSetter modalSetState) async {
    List<ReadTheme> themes = await selectThemes();
    modalSetState(() {
      _currentPage = ThemeWidget(
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

  Future<void> styleHandler() async {
    setState(() {
      _currentPage = StyleWidget(
        epubPlayerKey: epubPlayerKey,
      );
    });
  }

  void showBottomBar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(child: _currentPage),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.toc),
                        onPressed: () {
                          tocHandler();
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note),
                        onPressed: () {
                          noteHandler();
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.data_usage),
                        onPressed: () {
                          progressHandler();
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.color_lens),
                        onPressed: () {
                          themeHandler(setState);
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.text_fields),
                        onPressed: () {
                          styleHandler();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((value) {
      setState(() {
        _currentPage = const SizedBox(height: 1);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_content == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          if (didPop) return;
          String cfi = await epubPlayerKey.currentState!.onReadingLocation();
          double readProgress = epubPlayerKey.currentState!.progress;
          Map<String, dynamic> result = {
            'cfi': cfi,
            'readProgress': readProgress,
          };
          Navigator.pop(context, result);
        },
        child: Scaffold(
          body: Stack(
            children: [
              EpubPlayer(
                key: epubPlayerKey,
                content: _content!,
                bookId: _book.id,
                showOrHideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
              ),
            ],
          ),
        ),
      );
    }
  }
}
