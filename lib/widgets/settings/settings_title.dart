import 'package:anx_reader/widgets/settings/settings_app_bar.dart';
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

Scaffold settingsBody({
  required String title,
  required bool isMobile,
  required List<AbstractSettingsSection> sections,
}) {
  BuildContext context = navigatorKey.currentContext!;
  return Scaffold(
    appBar: isMobile ? settingsAppBar(title, context) : null,
    body: SettingsList(
        lightTheme: SettingsThemeData(
          settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          titleTextColor: Theme.of(context).colorScheme.primary,
        ),
        sections: sections),
  );
}
