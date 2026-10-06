import 'dart:io';
import 'package:anx_reader/utils/platform_utils.dart';

import 'package:anx_reader/utils/get_path/get_download_path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

Future<String?> saveFileToDownload(
    {Uint8List? bytes,
    String? sourceFilePath,
    required String fileName,
    String? mimeType}) async {
  String downloadPath = await getDownloadPath();
  String fileSavePath = '$downloadPath/$fileName';

  switch (AnxPlatform.type) {
    case AnxPlatformEnum.android:
    case AnxPlatformEnum.ios:
    case AnxPlatformEnum.ohos:
      SaveFileDialogParams params = SaveFileDialogParams(
        sourceFilePath: sourceFilePath,
        data: bytes,
        mimeTypesFilter: [mimeType ?? 'application/zip'],
        fileName: fileName,
      );
      final filePath = await FlutterFileDialog.saveFile(params: params);
      return filePath;
    case AnxPlatformEnum.macos:
      String? outputFile = await FilePicker.platform.saveFile(
        fileName: fileName,
      );
      bytes ??= await File(sourceFilePath!).readAsBytes();
      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
        return outputFile;
      }
      return outputFile;
    case AnxPlatformEnum.windows:
    case AnxPlatformEnum.linux:
      final file = File(fileSavePath);

      if (!await file.exists()) {
        await file.create(recursive: true);
      }

      bytes ??= await File(sourceFilePath!).readAsBytes();
      await file.writeAsBytes(bytes);
      return fileSavePath;
  }
}
