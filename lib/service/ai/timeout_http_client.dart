import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient(
    this._inner, {
    required this.timeout,
    this.requestBodyPatch = const {},
  });

  final http.Client _inner;
  final Duration timeout;
  final Map<String, dynamic> requestBodyPatch;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request = _patchJsonRequest(request);
    final response = timeout == Duration.zero
        ? await _inner.send(request)
        : await _inner.send(request).timeout(timeout);

    if (timeout == Duration.zero) {
      return response;
    }

    return http.StreamedResponse(
      response.stream.timeout(timeout),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  http.BaseRequest _patchJsonRequest(http.BaseRequest request) {
    if (requestBodyPatch.isEmpty || request is! http.Request) return request;
    var contentType = '';
    for (final entry in request.headers.entries) {
      if (entry.key.toLowerCase() == 'content-type') {
        contentType = entry.value.toLowerCase();
        break;
      }
    }
    if (!contentType.contains('application/json') || request.body.isEmpty) {
      return request;
    }
    try {
      final decoded = jsonDecode(request.body);
      if (decoded is! Map<String, dynamic>) return request;
      final patched = Map<String, dynamic>.from(decoded);
      for (final entry in requestBodyPatch.entries) {
        final current = patched[entry.key];
        final incoming = entry.value;
        if (current is Map && incoming is Map) {
          patched[entry.key] = {
            ...Map<String, dynamic>.from(current),
            ...Map<String, dynamic>.from(incoming),
          };
        } else {
          patched[entry.key] = incoming;
        }
      }
      final copy = http.Request(request.method, request.url)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection
        ..headers.addAll(request.headers)
        ..body = jsonEncode(patched);
      return copy;
    } catch (_) {
      // A provider-specific extension must never make a normal request fail.
      return request;
    }
  }

  @override
  void close() {
    _inner.close();
  }
}
