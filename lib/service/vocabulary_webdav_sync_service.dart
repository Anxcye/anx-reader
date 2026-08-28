import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/vocabulary.dart';
import 'package:anx_reader/models/vocabulary_item.dart';
import 'package:anx_reader/service/sync/sync_client_base.dart';
import 'package:anx_reader/service/sync/sync_client_factory.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class VocabularyWebdavSyncResult {
  const VocabularyWebdavSyncResult({
    required this.localCount,
    required this.remoteCount,
    required this.changedCount,
    required this.finalCount,
  });

  final int localCount;
  final int remoteCount;
  final int changedCount;
  final int finalCount;
}

class VocabularyWebdavSyncService {
  VocabularyWebdavSyncService._();

  static const int _backupVersion = 1;
  static const String _remoteDir = 'anx/data/vocabulary';
  static const String _remoteFile = '$_remoteDir/vocabulary.json';

  static Future<VocabularyWebdavSyncResult> backup() async {
    final client = await _prepareClient();
    final items = await vocabularyDao.selectAll();
    await _uploadItems(client, items);
    return VocabularyWebdavSyncResult(
      localCount: items.length,
      remoteCount: 0,
      changedCount: 0,
      finalCount: items.length,
    );
  }

  static Future<VocabularyWebdavSyncResult> sync() async {
    final client = await _prepareClient();
    final localItems = await vocabularyDao.selectAll();
    final remoteItems = await _downloadItems(client);
    final changedCount = await vocabularyDao.upsertFromSync(remoteItems);
    final finalItems = await vocabularyDao.selectAll();
    await _uploadItems(client, finalItems);

    return VocabularyWebdavSyncResult(
      localCount: localItems.length,
      remoteCount: remoteItems.length,
      changedCount: changedCount,
      finalCount: finalItems.length,
    );
  }

  static Future<SyncClientBase> _prepareClient() async {
    if (!Prefs().bottomNavigatorShowVocabulary) {
      throw const VocabularyWebdavSyncException('Vocabulary is disabled');
    }
    if (!Prefs().webdavStatus) {
      throw const VocabularyWebdavSyncException('WebDAV is not enabled');
    }
    if (Prefs().onlySyncWhenWifi &&
        !(await Connectivity().checkConnectivity())
            .contains(ConnectivityResult.wifi)) {
      throw const VocabularyWebdavSyncException('Wi-Fi is required');
    }

    if (SyncClientFactory.currentClient == null) {
      SyncClientFactory.initializeCurrentClient();
    }

    final client = SyncClientFactory.currentClient;
    if (client == null || !client.isConfigured) {
      throw const VocabularyWebdavSyncException(
        'Please set WebDAV information first',
      );
    }

    await client.ping();
    await client.mkdirAll(_remoteDir);
    return client;
  }

  static Future<List<VocabularyItem>> _downloadItems(
    SyncClientBase client,
  ) async {
    final remoteFile = await client.readProps(_remoteFile);
    if (remoteFile == null) return const [];

    final tempFile = await _createTempFile();
    try {
      await client.downloadFile(_remoteFile, tempFile.path);
      final decoded = jsonDecode(await tempFile.readAsString());
      if (decoded is! Map<String, dynamic>) return const [];
      final items = decoded['items'];
      if (items is! List) return const [];

      return items
          .whereType<Map>()
          .map((item) {
            try {
              return VocabularyItem.fromJson(Map<String, dynamic>.from(item));
            } catch (_) {
              return null;
            }
          })
          .whereType<VocabularyItem>()
          .toList(growable: false);
    } finally {
      await _deleteQuietly(tempFile);
    }
  }

  static Future<void> _uploadItems(
    SyncClientBase client,
    List<VocabularyItem> items,
  ) async {
    final tempFile = await _createTempFile();
    try {
      final payload = {
        'type': 'anx-reader-vocabulary',
        'version': _backupVersion,
        'updatedAt': DateTime.now().toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(growable: false),
      };
      await tempFile.writeAsString(jsonEncode(payload), flush: true);
      await client.uploadFile(tempFile.path, _remoteFile, replace: true);
    } finally {
      await _deleteQuietly(tempFile);
    }
  }

  static Future<File> _createTempFile() async {
    final tempDir = await getAnxTempDir();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return File('${tempDir.path}/vocabulary_webdav_$timestamp.json');
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort temp cleanup.
    }
  }
}

class VocabularyWebdavSyncException implements Exception {
  const VocabularyWebdavSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}
