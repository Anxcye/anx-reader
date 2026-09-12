import 'dart:io';
import 'package:anx_reader/utils/platform_utils.dart';

import 'package:path_provider/path_provider.dart' as path;
import 'package:permission_handler/permission_handler.dart';

// from localsend
Future<String> getDownloadPath() async {
  switch (AnxPlatform.type) {
    case AnxPlatformEnum.android:
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }
      return '/storage/emulated/0/Download';
    case AnxPlatformEnum.ios:
      return (await path.getApplicationDocumentsDirectory()).path;
    case AnxPlatformEnum.macos:
    case AnxPlatformEnum.windows:
    case AnxPlatformEnum.linux:
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
