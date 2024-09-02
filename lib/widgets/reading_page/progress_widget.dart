import 'dart:async';

import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:flutter/material.dart';

class ProgressWidget extends StatefulWidget {
  final GlobalKey<EpubPlayerState> epubPlayerKey;
  final Function(bool) showOrHideAppBarAndBottomBar;

  const ProgressWidget({
    super.key,
    required this.epubPlayerKey,
    required this.showOrHideAppBarAndBottomBar,
  });

  @override
  State<ProgressWidget> createState() => _ProgressWidgetState();
}

class _ProgressWidgetState extends State<ProgressWidget> {
  Timer? _sliderTimer;
  double _readProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _readProgress = epubPlayerKey.currentState!.percentage;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            widget.epubPlayerKey.currentState!.chapterTitle,
            textAlign: TextAlign.center,
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
                    setState(() {
                      _readProgress = value;
                    });
                    _sliderTimer?.cancel();
                    _sliderTimer = Timer(
                      const Duration(milliseconds: 100),
                      () async {
                        await widget.epubPlayerKey.currentState!
                            .goToPercentage(value);
                        Timer(const Duration(milliseconds: 300), () {
                          setState(() {});
                        });
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
              ProgressDisplay(
                mainText: widget.epubPlayerKey.currentState!.chapterCurrentPage
                    .toString(),
                subText: L10n.of(context).reading_page_current_page,
              ),
              ProgressDisplay(
                mainText: widget.epubPlayerKey.currentState!.chapterTotalPages
                    .toString(),
                subText: L10n.of(context).reading_page_chapter_pages,
              ),
              ProgressDisplay(
                mainText: (widget.epubPlayerKey.currentState!.percentage * 100)
                    .toStringAsFixed(2),
                subText: '%',
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class ProgressDisplay extends StatelessWidget {
  const ProgressDisplay({
    super.key,
    required this.mainText,
    required this.subText,
  });

  final String mainText;
  final String subText;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
    );
  }
}
