import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/convert_chinese_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

Widget readingSettings = StatefulBuilder(
  builder: (context, setState) => SingleChildScrollView(
    child: Container(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          columnCount(),
          const Divider(height: 18),
          convertChinese(),
        ],
      ),
    ),
  ),
);

Widget convertChinese() {
  const iconStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  return StatefulBuilder(
    builder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).reading_page_convert_chinese,
              style: Theme.of(context).textTheme.titleMedium),
          Row(
            children: [
              Expanded(
                child: SegmentedButton(
                  segments: [
                    ButtonSegment<String>(
                      label: Text(L10n.of(context).reading_page_original),
                      value: "none",
                      icon: const Text("原", style: iconStyle),
                    ),
                    ButtonSegment<String>(
                      label: Text(L10n.of(context).reading_page_simplified),
                      value: "t2s",
                      icon: const Text("简", style: iconStyle),
                    ),
                    ButtonSegment<String>(
                      label: Text(L10n.of(context).reading_page_traditional),
                      value: "s2t",
                      icon: const Text("繁", style: iconStyle),
                    ),
                  ],
                  selected: {Prefs().convertChineseMode.name},
                  onSelectionChanged: (value) {
                    setState(() {
                      Prefs().convertChineseMode =
                          ConvertChineseMode.values.byName(value.first);
                      epubPlayerKey.currentState!
                          .changeConvertChinese(Prefs().convertChineseMode);
                    });
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.error_outline),
              Text(L10n.of(context).reading_page_convert_chinese_tips),
            ],
          ),
        ],
      );
    },
  );
}

Widget columnCount() {
  return StatefulBuilder(
    builder: (context, setState) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).reading_page_column_count,
            style: Theme.of(context).textTheme.titleMedium),
        Row(
          children: [
            Expanded(
              child: SegmentedButton(
                segments: [
                  ButtonSegment<int>(
                    label: Text(L10n.of(context).reading_page_auto),
                    value: 0,
                    icon: const Icon(Icons.auto_awesome),
                  ),
                  ButtonSegment<int>(
                    label: Text(L10n.of(context).reading_page_single),
                    value: 1,
                    icon: const Icon(EvaIcons.book),
                  ),
                  ButtonSegment<int>(
                    label: Text(L10n.of(context).reading_page_double),
                    value: 2,
                    icon: const Icon(EvaIcons.book_open),
                  ),
                ],
                selected: {Prefs().bookStyle.maxColumnCount},
                onSelectionChanged: (value) {
                  setState(() {
                    final newBookStyle =
                        Prefs().bookStyle.copyWith(maxColumnCount: value.first);
                    Prefs().saveBookStyleToPrefs(newBookStyle);
                    epubPlayerKey.currentState!.changeStyle(newBookStyle);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
