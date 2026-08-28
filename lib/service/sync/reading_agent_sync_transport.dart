import 'dart:io';

import 'package:anx_reader/models/reading_agent_sync.dart';
import 'package:anx_reader/service/sync/sync_client_base.dart';
import 'package:anx_reader/utils/get_path/get_cache_dir.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:path/path.dart' as p;

abstract interface class ReadingAgentSyncTransport {
  Future<void> ping();

  Future<List<ReadingAgentBookDelta>> downloadPackages(
    Iterable<String> bookKeys,
  );

  Future<void> uploadPackages(
    Iterable<ReadingAgentBookDelta> packages,
  );
}

class WebDavReadingAgentSyncTransport implements ReadingAgentSyncTransport {
  WebDavReadingAgentSyncTransport({
    required this.client,
    required this.deviceId,
  });

  static const remoteRoot = '/anx/data/reading-agent';
  final SyncClientBase client;
  final String deviceId;

  @override
  Future<void> ping() => client.ping();

  @override
  Future<List<ReadingAgentBookDelta>> downloadPackages(
    Iterable<String> bookKeys,
  ) async {
    final packages = <ReadingAgentBookDelta>[];
    final cache = await getAnxCacheDir();
    for (final bookKey in bookKeys.toSet()) {
      final dir = '$remoteRoot/${_pathSegment(bookKey)}';
      final files = await client.safeReadDir(dir);
      for (final file in files.where((entry) => entry.isDir != true)) {
        if (file.name?.endsWith('.json') != true) continue;
        final tempPath = p.join(cache.path,
            'reading_agent_sync_${DateTime.now().microsecondsSinceEpoch}.json');
        try {
          await client.downloadFile('$dir/${file.name}', tempPath);
          packages.add(
            ReadingAgentBookDelta.decode(await File(tempPath).readAsString()),
          );
        } catch (error) {
          AnxLog.warning('Ignored invalid Reading Agent sync package: $error');
        } finally {
          final temp = File(tempPath);
          if (await temp.exists()) await temp.delete();
        }
      }
    }
    return packages;
  }

  @override
  Future<void> uploadPackages(
    Iterable<ReadingAgentBookDelta> packages,
  ) async {
    final cache = await getAnxCacheDir();
    for (final package in packages) {
      final dir = '$remoteRoot/${_pathSegment(package.bookKey)}';
      await client.mkdirAll(dir);
      final tempPath = p.join(cache.path,
          'reading_agent_upload_${DateTime.now().microsecondsSinceEpoch}.json');
      final temp = File(tempPath);
      try {
        await temp.writeAsString(package.encode(), flush: true);
        await client.uploadFile(
          tempPath,
          '$dir/${_pathSegment(deviceId)}.json',
          replace: true,
        );
      } finally {
        if (await temp.exists()) await temp.delete();
      }
    }
  }

  static String _pathSegment(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
}
