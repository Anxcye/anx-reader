import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

class About extends StatefulWidget {
  const About({
    super.key,
  });

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  String version = '';

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    final pubspecContent = await rootBundle.loadString('pubspec.yaml');
    final pubspec = Pubspec.parse(pubspecContent);
    setState(() {
      version = pubspec.version.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AboutListTile(
      icon: const Icon(Icons.info),
      applicationName: context.appName,
      applicationVersion: version,
      applicationLegalese: '© 2023 ${context.appName}',
    );
  }
}
