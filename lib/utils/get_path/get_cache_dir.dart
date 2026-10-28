import 'dart:io';
import 'package:anx_reader/utils/platform_utils.dart';

import 'package:path_provider/path_provider.dart';

Future<Directory> getAnxCacheDir() async {
  switch (AnxPlatform.type) {
    case AnxPlatformEnum.android:
    case AnxPlatformEnum.ohos:
    case AnxPlatformEnum.windows:
    case AnxPlatformEnum.linux:
    case AnxPlatformEnum.macos:
    case AnxPlatformEnum.ios:
      return await getApplicationCacheDirectory();
  }
}
