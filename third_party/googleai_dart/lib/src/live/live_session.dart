import 'dart:async' show StreamController, StreamSubscription, unawaited;
import 'dart:convert';

import 'package:web_socket/web_socket.dart';

import '../errors/exceptions.dart';
import '../models/content/content.dart';
import '../models/live/messages/client/client_message.dart';
import '../models/live/messages/server/server_message.dart';
import '../models/tools/function_response.dart';

/// A live streaming session with the Gemini Live API.
///
/// Provides bidirectional real-time communication for audio, video, and text.
///
/// ## Example
///
/// ```dart
/// final session = await liveClient.connect(model: 'gemini-2.0-flash-live-001');
///
/// // Send text
/// session.sendText('Hello!');
///
/// // Send audio (16kHz, 16-bit, mono PCM)
/// session.sendAudio(pcmBytes);
///
/// // Handle responses
/// await for (final message in session.messages) {
///   switch (message) {
///     case BidiGenerateContentServerContent(:final modelTurn):
///       // Handle model response
///     case BidiGenerateContentToolCall(:final functionCalls):
///       // Handle tool calls
///       session.sendToolResponse(responses);
///   }
/// }
///
/// await session.close();
/// ```
class LiveSession {
  final WebSocket _socket;
  final StreamController<BidiGenerateContentServerMessage> _messageController;
  StreamSubscription<WebSocketEvent>? _subscription;
  bool _isConnected = true;

  /// Session ID returned by the server after setup.
  String? sessionId;

  /// Latest resumption token for session resumption.
  String? resumptionToken;

  /// Whether the session can be resumed.
  bool? resumable;

  LiveSession._({required WebSocket socket})
    : _socket = socket,
      _messageController = StreamController.broadcast();

  /// Creates a new [LiveSession] from an established WebSocket connection.
  factory LiveSession.fromWebSocket(WebSocket socket) {
    final session = LiveSession._(socket: socket).._startListening();
    return session;
  }

  void _startListening() {
    _subscription = _socket.events.listen(
      _handleEvent,
      onError: _handleError,
      onDone: _handleDone,
    );
  }

  void _handleEvent(WebSocketEvent event) {
    switch (event) {
      case TextDataReceived(:final text):
        _parseAndEmitMessage(text);
      case BinaryDataReceived(:final data):
        // The Live API returns messages as binary WebSocket frames
        // containing UTF-8 encoded JSON
        final text = utf8.decode(data);
        _parseAndEmitMessage(text);
      case CloseReceived(:final code, :final reason):
        _isConnected = false;
        if (!_messageController.isClosed) {
          _messageController.addError(
            LiveSessionClosedException(code: code, reason: reason),
          );
          unawaited(_messageController.close());
        }
    }
  }

  void _parseAndEmitMessage(String text) {
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      final message = BidiGenerateContentServerMessage.fromJson(json);

      // Track session state
      switch (message) {
        case BidiGenerateContentSetupComplete(:final sessionId):
          this.sessionId = sessionId;
        case SessionResumptionUpdate(:final newHandle, :final resumable):
          resumptionToken = newHandle;
          this.resumable = resumable;
        default:
          break;
      }

      _messageController.add(message);
    } on FormatException catch (e) {
      _messageController.addError(
        LiveSessionException(message: 'Failed to parse message: $e'),
      );
    }
  }

  void _handleError(Object error) {
    if (!_messageController.isClosed) {
      _messageController.addError(
        LiveSessionException(
          message: 'WebSocket error: $error',
          cause: error is Exception ? error : null,
        ),
      );
    }
  }

  void _handleDone() {
    _isConnected = false;
    if (!_messageController.isClosed) {
      unawaited(_messageController.close());
    }
  }

  /// Whether the session is currently connected.
  bool get isConnected => _isConnected;

  /// Stream of server messages.
  ///
  /// Listen to this stream to receive model responses, tool calls,
  /// and other server events.
  Stream<BidiGenerateContentServerMessage> get messages =>
      _messageController.stream;

  /// Sends a raw message to the server.
  void send(BidiGenerateContentClientMessage message) {
    if (!_isConnected) {
      throw const LiveSessionClosedException();
    }
    final json = jsonEncode(message.toJson());
    _socket.sendText(json);
  }

  /// Sends audio data to the server.
  ///
  /// Audio must be:
  /// - Format: Linear PCM
  /// - Sample rate: 16,000 Hz
  /// - Bit depth: 16-bit signed little-endian
  /// - Channels: Mono
  void sendAudio(List<int> pcmBytes) {
    send(BidiGenerateContentRealtimeInput.audio(pcmBytes));
  }

  /// Sends text input to the server.
  void sendText(String text) {
    send(BidiGenerateContentRealtimeInput.textInput(text));
  }

  /// Sends conversation context/turns to the server.
  void sendContent({required List<Content> turns, bool? turnComplete}) {
    send(
      BidiGenerateContentClientContent(
        turns: turns,
        turnComplete: turnComplete,
      ),
    );
  }

  /// Sends tool responses to the server.
  ///
  /// Call this after receiving a [BidiGenerateContentToolCall] with the
  /// results of executing the requested tools.
  void sendToolResponse(List<FunctionResponse> responses) {
    send(BidiGenerateContentToolResponse(functionResponses: responses));
  }

  /// Signals that user activity has started (manual VAD mode).
  ///
  /// Use this when `automaticActivityDetection.disabled` is `true`
  /// in the session configuration.
  void signalActivityStart() {
    send(BidiGenerateContentRealtimeInput.startActivity());
  }

  /// Signals that user activity has ended (manual VAD mode).
  ///
  /// Use this when `automaticActivityDetection.disabled` is `true`
  /// in the session configuration.
  void signalActivityEnd() {
    send(BidiGenerateContentRealtimeInput.endActivity());
  }

  /// Signals that the audio stream has ended.
  void signalAudioStreamEnd() {
    send(const BidiGenerateContentRealtimeInput(audioStreamEnd: true));
  }

  /// Closes the session.
  ///
  /// After calling this, the session can no longer send or receive messages.
  /// If session resumption is enabled, save the [resumptionToken] before
  /// closing to resume the session later.
  Future<void> close([int? code, String? reason]) async {
    _isConnected = false;
    await _subscription?.cancel();
    await _socket.close(code, reason);
    if (!_messageController.isClosed) {
      await _messageController.close();
    }
  }
}
