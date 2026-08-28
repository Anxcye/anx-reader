import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/widgets/common/anx_segmented_button.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:anx_reader/widgets/settings/simple_dialog.dart';
import 'package:anx_reader/widgets/settings/theme_mode.dart';
import 'package:anx_reader/widgets/settings/device_display_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/enums/bookshelf_folder_style.dart';

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
  {'Română': 'ro'},
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
          title: Text(L10n.of(context).settingsDeviceDisplayProfile),
          tiles: const [
            CustomSettingsTile(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: DeviceDisplayProfileCard(),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: Text(L10n.of(context).settingsColorAppearance),
          tiles: [
            const CustomSettingsTile(
                child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: ChangeThemeMode(),
            )),
            SettingsTile.navigation(
                title: Text(L10n.of(context).settingsAppearanceThemeColor),
                leading: const Icon(Icons.color_lens),
                enabled: !Prefs().isEInkMode,
                description: Prefs().isEInkMode
                    ? Text(L10n.of(context).eInkSettingDisabledTip)
                    : null,
                onPressed: (context) async {
                  await showColorPickerDialog(context);
                }),
            SettingsTile.switchTile(
              title: Text(L10n.of(context).oledPureBlack),
              leading: const Icon(Icons.brightness_2),
              enabled: !Prefs().isEInkMode,
              description: Prefs().isEInkMode
                  ? Text(L10n.of(context).eInkSettingDisabledTip)
                  : Text(L10n.of(context).oledPureBlackDescription),
              initialValue: Prefs().trueDarkMode,
              onToggle: (bool value) {
                setState(() {
                  Prefs().trueDarkMode = value;
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
                title:
                    Text(L10n.of(context).settingsAppearanceOpenBookAnimation),
                leading: const Icon(Icons.animation),
                initialValue: Prefs().openBookAnimation,
                onToggle: (bool value) {
                  setState(() {
                    Prefs().openBookAnimation = value;
                  });
                },
              ),
              SettingsTile.switchTile(
                title: Text(L10n.of(context).settingsAdvancedAutoHideBottomBar),
                leading: const Icon(Icons.vertical_align_bottom),
                initialValue: Prefs().autoHideBottomBar,
                onToggle: (value) {
                  Prefs().autoHideBottomBar = value;
                  setState(() {});
                },
              ),
              SettingsTile.switchTile(
                title: Text(L10n.of(context).reduceVibrationFeedback),
                leading: const Icon(Icons.vibration),
                initialValue: Prefs().reduceVibrationFeedback,
                onToggle: (bool value) {
                  setState(() {
                    Prefs().reduceVibrationFeedback = value;
                  });
                },
              ),
              SettingsTile.switchTile(
                title: Text(L10n.of(context).readingPageShowActionLabels),
                leading: const Icon(Icons.subtitles_outlined),
                initialValue: Prefs().showActionLabels,
                onToggle: (bool value) {
                  setState(() {
                    Prefs().showActionLabels = value;
                  });
                },
                description:
                    Text(L10n.of(context).readingPageShowActionLabelsTips),
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
              CustomSettingsTile(
                  child: ListTile(
                title: Text(L10n.of(context).settingsBookshelfFolderStyle),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AnxSegmentedButton<BookshelfFolderStyle>(
                    segments: [
                      SegmentButtonItem(
                        label: L10n.of(context)
                            .settingsBookshelfFolderStyleOverlap,
                        value: BookshelfFolderStyle.stacked,
                        icon: Icon(Icons.layers),
                      ),
                      SegmentButtonItem(
                        label:
                            L10n.of(context).settingsBookshelfFolderStyleGrid,
                        value: BookshelfFolderStyle.grid2x2,
                        icon: Icon(Icons.grid_view),
                      ),
                    ],
                    selected: {Prefs().bookshelfFolderStyle},
                    onSelectionChanged: (value) {
                      setState(() {
                        Prefs().bookshelfFolderStyle = value.first;
                      });
                    },
                  ),
                ),
              )),
              SettingsTile.switchTile(
                title: Text(
                    L10n.of(context).settingsBookshelfDefaultCoverShowTitle),
                leading: const Icon(Icons.title),
                initialValue: Prefs().showBookTitleOnDefaultCover,
                onToggle: (bool value) {
                  setState(() {
                    Prefs().showBookTitleOnDefaultCover = value;
                  });
                },
              ),
              SettingsTile.switchTile(
                title: Text(
                    L10n.of(context).settingsBookshelfDefaultCoverShowAuthor),
                leading: const Icon(Icons.person),
                initialValue: Prefs().showAuthorOnDefaultCover,
                onToggle: (bool value) {
                  setState(() {
                    Prefs().showAuthorOnDefaultCover = value;
                  });
                },
              ),
              // SettingsTile.switchTile(
              //   title: Text(
              //       L10n.of(context).settingsAdvancedUseOriginalCoverRatio),
              //   leading: const Icon(Icons.photo_size_select_large_outlined),
              //   initialValue: Prefs().useOriginalCoverRatio,
              //   onToggle: (bool value) {
              //     setState(() {
              //       Prefs().useOriginalCoverRatio = value;
              //     });
              //   },
              // ),
            ]),
        SettingsSection(
          title: Text(L10n.of(context).settingsAppearanceBottomNavigatorShow),
          tiles: [
            if (EnvVar.enableAIFeature)
              SettingsTile.switchTile(
                title: Text(L10n.of(context).navBarAI),
                initialValue: Prefs().bottomNavigatorShowAI,
                onToggle: (bool value) {
                  setState(() {
                    Prefs().bottomNavigatorShowAI = value;
                  });
                },
              ),
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
            SettingsTile.switchTile(
              title: Text(L10n.of(context).vocabularyTitle),
              initialValue: Prefs().bottomNavigatorShowVocabulary,
              onToggle: (bool value) {
                setState(() {
                  Prefs().bottomNavigatorShowVocabulary = value;
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
              prefsProvider.saveThemeToPrefs(pickedColor.toARGB32());
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
