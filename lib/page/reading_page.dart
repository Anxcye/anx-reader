import 'dart:io';

import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';

import '../utils/generate_index_html.dart';

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

  void showOrHideAppBarAndBottomBar() {
    setState(() {
      if (_isAppBarVisible) {
        _appBarTopPosition = -kToolbarHeight;
      } else {
        _appBarTopPosition = 0;
      }
      _isAppBarVisible = !_isAppBarVisible;
    });
  }

  void onReadProgressChanged(double value) {
    setState(() {
      readProgress = value;
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
                        Container(
                          height: 700,
                          child: ListView(

                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.toc),
                              onPressed: () {
                                // _epubPlayerKey.currentState!.previousPage();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note),
                              onPressed: () {
                                // _epubPlayerKey.currentState!.nextPage();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.data_usage),
                              onPressed: () {
                                // _epubPlayerKey.currentState!.nextPage();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.color_lens),
                              onPressed: () {
                                // _epubPlayerKey.currentState!.nextPage();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.text_fields),
                              onPressed: () {
                                // _epubPlayerKey.currentState!.nextPage();
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
