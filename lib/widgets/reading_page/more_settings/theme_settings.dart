import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/utils/ui/status_bar.dart';
import 'package:anx_reader/widgets/reading_page/page_turning/diagram.dart';
import 'package:flutter/material.dart';

Widget themeSettings = StatefulBuilder(
  builder: (context, setState) => SingleChildScrollView(
    child: Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          fullScreen(context, setState),
          pageTurningControl(),
        ],
      ),
    ),
  ),
);

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

Widget pageTurningControl() {
  List<PageTurningType> type1 = [
    PageTurningType.prev,
    PageTurningType.menu,
    PageTurningType.next,
    PageTurningType.prev,
    PageTurningType.menu,
    PageTurningType.next,
    PageTurningType.prev,
    PageTurningType.menu,
    PageTurningType.next
  ];
  List<int> icon1 = [5, 3, 4];

  List<PageTurningType> type2 = [
    PageTurningType.prev,
    PageTurningType.prev,
    PageTurningType.next,
    PageTurningType.prev,
    PageTurningType.menu,
    PageTurningType.next,
    PageTurningType.prev,
    PageTurningType.next,
    PageTurningType.next
  ];
  List<int> icon2 = [5, 3, 4];

  List<PageTurningType> type3 = [
    PageTurningType.prev,
    PageTurningType.prev,
    PageTurningType.next,
    PageTurningType.prev,
    PageTurningType.menu,
    PageTurningType.next,
    PageTurningType.next,
    PageTurningType.next,
    PageTurningType.next
  ];
  List<int> icon3 = [5, 3, 4];

  List<PageTurningType> type4 = [
    PageTurningType.prev,
    PageTurningType.menu,
    PageTurningType.prev,
    PageTurningType.prev,
    PageTurningType.menu,
    PageTurningType.next,
    PageTurningType.next,
    PageTurningType.next,
    PageTurningType.next
  ];
  List<int> icon4 = [5, 3, 4];

  List<List<PageTurningType>> types = [type1, type2, type3, type4];
  List<List<int>> icons = [icon1, icon2, icon3, icon4];

  int currentType = Prefs().pageTurningType;

  return StatefulBuilder(builder: (
    BuildContext context,
    void Function(void Function()) setState,
  ) {
    void onTap(int index) {
      Prefs().pageTurningType = index;
      currentType = index;
      setState(() {});
    }

    return ListTile(
      title: Text('Page Turning Control'),
      subtitle: SizedBox(
        height: 120,
        child: ListView.builder(
          itemCount: 4,
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: getPageTurningDiagram(
                  context, types[index], icons[index], currentType == index,
                  () {
                onTap(index);
              }),
            );
          },
        ),
      ),
    );
  });
}
