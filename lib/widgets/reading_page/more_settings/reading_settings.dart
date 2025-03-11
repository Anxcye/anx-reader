import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/convert_chinese_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class ReadingMoreSettings extends StatefulWidget {
  const ReadingMoreSettings({super.key});

  @override
  State<ReadingMoreSettings> createState() => _ReadingMoreSettingsState();
}

class _ReadingMoreSettingsState extends State<ReadingMoreSettings> {
  @override
  Widget build(BuildContext context) {
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
                    child: SegmentedButton<ConvertChineseMode>(
                      segments: [
                        ButtonSegment<ConvertChineseMode>(
                          label: Text(L10n.of(context).reading_page_original),
                          value: ConvertChineseMode.none,
                          icon: const Text("原", style: iconStyle),
                        ),
                        ButtonSegment<ConvertChineseMode>(
                          label: Text(L10n.of(context).reading_page_simplified),
                          value: ConvertChineseMode.t2s,
                          icon: const Text("简", style: iconStyle),
                        ),
                        ButtonSegment<ConvertChineseMode>(
                          label:
                              Text(L10n.of(context).reading_page_traditional),
                          value: ConvertChineseMode.s2t,
                          icon: const Text("繁", style: iconStyle),
                        ),
                      ],
                      selected: {Prefs().readingRules.convertChineseMode},
                      onSelectionChanged: (value) {
                        setState(() {
                          // Prefs().readingRules.convertChineseMode =
                          //     ConvertChineseMode.values.byName(value.first);
                          Prefs().readingRules = Prefs()
                              .readingRules
                              .copyWith(convertChineseMode: value.first);
                          epubPlayerKey.currentState!
                              .changeReadingRules(Prefs().readingRules);
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.error_outline),
                  Expanded(
                    child: Text(
                      L10n.of(context).reading_page_convert_chinese_tips,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }

    // Widget bionicReading() {
    //   return StatefulBuilder(
    //     builder: (context, setState) => ListTile(
    //       contentPadding: EdgeInsets.zero,
    //       title: Text(L10n.of(context).reading_page_bionic_reading,
    //           style: Theme.of(context).textTheme.titleMedium),
    //       subtitle: GestureDetector(
    //         child: Text(
    //           textAlign: TextAlign.start,
    //           L10n.of(context).reading_page_bionic_reading_tips,
    //           style: const TextStyle(
    //             fontSize: 12,
    //             color: Color(0xFF666666),
    //             decoration: TextDecoration.underline,
    //           ),
    //         ),
    //         onTap: () {
    //           launchUrl(
    //             Uri.parse('https://github.com/Anxcye/anx-reader/issues/49'),
    //             mode: LaunchMode.externalApplication,
    //           );
    //         },
    //       ),
    //       trailing: Switch(
    //         value: Prefs().readingRules.bionicReading,
    //         onChanged: (value) {
    //           setState(() {
    //             Prefs().readingRules =
    //                 Prefs().readingRules.copyWith(bionicReading: value);
    //             epubPlayerKey.currentState!
    //                 .changeReadingRules(Prefs().readingRules);
    //           });
    //         },
    //       ),
    //     ),
    //   );
    // }

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
                        final newBookStyle = Prefs()
                            .bookStyle
                            .copyWith(maxColumnCount: value.first);
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

    return Container(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          columnCount(),
          const Divider(height: 8),
          convertChinese(),
          // const Divider(height: 8),
          // bionicReading(),
        ],
      ),
    );
  }
}
