import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/utils/ui/status_bar.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/page_turning/diagram.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/page_turning/types_and_icons.dart';
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
      title: Text(context.readingPagePageTurningMethod),
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
                  context, pageTurningTypes[index], pageTurningIcons[index], currentType == index,
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
