import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/toc_item.dart';
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
  List<TocItem> _tocItems = [];
  Widget _currentPage = const SizedBox(height: 1);
  Timer? _sliderTimer;
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
      _isAppBarVisible = show;
    });
  }

  void onReadProgressChanged(double value) {
    setState(() {
      readProgress = value;
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

  Future<void> progressHandler() async {
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

class ProgressDisplayer extends StatelessWidget {
  const ProgressDisplayer({
    super.key,
    required this.mainText,
    required this.subText,
  });

  final mainText;
  final subText;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        // width: 50,
        child: Column(
          children: [
            Text(
              mainText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'SourceHanSerif',
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'SourceHanSerif',
                fontWeight: FontWeight.w300,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class TocWidget extends StatelessWidget {
  const TocWidget({
    super.key,
    required this.tocItems,
    required this.epubPlayerKey,
    required this.hideAppBarAndBottomBar,
  });

  final List<TocItem> tocItems;
  final epubPlayerKey;
  final hideAppBarAndBottomBar;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 700,
        child: ListView.builder(
          itemCount: tocItems.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(tocItems[index].label),
              onTap: () {
                hideAppBarAndBottomBar(false);
                epubPlayerKey.currentState!.goTo(tocItems[index].href);
              },
            );
          },
        ));
  }
}
class ProgressWidget extends StatefulWidget {
  final GlobalKey<EpubPlayerState> epubPlayerKey;
  final Function(bool) showOrHideAppBarAndBottomBar;
  final double readProgress;

  const ProgressWidget({
    Key? key,
    required this.epubPlayerKey,
    required this.showOrHideAppBarAndBottomBar,
    required this.readProgress,
  }) : super(key: key);

  @override
  State<ProgressWidget> createState() => _ProgressWidgetState();
}

class _ProgressWidgetState extends State<ProgressWidget> {
  Timer? _sliderTimer;
  double _readProgress = 0.0;
  @override
  void initState() {
    super.initState();
    _readProgress = widget.readProgress;
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            widget.epubPlayerKey.currentState!.chapterTitle,
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'SourceHanSerif',
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  widget.epubPlayerKey.currentState!.prevChapter();
                  widget.showOrHideAppBarAndBottomBar(false);
                },
              ),
              Expanded(
                child: Slider(
                  inactiveColor: Colors.grey.shade300,
                  value: _readProgress,
                  onChanged: (value) {
                    _sliderTimer?.cancel();
                    _sliderTimer = Timer(
                      const Duration(milliseconds: 300),
                      () {
                        widget.epubPlayerKey.currentState!.goToPersentage(value);
                      },
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  widget.epubPlayerKey.currentState!.nextChapter();
                  widget.showOrHideAppBarAndBottomBar(false);
                },
              ),
            ],
          ),
          Row(
            children: [
              ProgressDisplayer(
                mainText: widget.epubPlayerKey.currentState!.chapterCurrentPage.toString(),
                subText: 'current page',
              ),
              ProgressDisplayer(
                mainText: widget.epubPlayerKey.currentState!.chapterTotalPage.toString(),
                subText: 'total page',
              ),
              ProgressDisplayer(
                mainText: widget.epubPlayerKey.currentState!.progress.toStringAsFixed(2),
                subText: 'percentage',
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
        ],
      ),
    );
  }
}