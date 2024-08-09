import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/settings_page/log_page.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

class AdvancedSetting extends StatelessWidget {
  const AdvancedSetting(
      {super.key,
      required this.isMobile,
      required this.id,
      required this.selectedIndex,
      required this.setDetail});

  final bool isMobile;
  final int id;
  final int selectedIndex;
  final void Function(Widget detail, int id) setDetail;

  @override
  Widget build(BuildContext context) {
    return settingsTitle(
        icon: const Icon(Icons.shield_outlined),
        title: L10n.of(context).settings_advanced,
        isMobile: isMobile,
        id: id,
        selectedIndex: selectedIndex,
        setDetail: setDetail,
        subPage: SubAdvancedSettings(isMobile: isMobile));
  }
}

class SubAdvancedSettings extends StatefulWidget {
  const SubAdvancedSettings({super.key, required this.isMobile});

  final bool isMobile;

  @override
  State<SubAdvancedSettings> createState() => _SubAdvancedSettingsState();
}

class _SubAdvancedSettingsState extends State<SubAdvancedSettings> {
  @override
  Widget build(BuildContext context) {
    return settingsBody(
      title: L10n.of(context).settings_advanced,
      isMobile: widget.isMobile,
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
