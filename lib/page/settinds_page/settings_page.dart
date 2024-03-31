import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/page/settinds_page/more_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/settings/about.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _themeModeSetting = 'auto';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.navBarSettings),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 10, 8),
            child: Row(
              children: <Widget>[
                _buildThemeModeButton('auto', context.settingsSystemMode),
                _buildThemeModeButton('dark', context.settingsDarkMode),
                _buildThemeModeButton('light', context.settingsLightMode),
              ],
            ),
          ),
          const Divider(),
          const MoreSettings(),
          const About(),
        ],
      ),
    );
  }

  Widget _buildThemeModeButton(String mode, String text) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _themeModeSetting = mode;
            SharedPreferencesProvider prefs = SharedPreferencesProvider();
            prefs.saveThemeModeToPrefs(mode);
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed) ||
                  _themeModeSetting == mode) {
                return Theme.of(context).colorScheme.primary;
              }
              return Theme.of(context).colorScheme.surface;
            },
          ),
          foregroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed) ||
                  _themeModeSetting == mode) {
                return Theme.of(context).colorScheme.onPrimary;
              }
              return Theme.of(context).colorScheme.onSurface;
            },
          ),
        ),
        child: Text(text),
      ),
    );
  }
}
