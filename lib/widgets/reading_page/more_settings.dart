import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/main.dart';
import 'package:contentsize_tabbarview/contentsize_tabbarview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ReadingSettings { theme, font }

void showMoreSettings(ReadingSettings settings) {
  BuildContext context = navigatorKey.currentContext!;
  Navigator.of(context).pop();
  TabController? tabController =
      TabController(length: 2, vsync: Navigator.of(context));

  Widget themeSettings = StatefulBuilder(
    builder: (context, setState) => SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(8.0),
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
              title: Text('full screen'),
            )
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
                Tab(text: 'Theme'),
                Tab(text: 'Font'),
              ],
            ),
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
