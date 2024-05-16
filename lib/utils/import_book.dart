import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:anx_reader/utils/log/common.dart';
import 'package:image/image.dart';

Future<bool> saveImageToLocal(Image? imageFile, String path) async {
  if (imageFile == null) {
    return false;
  }
  try {
    Uint8List pngBytes = Uint8List.fromList(encodePng(imageFile));

    final file = File(path);
    await file.writeAsBytes(pngBytes);

    return true;
  } catch (e) {
    AnxLog.severe('Error saving image\n$e');
    return false;
  }
}
