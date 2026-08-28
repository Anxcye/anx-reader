import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDirectory;
  late File bookFile;

  setUpAll(() async {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Prefs().initPrefs();
  });

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('anx-server-test-');
    bookFile = File('${tempDirectory.path}/sample book.pdf');
    await bookFile.writeAsBytes(List<int>.generate(32, (index) => index));
  });

  tearDown(() async {
    await Server().stop();
    await tempDirectory.delete(recursive: true);
  });

  test('ensureStarted is idempotent for concurrent callers', () async {
    await Future.wait([
      Server().ensureStarted(),
      Server().ensureStarted(),
      Server().ensureStarted(),
    ]);

    final port = Server().port;
    expect(Server().isHealthy, isTrue);

    await Server().ensureStarted();
    expect(Server().port, port);
  });

  test('serves only registered token URL and revokes access', () async {
    final handle = await Server().registerBookResource(bookFile);
    final response = await _request(handle.url);
    expect(response.statusCode, HttpStatus.ok);
    expect(response.headers.contentType?.mimeType, 'application/pdf');
    expect(response.headers.value('x-content-type-options'), 'nosniff');
    expect(response.headers.value('accept-ranges'), 'bytes');
    expect(response.headers.contentLength, 32);
    expect(
        await _readBytes(response), List<int>.generate(32, (index) => index));

    final escaped = await _request('${Server().origin}/book/%2Ftmp%2Fbook.pdf');
    expect(escaped.statusCode, HttpStatus.notFound);

    handle.revoke();
    final revoked = await _request(handle.url);
    expect(revoked.statusCode, HttpStatus.notFound);
  });

  test('supports HEAD and standard single byte ranges', () async {
    final handle = await Server().registerBookResource(bookFile);

    final head = await _request(handle.url, method: 'HEAD');
    expect(head.statusCode, HttpStatus.ok);
    expect(head.headers.contentLength, 32);
    expect(await _readBytes(head), isEmpty);

    final range = await _request(handle.url, range: 'bytes=4-9');
    expect(range.statusCode, HttpStatus.partialContent);
    expect(range.headers.value('content-range'), 'bytes 4-9/32');
    expect(range.headers.contentLength, 6);
    expect(await _readBytes(range), [4, 5, 6, 7, 8, 9]);

    final suffix = await _request(handle.url, range: 'bytes=-4');
    expect(suffix.statusCode, HttpStatus.partialContent);
    expect(await _readBytes(suffix), [28, 29, 30, 31]);

    final invalid = await _request(handle.url, range: 'bytes=99-100');
    expect(invalid.statusCode, HttpStatus.requestedRangeNotSatisfiable);
    expect(invalid.headers.value('content-range'), 'bytes */32');
  });

  test('returns CORS only to the active reader origin', () async {
    final handle = await Server().registerBookResource(bookFile);
    final allowed = await _request(handle.url, origin: Server().origin);
    expect(
      allowed.headers.value('access-control-allow-origin'),
      Server().origin,
    );
    await allowed.drain<void>();

    final denied = await _request(handle.url, origin: 'https://example.com');
    expect(denied.headers.value('access-control-allow-origin'), isNull);
    await denied.drain<void>();
  });
}

Future<HttpClientResponse> _request(
  String url, {
  String method = 'GET',
  String? range,
  String? origin,
}) async {
  final client = HttpClient();
  final request = await client.openUrl(method, Uri.parse(url));
  if (range != null) request.headers.set(HttpHeaders.rangeHeader, range);
  if (origin != null) request.headers.set('origin', origin);
  return request.close();
}

Future<List<int>> _readBytes(HttpClientResponse response) async {
  final bytes = <int>[];
  await for (final chunk in response) {
    bytes.addAll(chunk);
  }
  return bytes;
}
