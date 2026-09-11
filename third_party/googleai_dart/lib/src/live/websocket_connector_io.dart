import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:web_socket/web_socket.dart';

/// IO implementation that uses dart:io WebSocket with header support.
///
/// This allows Vertex AI OAuth tokens to be passed via Authorization header
/// on native platforms (server, CLI, mobile).
Future<WebSocket> connectWebSocket(
  Uri uri, {
  Map<String, String>? headers,
}) async {
  if (!uri.isScheme('ws') && !uri.isScheme('wss')) {
    throw ArgumentError.value(
      uri,
      'url',
      'only ws: and wss: schemes are supported',
    );
  }

  final io.WebSocket ioSocket;
  try {
    // Use dart:io WebSocket which supports custom headers
    ioSocket = await io.WebSocket.connect(uri.toString(), headers: headers);
  } on io.WebSocketException catch (e) {
    throw WebSocketException(e.message);
  }

  // Wrap in the platform-independent WebSocket interface
  return _IOWebSocketWrapper(ioSocket);
}

/// Wrapper around dart:io WebSocket to implement the web_socket package interface.
///
/// This is needed because the web_socket package's IOWebSocket.connect() doesn't
/// support custom headers, but dart:io WebSocket.connect() does.
class _IOWebSocketWrapper implements WebSocket {
  final io.WebSocket _webSocket;
  final StreamController<WebSocketEvent> _events = StreamController();

  _IOWebSocketWrapper(this._webSocket) {
    _webSocket.listen(
      (event) {
        if (_events.isClosed) return;
        switch (event) {
          case final String e:
            _events.add(TextDataReceived(e));
          case final List<int> e:
            _events.add(BinaryDataReceived(Uint8List.fromList(e)));
        }
      },
      onError: (Object e, StackTrace st) {
        if (_events.isClosed) return;
        final wse = switch (e) {
          io.WebSocketException(message: final message) => WebSocketException(
            message,
          ),
          _ => WebSocketException(e.toString()),
        };
        _events.addError(wse, st);
      },
      onDone: () {
        if (_events.isClosed) return;
        _events.add(
          CloseReceived(_webSocket.closeCode, _webSocket.closeReason ?? ''),
        );
        unawaited(_events.close());
      },
    );
  }

  @override
  Stream<WebSocketEvent> get events => _events.stream;

  @override
  String get protocol => _webSocket.protocol ?? '';

  @override
  void sendBytes(Uint8List b) {
    if (_events.isClosed) {
      throw WebSocketConnectionClosed();
    }
    _webSocket.add(b);
  }

  @override
  void sendText(String s) {
    if (_events.isClosed) {
      throw WebSocketConnectionClosed();
    }
    _webSocket.add(s);
  }

  @override
  Future<void> close([int? code, String? reason]) async {
    if (_events.isClosed) {
      throw WebSocketConnectionClosed();
    }

    // Validate close code (RFC 6455)
    if (code != null) {
      if (code != 1000 && !(code >= 3000 && code <= 4999)) {
        throw ArgumentError.value(
          code,
          'code',
          'must be 1000 or in range 3000-4999',
        );
      }
    }

    // Validate close reason (max 123 bytes when UTF-8 encoded)
    if (reason != null && reason.length > 123) {
      throw ArgumentError.value(
        reason,
        'reason',
        'must be no longer than 123 bytes when encoded as UTF-8',
      );
    }

    unawaited(_events.close());
    try {
      await _webSocket.close(code, reason);
    } on io.WebSocketException catch (e) {
      throw WebSocketException(e.message);
    }
  }
}
