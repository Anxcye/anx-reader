import 'dart:io';

import 'package:anx_reader/models/storege_info_model.dart';
import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/get_path/get_cache_dir.dart';
import 'package:anx_reader/utils/get_path/log_file.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_info.g.dart';

@riverpod
class StorageInfo extends _$StorageInfo {
  @override
  Future<StorageInfoModel> build() async {
    return StorageInfoModel(
      databaseSize: calculatePathSize(await getAnxDataBasesDir()),
      booksSize: calculatePathSize(getFileDir()),
      fontSize: calculatePathSize(getFontDir()),
      cacheSize: calculatePathSize(
        await getAnxCacheDir(),
        recursive: true,
      ),
      logSize: calsulateFileSize(await getLogFile()),
      coverSize: calculatePathSize(getCoverDir()),
    );
  }

  Future<bool> clearCache() async {
    try {
      final cacheDir = await getAnxCacheDir();
      if (!cacheDir.existsSync()) {
        return true;
      }

      final entities = cacheDir.listSync(recursive: true);
      for (var entity in entities) {
        if (entity.existsSync()) {
          if (entity is File) {
            entity.deleteSync();
          } else if (entity is Directory) {
            entity.deleteSync(recursive: true);
          }
        }
      }

      state = AsyncData(await build());

      return true;
    } catch (e) {
      AnxLog.severe('StorageInfo clearCache error: $e');
      return false;
    }
  }

  int calculatePathSize(Directory dir, {bool recursive = false}) {
    if (!dir.existsSync()) {
      return 0;
    }

    int totalSize = 0;
    final entities = dir.listSync(recursive: recursive);
    for (var entity in entities) {
      if (entity is File) {
        totalSize += entity.lengthSync();
      }
    }

    return totalSize;
  }

  int calsulateFileSize(File file) {
    return file.lengthSync();
  }

  List<File> listBookFiles() {
    final fileDir = getFileDir();
    if (!fileDir.existsSync()) {
      return [];
    }

    final files = <File>[];
    final entities = fileDir.listSync(recursive: true);
    for (var entity in entities) {
      if (entity is File) {
        files.add(entity);
      }
    }

    return files;
  }

  List<File> listFontFiles() {
    final fontDir = getFontDir();
    if (!fontDir.existsSync()) {
      return [];
    }

    final files = <File>[];
    final entities = fontDir.listSync();
    for (var entity in entities) {
      if (entity is File) {
        files.add(entity);
      }
    }

    return files;
  }

  List<File> listCoverFiles() {
    final coverDir = getCoverDir();
    if (!coverDir.existsSync()) {
      return [];
    }

    final files = <File>[];
    final entities = coverDir.listSync(recursive: true);
    for (var entity in entities) {
      if (entity is File) {
        files.add(entity);
      }
    }

    return files;
  }
}
