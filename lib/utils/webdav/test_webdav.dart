import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/enums/sync_trigger.dart';
import 'package:anx_reader/enums/sync_protocol.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/service/sync/sync_connection_tester.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> testEnableWebdav() async {
  final webdavInfo = Prefs().getSyncInfo(SyncProtocol.webdav);
  if (webdavInfo['url'] != null &&
      webdavInfo['username'] != null &&
      webdavInfo['password'] != null) {
    final result = await SyncConnectionTester.testConnection(
      protocol: SyncProtocol.webdav,
      config: {
        'url': webdavInfo['url'],
        'username': webdavInfo['username'],
        'password': webdavInfo['password'],
      },
    );
    if (result.isSuccess) {
      return true;
    } else {
      AnxToast.show(
          L10n.of(navigatorKey.currentContext!).webdavConnectionFailed);
    }
  } else {
    AnxToast.show(L10n.of(navigatorKey.currentContext!).webdavSetInfoFirst);
  }
  return false;
}

void chooseDirection(WidgetRef ref) {
  // BuildContext context = navigatorKey.currentContext!;
  showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) {
        return SimpleDialog(
          title: Text(L10n.of(context).webdavChoose_Sources),
          children: [
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                await Sync().syncData(SyncDirection.upload, ref,
                    trigger: SyncTrigger.manual);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(L10n.of(context).webdavUpload),
              ),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                await Sync().syncData(SyncDirection.download, ref,
                    trigger: SyncTrigger.manual);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(L10n.of(context).webdavDownload),
              ),
            ),
          ],
        );
      });
}
