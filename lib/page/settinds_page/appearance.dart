import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/shared_preference_provider.dart';
import '../../widgets/settings/setting_color_item.dart';
import '../../widgets/settings/settings_group_title.dart';

class AppearanceSetting extends StatelessWidget {
  const AppearanceSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: Text(context.appearance),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const SubAppearanceSettings()),
        );
      },
    );
  }
}

class SubAppearanceSettings extends StatelessWidget {
  const SubAppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(context.appearance),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          SettingsGroupTitle(
            title: context.appearanceTheme,
          ),
          ListTile(
            title: Text(context.appearanceThemeColor),
            onTap: () async {
              await _showColorPickerDialog(context);
            },
          ),
          SettingsGroupTitle(title: context.appearanceDisplay),
          ListTile(
            title: Text(context.appearanceLanguage),
            onTap: () {
              _showLanguagePickerDialog(context);
            },
          )
        ],
      ),
    );
  }

  Future<int?> _showColorPickerDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(context.appearanceThemeColor),
          children: <Widget>[
            SettingsColorItem(
              colorValue: Colors.blue.value,
            ),
            SettingsColorItem(
              colorValue: Colors.green.value,
            ),
          ],
        );
      },
    );
  }
}

_showLanguagePickerDialog(BuildContext context) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(context.appearanceLanguage),
          children: const <Widget>[
            SettingLangItem(languageName: '简体中文', languageCode: 'zh'),
            SettingLangItem(languageName: 'English', languageCode: 'en'),
          ],
        );
      });
}

class SettingLangItem extends StatelessWidget {
  const SettingLangItem({
    super.key,
    required this.languageName,
    required this.languageCode,
  });

  final String languageName;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () async {
        final prefsProvider =
            Provider.of<SharedPreferencesProvider>(context, listen: false);
        await prefsProvider.saveLocaleToPrefs(languageCode);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(languageName),
      ),
    );
  }
}
