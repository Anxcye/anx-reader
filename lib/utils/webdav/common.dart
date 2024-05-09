import 'dart:async';
import 'dart:io' as io;
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/utils/get_base_path.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/webdav/safe_read.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../config/shared_preference_provider.dart';
import '../../dao/book.dart';

enum SyncDirection { upload, download, both }

class AnxWebdav {
  static late Client client;
  static final StreamController<bool> _syncingController =
      StreamController<bool>.broadcast();

  static Stream<bool> get syncing => _syncingController.stream;

  static Future<void> init() async {
    client = newClient(
      Prefs().webdavInfo['url'],
      user: Prefs().webdavInfo['username'],
      password: Prefs().webdavInfo['password'],
      debug: true,
    );
    client.setHeaders({
      'accept-charset': 'utf-8',
      'Content-Type': 'application/octet-stream'
    });
    client.setConnectTimeout(8000);
    // client.setSendTimeout(8000);
    // client.setReceiveTimeout(8000);

    try {
      await client.ping();
    } catch (e) {
      AnxToast.show('WebDAV connection failed\n${e.toString()}',
          duration: 5000);
    }
    List<File> files = await client.readDir('/');
    for (var element in files) {
      if (element.name == 'anx') {
        return;
      }
    }
    await client.mkdir('anx');
  }

  static Future<void> syncData(SyncDirection direction) async {
    BuildContext context = navigatorKey.currentContext!;
    if (syncing == true) {
      return;
    }
    if (!Prefs().webdavStatus) {
      AnxToast.show(context.webdavWebdavNotEnabled);
      return;
    }
    _syncingController.add(true);
    AnxToast.show(context.webdavSyncing);
    try {
      client.mkdir('anx/data').then((value) {
        syncDatabase(direction).then((value) {
          AnxToast.show(context.webdavSyncingFiles);
          syncFiles().then((value) {
            AnxToast.show(context.webdavSyncComplete);
          });
        });
      });
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        AnxToast.show('WebDAV connection failed, check your network');
      } else {
        AnxToast.show('Sync failed');
      }
    }
    _syncingController.add(false);
  }

  static Future<void> syncFiles() async {
    List<String> currentBooks = await getCurrentBooks();
    List<String> currentCover = await getCurrentCover();
    List<File> remoteFiles = await client.readDir('/anx/data');
    List<String> remoteBooksName = [];
    List<String> remoteCoversName = [];

    for (var file in remoteFiles) {
      if (file.name == 'file') {
        final remoteBooks = await client.readDir('/anx/data/file');
        remoteBooksName = List.generate(
            remoteBooks.length, (index) => 'file/${remoteBooks[index].name!}');
      } else if (file.name == 'cover') {
        final remoteCovers = await client.readDir('/anx/data/cover');
        remoteCoversName = List.generate(remoteCovers.length,
            (index) => 'cover/${remoteCovers[index].name!}');
      }
    }
    List<String> totalCurrentFiles = [...currentBooks, ...currentCover];
    List<String> totalRemoteFiles = [...remoteBooksName, ...remoteCoversName];
    List<String> localBooks =
        io.Directory(getBasePath('file')).listSync().map((e) {
      return 'file/${basename(e.path)}';
    }).toList();
    List<String> localCovers =
        io.Directory(getBasePath('cover')).listSync().map((e) {
      return 'cover/${basename(e.path)}';
    }).toList();
    List<String> totalLocalFiles = [...localBooks, ...localCovers];

    // sync files
    for (var file in totalCurrentFiles) {
      if (!totalRemoteFiles.contains(file)) {
        await uploadFile(getBasePath(file), 'anx/data/$file');
      }
      if (!io.File(getBasePath(file)).existsSync()) {
        await downloadFile('anx/data/$file', getBasePath(file));
      }
    }
    // remove remote files not in database
    for (var file in totalRemoteFiles) {
      if (!totalCurrentFiles.contains(file)) {
        await client.remove('anx/data/$file');
      }
    }
    // remove local files not in database
    for (var file in totalLocalFiles) {
      if (!totalCurrentFiles.contains(file)) {
        await io.File(getBasePath(file)).delete();
      }
    }
  }

  static Future<void> syncDatabase(SyncDirection direction) async {
    File? remoteDb = await safeReadProps('anx/app_database.db');

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'app_database.db');

    io.File localDb = io.File(path);
    switch (direction) {
      case SyncDirection.upload:
        DBHelper.close();
        await uploadFile(path, 'anx/app_database.db');
        DBHelper().initDB();
        break;
      case SyncDirection.download:
        DBHelper.close();
        await downloadFile('anx/app_database.db', path);
        DBHelper().initDB();
        break;
      case SyncDirection.both:
        if (remoteDb == null ||
            remoteDb.mTime!.isBefore(localDb.lastModifiedSync())) {
          DBHelper.close();
          await uploadFile(path, 'anx/app_database.db');
          DBHelper().initDB();
        } else {
          DBHelper.close();
          await downloadFile('anx/app_database.db', path);
          DBHelper().initDB();
        }
        break;
    }
  }

  static Future<void> uploadFile(String localPath, String remotePath,
      [bool replace = false]) async {
    CancelToken c = CancelToken();
    if (replace) {
      try {
        await client.remove(remotePath);
      } catch (e) {
        print(e);
      }
    }
    await client.writeFromFile(localPath, remotePath, onProgress: (c, t) {
      print(c / t);
    }, cancelToken: c);
  }

  static Future<void> downloadFile(String remotePath, String localPath) async {
    await client.read2File(remotePath, localPath, onProgress: (c, t) {
      print(c / t);
    });
  }
}
