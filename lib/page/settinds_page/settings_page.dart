import 'package:anx_reader/page/settinds_page/more_settings_page.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
            ),
          ),
          const Divider(),
          const MoreSettings(),
          const AboutListTile(
            icon: Icon(Icons.info),
            applicationName: 'Anx Reader',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2023 Anx Reader',
          ),
        ],
      ),
    );
  }
}
