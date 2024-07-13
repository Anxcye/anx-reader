import 'package:anx_reader/page/settings_page/more_settings_page.dart';
import 'package:anx_reader/widgets/settings/about.dart';
import 'package:anx_reader/widgets/settings/theme_mode.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 40, 0, 20),
              child: Center(
                child: Text(
                  'Anx',
                  style: TextStyle(
                    fontSize: 130,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 10, 8),
            child: ChangeThemeMode(),
          ),
          const Divider(),
          const MoreSettings(),
          const About(),
        ],
      ),
    );
  }
}
