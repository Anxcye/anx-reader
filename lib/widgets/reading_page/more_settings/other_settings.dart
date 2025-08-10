import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/ui/status_bar.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/page_turning/diagram.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/page_turning/types_and_icons.dart';
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

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            L10n.of(context).readingPagePageTurningMethod,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: SizedBox(
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
        );
      });
    }

    Widget autoTranslateSelection() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        trailing: Switch(
          value: Prefs().autoTranslateSelection,
          onChanged: (bool value) => setState(() {
            Prefs().autoTranslateSelection = value;
          }),
        ),
        title: Text(L10n.of(context).readingPageAutoTranslateSelection),
      );
    }

    ListTile autoSummaryPreviousContent() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title:
            Text(L10n.of(context).readingPageAutoSummaryPreviousContent),
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
        subtitle:
            Text(L10n.of(context).readingPageAutoAdjustReadingThemeTips),
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

    ListTile swapPageTurnArea() {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(L10n.of(context).readingPageSwapPageTurnArea ?? "Swap page turn area"),
        subtitle: Text(L10n.of(context).readingPageSwapPageTurnAreaTips ?? "Turn the up area into down area"),
        trailing: Switch(
          value: Prefs().swapPageTurnArea,
          onChanged: (bool value) => setState(() {
            Prefs().swapPageTurnArea = value;
          }),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          fullScreen(),
          if (Platform.isAndroid) keyboardTurnPage(),
          swapPageTurnArea(),
          autoAdjustReadingTheme(),
          autoTranslateSelection(),
          autoSummaryPreviousContent(),
          screenTimeout(),
          pageTurningControl(),
        ],
      ),
    );
  }
}
