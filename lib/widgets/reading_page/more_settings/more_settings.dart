import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/other_settings.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/reading_settings.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/style_settings.dart';
import 'package:contentsize_tabbarview/contentsize_tabbarview.dart';
import 'package:flutter/material.dart';

enum ReadingSettings { theme, style }

void showMoreSettings(ReadingSettings settings) {
  BuildContext context = navigatorKey.currentContext!;
  // Navigator.of(context).pop();
  readingPageKey.currentState!.showOrHideAppBarAndBottomBar(false);

  List<Tab> tabs = [
    Tab(text: L10n.of(context).reading_page_reading),
    Tab(text: L10n.of(context).reading_page_style),
    Tab(text: L10n.of(context).reading_page_other),
  ];

  List<Widget> childrens = [
    readingSettings,
    styleSettings,
    otherSettings,
  ];

  TabController? tabController = TabController(
    length: tabs.length,
    vsync: Navigator.of(context),
    initialIndex: settings == ReadingSettings.theme ? 0 : 1,
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
              tabs: tabs,
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
                children: childrens,
              ),
            ),
          ],
        ),
      );
    },
  );
}
