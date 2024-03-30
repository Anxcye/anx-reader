import 'package:anx_reader/config/preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme_data.dart';
import '../../widgets/settings/settings_group_title.dart';

class AppearanceSetting extends StatelessWidget {
  const AppearanceSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('Appearance'),
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
        title: const Text('Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          const SettingsGroupTitle(
            title: 'Theme',
          ),
          ListTile(
            title: const Text('Theme Color'),
            onTap: () async {
              await _showColorPickerDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Future<int?> _showColorPickerDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Theme Color'),
          children: <Widget>[
            SettingsColorItem(
              colorName: 'Blue',
              colorValue: Colors.blue.value,
            ),
            SettingsColorItem(
              colorName: 'Green',
              colorValue: Colors.green.value,
            ),
          ],
        );
      },
    );
  }
}

class SettingsColorItem extends StatelessWidget {
  const SettingsColorItem({
    super.key,
    required this.colorName,
    required this.colorValue,
  });

  final String colorName;
  final int colorValue;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () async {
        final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
        themeNotifier.themeColor = Color(colorValue);
        await themeNotifier.saveThemeToPrefs();

        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(colorName),
      ),
    );
  }
}
