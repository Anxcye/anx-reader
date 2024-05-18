import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/ui/status_bar.dart';
import 'package:contentsize_tabbarview/contentsize_tabbarview.dart';
import 'package:flutter/material.dart';

enum ReadingSettings { theme, style }

void showMoreSettings(ReadingSettings settings) {
  BuildContext context = navigatorKey.currentContext!;
  Navigator.of(context).pop();
  TabController? tabController = TabController(
    length: 2,
    vsync: Navigator.of(context),
    initialIndex: settings == ReadingSettings.theme ? 0 : 1,
  );

  Widget themeSettings = StatefulBuilder(
    builder: (context, setState) => SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            fullScreen(context, setState),
          ],
        ),
      ),
    ),
  );

  Widget fontSettings = StatefulBuilder(
    builder: (context, setState) => SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            screenTimeout(context, setState),
          ],
        ),
      ),
    ),
  );

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: tabController,
              tabs: [
                Tab(text: context.readingPageTheme),
                Tab(text: context.readingPageStyle),
              ],
            ),
            const Divider(height: 0),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: ContentSizeTabBarView(
                animationDuration: const Duration(milliseconds: 600),
                controller: tabController,
                children: [
                  themeSettings,
                  fontSettings,
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget screenTimeout(BuildContext context, StateSetter setState) {
  return Padding(
    padding: const EdgeInsets.only(left: 10.0, right: 10.0),
    child: ListTile(
      title: Text(context.readingPageScreenTimeout),
      leadingAndTrailingTextStyle: TextStyle(
        fontSize: 16,
        color: Theme.of(context).textTheme.bodyLarge!.color,
      ),
      subtitle: Row(
        children: [
          Text(Prefs().awakeTime.toString() + context.commonMinutes),
          Expanded(
            child: Slider(
                min: 0,
                max: 60,
                label: Prefs().awakeTime.toString(),
                value: Prefs().awakeTime.toDouble(),
                onChangeEnd: (value) => setState(() {
                      readingPageKey.currentState!.setAwakeTimer(value.toInt());
                    }),
                onChanged: (value) => setState(() {
                      Prefs().awakeTime = value.toInt();
                    })),
          ),
        ],
      ),
    ),
  );
}

ListTile fullScreen(BuildContext context, StateSetter setState) {
  return ListTile(
    leading: Checkbox(
        value: Prefs().hideStatusBar,
        onChanged: (bool? value) => setState(() {
              Prefs().saveHideStatusBar(value!);
              if (value) {
                hideStatusBar();
              } else {
                showStatusBar();
              }
            })),
    title: Text(context.readingPageFullScreen),
  );
}
