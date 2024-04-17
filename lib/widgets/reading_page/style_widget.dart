import 'package:flutter/material.dart';

import '../../config/shared_preference_provider.dart';
import '../../models/book_style.dart';
import '../../page/book_player/epub_player.dart';

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
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
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
                  min: 10,
                  max: 300,
                  divisions: 29,
                  label: (bookStyle.fontSize/10).round().toString(),
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
                  max: 200,
                  divisions: 20,
                  label: (bookStyle.sideMargin/10).round().toString(),
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
      ),
    );
  }
}
