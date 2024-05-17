import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:contentsize_tabbarview/contentsize_tabbarview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ReadingSettings { theme, font }

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
            ListTile(
              leading: Checkbox(
                  value: Prefs().hideStatusBar,
                  onChanged: (bool? value) => setState(() {
                        Prefs().saveHideStatusBar(value!);
                        if (value) {
                          SystemChrome.setEnabledSystemUIMode(
                              SystemUiMode.immersiveSticky);
                        } else {
                          SystemChrome.setEnabledSystemUIMode(
                              SystemUiMode.edgeToEdge);
                        }
                      })),
              // TODO l10n
              title: Text('full screen'),
            ),
            ListTile(
              // title: Text('Awake time'),
              title: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text('Turn off after ${Prefs().awakeTime} minutes'),
              ),
              subtitle: Slider(
                  min: 0,
                  max: 60,
                  label: Prefs().awakeTime.toString(),
                  value: Prefs().awakeTime.toDouble(),
                  onChangeEnd: (value) => setState(() {
                        readingPageKey.currentState!
                            .setAwakeTimer(value.toInt());
                      }),
                  onChanged: (value) => setState(() {
                        Prefs().awakeTime = value.toInt();
                      })),
            ),
          ],
        ),
      ),
    ),
  );
  Widget fontSettings = SingleChildScrollView(
    child: Container(
      padding: EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
          Text('Font content goes here.'),
        ],
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
              tabs: const [
                // TODO l10n
                Tab(text: 'Theme'),
                Tab(text: 'Font'),
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
