import 'dart:convert';
import 'package:http/http.dart' as http;

/// HTTP transport adapter.
class HttpAdapter {
  /// HTTP client.
  final http.Client client;

  /// Creates an [HttpAdapter].
  const HttpAdapter({required this.client});

  /// Sends a GET request.
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return client.get(url, headers: headers);
  }

  /// Sends a POST request.
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return client.post(url, headers: headers, body: body);
  }

  /// Sends a PATCH request.
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return client.patch(url, headers: headers, body: body);
  }

  /// Sends a DELETE request.
  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) {
    return client.delete(url, headers: headers);
  }

  /// Sends a JSON POST request.
  Future<http.Response> postJson(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) {
    final mergedHeaders = {'Content-Type': 'application/json', ...?headers};

    return post(
      url,
      headers: mergedHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
