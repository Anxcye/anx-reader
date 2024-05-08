import 'dart:io' as io;
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/utils/get_base_path.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/webdav/safe_read.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../config/shared_preference_provider.dart';
import '../../dao/book.dart';

class AnxWebdav {
  static late Client client;

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
    client.setSendTimeout(8000);
    client.setReceiveTimeout(8000);

    try {
      await client.ping();
    } catch (e) {
      AnxToast.show('WebDAV connection failed\n${e.toString()}');
    }
    List<File> files = await client.readDir('/');
    for (var element in files) {
      if (element.name == 'anx') {
        return;
      }
    }
    await client.mkdir('anx');
  }

  static Future<void> syncData() async {
    // await uploadFile(
    //     '/data/data/com.anxcye.anx_reader/app_flutter/file/小王子-[法国]圣埃克苏佩里-2024-05-08 18:07:37.534323.epub',
    //     'anx/data/华丽人生.epub');
    await client.mkdir('/anx/data');
    await syncDatabase();
    await syncFiles();
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
            remoteBooks.length, (index) => remoteBooks[index].name!);
      } else if (file.name == 'cover') {
        final remoteCovers = await client.readDir('/anx/data/cover');
        remoteCoversName = List.generate(
            remoteCovers.length, (index) => remoteCovers[index].name!);
      }
    }

    for (var books in currentBooks) {
      if (!remoteBooksName.contains(books)) {
        print('/////////remotenot');
        print('uploading $books');
        await uploadFile(getBasePath(books), 'anx/data/$books');
      }
      // if local file not exist, download it
      if (!io.File(getBasePath(books)).existsSync()) {
        print('/////////localnot');
        await downloadFile('anx/data/$books', getBasePath(books));
      }
    }

    // for (var covers in currentCover) {
    //   if (!remoteCoversName.contains(covers)) {
    //     await uploadFile(getBasePath(covers), 'anx/data/$covers');
    //   }
    //   // if local file not exist, download it
    //   if (!io.File(getBasePath(covers)).existsSync()) {
    //     await downloadFile('anx/data/$covers', getBasePath(covers));
    //   }
    // }
  }

  static Future<void> syncDatabase() async {
    File? remoteDb = await safeReadProps('anx/app_database.db');

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'app_database.db');

    io.File localDb = io.File(path);
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
  }

  static Future<void> uploadFile(String localPath, String remotePath,
      [bool replace = false]) async {
    print('uploading///////////////');
    print(localPath);
    print(remotePath);
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

  // static Future uploadFile(String localPath, String remotePath,
  //     [bool replace = false]) async {
  //   print('uploading///////////////');
  //   print(localPath);
  //
  //   String encodedRemotePath = Uri.encodeComponent(remotePath);
  //   print(encodedRemotePath);
  //
  //   CancelToken c = CancelToken();
  //
  //   if (replace) {
  //     try {
  //       await client.remove(encodedRemotePath);
  //     } catch (e) {
  //       print(e);
  //     }
  //   }
  //
  //   await client.writeFromFile(localPath, encodedRemotePath,
  //       onProgress: (c, t) {
  //     print(c / t);
  //   }, cancelToken: c);
  // }

  static Future<void> downloadFile(String remotePath, String localPath) async {
    print('downloading');
    await client.read2File(remotePath, localPath, onProgress: (c, t) {
      print(c / t);
    });
  }
}
