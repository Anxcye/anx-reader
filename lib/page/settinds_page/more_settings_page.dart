import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/page/settinds_page/appearance.dart';
import 'package:anx_reader/page/settinds_page/settings_page.dart';
import 'package:flutter/material.dart';

class MoreSettings extends StatelessWidget {
  const MoreSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.settings),
      title: Text(context.settingsMoreSettings),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubMoreSettings()),
        );
      },
    );
  }
}

class SubMoreSettings extends StatelessWidget {
  const SubMoreSettings({super.key});

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
        title: Text(context.settingsMoreSettings),
      ),
      body: ListView(
        children: const [
          AppearanceSetting(),
          About(),
        ],
      ),
    );
  }
}
