import 'package:anx_reader/utils/log/common.dart';
import 'package:dio/dio.dart';
import 'package:webdav_client/webdav_client.dart';

class WebdavClient {
  late Client _client;
  
  WebdavClient({
    required String url,
    required String username, 
    required String password,
  }) {
    _client = newClient(
      url,
      user: username,
      password: password,
      debug: false,
    )
      ..setHeaders({
        'accept-charset': 'utf-8',
        'Content-Type': 'application/octet-stream'
      })
      ..setConnectTimeout(8000);
  }

  Future<void> ping() async {
    await _client.ping();
  }

  Future<void> mkdir(String path) async {
    await _client.mkdir(path);
  }

  Future<bool> isExist(String path) async {
    return (await readProps(path)) != null;
  }

  Future<List<File>> readDir(String path) async {
    return await _client.readDir(path);
  }

Future<File?> readProps(String path) async {
    File? file;
    try {
      file = await _client.readProps(path);
    } catch (e) {
      return null;
    }
    return file;
  }



  Future<void> remove(String path) async {
    await _client.remove(path);
  }

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

  Future<List<File>> safeReadDir(String path) async {
    try {
      return await readDir(path);
    } catch (e) {
      await mkdir(path);
      return await readDir(path);
    }
  }

  String _safeEncodePath(String path) {
    return Uri.encodeComponent(path).replaceAll('%2F', '/');
  }
}