import 'package:anx_reader/models/remote_file.dart';
import 'package:anx_reader/service/sync/sync_client_base.dart';
import 'package:anx_reader/utils/log/common.dart';
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
      ..setConnectTimeout(8000);
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
