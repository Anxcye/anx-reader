import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
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
    print('Error saving image: $e');
    return false;
  }
}
