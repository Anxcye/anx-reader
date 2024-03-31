import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/widgets/settings/theme_mode.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../config/shared_preference_provider.dart';
import '../../widgets/settings/settings_app_bar.dart';

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
          CupertinoPageRoute(
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
      appBar: settingsAppBar(context.appearance, context),
      body: SettingsList(
        lightTheme: SettingsThemeData(
          settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          titleTextColor: Theme.of(context).colorScheme.primary,
        ),
        sections: [
          SettingsSection(
            title: Text(context.appearanceTheme),
            tiles: [
              CustomSettingsTile(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: ChangeThemeMode(),
              )),
              SettingsTile.navigation(
                  title: Text(context.appearanceThemeColor),
                  leading: const Icon(Icons.color_lens),
                  onPressed: (context) async {
                    await _showColorPickerDialog(context);
                  }),
              const CustomSettingsTile(child: Divider()),
            ],
          ),
          SettingsSection(
              title: Text(context.appearanceDisplay),
              tiles: [
                SettingsTile.navigation(
                    title: Text(context.appearanceLanguage),
                    leading: Icon(Icons.language),
                    onPressed: (context) {
                      _showLanguagePickerDialog(context);
                    })
              ])
        ],
      ),

      // ListView(
      //   padding: const EdgeInsets.all(15),
      //   children: [
      //     SettingsGroupTitle(
      //       title: context.appearanceTheme,
      //     ),
      //     Padding(
      //       padding: const EdgeInsets.all(8.0),
      //       child: ChangeThemeMode(),
      //     ),
      //     ListTile(
      //       title: Text(context.appearanceThemeColor),
      //       onTap: () async {
      //         await _showColorPickerDialog(context);
      //       },
      //     ),
      //     SettingsGroupTitle(title: context.appearanceDisplay),
      //     ListTile(
      //       title: Text(context.appearanceLanguage),
      //       onTap: () {
      //         _showLanguagePickerDialog(context);
      //       },
      //     )
      //   ],
      // ),
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

// Future<int?> _showColorPickerDialog(BuildContext context) {
//   return showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return SimpleDialog(
//         title: Text(context.appearanceThemeColor),
//         children: <Widget>[
//           SettingsColorItem(
//             colorValue: Colors.blue.value,
//           ),
//           SettingsColorItem(
//             colorValue: Colors.green.value,
//           ),
//         ],
//       );
//     },
//   );
// }
//
//
// class SettingsColorItem extends StatelessWidget {
//   const SettingsColorItem({
//     super.key,
//     // required this.colorName,
//     required this.colorValue,
//   });
//
//   // final String colorName;
//   final int colorValue;
//
//   @override
//   Widget build(BuildContext context) {
//     return SimpleDialogOption(
//       onPressed: () async {
//         final prefsProvider =
//             Provider.of<SharedPreferencesProvider>(context, listen: false);
//         // prefsProvider.themeColor = Color(colorValue);
//         await prefsProvider.saveThemeToPrefs(colorValue);
//
//         Navigator.pop(context);
//       },
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 6),
//         child: Container(
//           color: Color(colorValue),
//           height: 50,
//         ),
//       ),
//     );
//   }
// }

Future<void> _showColorPickerDialog(BuildContext context) async {
  final prefsProvider =
  Provider.of<SharedPreferencesProvider>(context, listen: false);
  final currentColor = prefsProvider.themeColor;

  Color pickedColor = currentColor; // Initialize pickedColor with currentColor

  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(context.appearanceThemeColor),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickedColor, // Use pickedColor here
            onColorChanged: (color) {
              pickedColor = color; // Update pickedColor when color changes
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
              prefsProvider.saveThemeToPrefs(pickedColor.value); // Save pickedColor here
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
