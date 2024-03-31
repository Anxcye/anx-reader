import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/utils/theme_mode_to_string.dart';
import 'package:flutter/material.dart';

import '../../config/shared_preference_provider.dart';

class ChangeThemeMode extends StatefulWidget {
  ChangeThemeMode({Key? key}) : super(key: key);

  @override
  _ChangeThemeModeState createState() => _ChangeThemeModeState();
}

class _ChangeThemeModeState extends State<ChangeThemeMode> {
  late SharedPreferencesProvider prefs;
  late String _themeMode;

  @override
  void initState() {
    super.initState();
    prefs = SharedPreferencesProvider();
    _themeMode = themeModeToString(prefs.themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _buildThemeModeButton('auto', context.settingsSystemMode),
        _buildThemeModeButton('dark', context.settingsDarkMode),
        _buildThemeModeButton('light', context.settingsLightMode),
      ],
    );
  }

  Widget _buildThemeModeButton(String mode, String text) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          prefs.saveThemeModeToPrefs(mode);
          setState(() {
            _themeMode = mode;
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed) ||
                  _themeMode == mode) {
                return Theme.of(context).colorScheme.primary;
              }
              return Theme.of(context).colorScheme.surface;
            },
          ),
          foregroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed) ||
                  _themeMode == mode) {
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