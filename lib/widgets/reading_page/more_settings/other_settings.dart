import 'package:anx_reader/utils/platform_utils.dart';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/page_turn_mode.dart';
import 'package:anx_reader/enums/long_press_selection_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/ui/status_bar.dart';
import 'package:anx_reader/widgets/common/anx_segmented_button.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/page_turning/diagram.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/page_turning/page_turn_dropdown.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/page_turning/types_and_icons.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/selection_menu_settings_dialog.dart';
import 'package:flutter/material.dart';

class OtherSettings extends StatefulWidget {
  const OtherSettings({super.key});

  @override
  State<OtherSettings> createState() => _OtherSettingsState();
}

class _OtherSettingsState extends State<OtherSettings> {
  @override
  Widget build(BuildContext context) {
    Widget screenTimeout() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          L10n.of(context).readingPageScreenTimeout,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        leadingAndTrailingTextStyle: TextStyle(
          fontSize: 16,
          color: Theme.of(context).textTheme.bodyLarge!.color,
        ),
        subtitle: Row(
          children: [
            Text(L10n.of(context).commonMinutes(Prefs().awakeTime)),
            Expanded(
              child: Slider(
                  min: 0,
                  max: 60,
                  label: Prefs().awakeTime.toString(),
                  value: Prefs().awakeTime.toDouble(),
                  onChangeEnd: (value) => setState(() {
                        readingPageKey.currentState
                            ?.setAwakeTimer(value.toInt());
                      }),
                  onChanged: (value) => setState(() {
                        Prefs().awakeTime = value.toInt();
                      })),
            ),
          ],
        ),
      );
    }

    ListTile fullScreen() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        trailing: Switch(
            value: Prefs().hideStatusBar,
            onChanged: (bool? value) => setState(() {
                  Prefs().saveHideStatusBar(value!);
                  if (value) {
                    hideStatusBar();
                  } else {
                    showStatusBar();
                  }
                })),
        title: Text(L10n.of(context).readingPageFullScreen),
      );
    }

    Widget pageTurningControl() {
      int currentType = Prefs().pageTurningType;
      ScrollController scrollController = ScrollController();
      PageTurnMode currentMode = PageTurnMode.fromCode(Prefs().pageTurnMode);

      return StatefulBuilder(builder: (
        BuildContext context,
        void Function(void Function()) setState,
      ) {
        void onTap(int index) {
          setState(() {
            Prefs().pageTurningType = index;
            currentType = index;
          });
        }

        void onModeChanged(Set<PageTurnMode> selected) {
          setState(() {
            currentMode = selected.first;
            Prefs().pageTurnMode = selected.first.code;
          });
        }

        void onCustomConfigChanged(int index, PageTurningType type) {
          List<int> config = Prefs().customPageTurnConfig;
          config[index] = type.index;
          Prefs().customPageTurnConfig = config;
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                L10n.of(context).readingPagePageTurningMethod,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AnxSegmentedButton<PageTurnMode>(
                segments: [
                  SegmentButtonItem(
                    value: PageTurnMode.simple,
                    label: L10n.of(context).pageTurnModeSimple,
                  ),
                  SegmentButtonItem(
                    value: PageTurnMode.custom,
                    label: L10n.of(context).pageTurnModeCustom,
                  ),
                ],
                selected: {currentMode},
                onSelectionChanged: onModeChanged,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              if (currentMode == PageTurnMode.simple) ...[
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: pageTurningTypes.length,
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: getPageTurningDiagram(
                          context,
                          pageTurningTypes[index],
                          pageTurningIcons[index],
                          currentType == index,
                          () {
                            onTap(index);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Text(
                  L10n.of(context).customPageTurnConfig,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    for (int row = 0; row < 3; row++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            for (int col = 0; col < 3; col++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: col < 2 ? 8.0 : 0,
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      int index = row * 3 + col;
                                      List<int> config =
                                          Prefs().customPageTurnConfig;
                                      return PageTurnDropdown(
                                        value: PageTurningType
                                            .values[config[index]],
                                        onChanged: (type) {
                                          if (type != null) {
                                            setState(() {
                                              onCustomConfigChanged(
                                                  index, type);
                                            });
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      });
    }

    Widget longPressSelectionMode() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(L10n.of(context).readingPageLongPressSelection),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L10n.of(context).readingPageLongPressSelectionTips),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final mode in LongPressSelectionMode.values)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      minimumSize: Size(48, Prefs().eInkMode ? 56 : 48)),
                  icon: Icon(Prefs().longPressSelectionMode == mode
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked),
                  label: Text(mode == LongPressSelectionMode.word
                      ? L10n.of(context).selectionRangeWord
                      : L10n.of(context).selectionRangeSentence),
                  onPressed: () => setState(() {
                    Prefs().longPressSelectionMode = mode;
                  }),
                ),
            ]),
          ],
        ),
      );
    }

    Widget selectionMenuSettings() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(L10n.of(context).selectionMenuSettingsTitle),
        subtitle: Text(L10n.of(context).selectionMenuSettingsTips),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showSelectionMenuSettingsDialog(context),
      );
    }

    ListTile autoSummaryPreviousContent() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(L10n.of(context).readingPageAutoSummaryPreviousContent),
        trailing: Switch(
          value: Prefs().autoSummaryPreviousContent,
          onChanged: (bool value) => setState(() {
            Prefs().autoSummaryPreviousContent = value;
          }),
        ),
      );
    }

    ListTile autoAdjustReadingTheme() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(L10n.of(context).readingPageAutoAdjustReadingTheme),
        subtitle: Text(L10n.of(context).readingPageAutoAdjustReadingThemeTips),
        trailing: Switch(
          value: Prefs().autoAdjustReadingTheme,
          onChanged: (bool value) => setState(() {
            Prefs().autoAdjustReadingTheme = value;
          }),
        ),
      );
    }

    ListTile keyboardTurnPage() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(L10n.of(context).readingPageVolumeKeyTurnPage),
        trailing: Switch(
          value: Prefs().volumeKeyTurnPage,
          onChanged: (bool value) => setState(() {
            Prefs().volumeKeyTurnPage = value;
          }),
        ),
      );
    }

    Widget swipeTurnPage() => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(L10n.of(context).readingPageSwipeToTurnPage),
          subtitle: Text(L10n.of(context).readingPageSwipeToTurnPageHint),
          trailing: Switch(
            value: Prefs().swipeToTurnPage,
            onChanged: (value) => setState(() {
              Prefs().swipeToTurnPage = value;
            }),
          ),
        );

    ListTile swapPageTurnArea() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(L10n.of(context).readingPageSwapPageTurnArea),
        subtitle: Text(L10n.of(context).readingPageSwapPageTurnAreaTips),
        trailing: Switch(
          value: Prefs().swapPageTurnArea,
          onChanged: (bool value) => setState(() {
            Prefs().swapPageTurnArea = value;
          }),
        ),
      );
    }

    ListTile showMenuOnHover() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(L10n.of(context).readingPageShowMenuOnHover),
        subtitle: Text(L10n.of(context).readingPageShowMenuOnHoverTips),
        trailing: Switch(
          value: Prefs().showMenuOnHover,
          onChanged: (bool value) => setState(() {
            Prefs().showMenuOnHover = value;
          }),
        ),
      );
    }

    ListTile keyboardShortcutTurnPage() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(L10n.of(context).readingPageKeyboardShortcutTurnPage),
        subtitle:
            Text(L10n.of(context).readingPageKeyboardShortcutTurnPageTips),
        trailing: Switch(
          value: Prefs().keyboardShortcutTurnPage,
          onChanged: (bool value) => setState(() {
            Prefs().keyboardShortcutTurnPage = value;
          }),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          fullScreen(),
          if (AnxPlatform.isAndroid) keyboardTurnPage(),
          swipeTurnPage(),
          // if (PageTurnMode.fromCode(Prefs().pageTurnMode) ==
          //     PageTurnMode.simple)
          swapPageTurnArea(),
          showMenuOnHover(),
          if (AnxPlatform.isDesktop) keyboardShortcutTurnPage(),
          autoAdjustReadingTheme(),
          longPressSelectionMode(),
          selectionMenuSettings(),
          autoSummaryPreviousContent(),
          screenTimeout(),
          pageTurningControl(),
        ],
      ),
    );
  }
}
