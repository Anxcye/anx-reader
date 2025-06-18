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
        .get('https://api.anx.anxcye.com/api/info/latest');
  } catch (e) {
    if (manualCheck) {
      AnxToast.show(L10n.of(context).common_failed);
    }
    throw Exception('Update: Failed to check for updates $e');
  }
  String newVersion = response.data['version'].toString().substring(1);
  String currentVersion =
      (await getAppVersion()).split('+').first;
  AnxLog.info('Update: new version $newVersion');

  List<String> newVersionList = newVersion.split('.');
  List<String> currentVersionList = currentVersion.split('.');
  AnxLog.info('Current version: $currentVersionList, New version: $newVersionList');
  bool needUpdate = false;
  for (int i = 0; i < newVersionList.length; i++) {
    int newVer = int.parse(newVersionList[i]);
    int curVer = int.parse(currentVersionList[i]);
    if (newVer > curVer) {
      needUpdate = true;
      break;
    } else if (newVer < curVer) {
      needUpdate = false;
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
                data: '''### ${L10n.of(context).update_new_version} $newVersion\n
${L10n.of(context).update_current_version} $currentVersion\n
$body'''),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                SmartDialog.dismiss();
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
              child: Text(L10n.of(context).update_via_github),
            ),
            TextButton(
              onPressed: () {
                launchUrl(
                    Uri.parse(
                        'https://anx.anxcye.com/download'),
                    mode: LaunchMode.externalApplication);
              },
              child: Text(L10n.of(context).update_via_official_website),
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
