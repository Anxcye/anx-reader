import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/utils/platform_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureAndroidDirectStoragePermission({
  BuildContext? context,
}) async {
  if (!AnxPlatform.isAndroid) return true;

  final androidInfo = await DeviceInfoPlugin().androidInfo;
  final sdkInt = androidInfo.version.sdkInt;
  final permission =
      sdkInt >= 30 ? Permission.manageExternalStorage : Permission.storage;

  var status = await permission.status;
  if (status.isGranted) return true;

  status = await permission.request();
  if (status.isGranted) return true;

  if (context != null && !context.mounted) {
    return false;
  }

  final dialogContext = context ?? navigatorKey.currentContext;
  if (dialogContext == null) {
    return false;
  }

  final l10n = L10n.of(dialogContext);
  await showDialog<void>(
    context: dialogContext,
    builder: (context) => AlertDialog(
      title: Text(l10n.storagePermissionDenied),
      content: Text(l10n.storagePermissionDenied),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await openAppSettings();
          },
          child: Text(l10n.gotoAuthorize),
        ),
      ],
    ),
  );

  return false;
}
