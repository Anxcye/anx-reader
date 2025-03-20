import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/utils/app_version.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> checkUpdate(bool manualCheck) async {
  if (EnvVar.isAppStore) {
    return;
  }
  // if is today
  if (!manualCheck &&
      DateTime.now().difference(Prefs().lastShowUpdate) <
          const Duration(days: 1)) {
    return;
  }
  Prefs().lastShowUpdate = DateTime.now();

  BuildContext context = navigatorKey.currentContext!;
  Response response;
  try {
    response = await Dio()
        .get('https://api.github.com/repos/Anxcye/anx-reader/releases/latest');
  } catch (e) {
    if (manualCheck) {
      AnxToast.show(L10n.of(context).common_failed);
    }
    throw Exception('Update: Failed to check for updates $e');
  }
  String newVersion = response.data['tag_name'].toString().substring(1);
  String currentVersion =
      (await getAppVersion()).substring(0, newVersion.length);
  AnxLog.info('Update: new version $newVersion');

  List<String> newVersionList = newVersion.split('.');
  List<String> currentVersionList = currentVersion.split('.');
  bool needUpdate = false;
  for (int i = 0; i < newVersionList.length; i++) {
    if (int.parse(newVersionList[i]) > int.parse(currentVersionList[i])) {
      needUpdate = true;
      break;
    }
  }

  if (needUpdate) {
    if (manualCheck) {
      Navigator.of(context).pop();
    }
    SmartDialog.show(
      builder: (BuildContext context) {
        final body =
            response.data['body'].toString().split('\n').skip(1).join('\n');
        return AlertDialog(
          title: Text(L10n.of(context).common_new_version,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              )),
          content: SingleChildScrollView(
            child: MarkdownBody(
                data: '''### ${L10n.of(context).update_new_version} $newVersion
${L10n.of(context).update_current_version} $currentVersion
$body'''),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(L10n.of(context).common_cancel),
            ),
            TextButton(
              onPressed: () {
                launchUrl(
                    Uri.parse(
                        'https://github.com/Anxcye/anx-reader/releases/latest'),
                    mode: LaunchMode.externalApplication);
              },
              child: Text(L10n.of(context).common_update),
            ),
          ],
        );
      },
    );
  } else {
    if (manualCheck) {
      AnxToast.show(L10n.of(context).common_no_new_version);
    }
  }
}
