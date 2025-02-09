import 'package:anx_reader/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

Widget settingsTitle(
    {required Icon icon,
    required String title,
    required bool isMobile,
    required int id,
    required int selectedIndex,
    required Function setDetail,
    required Widget subPage}) {
  BuildContext context = navigatorKey.currentContext!;
  return ListTile(
    leading: icon,
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    selected: !isMobile && selectedIndex == id,
    onTap: () {
      if (!isMobile) {
        setDetail(subPage, id);
        return;
      }
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (context) => subPage),
      );
    },
  );
}

Widget settingsSections({
  required List<AbstractSettingsSection> sections,
}) {
  return SettingsList(sections: sections);
}
