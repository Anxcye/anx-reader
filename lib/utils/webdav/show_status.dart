import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/utils/webdav/common.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

void showWebdavStatus(
    SyncDirection direction, String fileName, int count, int total) {
  final context = navigatorKey.currentContext!;
  String dir = direction == SyncDirection.upload
      ? context.commonUploading
      : context.commonDownloading;
  String byteToHuman(int byte) {
    if (byte < 1024) {
      return '$byte B';
    } else if (byte < 1024 * 1024) {
      return '${(byte / 1024).toStringAsFixed(2)} KB';
    } else if (byte < 1024 * 1024 * 1024) {
      return '${(byte / 1024 / 1024).toStringAsFixed(2)} MB';
    } else {
      return '${(byte / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(dir),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    fileName,
                  ),
                ),
              ],
            ),
            LinearProgressIndicator(
              value: AnxWebdav.count / AnxWebdav.total,
            ),
            Text('${byteToHuman(count)} / ${byteToHuman(total)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(context.commonOk),
          ),
        ],
      );
    },
  );
}
