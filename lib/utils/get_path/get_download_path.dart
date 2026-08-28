import 'dart:io';
import 'package:anx_reader/utils/platform_utils.dart';
import 'package:anx_reader/utils/permission/android_storage_permission.dart';

import 'package:path_provider/path_provider.dart' as path;

// from localsend
Future<String> getDownloadPath() async {
  switch (AnxPlatform.type) {
    case AnxPlatformEnum.android:
      await ensureAndroidDirectStoragePermission();
      return '/storage/emulated/0/Download';
    case AnxPlatformEnum.ios:
      return (await path.getApplicationDocumentsDirectory()).path;
    case AnxPlatformEnum.macos:
    case AnxPlatformEnum.windows:
    case AnxPlatformEnum.ohos:
      var downloadDir = await path.getDownloadsDirectory();
      if (downloadDir == null) {
        if (AnxPlatform.isWindows) {
          downloadDir =
              Directory('${Platform.environment['HOMEPATH']}/Downloads');
          if (!downloadDir.existsSync()) {
            downloadDir = Directory(Platform.environment['HOMEPATH']!);
          }
        } else {
          downloadDir = Directory('${Platform.environment['HOME']}/Downloads');
          if (!downloadDir.existsSync()) {
            downloadDir = Directory(Platform.environment['HOME']!);
          }
        }
      }
      return downloadDir.path.replaceAll('\\', '/');
  }
}
