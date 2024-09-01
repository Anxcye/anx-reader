import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';

Future<String> saveImageToLocal(String? imageFile, String name) async {
  if (imageFile == null) {
    return name;
  }
  try {
    // image is base64 encoded
    // data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD//gA8Q1JFQVRPUjogZ2...
    final List<String> parts = imageFile.split(',');
    final String base64String = parts[1];
    final Uint8List pngBytes = base64.decode(base64String);
    final extension = parts[0].split('/')[1].split(';')[0];

    name = '$name.$extension';
    final path = getBasePath(name);

    final file = File(path);
    await file.writeAsBytes(pngBytes);

    return name;
  } catch (e) {
    AnxLog.severe('Error saving image\n$e');
    return name;
  }
}
