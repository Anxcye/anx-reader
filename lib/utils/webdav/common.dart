import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../main.dart';

Future<void> testWebdav(Map webdavInfo) async {
  final context = navigatorKey.currentContext!;
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

  try {
    await client.ping();
    showDialog(
      context: context,
      builder: (context) {
        // TODO l10n
        return buildAlertDialog('success', 'Connection successful');
      },
    );
  } catch (e) {
    showDialog(
      context: context,
      builder: (context) {
        // TODO l10n
        return buildAlertDialog('failed', e.toString());
      },
    );
  }
}
