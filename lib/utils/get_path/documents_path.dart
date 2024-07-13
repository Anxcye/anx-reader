import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getDocumentsPath() async {
  final directory = await getApplicationDocumentsDirectory();
  switch(defaultTargetPlatform) {
    case TargetPlatform.android:
      return directory.path;
    case TargetPlatform.windows:
      return '${directory.path}\\AnxReader';
    default:
      throw Exception('Unsupported platform');
  }
}
