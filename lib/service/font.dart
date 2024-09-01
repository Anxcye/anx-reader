import 'dart:io';

import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:file_picker/file_picker.dart';

Future<void> importFont() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['ttf', 'otf'],
    allowMultiple: true,
  );

  if (result == null) {
    return;
  }

  List<PlatformFile> files = result.files;
  for (var file in files) {
    final fontDir = getFontDir();
    File newFile = File(file.path!);
    newFile.copy('${fontDir.path}/${file.name}');


  }
}