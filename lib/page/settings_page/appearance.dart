import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
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
        title: L10n.of(context).settings_appearance,
        isMobile: isMobile,
        id: id,
        selectedIndex: selectedIndex,
        setDetail: setDetail,
        subPage: SubAppearanceSettings(isMobile: isMobile));
  }
}

class SubAppearanceSettings extends StatefulWidget {
  const SubAppearanceSettings({super.key, required this.isMobile});

  final bool isMobile;

  @override
  State<SubAppearanceSettings> createState() => _SubAppearanceSettingsState();
}

class _SubAppearanceSettingsState extends State<SubAppearanceSettings> {
  @override
  Widget build(BuildContext context) {
    return settingsBody(
      title: L10n.of(context).settings_appearance,
      isMobile: widget.isMobile,
      sections: [
        SettingsSection(
          title: Text(L10n.of(context).settings_appearance_theme),
          tiles: [
            const CustomSettingsTile(
                child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: ChangeThemeMode(),
            )),
            SettingsTile.navigation(
                title: Text(L10n.of(context).settings_appearance_themeColor),
                leading: const Icon(Icons.color_lens),
                onPressed: (context) async {
                  await showColorPickerDialog(context);
                }),
            SettingsTile.switchTile(
              title: Text("OLED Dark Mode"),
              leading: const Icon(Icons.brightness_2),
              initialValue: Prefs().trueDarkMode,
              onToggle: (bool value) {
                setState(() {

                Prefs().trueDarkMode = value;
                });
              },
            ),
            const CustomSettingsTile(child: Divider()),
          ],
        ),
        SettingsSection(
            title: Text(L10n.of(context).settings_appearance_display),
            tiles: [
              SettingsTile.navigation(
                  title: Text(L10n.of(context).settings_appearance_language),
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
  final title = L10n.of(context).settings_appearance_language;
  final saveToPrefs = Prefs().saveLocaleToPrefs;
  final children = [
    dialogOption('System', '', saveToPrefs),
    dialogOption('English', 'en', saveToPrefs),
    dialogOption('简体中文', 'zh', saveToPrefs),
    dialogOption('Türkçe', 'tr', saveToPrefs)
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
        title: Text(L10n.of(context).settings_appearance_themeColor),
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
            child: Text(L10n.of(context).common_cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(L10n.of(context).common_ok),
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
