import 'dart:io';

import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:flutter/services.dart';

Future<void> loadDefaultFont() async {
  final sourceHanSerif = await rootBundle.load('assets/fonts/SourceHanSerifSC-Regular.otf');
  final fontDir = getFontDir();
  final fontFile = File('${fontDir.path}/SourceHanSerifSC-Regular.otf');
  if (!fontFile.existsSync()) {
    fontFile.writeAsBytesSync(sourceHanSerif.buffer.asUint8List());
  }
}