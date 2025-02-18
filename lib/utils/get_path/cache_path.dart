import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<Directory> getAnxCacheDir() async {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return await getApplicationCacheDirectory();
    case TargetPlatform.windows:
      return await getApplicationCacheDirectory();
    case TargetPlatform.linux:
      final path = (await getTemporaryDirectory()).path;
      return Directory(path);
    default:
      throw Exception('Unsupported platform');
  }
}
