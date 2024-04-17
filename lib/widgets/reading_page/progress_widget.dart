import 'dart:async';

import 'package:flutter/material.dart';

import '../../page/book_player/epub_player.dart';

class ProgressWidget extends StatefulWidget {
  final GlobalKey<EpubPlayerState> epubPlayerKey;
  final Function(bool) showOrHideAppBarAndBottomBar;
  final double readProgress;

  const ProgressWidget({
    super.key,
    required this.epubPlayerKey,
    required this.showOrHideAppBarAndBottomBar,
    required this.readProgress,
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
                    setState(() {
                      _readProgress = value;
                    });
                    _sliderTimer?.cancel();
                    _sliderTimer = Timer(
                      const Duration(milliseconds: 300),
                      () {
                        widget.epubPlayerKey.currentState!
                            .goToPersentage(value);
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
                mainText: widget.epubPlayerKey.currentState!.chapterCurrentPage
                    .toString(),
                subText: 'current page',
              ),
              ProgressDisplayer(
                mainText: widget.epubPlayerKey.currentState!.chapterTotalPage
                    .toString(),
                subText: 'total page',
              ),
              ProgressDisplayer(
                mainText: (widget.epubPlayerKey.currentState!.progress * 100)
                    .toStringAsFixed(2),
                subText: 'percentage',
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
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
