import 'dart:async';
import 'dart:io' as io;
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/page/home_page/bookshelf_page.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/webdav/safe_read.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:webdav_client/webdav_client.dart';

enum SyncDirection { upload, download, both }

class AnxWebdav {
  static late Client client;
  static final StreamController<bool> _syncingController =
      StreamController<bool>.broadcast();

  static Stream<bool> get syncing => _syncingController.stream;
  static bool isSyncing = false;

  static SyncDirection direction = SyncDirection.both;
  static int count = 0;
  static int total = 0;
  static String fileName = '';

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
      AnxLog.severe('WebDAV connection failed, ping failed\n${e.toString()}');
    }
    List<File> files = await client.readDir('/');
    for (var element in files) {
      if (element.name == 'anx') {
        return;
      }
    }
    await client.mkdir('anx');
  }

  static void setSyncing(bool value) {
    isSyncing = value;
    _syncingController.add(value);
  }

  static Future<void> syncData(SyncDirection direction) async {
    BuildContext context = navigatorKey.currentContext!;
    // if is  syncing
    if (isSyncing) {
      return;
    }
    if (!Prefs().webdavStatus) {
      AnxToast.show(L10n.of(context).webdav_webdav_not_enabled);
      return;
    }
    setSyncing(true);
    AnxToast.show(L10n.of(context).webdav_syncing);
    try {
      client.mkdir('anx/data').then((value) {
        syncDatabase(direction).then((value) {
          AnxToast.show(L10n.of(context).webdav_syncing_files);
          syncFiles().then((value) {
            imageCache.clear();
            imageCache.clearLiveImages();
            // refresh book list
            const BookshelfPage().refreshBookList();
            AnxToast.show(L10n.of(context).webdav_sync_complete);
            setSyncing(false);
          });
        });
      });
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        AnxToast.show('WebDAV connection failed, check your network');
        AnxLog.severe('WebDAV connection failed, connection error\n$e');
      } else {
        AnxToast.show('Sync failed');
        AnxLog.severe('Sync failed\n$e');
      }
      setSyncing(false);
    }
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
    List<String> totalCurrentFiles = [...currentCover, ...currentBooks];
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

    final databasePath = await getAnxDataBasesPath();
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
    direction = SyncDirection.upload;
    fileName = localPath.split('/').last;
    if (replace) {
      try {
        await client.remove(remotePath);
      } catch (e) {
        AnxLog.severe('Failed to remove file\n$e');
      }
    }
    await client.writeFromFile(localPath, remotePath, onProgress: (c, t) {
      count = c;
      total = t;
      setSyncing(true);
    }, cancelToken: c);
  }

  static Future<void> downloadFile(String remotePath, String localPath) async {
    direction = SyncDirection.download;
    fileName = remotePath.split('/').last;
    await client.read2File(remotePath, localPath, onProgress: (c, t) {
      count = c;
      total = t;
      setSyncing(true);
    });
  }
}