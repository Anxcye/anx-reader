import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anx_reader/utils/log/common.dart';

Future<String> saveImageToPath(String image, String path, String? name) async {
  try {
    // image is base64 encoded
    // data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD//gA8Q1JFQVRPUjogZ2...
    final List<String> parts = image.split(',');
    final String base64String = parts[1];
    final Uint8List pngBytes = base64.decode(base64String);
    final extension = parts[0].split('/')[1].split(';')[0];

    name = '$name.$extension';
    path = '$path/$name';

    final file = File(path);
    await file.writeAsBytes(pngBytes);

    return path;
  } catch (e) {
    AnxLog.severe('Error saving image\n$e');
    return '';
  }
}