import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:anx_reader/widgets/settings/simple_dialog.dart';
import 'package:anx_reader/widgets/settings/theme_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

class AppearanceSetting extends StatelessWidget {
  const AppearanceSetting(
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
    return settingsTitle(
        icon: const Icon(Icons.palette_outlined),
        title: context.settingsAppearance,
        isMobile: isMobile,
        id: id,
        selectedIndex: selectedIndex,
        setDetail: setDetail,
        subPage: SubAppearanceSettings(isMobile: isMobile));
  }
}

class SubAppearanceSettings extends StatelessWidget {
  const SubAppearanceSettings({super.key, required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return settingsBody(
      title: context.settingsAppearance,
      isMobile: isMobile,
      sections: [
        SettingsSection(
          title: Text(context.settingsAppearanceTheme),
          tiles: [
            const CustomSettingsTile(
                child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: ChangeThemeMode(),
            )),
            SettingsTile.navigation(
                title: Text(context.settingsAppearanceThemeColor),
                leading: const Icon(Icons.color_lens),
                onPressed: (context) async {
                  await showColorPickerDialog(context);
                }),
            const CustomSettingsTile(child: Divider()),
          ],
        ),
        SettingsSection(title: Text(context.settingsAppearanceDisplay), tiles: [
          SettingsTile.navigation(
              title: Text(context.settingsAppearanceLanguage),
              value: Text(Prefs().locale?.languageCode ?? 'system'),
              leading: const Icon(Icons.language),
              onPressed: (context) {
                showLanguagePickerDialog(context);
              })
        ])
      ],
    );
  }
}

void showLanguagePickerDialog(BuildContext context) {
  final title = context.settingsAppearanceLanguage;
  final saveToPrefs = Prefs().saveLocaleToPrefs;
  final children = [
    dialogOption('System', '', saveToPrefs),
    dialogOption('简体中文', 'zh', saveToPrefs),
    dialogOption('English', 'en', saveToPrefs),
  ];
  showSimpleDialog(title, saveToPrefs, children);
}

Future<void> showColorPickerDialog(BuildContext context) async {
  final prefsProvider = Provider.of<Prefs>(context, listen: false);
  final currentColor = prefsProvider.themeColor;

  Color pickedColor = currentColor;

  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(context.settingsAppearanceThemeColor),
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
          TextButton(
            child: Text(context.commonCancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(context.commonOk),
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
