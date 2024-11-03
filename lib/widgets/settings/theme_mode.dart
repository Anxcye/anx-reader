import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/utils/theme_mode_to_string.dart';
import 'package:flutter/material.dart';

import 'package:anx_reader/config/shared_preference_provider.dart';

class ChangeThemeMode extends StatefulWidget {
  const ChangeThemeMode({super.key});

  @override
  _ChangeThemeModeState createState() => _ChangeThemeModeState();
}

class _ChangeThemeModeState extends State<ChangeThemeMode> {
  late String _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = themeModeToString(Prefs().themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: <ButtonSegment<String>>[
        ButtonSegment<String>(
          value: 'auto',
          label: Text(L10n.of(context).settings_system_mode),
          icon: const Icon(Icons.brightness_auto),
        ),
        ButtonSegment<String>(
          value: 'dark',
          label: Text(L10n.of(context).settings_dark_mode),
          icon: const Icon(Icons.brightness_2),
        ),
        ButtonSegment<String>(
          value: 'light',
          label: Text(L10n.of(context).settings_light_mode),
          icon: const Icon(Icons.brightness_5),
        ),
      ],
      selected: {_themeMode},
      onSelectionChanged: (Set<String> newSelection) {
        final String mode = newSelection.first;
        Prefs().saveThemeModeToPrefs(mode);
        setState(() {
          _themeMode = mode;
        });
      },
    );
  }
}
