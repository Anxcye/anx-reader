import 'dart:convert';

import 'package:http/http.dart' as http;

/// HTTP client that injects reasoning-related fields into the JSON body of
/// outgoing POST requests.
///
/// The LangChain wrappers used by this app cannot express every reasoning
/// parameter (e.g. OpenAI's explicit `reasoning_effort: "none"`, DeepSeek's
/// `thinking.type`, Gemini's `generationConfig.thinkingConfig`). This client
/// intercepts the request body and deep-merges the computed fields before
/// forwarding the request.
class AiReasoningBodyInterceptor extends http.BaseClient {
  AiReasoningBodyInterceptor({
    required http.Client inner,
    required Map<String, dynamic> Function() overrides,
  })  : _inner = inner,
        _overrides = overrides;

  final http.Client _inner;
  final Map<String, dynamic> Function() _overrides;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final overrides = _overrides();
    if (overrides.isNotEmpty &&
        request is http.Request &&
        request.method == 'POST') {
      try {
        final decoded = jsonDecode(request.body);
        if (decoded is Map<String, dynamic>) {
          final merged = _deepMerge(decoded, overrides);
          final updated = http.Request(request.method, request.url)
            ..followRedirects = request.followRedirects
            ..persistentConnection = request.persistentConnection
            ..headers.addAll(_copyHeaders(request.headers))
            ..body = jsonEncode(merged);
          return _inner.send(updated);
        }
      } catch (_) {
        // Not a JSON body (or unparsable): forward the request unchanged.
      }
    }
    return _inner.send(request);
  }

  /// Copy request headers, dropping `content-length` so it is recomputed
  /// from the modified body.
  Map<String, String> _copyHeaders(Map<String, String> headers) {
    final result = <String, String>{};
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'content-length') continue;
      result[entry.key] = entry.value;
    }
    return result;
  }

  /// Deep-merge [overrides] into [base]: nested maps are merged recursively,
  /// other values replace the existing key.
  Map<String, dynamic> _deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> overrides,
  ) {
    final result = Map<String, dynamic>.from(base);
    for (final entry in overrides.entries) {
      final existing = result[entry.key];
      if (existing is Map<String, dynamic> &&
          entry.value is Map<String, dynamic>) {
        result[entry.key] =
            _deepMerge(existing, entry.value as Map<String, dynamic>);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  @override
  void close() {
    _inner.close();
  }
}
