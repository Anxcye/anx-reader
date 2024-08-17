import 'dart:async';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/dao/theme.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/page/book_detail.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/service/tts.dart';
import 'package:anx_reader/utils/ui/status_bar.dart';
import 'package:anx_reader/widgets/reading_page/notes_widget.dart';
import 'package:anx_reader/models/reading_time.dart';
import 'package:anx_reader/widgets/reading_page/progress_widget.dart';
import 'package:anx_reader/widgets/reading_page/tts_widget.dart';
import 'package:anx_reader/widgets/reading_page/style_widget.dart';
import 'package:anx_reader/widgets/reading_page/toc_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key, required this.book, this.cfi});

  final Book book;
  final String? cfi;

  @override
  State<ReadingPage> createState() => ReadingPageState();
}

final GlobalKey<ReadingPageState> readingPageKey =
    GlobalKey<ReadingPageState>();
final epubPlayerKey = GlobalKey<EpubPlayerState>();

class ReadingPageState extends State<ReadingPage> with WidgetsBindingObserver {
  late Book _book;

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
    Tts.dispose();
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

  void showOrHideAppBarAndBottomBar(bool show) {
    if (show) {
      showBottomBar(context);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> tocHandler() async {
    setState(() {
      _currentPage = TocWidget(
          tocItems: epubPlayerKey.currentState!.toc,
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
    setState(() {
      _currentPage = ProgressWidget(
        epubPlayerKey: epubPlayerKey,
        showOrHideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
      );
    });
  }

  Future<void> styleHandler(StateSetter modalSetState) async {
    List<ReadTheme> themes = await selectThemes();
    modalSetState(() {
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

  void showBottomBar(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 200),
      barrierLabel: MaterialLocalizations.of(context).dialogLabel,
      barrierColor: Colors.black.withOpacity(0.1),
      pageBuilder: (context, _, __) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            AppBar(
              title: Text(_book.title, overflow: TextOverflow.ellipsis),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // close bottom bar
                  Navigator.pop(context);
                  // close reading page
                  Navigator.pop(context);
                },
              ),
              actions: [
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
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Material(
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return IntrinsicHeight(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                                icon: const Icon(EvaIcons.edit),
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
                                  styleHandler(setState);
                                  setState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(EvaIcons.headphones),
                                onPressed: () {
                                  ttsHandler();
                                  setState(() {});
                                },
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
          ],
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
    return Hero(
      tag: _book.coverFullPath,
      child: Scaffold(
        body: Stack(
          children: [
            EpubPlayer(
              key: epubPlayerKey,
              book: _book,
              cfi: widget.cfi,
              showOrHideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
            ),
          ],
        ),
      ),
    );
  }
}
