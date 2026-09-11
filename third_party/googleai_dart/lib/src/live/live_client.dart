import 'dart:async' show Completer, StreamSubscription, unawaited;

import 'package:logging/logging.dart';

import '../auth/auth_provider.dart';
import '../client/config.dart';
import '../errors/exceptions.dart';
import '../models/live/config/live_config.dart';
import '../models/live/config/session_resumption_config.dart';
import '../models/live/messages/client/client_message.dart';
import '../models/live/messages/server/server_message.dart';
import 'live_session.dart';
import 'websocket_connector.dart' as ws;

/// Client for the Gemini Live API.
///
/// Provides WebSocket-based real-time bidirectional streaming for
/// audio, video, and text conversations.
///
/// ## Example
///
/// ```dart
/// final client = GoogleAIClient(config: config);
/// final liveClient = client.createLiveClient();
///
/// final session = await liveClient.connect(
///   model: 'gemini-2.0-flash-live-001',
///   liveConfig: LiveConfig(
///     generationConfig: LiveGenerationConfig(
///       responseModalities: ['AUDIO', 'TEXT'],
///     ),
///   ),
/// );
///
/// // Use session for streaming...
///
/// await session.close();
/// await liveClient.close();
/// ```
class LiveClient {
  static final _log = Logger('LiveClient');

  final GoogleAIConfig _config;
  final List<LiveSession> _sessions = [];

  /// Creates a [LiveClient].
  LiveClient({required GoogleAIConfig config}) : _config = config;

  /// Connects to the Live API and starts a new session.
  ///
  /// [model] is the model to use (e.g., 'gemini-2.0-flash-live-001').
  /// [liveConfig] contains session configuration (generation, VAD, tools, etc.).
  /// [accessToken] is an optional ephemeral token for client-side authentication.
  /// When provided, this token is used instead of the configured auth provider.
  ///
  /// Returns a [LiveSession] for bidirectional streaming.
  ///
  /// Throws [LiveConnectionException] if the connection fails.
  /// Throws [LiveSessionSetupException] if session setup fails.
  ///
  /// ## Using Ephemeral Tokens
  ///
  /// Ephemeral tokens allow secure client-side authentication without exposing
  /// the main API key. Create tokens server-side using [AuthTokensResource.create]:
  ///
  /// ```dart
  /// // Server-side
  /// final token = await client.authTokens.create(
  ///   authToken: AuthToken(
  ///     expireTime: DateTime.now().add(Duration(minutes: 30)),
  ///     uses: 1,
  ///   ),
  /// );
  ///
  /// // Client-side
  /// final session = await liveClient.connect(
  ///   model: 'gemini-2.0-flash-live-001',
  ///   accessToken: tokenFromServer,
  /// );
  /// ```
  Future<LiveSession> connect({
    required String model,
    LiveConfig? liveConfig,
    String? accessToken,
  }) async {
    final uri = await _buildWebSocketUri(model, accessToken: accessToken);
    _log.fine('Connecting to Live API');

    // Get headers for Vertex AI OAuth (native platforms only)
    // Web platforms don't support WebSocket headers - the connector will throw
    // a clear error if headers are needed but not supported.
    Map<String, String>? headers;
    if (_config.apiMode == ApiMode.vertexAI && accessToken == null) {
      final credentials = await _config.authProvider?.getCredentials();
      if (credentials is BearerTokenCredentials) {
        headers = {'Authorization': 'Bearer ${credentials.token}'};
      }
    }

    // Phase 1: Establish WebSocket connection
    LiveSession session;
    try {
      // Connect WebSocket with optional auth headers
      // On native platforms (dart:io), headers are passed to the WebSocket.
      // On web platforms, if headers are provided, a clear error is thrown.
      final socket = await ws.connectWebSocket(uri, headers: headers);

      // Create session
      session = LiveSession.fromWebSocket(socket);
      _sessions.add(session);
    } on Exception catch (e) {
      throw LiveConnectionException(
        message: 'Failed to connect to Live API: $e',
        uri: uri,
        cause: e,
      );
    }

    // Phase 2: Setup session (separate try block to surface setup errors)
    try {
      await _setupSession(session, model, liveConfig);
      _log.fine('Live session established: ${session.sessionId}');
      return session;
    } on LiveSessionSetupException {
      // Clean up failed session and rethrow setup errors directly
      await session.close();
      _sessions.remove(session);
      rethrow;
    } on Exception catch (e) {
      // Clean up failed session and wrap other errors
      await session.close();
      _sessions.remove(session);
      throw LiveSessionSetupException(
        message: 'Session setup failed: $e',
        cause: e,
      );
    }
  }

  /// Resumes a previous session using a resumption token.
  ///
  /// [model] is the model to use (must match the original session).
  /// [resumptionToken] is the token from [LiveSession.resumptionToken].
  /// [liveConfig] contains additional session configuration.
  /// [accessToken] is an optional ephemeral token for client-side authentication.
  ///
  /// Throws [LiveSessionResumptionException] if resumption fails.
  Future<LiveSession> resume({
    required String model,
    required String resumptionToken,
    LiveConfig? liveConfig,
    String? accessToken,
  }) async {
    final config =
        liveConfig?.copyWith(
          sessionResumption: SessionResumptionConfig.resume(resumptionToken),
        ) ??
        LiveConfig(
          sessionResumption: SessionResumptionConfig.resume(resumptionToken),
        );

    try {
      return await connect(
        model: model,
        liveConfig: config,
        accessToken: accessToken,
      );
    } on LiveConnectionException catch (e) {
      throw LiveSessionResumptionException(
        message: 'Failed to resume session: ${e.message}',
        handle: resumptionToken,
        cause: e.cause,
      );
    }
  }

  Future<Uri> _buildWebSocketUri(String model, {String? accessToken}) async {
    // Get auth credentials for query params
    final queryParams = await _getAuthQueryParams(accessToken: accessToken);

    switch (_config.apiMode) {
      case ApiMode.googleAI:
        // Google AI endpoint
        // wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent
        final baseUrl = _config.baseUrl.isNotEmpty
            ? _config.baseUrl
            : 'generativelanguage.googleapis.com';

        queryParams.addAll(_config.defaultQueryParams);

        return Uri(
          scheme: 'wss',
          host: baseUrl
              .replaceFirst('https://', '')
              .replaceFirst('http://', ''),
          port: 443, // Explicit port to avoid :0 issue
          path:
              '/ws/google.ai.generativelanguage.${_config.apiVersion.value}.GenerativeService.BidiGenerateContent',
          queryParameters: queryParams,
        );

      case ApiMode.vertexAI:
        // Vertex AI endpoint
        // wss://{location}-aiplatform.googleapis.com/ws/google.cloud.aiplatform.v1beta1.PredictionService.BidiGenerateContent
        final location = _config.location ?? 'us-central1';
        final projectId = _config.projectId;

        if (projectId == null) {
          throw const LiveSessionSetupException(
            message: 'Project ID is required for Vertex AI',
          );
        }

        final host = '$location-aiplatform.googleapis.com';
        final version = _config.apiVersion == ApiVersion.v1 ? 'v1' : 'v1beta1';

        queryParams['project'] = projectId;
        queryParams['location'] = location;
        queryParams.addAll(_config.defaultQueryParams);

        // Note: Vertex AI requires OAuth Bearer token in headers.
        // On native platforms, the websocket_connector passes headers to dart:io.
        // On web platforms, headers aren't supported and an error is thrown.
        return Uri(
          scheme: 'wss',
          host: host,
          path:
              '/ws/google.cloud.aiplatform.$version.PredictionService.BidiGenerateContent',
          queryParameters: queryParams,
        );
    }
  }

  Future<Map<String, String>> _getAuthQueryParams({String? accessToken}) async {
    final params = <String, String>{};

    // If an ephemeral access token is provided, use it directly
    if (accessToken != null) {
      params['access_token'] = accessToken;
      return params;
    }

    // Otherwise, get credentials from the auth provider
    if (_config.authProvider != null) {
      final credentials = await _config.authProvider!.getCredentials();

      switch (credentials) {
        case ApiKeyCredentials(:final apiKey):
          // API key goes in query params for WebSocket
          params['key'] = apiKey;
        case BearerTokenCredentials():
          // OAuth bearer tokens are handled via Authorization header
          // by the platform-specific WebSocket connector.
          // Do NOT add to query params - this would leak the token to logs,
          // proxies, and caches. The connector will either:
          // - Add the header (native platforms)
          // - Throw a clear error (web platforms)
          break;
        case EphemeralTokenCredentials(:final token):
          // Ephemeral tokens use access_token query parameter
          params['access_token'] = token;
        case NoAuthCredentials():
          // No auth needed
          break;
      }
    }

    return params;
  }

  Future<void> _setupSession(
    LiveSession session,
    String model,
    LiveConfig? liveConfig,
  ) async {
    // Build model path based on API mode
    final String modelPath;
    if (_config.apiMode == ApiMode.vertexAI) {
      // Vertex AI: projects/{project}/locations/{location}/publishers/google/models/{model}
      if (model.startsWith('projects/')) {
        modelPath = model; // Already fully qualified
      } else {
        final projectId = _config.projectId;
        if (projectId == null) {
          throw const LiveSessionSetupException(
            message: 'projectId required for Vertex AI',
          );
        }
        final location = _config.location ?? 'us-central1';
        modelPath =
            'projects/$projectId/locations/$location/publishers/google/models/$model';
      }
    } else {
      // Google AI: models/{model}
      modelPath = model.startsWith('models/') ? model : 'models/$model';
    }

    final setup = BidiGenerateContentSetup(
      model: modelPath,
      generationConfig: liveConfig?.generationConfig,
      systemInstruction: liveConfig?.systemInstruction,
      tools: liveConfig?.tools,
      realtimeInputConfig: liveConfig?.realtimeInputConfig,
      sessionResumption: liveConfig?.sessionResumption,
      contextWindowCompression: liveConfig?.contextWindowCompression,
      inputAudioTranscription: liveConfig?.inputAudioTranscription,
      outputAudioTranscription: liveConfig?.outputAudioTranscription,
      proactivity: liveConfig?.proactivity,
    );

    // Send setup
    session.send(setup);

    // Wait for setup complete or error
    final completer = Completer<void>();
    StreamSubscription<BidiGenerateContentServerMessage>? subscription;

    subscription = session.messages.listen(
      (message) {
        if (message is BidiGenerateContentSetupComplete) {
          unawaited(subscription?.cancel());
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      },
      onError: (Object error) {
        unawaited(subscription?.cancel());
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(
            const LiveSessionSetupException(
              message: 'Connection closed before setup completed',
            ),
          );
        }
      },
    );

    // Timeout for setup
    try {
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          unawaited(subscription?.cancel());
          throw const LiveSessionSetupException(
            message: 'Setup timed out after 30 seconds',
          );
        },
      );
    } on LiveSessionSetupException {
      rethrow;
    } on Exception catch (e) {
      throw LiveSessionSetupException(message: 'Setup failed: $e', cause: e);
    }
  }

  /// Closes all active sessions and cleans up resources.
  Future<void> close() async {
    for (final session in _sessions) {
      if (session.isConnected) {
        await session.close();
      }
    }
    _sessions.clear();
  }
}
