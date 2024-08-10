import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/reading_page/widget_title.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/more_settings.dart';
import 'package:flutter/material.dart';


class TtsWidget extends StatefulWidget {
  const TtsWidget({super.key, required this.epubPlayerKey});

  final GlobalKey<EpubPlayerState> epubPlayerKey;

  @override
  State<TtsWidget> createState() => _TtsWidgetState();
}

class _TtsWidgetState extends State<TtsWidget> {
  BookStyle bookStyle = Prefs().bookStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widgetTitle(L10n.of(context).reading_page_style, ReadingSettings.style),
        sliders(),
      ],
    );
  }

  Padding sliders() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
          children: [
            fontSizeSlider(),
            sideMarginSlider(),
            topBottomMarginSlider(),
            lineHeightAndParagraphSpacingSlider(),
            letterSpacingSlider(),
          ],
        ),
    );
  }

  Row letterSpacingSlider() {
    return Row(
      children: [
        const Icon(Icons.compare_arrows),
        Expanded(
          child: Slider(
            value: bookStyle.letterSpacing,
            onChanged: (double value) {
              setState(() {
                bookStyle.letterSpacing = value;
                widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: -3,
            max: 7,
            divisions: 10,
            label: (bookStyle.letterSpacing).toString(),
          ),
        ),
      ],
    );
  }

  Row lineHeightAndParagraphSpacingSlider() {
    return Row(
      children: [
        const Icon(Icons.line_weight),
        Expanded(
          child: Slider(
              value: bookStyle.lineHeight,
              onChanged: (double value) {
                setState(() {
                  bookStyle.lineHeight = value;
                  widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                  Prefs().saveBookStyleToPrefs(bookStyle);
                });
              },
              min: 0,
              max: 3,
              divisions: 10,
              label: (bookStyle.lineHeight / 3 * 10).round().toString()),
        ),
        const Icon(Icons.height),
        Expanded(
          child: Slider(
            value: bookStyle.paragraphSpacing,
            onChanged: (double value) {
              setState(() {
                bookStyle.paragraphSpacing = value;
                widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 0,
            max: 5,
            divisions: 10,
            label: (bookStyle.paragraphSpacing / 5 * 10).round().toString(),
          ),
        ),
      ],
    );
  }

  Row topBottomMarginSlider() {
    return Row(
      children: [
        const Icon(Icons.vertical_align_top_outlined),
        Expanded(
          child: Slider(
            value: bookStyle.topMargin,
            onChanged: (double value) {
              setState(() {
                bookStyle.topMargin = value;
                widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 0,
            max: 200,
            divisions: 10,
            label: (bookStyle.topMargin / 20).toStringAsFixed(0),
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
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 0,
            max: 200,
            divisions: 10,
            label: (bookStyle.bottomMargin / 20).toStringAsFixed(0),
          ),
        ),
      ],
    );
  }

  Row sideMarginSlider() {
    return Row(
      children: [
        const Icon(Icons.format_indent_increase),
        Expanded(
          child: Slider(
            value: bookStyle.sideMargin,
            onChanged: (double value) {
              setState(() {
                bookStyle.sideMargin = value;
                widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 0,
            max: 20,
            divisions: 20,
            label: bookStyle.sideMargin.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }

  Row fontSizeSlider() {
    return Row(
      children: [
        const Icon(Icons.format_size),
        Expanded(
          child: Slider(
            value: bookStyle.fontSize,
            onChanged: (double value) {
              setState(() {
                bookStyle.fontSize = value;
                widget.epubPlayerKey.currentState!.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 0.4,
            max: 3.0,
            divisions: 13,
            label: bookStyle.fontSize.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }
}
