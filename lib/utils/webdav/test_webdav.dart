import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/utils/webdav/common.dart';
import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../config/shared_preference_provider.dart';
import '../../main.dart';
import '../toast/common.dart';

Future<Map<String, dynamic>> testWebdavInfo(Map webdavInfo) async {
  var client = newClient(
    webdavInfo['url'],
    user: webdavInfo['username'],
    password: webdavInfo['password'],
    debug: true,
  );

  client.setHeaders({'accept-charset': 'utf-8'});
  client.setConnectTimeout(8000);
  client.setSendTimeout(8000);
  client.setReceiveTimeout(8000);

  try {
    await client.ping();
    return {'status': true};
  } catch (e) {
    return {'status': false, 'error': e.toString()};
  }
}

Future<void> testWebdav(Map webdavInfo) async {
  final context = navigatorKey.currentContext!;
  Widget buildAlertDialog(String title, String content) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(context.commonOk),
        ),
      ],
    );
  }

  final result = await testWebdavInfo(webdavInfo);

  if (result['status']) {
    showDialog(
      context: context,
      builder: (context) {
        return buildAlertDialog(
            context.commonSuccess, context.webdavConnectionSuccess);
      },
    );
  } else {
    showDialog(
      context: context,
      builder: (context) {
        return buildAlertDialog(context.commonFailed,
            '${context.webdavConnectionFailed}\n${result['error']}');
      },
    );
  }
}

Future<bool> testEnableWebdav() async {
  BuildContext context = navigatorKey.currentContext!;
  final webdavInfo = Prefs().webdavInfo;
  if (webdavInfo['url'] != null &&
      webdavInfo['username'] != null &&
      webdavInfo['password'] != null) {
    final result = await testWebdavInfo(webdavInfo);
    if (result['status']) {
      return true;
    } else {
      AnxToast.show(context.webdavConnectionFailed);
    }
  } else {
    AnxToast.show(context.webdavSetInfoFirst);
  }
  return false;
}

void chooseDirection() {
  BuildContext context = navigatorKey.currentContext!;
  showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        return SimpleDialog(
          title: Text(context.webdavChooseSources),
          children: [
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                await AnxWebdav.syncData(SyncDirection.upload);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(context.webdavUpload),
              ),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                await AnxWebdav.syncData(SyncDirection.download);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(context.webdavDownload),
              ),
            ),
          ],
        );
      });
}
