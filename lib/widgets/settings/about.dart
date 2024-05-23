import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/widgets/settings/link_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:url_launcher/url_launcher.dart';

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
        icon: const Icon(Icons.info_outline),
        applicationName: context.appName,
        applicationVersion: version,
        applicationLegalese: '© 2023 ${context.appName}',
        aboutBoxChildren: [
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                linkIcon(
                    icon: IonIcons.logo_github,
                    url: 'https://github.com/Anxcye/anx-reader',
                    mode: LaunchMode.externalApplication),
                linkIcon(
                    icon: Icons.telegram,
                    url: 'https://t.me/AnxReader',
                    mode: LaunchMode.externalApplication),
              ],
            ),
          ),
        ]);
  }
}
