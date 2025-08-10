import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

void showDonateDialog(BuildContext context) {
  SmartDialog.show(
    builder: (context) => AlertDialog(
      title: Text(L10n.of(context).appDonate),
      content: Text(L10n.of(context).appDonateTips),
      actions: [
        TextButton(
          onPressed: () {
            launchUrl(
              Uri.parse('https://anxcye.com/home/7'),
              mode: LaunchMode.externalApplication,
            );
          },
          child: Text(L10n.of(context).appDonate),
        ),
      ],
    ),
  );
}
