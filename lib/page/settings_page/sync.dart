import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/widgets/settings/theme_mode.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../config/shared_preference_provider.dart';
import '../../widgets/settings/dialog_option.dart';
import '../../widgets/settings/settings_app_bar.dart';

class SyncSetting extends StatelessWidget {
  const SyncSetting(
      {super.key,
      required this.isMobile,
      required this.id,
      required this.selectedIndex,
      required this.setDetail});

  final bool isMobile;
  final int id;
  final int selectedIndex;
  final void Function(Widget detail, int id) setDetail;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.sync),
      // TODO l10n
      title: Text('Sync'),
      trailing: const Icon(Icons.chevron_right),
      selected: selectedIndex == id,
      onTap: () {
        if (!isMobile) {
          setDetail(SubSyncSettings(isMobile: isMobile), id);
          return;
        }
        Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => SubSyncSettings(isMobile: isMobile)),
        );
      },
    );
  }
}

class SubSyncSettings extends StatelessWidget {
  const SubSyncSettings({super.key, required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isMobile ? settingsAppBar(context.appearance, context) : null,
      body: SettingsList(
        lightTheme: SettingsThemeData(
          settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          titleTextColor: Theme.of(context).colorScheme.primary,
        ),
        sections: [
          SettingsSection(
            title: Text(context.appearanceTheme),
            tiles: [
              SettingsTile.navigation(
                  title: Text(context.appearanceThemeColor),
                  leading: const Icon(Icons.color_lens),
                  onPressed: (context) async {
                    await _showColorPickerDialog(context);
                  }),
              // const CustomSettingsTile(child: Divider()),
            ],
          ),
          SettingsSection(title: Text(context.appearanceDisplay), tiles: [
            SettingsTile.navigation(
                title: Text(context.appearanceLanguage),
                leading: Icon(Icons.language),
                value: Text('ZH'),
                onPressed: (context) {
                  _showLanguagePickerDialog(context);
                })
          ])
        ],
      ),
    );
  }
}

_showLanguagePickerDialog(BuildContext context) {
  final saveToPrefs = Prefs().saveLocaleToPrefs;
  return showDialog(
      context: context,
      builder: (BuildContext context) {

        return SimpleDialog(
          title: Text(context.appearanceLanguage),
          children: [
            dialogOption('简体中文', 'zh', saveToPrefs),
            dialogOption('English', 'en', saveToPrefs),
          ],
        );
      });
}


Future<void> _showColorPickerDialog(BuildContext context) async {
  final prefsProvider =
      Provider.of<Prefs>(context, listen: false);
  final currentColor = prefsProvider.themeColor;

  Color pickedColor = currentColor;

  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(context.appearanceThemeColor),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickedColor,
            onColorChanged: (color) {
              pickedColor = color;
            },
            enableAlpha: false,
            displayThumbColor: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: Text('CANCEL'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('OK'),
            onPressed: () {
              prefsProvider.saveThemeToPrefs(pickedColor.value);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
