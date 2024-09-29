import 'dart:io';

import 'package:anx_reader/utils/get_path/get_download_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

Future<String?> fileSaver(
    {required Uint8List bytes,
    required String fileName,
    String? mimeType}) async {
  String downloadPath = await getDownloadPath();
  String fileSavePath = '$downloadPath/$fileName';

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      SaveFileDialogParams params = SaveFileDialogParams(
        // sourceFilePath: file.path,
        data: bytes,
        mimeTypesFilter: [mimeType ?? 'application/zip'],
        fileName: fileName,
      );
      final filePath = await FlutterFileDialog.saveFile(params: params);
      return filePath;
    case TargetPlatform.windows:
      final file = File(fileSavePath);

      if (!await file.exists()) {
        await file.create(recursive: true);
      }

      await file.writeAsBytes(bytes);
      return fileSavePath;
    default:
      throw Exception('Unsupported platform');
  }
}
