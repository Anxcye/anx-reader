import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/dao/theme.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../dao/book_note.dart';
import '../models/reading_time.dart';
import '../models/toc_item.dart';
import '../utils/generate_index_html.dart';
import '../widgets/reading_page/progress_widget.dart';
import '../widgets/reading_page/style_widget.dart';
import '../widgets/reading_page/theme_widget.dart';
import '../widgets/reading_page/toc_widget.dart';
import 'book_notes_page.dart';

class ReadingPage extends StatefulWidget {
  final Book book;

  const ReadingPage({super.key, required this.book});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> with WidgetsBindingObserver {
  late Book _book;
  String? _content;
  late BookStyle _bookStyle;
  late ReadTheme _readTheme;

  // bool _isAppBarVisible = false;
  // double _appBarTopPosition = -kToolbarHeight;
  double readProgress = 0.0;
  List<TocItem> _tocItems = [];
  Widget _currentPage = const SizedBox(height: 1);
  final _epubPlayerKey = GlobalKey<EpubPlayerState>();
  Stopwatch _readTimeWatch = Stopwatch();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _readTimeWatch.start();

    _book = widget.book;
    _bookStyle = Prefs().bookStyle;
    _readTheme = Prefs().readTheme;
    loadContent();
  }

  @override
  void dispose() {
    _readTimeWatch.stop();
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
    String toc = await _epubPlayerKey.currentState!.getToc();
    setState(() {
      _tocItems =
          (json.decode(toc) as List).map((i) => TocItem.fromJson(i)).toList();
      _currentPage = TocWidget(
          tocItems: _tocItems,
          epubPlayerKey: _epubPlayerKey,
          hideAppBarAndBottomBar: showOrHideAppBarAndBottomBar);
    });
  }

  void noteHandler() {
    setState(() {
      _currentPage = Container(
        height: 550,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 10),
              child: Text(
                context.navBarNotes,
                style: const TextStyle(
                  fontSize: 28,
                  fontFamily: 'SourceHanSerif',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView(children: [bookNotesList(_book.id)]),
            ),
          ],
        ),
      );
    });
  }

  void progressHandler() {
    readProgress = _epubPlayerKey.currentState!.progress;
    setState(() {
      _currentPage = ProgressWidget(
        epubPlayerKey: _epubPlayerKey,
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
      epubPlayerKey: _epubPlayerKey,
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
        epubPlayerKey: _epubPlayerKey,
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
    );
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
          String cfi = await _epubPlayerKey.currentState!.onReadingLocation();
          double readProgress = _epubPlayerKey.currentState!.progress;
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
                key: _epubPlayerKey,
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
