import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/writing_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/widgets/icon_and_text.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/custom_css_editor.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class StyleSettings extends StatefulWidget {
  const StyleSettings({super.key});

  @override
  State<StyleSettings> createState() => _StyleSettingsState();
}

class _StyleSettingsState extends State<StyleSettings> {
  @override
  Widget build(BuildContext context) {
    Widget textIndent(BookStyle bookStyle, StateSetter setState) {
      return Row(children: [
        IconAndText(
          icon: const Icon(Icons.format_indent_increase),
          text: L10n.of(context).readingPageIndent,
        ),
        Expanded(
          child: Slider(
            padding: EdgeInsets.symmetric(horizontal: 8),
            value: bookStyle.indent,
            onChanged: (double value) {
              setState(() {
                bookStyle.indent = value;
                epubPlayerKey.currentState?.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: -0.5,
            max: 8,
            divisions: 17,
            label: bookStyle.indent < 0
                ? L10n.of(context).readingPageIndentNoChange
                : bookStyle.indent.toStringAsFixed(1),
          ),
        ),
      ]);
    }

    Widget sideMarginSlider(BookStyle bookStyle, StateSetter setState) {
      return Row(children: [
        Prefs().writingMode == WritingModeEnum.vertical
            ? IconAndText(
                icon: const Icon(Bootstrap.arrows_vertical),
                text: L10n.of(context).readingPageVerticleMargin,
              )
            : IconAndText(
                icon: const Icon(Bootstrap.arrows),
                text: L10n.of(context).readingPageSideMargin,
              ),
        Expanded(
          child: Slider(
            padding: EdgeInsets.symmetric(horizontal: 8),
            value: bookStyle.sideMargin,
            onChanged: (double value) {
              setState(() {
                bookStyle.sideMargin = value;
                epubPlayerKey.currentState?.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 0,
            max: 20,
            divisions: 20,
            label: bookStyle.sideMargin.toStringAsFixed(1),
          ),
        )
      ]);
    }

    Widget letterSpacingSlider(BookStyle bookStyle, StateSetter setState) {
      return Row(children: [
        IconAndText(
          icon: const Icon(Icons.compare_arrows),
          text: L10n.of(context).readingPageLetterSpacing,
        ),
        Expanded(
          child: Slider(
            padding: EdgeInsets.symmetric(horizontal: 8),
            value: bookStyle.letterSpacing,
            onChanged: (double value) {
              setState(() {
                bookStyle.letterSpacing = value;
                epubPlayerKey.currentState?.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: -3,
            max: 7,
            divisions: 10,
            label: (bookStyle.letterSpacing).toString(),
          ),
        ),
      ]);
    }

    Row topBottomMarginSlider(BookStyle bookStyle, StateSetter setState) {
      return Row(children: [
        Prefs().writingMode == WritingModeEnum.vertical
            ? IconAndText(
                icon: const Icon(Bootstrap.chevron_bar_right),
                text: L10n.of(context).readingPageRightMargin,
              )
            : IconAndText(
                icon: const Icon(Bootstrap.chevron_bar_up),
                text: L10n.of(context).readingPageTopMargin,
              ),
        Expanded(
          child: Slider(
            padding: EdgeInsets.symmetric(horizontal: 8),
            value: bookStyle.topMargin,
            onChanged: (double value) {
              setState(() {
                bookStyle.topMargin = value;
                epubPlayerKey.currentState?.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 0,
            max: 200,
            divisions: 10,
            label: (bookStyle.topMargin / 20).toStringAsFixed(0),
          ),
        ),
        Prefs().writingMode == WritingModeEnum.vertical
            ? IconAndText(
                icon: const Icon(Bootstrap.chevron_bar_left),
                text: L10n.of(context).readingPageLeftMargin,
              )
            : IconAndText(
                icon: const Icon(Bootstrap.chevron_bar_down),
                text: L10n.of(context).readingPageBottomMargin,
              ),
        Expanded(
          child: Slider(
            padding: EdgeInsets.symmetric(horizontal: 8),
            value: bookStyle.bottomMargin,
            onChanged: (double value) {
              setState(() {
                bookStyle.bottomMargin = value;
                epubPlayerKey.currentState?.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 0,
            max: 200,
            divisions: 10,
            label: (bookStyle.bottomMargin / 20).toStringAsFixed(0),
          ),
        ),
      ]);
    }

    Widget fontWeightSlider(BookStyle bookStyle, StateSetter setState) {
      return Row(children: [
        IconAndText(
          icon: const Icon(Icons.format_bold),
          text: L10n.of(context).readingPageFontWeight,
        ),
        Expanded(
          child: Slider(
            padding: EdgeInsets.symmetric(horizontal: 8),
            value: bookStyle.fontWeight,
            onChanged: (double value) {
              setState(() {
                bookStyle.fontWeight = value;
                epubPlayerKey.currentState?.changeStyle(bookStyle);
                Prefs().saveBookStyleToPrefs(bookStyle);
              });
            },
            min: 100,
            max: 900,
            divisions: 8,
            label: bookStyle.fontWeight.toString(),
          ),
        ),
      ]);
    }

    Widget sliders() {
      BookStyle bookStyle = Prefs().bookStyle;
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => Column(
          children: [
            textIndent(bookStyle, setState),
            sideMarginSlider(bookStyle, setState),
            topBottomMarginSlider(bookStyle, setState),
            letterSpacingSlider(bookStyle, setState),
            fontWeightSlider(bookStyle, setState),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          sliders(),
          const SizedBox(height: 16),
          CustomCSSEditor(),
        ],
      ),
    );
  }
}
