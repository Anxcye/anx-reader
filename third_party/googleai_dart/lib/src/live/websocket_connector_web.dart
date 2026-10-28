import 'package:web_socket/web_socket.dart';

import '../errors/exceptions.dart';

/// Web implementation using the web_socket package.
///
/// Web browsers do not support custom headers on WebSocket connections,
/// so Vertex AI OAuth tokens cannot be passed via Authorization header.
/// In this case, an error is thrown with guidance.
Future<WebSocket> connectWebSocket(Uri uri, {Map<String, String>? headers}) {
  // Web browsers don't support custom headers on WebSocket connections
  if (headers != null && headers.isNotEmpty) {
    // Check if this is an OAuth authorization header (Vertex AI)
    if (headers.containsKey('Authorization')) {
      throw LiveConnectionException(
        message:
            'Vertex AI Live API requires OAuth headers which are not '
            'supported by browser WebSocket connections. '
            'On web platforms, use Google AI mode with an API key, or use '
            'ephemeral tokens (accessToken parameter) for authentication. '
            'Vertex AI Live API with OAuth is supported on native platforms '
            '(server, CLI, mobile).',
        uri: uri,
      );
    }
  }

  // Use the web_socket package for browser connections
  return WebSocket.connect(uri);
}
