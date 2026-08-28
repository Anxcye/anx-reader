import 'dart:convert';

import 'package:anx_reader/models/reading_agent_sync.dart';
import 'package:anx_reader/service/sync/reading_agent_sync_transport.dart';
import 'package:dio/dio.dart';

class CloudBaseAccountSession {
  const CloudBaseAccountSession(
      {required this.username, required this.accessToken});
  final String username;
  final String accessToken;
}

class CloudBaseReadingSyncTransport implements ReadingAgentSyncTransport {
  CloudBaseReadingSyncTransport({
    required String endpoint,
    required this.accessToken,
    Dio? dio,
  })  : endpoint = _normalizeEndpoint(endpoint),
        _dio = dio ??
            Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));

  final String endpoint;
  final String accessToken;
  final Dio _dio;

  Options get _options => Options(headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      });

  Future<CloudBaseAccountSession> registerAccount({
    required String username,
    required String password,
  }) async =>
      _accountRequest('/v1/account/register', username, password);

  Future<CloudBaseAccountSession> loginAccount({
    required String username,
    required String password,
  }) async =>
      _accountRequest('/v1/account/login', username, password);

  Future<void> logoutAccount() async {
    if (accessToken.isEmpty) return;
    await _dio.post<void>('$endpoint/v1/account/logout', options: _options);
  }

  Future<CloudBaseAccountSession> _accountRequest(
      String path, String username, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$endpoint$path',
      data: <String, dynamic>{
        'username': username.trim(),
        'password': password
      },
    );
    final data = response.data ?? const {};
    final token = data['accessToken']?.toString() ?? '';
    final name = data['username']?.toString() ?? username.trim();
    if (token.isEmpty || name.isEmpty) {
      throw const FormatException('CloudBase account response is invalid');
    }
    return CloudBaseAccountSession(username: name, accessToken: token);
  }

  @override
  Future<void> ping() async {
    await _dio.get<void>('$endpoint/health');
    if (accessToken.isNotEmpty) {
      await _dio.get<void>(
        '$endpoint/v1/spaces/current',
        options: _options,
      );
    }
  }

  @override
  Future<List<ReadingAgentBookDelta>> downloadPackages(
    Iterable<String> bookKeys,
  ) async {
    final packages = <ReadingAgentBookDelta>[];
    for (final bookKey in bookKeys.toSet()) {
      final response = await _dio.get<Map<String, dynamic>>(
        '$endpoint/v1/books/${Uri.encodeComponent(bookKey)}/packages',
        options: _options,
      );
      final raw = response.data?['packages'];
      if (raw is! List) continue;
      for (final entry in raw.whereType<Map>()) {
        try {
          packages.add(ReadingAgentBookDelta.decode(
            _encodeJson(Map<String, dynamic>.from(entry)),
          ));
        } on FormatException {
          // A damaged remote branch must not block other devices from syncing.
        }
      }
    }
    return packages;
  }

  @override
  Future<void> uploadPackages(
    Iterable<ReadingAgentBookDelta> packages,
  ) async {
    for (final package in packages) {
      await _dio.put<void>(
        '$endpoint/v1/books/${Uri.encodeComponent(package.bookKey)}'
        '/packages/${Uri.encodeComponent(package.deviceId)}',
        data: package.toJson(),
        options: _options,
      );
    }
  }

  static String _normalizeEndpoint(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}

String _encodeJson(Map<String, dynamic> value) {
  return jsonEncode(value);
}
