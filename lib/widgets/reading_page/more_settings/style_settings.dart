import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/text_alignment.dart';
import 'package:anx_reader/enums/writing_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/widgets/icon_and_text.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/custom_css_editor.dart';
import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';

// Reusable style slider widget that can be disabled
class StyleSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) labelFormatter;
  final bool enabled;

  const StyleSlider({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    required this.divisions,
    required this.labelFormatter,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconAndText(
          icon: Icon(icon),
          text: label,
        ),
        Expanded(
          child: Slider(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            value: value,
            onChanged: enabled ? onChanged : null,
            min: min,
            max: max,
            divisions: divisions,
            label: labelFormatter(value),
          ),
        ),
      ],
    );
  }
}

class StyleSettings extends StatefulWidget {
  const StyleSettings({super.key});

  @override
  State<StyleSettings> createState() => _StyleSettingsState();
}

class _StyleSettingsState extends State<StyleSettings> {
  @override
  Widget build(BuildContext context) {
    Widget useBookStylesSwitch() {
      return SwitchListTile(
        title: Text(L10n.of(context).useBookStyles),
        subtitle: Text(
          L10n.of(context).useBookStylesDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: Prefs().useBookStyles,
        onChanged: (bool value) {
          setState(() {
            Prefs().useBookStyles = value;
            epubPlayerKey.currentState?.changeStyle(Prefs().bookStyle);
          });
        },
      );
    }

    Widget textIndent(BookStyle bookStyle, StateSetter setState) {
      bool enabled = !Prefs().useBookStyles;
      return StyleSlider(
        icon: Icons.format_indent_increase,
        label: L10n.of(context).readingPageIndent,
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
        labelFormatter: (value) => value < 0
            ? L10n.of(context).readingPageIndentNoChange
            : value.toStringAsFixed(1),
        enabled: enabled,
      );
    }

    Widget sideMarginSlider(BookStyle bookStyle, StateSetter setState) {
      return StyleSlider(
        icon: Prefs().writingMode == WritingModeEnum.verticalRl
            ? Bootstrap.arrows_vertical
            : Bootstrap.arrows,
        label: Prefs().writingMode == WritingModeEnum.verticalRl
            ? L10n.of(context).readingPageVerticleMargin
            : L10n.of(context).readingPageSideMargin,
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
        labelFormatter: (value) => value.toStringAsFixed(1),
        enabled: true, // Side margin is always enabled
      );
    }

    Widget letterSpacingSlider(BookStyle bookStyle, StateSetter setState) {
      bool enabled = !Prefs().useBookStyles;
      return StyleSlider(
        icon: Icons.compare_arrows,
        label: L10n.of(context).readingPageLetterSpacing,
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
        labelFormatter: (value) => value.toString(),
        enabled: enabled,
      );
    }

    Row topBottomMarginSlider(BookStyle bookStyle, StateSetter setState) {
      return Row(children: [
        Prefs().writingMode == WritingModeEnum.verticalRl
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
        Prefs().writingMode == WritingModeEnum.verticalRl
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
      bool enabled = !Prefs().useBookStyles;
      return StyleSlider(
        icon: Icons.format_bold,
        label: L10n.of(context).readingPageFontWeight,
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
        labelFormatter: (value) => value.toString(),
        enabled: enabled,
      );
    }

    Widget headingFontSizeSlider(BookStyle bookStyle, StateSetter setState) {
      bool enabled = !Prefs().useBookStyles;
      return StyleSlider(
        icon: Icons.title,
        label: L10n.of(context).headingFontSize,
        value: bookStyle.headingFontSize,
        onChanged: (double value) {
          setState(() {
            bookStyle.headingFontSize = value;
            epubPlayerKey.currentState?.changeStyle(bookStyle);
            Prefs().saveBookStyleToPrefs(bookStyle);
          });
        },
        min: 0.5,
        max: 2.0,
        divisions: 15,
        labelFormatter: (value) => value.toStringAsFixed(1),
        enabled: enabled,
      );
    }

    Widget textAlignment() {
      final items = [
        {
          "icon": Icons.auto_awesome,
          "text": L10n.of(context).textAlignmentAuto,
          "value": TextAlignmentEnum.auto
        },
        {
          "icon": Icons.format_align_left,
          "text": L10n.of(context).textAlignmentLeft,
          "value": TextAlignmentEnum.left
        },
        {
          "icon": Icons.format_align_center,
          "text": L10n.of(context).textAlignmentCenter,
          "value": TextAlignmentEnum.center
        },
        {
          "icon": Icons.format_align_right,
          "text": L10n.of(context).textAlignmentRight,
          "value": TextAlignmentEnum.right
        },
        {
          "icon": Icons.format_align_justify,
          "text": L10n.of(context).textAlignmentJustify,
          "value": TextAlignmentEnum.justify
        },
      ];

      return StatefulBuilder(
        builder: (context, setState) => Row(
          children: [
            Icon(Icons.format_align_left,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(L10n.of(context).textAlignment),
            const Spacer(),
            DropdownMenu<TextAlignmentEnum>(
              width: 140,
              initialSelection: Prefs().textAlignment,
              inputDecorationTheme: InputDecorationTheme(
                isDense: false,
                border: InputBorder.none,
              ),
              dropdownMenuEntries: items.map((item) {
                return DropdownMenuEntry<TextAlignmentEnum>(
                  value: item["value"] as TextAlignmentEnum,
                  label: item["text"] as String,
                  leadingIcon: Icon(item["icon"] as IconData),
                );
              }).toList(),
              onSelected: (value) {
                if (value != null) {
                  setState(() {
                    Prefs().textAlignment = value;
                    epubPlayerKey.currentState?.changeStyle(Prefs().bookStyle);
                  });
                }
              },
            ),
          ],
        ),
      );
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
            headingFontSizeSlider(bookStyle, setState),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          useBookStylesSwitch(),
          const Divider(),
          sliders(),
          const SizedBox(height: 16),
          const Divider(),
          textAlignment(),
          CustomCSSEditor(),
        ],
      ),
    );
  }
}
