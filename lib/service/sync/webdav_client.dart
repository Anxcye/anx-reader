import 'dart:io' as io;

import 'package:anx_reader/models/remote_file.dart';
import 'package:anx_reader/service/sync/sync_client_base.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/platform_utils.dart';
import 'package:dio/dio.dart';
import 'package:webdav_client/webdav_client.dart';

class WebdavClient extends SyncClientBase {
  late Client _client;
  late Map<String, dynamic> _config;

  WebdavClient({
    required String url,
    required String username,
    required String password,
  }) {
    _config = {
      'url': url,
      'username': username,
      'password': password,
    };
    _initClient();
  }

  void _initClient() {
    _client = newClient(
      _config['url'],
      user: _config['username'],
      password: _config['password'],
      debug: false,
    )
      ..setHeaders({
        'accept-charset': 'utf-8',
        'Content-Type': 'application/octet-stream'
      })
      // Keep network operations bounded so a stalled server cannot hold the
      // sync task (and its UI state) indefinitely. These are async Dio calls,
      // so the timeout prevents hangs without blocking the Flutter isolate.
      ..setConnectTimeout(8000)
      ..setSendTimeout(120000)
      ..setReceiveTimeout(120000);
  }

  @override
  Future<void> ping() async {
    int count = 0;
    while (count < 3) {
      try {
        await _client.ping();
        return;
      } catch (e) {
        AnxLog.warning('WebDAV ping failed, retrying... ($count)');
        count++;
        if (count >= 3) {
          AnxLog.severe('WebDAV ping failed after 3 attempts: $e');
          rethrow;
        }
      }
    }
  }

  @override
  Future<void> testFullCapabilities() async {
    const testDir = 'anx/.test';
    const testFile = '$testDir/test.txt';
    io.File? localTestFile;
    io.File? downloadTestFile;

    try {
      AnxLog.info('WebDAV full test: Starting comprehensive test');

      // 1. Create local temporary test file
      final tempDir = await getAnxTempDir();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      localTestFile = io.File('${tempDir.path}/webdav_test_$timestamp.txt');

      final testContent = 'Anx Reader WebDAV Test\n'
          'Test Time: ${DateTime.now()}\n'
          'Platform: ${AnxPlatform.type.name}\n'
          'Timestamp: $timestamp\n';

      await localTestFile.writeAsString(testContent);
      AnxLog.info('WebDAV full test: Created local test file');

      // 2. Create remote test directory
      try {
        await mkdirAll(testDir);
        AnxLog.info('WebDAV full test: Created remote directory');
      } catch (e) {
        AnxLog.severe('WebDAV full test: Failed to create directory: $e');
        throw Exception('Failed to create test directory');
      }

      // 3. Upload test file
      try {
        await uploadFile(localTestFile.path, testFile, replace: true);
        AnxLog.info('WebDAV full test: Uploaded test file');
      } catch (e) {
        AnxLog.severe('WebDAV full test: Failed to upload file: $e');
        throw Exception('Failed to upload test file');
      }

      // 4. Download and verify content
      try {
        downloadTestFile =
            io.File('${tempDir.path}/webdav_download_test_$timestamp.txt');
        await downloadFile(testFile, downloadTestFile.path);
        final downloadedContent = await downloadTestFile.readAsString();
        AnxLog.info('WebDAV full test: Downloaded test file');

        if (downloadedContent != testContent) {
          AnxLog.severe(
              'WebDAV full test: Content mismatch\nExpected: $testContent\nGot: $downloadedContent');
          throw Exception('Test file content mismatch, data integrity issue');
        }
        AnxLog.info('WebDAV full test: Content verification passed');
      } catch (e) {
        if (e.toString().contains('content mismatch')) {
          rethrow;
        }
        AnxLog.severe('WebDAV full test: Failed to download file: $e');
        throw Exception('Failed to download test file');
      }

      // 5. Delete remote test file
      try {
        await remove(testFile);
        AnxLog.info('WebDAV full test: Deleted remote test file');
      } catch (e) {
        AnxLog.warning('WebDAV full test: Failed to delete test file: $e');
        // Don't throw here, test is essentially successful
      }

      // 6. Try to delete test directory (may fail if not empty, that's ok)
      try {
        await remove(testDir);
        AnxLog.info('WebDAV full test: Deleted test directory');
      } catch (e) {
        AnxLog.info(
            'WebDAV full test: Could not delete test directory (may not be empty)');
        // Ignore error - directory might not be empty or already deleted
      }

      // 7. Clean up local files
      if (await localTestFile.exists()) {
        await localTestFile.delete();
      }
      if (await downloadTestFile.exists()) {
        await downloadTestFile.delete();
      }

      AnxLog.info('WebDAV full test: All tests passed successfully');
    } catch (e) {
      // Clean up resources on error
      try {
        if (localTestFile != null && await localTestFile.exists()) {
          await localTestFile.delete();
        }
        if (downloadTestFile != null && await downloadTestFile.exists()) {
          await downloadTestFile.delete();
        }
      } catch (cleanupError) {
        AnxLog.warning('WebDAV full test: Cleanup error: $cleanupError');
      }
      rethrow;
    }
  }

  @override
  Future<void> mkdirAll(String path) async {
    await _client.mkdirAll(path);
  }

  @override
  Future<bool> isExist(String path) async {
    return (await readProps(path)) != null;
  }

  @override
  Future<List<RemoteFile>> readDir(String path) async {
    return (await _client.readDir(path))
        .map((file) => file.toRemoteFile())
        .toList();
  }

  @override
  Future<RemoteFile?> readProps(String path) async {
    RemoteFile? file;
    try {
      file = (await _client.readProps(path)).toRemoteFile();
    } catch (e) {
      return null;
    }
    return file;
  }

  @override
  Future<void> remove(String path) async {
    await _client.remove(path);
  }

  @override
  Future<void> uploadFile(
    String localPath,
    String remotePath, {
    bool replace = true,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (replace) {
      try {
        await remove(_safeEncodePath(remotePath));
      } catch (e) {
        AnxLog.severe('Failed to remove file\n$e');
      }
    }

    await _client.writeFromFile(
      localPath,
      _safeEncodePath(remotePath),
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<void> downloadFile(
    String remotePath,
    String localPath, {
    void Function(int received, int total)? onProgress,
  }) async {
    await _client.read2File(
      _safeEncodePath(remotePath),
      localPath,
      onProgress: onProgress,
    );
  }

  @override
  Future<List<RemoteFile>> safeReadDir(String path) async {
    try {
      return await readDir(path);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        await mkdirAll(path);
        return [];
      }
      rethrow;
    }
  }

  @override
  String get protocolName => 'WebDAV';

  @override
  Map<String, dynamic> get config => Map.from(_config);

  @override
  void updateConfig(Map<String, dynamic> newConfig) {
    _config.addAll(newConfig);
    _initClient();
  }

  @override
  bool get isConfigured {
    return _config.containsKey('url') &&
        _config.containsKey('username') &&
        _config.containsKey('password') &&
        _config['url']?.isNotEmpty == true &&
        _config['username']?.isNotEmpty == true &&
        _config['password']?.isNotEmpty == true;
  }

  String _safeEncodePath(String path) {
    return Uri.encodeComponent(path).replaceAll('%2F', '/');
  }
}
