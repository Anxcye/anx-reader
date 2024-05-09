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
          // TODO l10n
          child: const Text('OK'),
        ),
      ],
    );
  }

  final result = await testWebdavInfo(webdavInfo);

  if (result['status']) {
    showDialog(
      context: context,
      builder: (context) {
        // TODO l10n
        return buildAlertDialog('success', 'Connection successful');
      },
    );
  } else {
    showDialog(
      context: context,
      builder: (context) {
        // TODO l10n
        return buildAlertDialog('failed', result['error']);
      },
    );
  }
}

Future<bool> testEnableWebdav() async {
  final webdavInfo = Prefs().webdavInfo;
  if (webdavInfo['url'] != null &&
      webdavInfo['username'] != null &&
      webdavInfo['password'] != null) {
    final result = await testWebdavInfo(webdavInfo);
    if (result['status']) {
      return true;
    } else {
      AnxToast.show('WebDAV connection failed');
    }
  } else {
    // TODO l10n
    AnxToast.show('Please set WebDAV information first');
  }
  return false;
}

void chooseDirection(){
   showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        return SimpleDialog(
          // TODO l10n
          title: Text('Choose Direction'),
          children: [
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                await AnxWebdav.syncData(SyncDirection.upload);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                // TODO l10n
                child: Text('Upload Data'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                await AnxWebdav.syncData(SyncDirection.download);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Download Data'),
              ),
            ),
          ],
        );
      });







}