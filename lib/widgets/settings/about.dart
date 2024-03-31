import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AboutListTile(
      icon: const Icon(Icons.info),
      applicationName: context.appName,
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2023 ${context.appName}',
    );
  }
}
