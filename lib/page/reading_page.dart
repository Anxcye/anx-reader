import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/theme.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/toc_item.dart';
import '../utils/generate_index_html.dart';
import '../widgets/reading_page/progress_widget.dart';
import '../widgets/reading_page/theme_widget.dart';
import '../widgets/reading_page/toc_widget.dart';

class ReadingPage extends StatefulWidget {
  final Book book;

  const ReadingPage({super.key, required this.book});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  late Book _book;
  String? _content;
  BookStyle _bookStyle = BookStyle();
  bool _isAppBarVisible = false;
  double _appBarTopPosition = -kToolbarHeight;
  double readProgress = 0.0;
  List<TocItem> _tocItems = [];
  Widget _currentPage = const SizedBox(height: 1);
  final _epubPlayerKey = GlobalKey<EpubPlayerState>();

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    loadContent();
  }

  void loadContent() {
    var content = generateIndexHtml(
        widget.book, _bookStyle, widget.book.lastReadPosition);
    setState(() {
      _content = content;
    });
  }

  void showOrHideAppBarAndBottomBar(bool show) {
    setState(() {
      if (show) {
        if (_isAppBarVisible) {
          show = false;
        }
        _appBarTopPosition = 0;
      } else {
        _currentPage = const SizedBox(height: 1);
        _appBarTopPosition = -kToolbarHeight;
      }
      if (!show) {
        _currentPage = const SizedBox(height: 1);
      }
      _isAppBarVisible = show;
    });
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
        height: 700,
      );
    });
  }

  void progressHandler() {
    readProgress = _epubPlayerKey.currentState!.progress;
    print(readProgress);
    setState(() {
      _currentPage = ProgressWidget(
        epubPlayerKey: _epubPlayerKey,
        showOrHideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
        readProgress: readProgress,
      );
    });
  }

  Future<void> themeHandler() async {
    List<ReadTheme> themes = await selectThemes();
    setState(() {
      _currentPage = ThemeWidget(
        themes: themes,
        epubPlayerKey: _epubPlayerKey,
        setCurrentPage: (Widget page) {
          setState(() {
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
          Navigator.pop(context, cfi);
        },
        child: Scaffold(
          body: Stack(
            children: [
              EpubPlayer(
                key: _epubPlayerKey,
                content: _content!,
                showOrHideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
              ),
              if (_isAppBarVisible)
                AnimatedPositioned(
                  top: _appBarTopPosition,
                  left: 0,
                  right: 0,
                  duration: const Duration(milliseconds: 3000),
                  child: AppBar(
                    title: Text(_book.title),
                  ),
                ),
              if (_isAppBarVisible)
                AnimatedPositioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  duration: const Duration(milliseconds: 3000),
                  // child: BottomAppBar(
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Wrap(
                      children: [
                        _currentPage,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.toc),
                              onPressed: () {
                                tocHandler();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note),
                              onPressed: () {
                                noteHandler();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.data_usage),
                              onPressed: () {
                                progressHandler();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.color_lens),
                              onPressed: () {
                                themeHandler();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.text_fields),
                              onPressed: () {
                                styleHandler();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }
}
class StyleWidget extends StatefulWidget {
  const StyleWidget({super.key, required this.epubPlayerKey});
  final GlobalKey<EpubPlayerState> epubPlayerKey;
  @override
  State<StyleWidget> createState() => _StyleWidgetState();
}

class _StyleWidgetState extends State<StyleWidget> {
  BookStyle bookStyle = SharedPreferencesProvider().bookStyle;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // font size
        Row(
          children: [
            const Icon(Icons.format_size),
            Expanded(
              child: Slider(
                value: bookStyle.fontSize,
                onChanged: (double value) {
                  setState(() {
                    bookStyle.fontSize = value;
                    widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                    SharedPreferencesProvider().saveBookStyleToPrefs(bookStyle);
                  });
                },
                min: 1,
                max: 30,
                divisions: 29,
                label: (bookStyle.fontSize).round().toString(),
              ),
            ),
          ],
        ),

        // side margin
        Row(
          children: [
            const Icon(Icons.format_indent_increase),
            Expanded(
              child: Slider(
                value: bookStyle.sideMargin,
                onChanged: (double value) {
                  setState(() {
                    bookStyle.sideMargin = value;
                    widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                    SharedPreferencesProvider().saveBookStyleToPrefs(bookStyle);
                  });
                },
                min: 0,
                max: 10,
                divisions: 30,
                label: (bookStyle.sideMargin).round().toString(),
              ),
            ),
          ],
        ),
        // top & bottom margin
        Row(
          children: [
            const Icon(Icons.vertical_align_top_outlined),
            Expanded(
              child: Slider(
                value: bookStyle.topMargin,
                onChanged: (double value) {
                  setState(() {
                    bookStyle.topMargin = value;
                    widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                    SharedPreferencesProvider().saveBookStyleToPrefs(bookStyle);
                  });
                },
                min: 0,
                max: 100,
                divisions: 10,
                label: (bookStyle.topMargin).round().toString(),
              ),
            ),
            const Icon(Icons.vertical_align_bottom_outlined),
            Expanded(
              child: Slider(
                value: bookStyle.bottomMargin,
                onChanged: (double value) {
                  setState(() {
                    bookStyle.bottomMargin = value;
                    widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                    SharedPreferencesProvider().saveBookStyleToPrefs(bookStyle);
                  });
                },
                min: 0,
                max: 100,
                divisions: 10,
                label: (bookStyle.bottomMargin).round().toString(),
              ),
            ),
          ],
        ),
        // line height
        Row(
          children: [
            const Icon(Icons.format_line_spacing),
            Expanded(
              child: Slider(
                value: bookStyle.lineHeight,
                onChanged: (double value) {
                  setState(() {
                    bookStyle.lineHeight = value;
                    widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                    SharedPreferencesProvider().saveBookStyleToPrefs(bookStyle);
                  });
                },
                min: 0,
                max: 3,
                divisions: 10,
                label: (bookStyle.lineHeight/3*10).round().toString()
              ),
            ),
          ],
        ),
        // paragraph spacing
        Row(
          children: [
            const Icon(Icons.height),
            Expanded(
              child: Slider(
                value: bookStyle.paragraphSpacing,
                onChanged: (double value) {
                  setState(() {
                    bookStyle.paragraphSpacing = value;
                    widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                    SharedPreferencesProvider().saveBookStyleToPrefs(bookStyle);
                  });
                },
                min: 0,
                max: 50,
                divisions: 10,
                label: (bookStyle.paragraphSpacing/50*10).round().toString(),
              ),
            ),
          ],
        ),
        // letter & word spacing
        Row(
          children: [
            const Icon(Icons.compare_arrows),
            Expanded(
              child: Slider(
                value: bookStyle.letterSpacing,
                onChanged: (double value) {
                  setState(() {
                    bookStyle.letterSpacing = value;
                    widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                    SharedPreferencesProvider().saveBookStyleToPrefs(bookStyle);
                  });
                },
                min: -3,
                max: 7,
                divisions: 10,
                label: (bookStyle.letterSpacing).toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
