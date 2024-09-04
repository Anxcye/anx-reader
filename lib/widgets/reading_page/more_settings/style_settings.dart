import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:flutter/material.dart';

Widget styleSettings = StatefulBuilder(
  builder: (context, setState) => SingleChildScrollView(
    child: Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          sliders(),
        ],
      ),
    ),
  ),
);

Widget sliders() {
  BookStyle bookStyle = Prefs().bookStyle;
  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) => Column(
      children: [
        textIndent(bookStyle, setState),
        sideMarginSlider(bookStyle, setState),
        topBottomMarginSlider(bookStyle, setState),
        letterSpacingSlider(bookStyle, setState),
      ],
    ),
  );
}

Widget textIndent(BookStyle bookStyle, StateSetter setState) {
  return ListTile(
    leading: const Icon(Icons.format_indent_increase),
    title: Slider(
      value: bookStyle.indent,
      onChanged: (double value) {
        setState(() {
          bookStyle.indent = value;
          epubPlayerKey.currentState!.changeStyle(bookStyle);
          Prefs().saveBookStyleToPrefs(bookStyle);
        });
      },
      min: 0,
      max: 8,
      divisions: 16,
      label: bookStyle.indent.toStringAsFixed(1),
    ),
  );
}

Widget sideMarginSlider(BookStyle bookStyle, StateSetter setState) {
  return ListTile(
    leading: const Icon(Icons.margin_rounded),
    title: Slider(
      value: bookStyle.sideMargin,
      onChanged: (double value) {
        setState(() {
          bookStyle.sideMargin = value;
          epubPlayerKey.currentState!.changeStyle(bookStyle);
          Prefs().saveBookStyleToPrefs(bookStyle);
        });
      },
      min: 0,
      max: 20,
      divisions: 20,
      label: bookStyle.sideMargin.toStringAsFixed(1),
    ),
  );
}

Widget letterSpacingSlider(BookStyle bookStyle, StateSetter setState) {
  return ListTile(
    leading: const Icon(Icons.compare_arrows),
    title: Slider(
      value: bookStyle.letterSpacing,
      onChanged: (double value) {
        setState(() {
          bookStyle.letterSpacing = value;
          epubPlayerKey.currentState!.changeStyle(bookStyle);
          Prefs().saveBookStyleToPrefs(bookStyle);
        });
      },
      min: -3,
      max: 7,
      divisions: 10,
      label: (bookStyle.letterSpacing).toString(),
    ),
  );
}

ListTile topBottomMarginSlider(BookStyle bookStyle, StateSetter setState) {
  return ListTile(
    title: Row(
      children: [
        const Icon(Icons.vertical_align_top_outlined),
        Expanded(
          child: Slider(
            value: bookStyle.topMargin,
            onChanged: (double value) {
              setState(() {
                bookStyle.topMargin = value;
                epubPlayerKey.currentState!.changeStyle(bookStyle);
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
                epubPlayerKey.currentState!.changeStyle(bookStyle);
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
    ),
  );
}
