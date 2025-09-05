import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/convert_chinese_mode.dart';
import 'package:anx_reader/enums/reading_info.dart';
import 'package:anx_reader/enums/translation_mode.dart';
import 'package:anx_reader/enums/writing_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/page/settings_page/subpage/fonts.dart';
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
              Text(L10n.of(context).readingPageConvertChinese,
                  style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<ConvertChineseMode>(
                      segments: [
                        ButtonSegment<ConvertChineseMode>(
                          label: Text(L10n.of(context).readingPageOriginal),
                          value: ConvertChineseMode.none,
                          icon: const Text("原", style: iconStyle),
                        ),
                        ButtonSegment<ConvertChineseMode>(
                          label: Text(L10n.of(context).readingPageSimplified),
                          value: ConvertChineseMode.t2s,
                          icon: const Text("简", style: iconStyle),
                        ),
                        ButtonSegment<ConvertChineseMode>(
                          label: Text(L10n.of(context).readingPageTraditional),
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
                          epubPlayerKey.currentState
                              ?.changeReadingRules(Prefs().readingRules);
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
                      L10n.of(context).readingPageConvertChineseTips,
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
    //       title: Text(L10n.of(context).readingPageBionicReading,
    //           style: Theme.of(context).textTheme.titleMedium),
    //       subtitle: GestureDetector(
    //         child: Text(
    //           textAlign: TextAlign.start,
    //           L10n.of(context).readingPageBionicReadingTips,
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
    //             epubPlayerKey.currentState?
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
            Text(L10n.of(context).readingPageColumnCount,
                style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton(
                    segments: [
                      ButtonSegment<int>(
                        label: Text(L10n.of(context).readingPageAuto),
                        value: 0,
                        icon: const Icon(Icons.auto_awesome),
                      ),
                      ButtonSegment<int>(
                        label: Text(L10n.of(context).readingPageSingle),
                        value: 1,
                        icon: const Icon(EvaIcons.book),
                      ),
                      ButtonSegment<int>(
                        label: Text(L10n.of(context).readingPageDouble),
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
                        epubPlayerKey.currentState?.changeStyle(newBookStyle);
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

    Widget writingMode() {
      return StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L10n.of(context).readingPageWritingDirection,
                style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton(
                    segments: [
                      ButtonSegment<WritingModeEnum>(
                        label: Text(
                            L10n.of(context).readingPageWritingDirectionAuto),
                        value: WritingModeEnum.auto,
                        icon: const Icon(EvaIcons.activity_outline),
                      ),
                      ButtonSegment<WritingModeEnum>(
                        label: Text(L10n.of(context)
                            .readingPageWritingDirectionVertical),
                        value: WritingModeEnum.vertical,
                        icon: const Icon(Bootstrap.arrows_vertical),
                      ),
                      ButtonSegment<WritingModeEnum>(
                        label: Text(L10n.of(context)
                            .readingPageWritingDirectionHorizontal),
                        value: WritingModeEnum.horizontal,
                        icon: const Icon(Bootstrap.arrows),
                      ),
                    ],
                    selected: {Prefs().writingMode},
                    onSelectionChanged: (value) {
                      setState(() {
                        final newBookStyle =
                            Prefs().bookStyle.copyWith(maxColumnCount: 1);
                        Prefs().saveBookStyleToPrefs(newBookStyle);
                        Prefs().writingMode = value.first;
                        epubPlayerKey.currentState?.changeStyle(newBookStyle);
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

    Widget translationMode() {
      return StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L10n.of(context).translationMode,
                style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton(
                    segments: [
                      ButtonSegment<TranslationModeEnum>(
                        label: Text(L10n.of(context).readingPageOriginal),
                        value: TranslationModeEnum.off,
                        icon: const Icon(Icons.translate_outlined),
                      ),
                      ButtonSegment<TranslationModeEnum>(
                        label: Text(L10n.of(context).translationOnly),
                        value: TranslationModeEnum.translationOnly,
                        icon: const Icon(Icons.g_translate),
                      ),
                      // ButtonSegment<TranslationModeEnum>(
                      //   label: const Text('Original'),
                      //   value: TranslationModeEnum.originalOnly,
                      //   icon: const Icon(Icons.text_fields),
                      // ),
                      ButtonSegment<TranslationModeEnum>(
                        label: Text(L10n.of(context).bilingual),
                        value: TranslationModeEnum.bilingual,
                        icon: const Icon(Icons.compare),
                      ),
                    ],
                    selected: {
                      epubPlayerKey.currentState != null
                          ? Prefs().getBookTranslationMode(
                              epubPlayerKey.currentState!.widget.book.id)
                          : TranslationModeEnum.off
                    },
                    onSelectionChanged: (value) {
                      setState(() {
                        final currentBookId =
                            epubPlayerKey.currentState!.widget.book.id;
                        final newMode = value.first;

                        Prefs().setBookTranslationMode(currentBookId, newMode);

                        epubPlayerKey.currentState?.setTranslationMode(newMode);
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

    Widget buildInfoDropdown(
      BuildContext context,
      String label,
      ReadingInfoEnum currentValue,
      Function(ReadingInfoEnum) onChanged,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          DropdownButton<ReadingInfoEnum>(
            isDense: true,
            isExpanded: true,
            value: currentValue,
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
            underline: Container(),
            dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            items: ReadingInfoEnum.values.map((info) {
              return DropdownMenuItem<ReadingInfoEnum>(
                value: info,
                child: Text(
                  info.getL10n(context),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    Widget readingInfo() {
      return StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L10n.of(context).readingPageHeaderSettings,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: buildInfoDropdown(
                      context,
                      L10n.of(context).readingPageLeft,
                      Prefs().readingInfo.headerLeft,
                      (value) {
                        setState(() {
                          final newRules = Prefs().readingInfo.copyWith(
                                headerLeft: value,
                              );
                          Prefs().readingInfo = newRules;
                          epubPlayerKey.currentState?.changeReadingInfo();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: buildInfoDropdown(
                      context,
                      L10n.of(context).readingPageCenter,
                      Prefs().readingInfo.headerCenter,
                      (value) {
                        setState(() {
                          final newRules = Prefs().readingInfo.copyWith(
                                headerCenter: value,
                              );
                          Prefs().readingInfo = newRules;
                          // epubPlayerKey.currentState
                          //     ?.changeReadingInfo(newRules);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: buildInfoDropdown(
                      context,
                      L10n.of(context).readingPageRight,
                      Prefs().readingInfo.headerRight,
                      (value) {
                        setState(() {
                          final newRules = Prefs().readingInfo.copyWith(
                                headerRight: value,
                              );
                          Prefs().readingInfo = newRules;
                          epubPlayerKey.currentState?.changeReadingInfo();
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(L10n.of(context).readingSettingsMargin),
                  Expanded(
                    child: Slider(
                      value: Prefs().pageHeaderMargin.toDouble(),
                      min: 0,
                      max: 80,
                      divisions: 40,
                      label: Prefs().pageHeaderMargin.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() {
                          Prefs().pageHeaderMargin = value;
                          epubPlayerKey.currentState?.changeReadingInfo();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const Divider(),
              Text(L10n.of(context).readingPageFooterSettings,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: buildInfoDropdown(
                      context,
                      L10n.of(context).readingPageLeft,
                      Prefs().readingInfo.footerLeft,
                      (value) {
                        setState(() {
                          final newRules = Prefs().readingInfo.copyWith(
                                footerLeft: value,
                              );
                          Prefs().readingInfo = newRules;
                          epubPlayerKey.currentState?.changeReadingInfo();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: buildInfoDropdown(
                      context,
                      L10n.of(context).readingPageCenter,
                      Prefs().readingInfo.footerCenter,
                      (value) {
                        setState(() {
                          final newRules = Prefs().readingInfo.copyWith(
                                footerCenter: value,
                              );
                          Prefs().readingInfo = newRules;
                          epubPlayerKey.currentState?.changeReadingInfo();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: buildInfoDropdown(
                      context,
                      L10n.of(context).readingPageRight,
                      Prefs().readingInfo.footerRight,
                      (value) {
                        setState(() {
                          final newRules = Prefs().readingInfo.copyWith(
                                footerRight: value,
                              );
                          Prefs().readingInfo = newRules;
                          epubPlayerKey.currentState?.changeReadingInfo();
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(L10n.of(context).readingSettingsMargin),
                  Expanded(
                    child: Slider(
                      value: Prefs().pageFooterMargin.toDouble(),
                      min: 0,
                      max: 80,
                      divisions: 40,
                      label: Prefs().pageFooterMargin.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() {
                          // final newRules = Prefs().readingInfo.copyWith(
                          //       headerFontSize: value.toInt(),
                          //     );
                          // Prefs().readingInfo = newRules;
                          // epubPlayerKey.currentState?.changeReadingInfo();
                          Prefs().pageFooterMargin = value;
                          epubPlayerKey.currentState?.changeReadingInfo();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }

    Widget downloadFonts() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(L10n.of(context).downloadFonts),
        leading: const Icon(Icons.font_download_outlined),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FontsSettingPage(),
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          downloadFonts(),
          const Divider(height: 20),
          writingMode(),
          translationMode(),
          columnCount(),
          convertChinese(),
          const Divider(height: 15),
          readingInfo(),
          // const Divider(height: 8),
          // bionicReading(),
        ],
      ),
    );
  }
}
