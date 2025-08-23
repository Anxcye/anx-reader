import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:anx_reader/widgets/settings/simple_dialog.dart';
import 'package:anx_reader/widgets/settings/theme_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';

const List<Map<String, String>> languageOptions = [
  {'system': 'System'},
  {'English': 'en'},
  {'简体中文': 'zh-CN'},
  {'繁體中文': 'zh-TW'},
  {'文言文': 'zh-LZH'},
  {'Türkçe': 'tr'},
  {'Deutsch': 'de'},
  {'العربية': 'ar'},
  {'Русский': 'ru'},
  {'Français': 'fr'},
  {'Español': 'es'},
  {'Italiano': 'it'},
  {'Português': 'pt'}, 
  {'日本語': 'ja'},
  {'한국어': 'ko'},
];

class AppearanceSetting extends StatefulWidget {
  const AppearanceSetting({super.key});

  @override
  State<AppearanceSetting> createState() => _AppearanceSettingState();
}

class _AppearanceSettingState extends State<AppearanceSetting> {
  @override
  Widget build(BuildContext context) {
    final languageSubtitle = Prefs().locale == null
        ? languageOptions[0].values.first
        : languageOptions
            .firstWhere(
                (element) =>
                    element.values.first ==
                    Prefs().locale!.languageCode +
                        (Prefs().locale!.countryCode != null
                            ? "-${Prefs().locale!.countryCode}"
                            : ""),
                orElse: () => languageOptions[0])
            .keys
            .first;

    return settingsSections(
      sections: [
        SettingsSection(
          title: Text(L10n.of(context).settingsAppearanceTheme),
          tiles: [
            const CustomSettingsTile(
                child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: ChangeThemeMode(),
            )),
            SettingsTile.navigation(
                title: Text(L10n.of(context).settingsAppearanceThemeColor),
                leading: const Icon(Icons.color_lens),
                onPressed: (context) async {
                  await showColorPickerDialog(context);
                }),
            SettingsTile.switchTile(
              title: const Text("OLED Dark Mode"),
              leading: const Icon(Icons.brightness_2),
              initialValue: Prefs().trueDarkMode,
              onToggle: (bool value) {
                setState(() {
                  Prefs().trueDarkMode = value;
                });
              },
            ),
            SettingsTile.switchTile(
              title: Text(L10n.of(context).eInkMode),
              leading: const Icon(Icons.contrast),
              initialValue: Prefs().eInkMode,
              onToggle: (bool value) {
                setState(() {
                  Prefs().saveThemeModeToPrefs('light');
                  Prefs().eInkMode = value;
                });
              },
            ),
          ],
        ),
        SettingsSection(
            title: Text(L10n.of(context).settingsAppearanceDisplay),
            tiles: [
              SettingsTile.navigation(
                  title: Text(L10n.of(context).settingsAppearanceLanguage),
                  value: Text(languageSubtitle),
                  leading: const Icon(Icons.language),
                  onPressed: (context) {
                    showLanguagePickerDialog(context);
                  }),
              SettingsTile.switchTile(
                title: Text(
                    L10n.of(context).settingsAppearanceOpenBookAnimation),
                leading: const Icon(Icons.animation),
                initialValue: Prefs().openBookAnimation,
                onToggle: (bool value) {
                  setState(() {
                    Prefs().openBookAnimation = value;
                  });
                },
              ),
            ]),
        SettingsSection(
            title: Text(L10n.of(context).settingsBookshelfCover),
            tiles: [
              CustomSettingsTile(
                  child: ListTile(
                title: Text(L10n.of(context).settingsBookshelfCoverWidth),
                subtitle: Row(
                  children: [
                    Text(Prefs().bookCoverWidth.toStringAsFixed(0)),
                    Expanded(
                      child: Slider(
                        value: Prefs().bookCoverWidth,
                        onChanged: (value) {
                          setState(() {
                            Prefs().bookCoverWidth = value;
                          });
                        },
                        max: 260,
                        min: 80,
                        divisions: 18,
                      ),
                    ),
                  ],
                ),
              )),
            ]),
        SettingsSection(
          title:
              Text(L10n.of(context).settingsAppearanceBottomNavigatorShow),
          tiles: [
            SettingsTile.switchTile(
              title: Text(L10n.of(context).navBarStatistics),
              initialValue: Prefs().bottomNavigatorShowStatistics,
              onToggle: (bool value) {
                setState(() {
                  Prefs().bottomNavigatorShowStatistics = value;
                });
              },
            ),
            SettingsTile.switchTile(
              title: Text(L10n.of(context).navBarNotes),
              initialValue: Prefs().bottomNavigatorShowNote,
              onToggle: (bool value) {
                setState(() {
                  Prefs().bottomNavigatorShowNote = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

void showLanguagePickerDialog(BuildContext context) {
  final title = L10n.of(context).settingsAppearanceLanguage;
  final saveToPrefs = Prefs().saveLocaleToPrefs;

  final children = languageOptions.map((e) {
    final key = e.keys.first;
    final value = e[key]!;
    return dialogOption(key, value, saveToPrefs);
  }).toList();
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
        title: Text(L10n.of(context).settingsAppearanceThemeColor),
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
            child: Text(L10n.of(context).commonCancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(L10n.of(context).commonOk),
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
