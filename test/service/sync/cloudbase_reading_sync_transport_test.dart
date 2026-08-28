import 'dart:convert';
import 'dart:typed_data';

import 'package:anx_reader/models/reading_agent_sync.dart';
import 'package:anx_reader/service/sync/cloudbase_reading_sync_transport.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.path.endsWith('/health') ||
        options.path.endsWith('/v1/spaces/current')) {
      return ResponseBody.fromString('{}', 200, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
    }
    if (options.path.endsWith('/v1/account/register') ||
        options.path.endsWith('/v1/account/login')) {
      return ResponseBody.fromString(
        '{"username":"reader","accessToken":"account-token"}',
        201,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        },
      );
    }
    if (options.path.endsWith('/packages') && options.method == 'GET') {
      return ResponseBody.fromString(
        jsonEncode({
          'packages': [
            {
              'type': ReadingAgentBookDelta.type,
              'schemaVersion': 1,
              'bookKey': 'book-a',
              'deviceId': 'device-b',
              'generatedAt': 10,
              'rows': <String, dynamic>{},
            }
          ]
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        },
      );
    }
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('uses account session without legacy or administrator credentials',
      () async {
    final adapter = _RecordingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final transport = CloudBaseReadingSyncTransport(
      endpoint: 'https://example.test/',
      accessToken: 'account-token',
      dio: dio,
    );

    await transport.ping();
    final packages = await transport.downloadPackages(['book-a']);
    await transport.uploadPackages([
      const ReadingAgentBookDelta(
        bookKey: 'book-a',
        deviceId: 'device-a',
        generatedAt: 11,
        rows: {},
      )
    ]);

    expect(packages.single.deviceId, 'device-b');
    expect(adapter.requests, hasLength(4));
    final authorized = adapter.requests.skip(1);
    for (final request in authorized) {
      expect(request.headers['Authorization'], 'Bearer account-token');
      expect(request.headers, isNot(contains('X-Anx-Sync-Space')));
      expect(request.headers.values.join(' '), isNot(contains('APIKEY')));
    }
    expect(adapter.requests.last.path,
        'https://example.test/v1/books/book-a/packages/device-a');
  });

  test('registers and logs in without invitation or sync-space fields',
      () async {
    final adapter = _RecordingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final transport = CloudBaseReadingSyncTransport(
      endpoint: 'https://example.test',
      accessToken: '',
      dio: dio,
    );

    final registered = await transport.registerAccount(
      username: ' reader ',
      password: 'password-123',
    );
    final loggedIn = await transport.loginAccount(
      username: 'reader',
      password: 'password-123',
    );

    expect(registered.accessToken, 'account-token');
    expect(loggedIn.username, 'reader');
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.first.data, {
      'username': 'reader',
      'password': 'password-123',
    });
    expect(adapter.requests.first.headers, isNot(contains('X-Anx-Sync-Space')));
  });
}
