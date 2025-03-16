import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/settings_page/subpage/log_page.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdvancedSetting extends StatefulWidget {
  const AdvancedSetting({super.key});

  @override
  State<AdvancedSetting> createState() => _AdvancedSettingState();
}

class _AdvancedSettingState extends State<AdvancedSetting> {
  @override
  Widget build(BuildContext context) {
    return settingsSections(
      sections: [
        SettingsSection(
          title: Text(L10n.of(context).settings_advanced_log),
          tiles: [
            SettingsTile.switchTile(
              title: Text(L10n.of(context).settings_advanced_clear_log_when_start),
              leading: const Icon(Icons.delete_forever_outlined),
              initialValue: Prefs().clearLogWhenStart,
              onToggle: (value) {
                Prefs().saveClearLogWhenStart(value);
                setState(() {});
              },
            ),
            SettingsTile.navigation(
                leading: const Icon(Icons.bug_report),
                title: Text(L10n.of(context).settings_advanced_log),
                onPressed: onLogPressed),
          ],
        ),
      ],
    );
  }
}

void onLogPressed(BuildContext context) {
  Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (context) => const LogPage(),
    ),
  );
}
