import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/service/sync/webdav_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestPathProvider extends PathProviderPlatform {
  _TestPathProvider(this.path);

  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'full connection test works when the server ignores hidden paths',
    () async {
      SharedPreferences.setMockInitialValues({});
      await Prefs().initPrefs();
      final temp = await Directory.systemTemp.createTemp('webdav-test-');
      final previousPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _TestPathProvider(temp.path);
      final previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
        PathProviderPlatform.instance = previousPathProvider;
        HttpOverrides.global = previousHttpOverrides;
        await temp.delete(recursive: true);
      });

      final directories = <String>{'/', '/anx'};
      final files = <String, List<int>>{};
      final uploads = <String>[];
      final downloads = <String>[];
      final hiddenRequests = <String>[];

      server.listen((request) async {
        final path = request.uri.path.replaceFirst(RegExp(r'/$'), '');
        final body = await request.fold<List<int>>(
          <int>[],
          (bytes, chunk) => bytes..addAll(chunk),
        );
        final response = request.response;
        if (request.uri.pathSegments.any((part) => part.startsWith('.'))) {
          // PikPak returns an empty 204 for hidden paths, including MKCOL.
          hiddenRequests.add(path);
          response.statusCode = HttpStatus.noContent;
        } else {
          switch (request.method) {
            case 'OPTIONS':
              response.statusCode = HttpStatus.ok;
              break;
            case 'MKCOL':
              if (directories.contains(path)) {
                response.statusCode = HttpStatus.methodNotAllowed;
              } else if (!directories.contains(
                path.substring(0, path.lastIndexOf('/')),
              )) {
                response.statusCode = HttpStatus.conflict;
              } else {
                directories.add(path);
                response.statusCode = HttpStatus.created;
              }
              break;
            case 'PUT':
              files[path] = body;
              uploads.add(path);
              response.statusCode = HttpStatus.noContent;
              break;
            case 'GET':
              final content = files[path];
              if (content == null) {
                response.statusCode = HttpStatus.notFound;
              } else {
                downloads.add(path);
                response.statusCode = HttpStatus.ok;
                response.contentLength = content.length;
                response.add(content);
              }
              break;
            case 'DELETE':
              final removed =
                  files.remove(path) != null || directories.remove(path);
              response.statusCode = removed
                  ? HttpStatus.noContent
                  : HttpStatus.notFound;
              break;
            default:
              response.statusCode = HttpStatus.methodNotAllowed;
          }
        }
        await response.close();
      });

      final client = WebdavClient(
        url: 'http://${server.address.address}:${server.port}',
        username: 'test-user',
        password: 'test-password',
      );

      // Exercise the production CRUD test twice: each run must use its own
      // visible directory, verify the download, and remove its test artifacts.
      await client.testFullCapabilities();
      await client.testFullCapabilities();

      expect(hiddenRequests, isEmpty);
      expect(uploads, hasLength(2));
      expect(uploads.toSet(), hasLength(2));
      expect(downloads, uploads);
      expect(files, isEmpty);
      expect(directories, {'/', '/anx'});
      expect(await temp.list().toList(), isEmpty);
    },
  );
}
