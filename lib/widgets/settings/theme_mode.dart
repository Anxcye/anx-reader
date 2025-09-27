import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/utils/theme_mode_to_string.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/widgets/common/anx_segmented_button.dart';
import 'package:flutter/material.dart';

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
    return AnxSegmentedButton<String>(
      segments: <SegmentButtonItem<String>>[
        SegmentButtonItem(
          value: 'auto',
          label: L10n.of(context).settingsSystemMode,
          icon: const Icon(Icons.brightness_auto),
        ),
        SegmentButtonItem(
          value: 'dark',
          label: L10n.of(context).settingsDarkMode,
          icon: const Icon(Icons.brightness_2),
        ),
        SegmentButtonItem(
          value: 'light',
          label: L10n.of(context).settingsLightMode,
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
