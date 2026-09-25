import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../auth/auth_provider.dart';
import '../errors/exceptions.dart';
import '../models/interactions/content/content.dart';
import '../models/interactions/events/events.dart';
import '../models/interactions/interaction.dart';
import '../models/interactions/tools/tools.dart';
import '../utils/request_id.dart';
import '../utils/streaming_parser.dart';
import 'base_resource.dart';

/// Resource for the Interactions API.
///
/// The Interactions API provides server-side state management for conversations
/// with Gemini models. It enables multi-turn conversations with managed state,
/// function calling with automatic result handling, and streaming responses.
///
/// This is an experimental API and is subject to change.
class InteractionsResource extends ResourceBase {
  /// Creates an [InteractionsResource].
  InteractionsResource({
    required super.config,
    required super.httpClient,
    required super.interceptorChain,
    required super.requestBuilder,
  });

  /// Creates a new interaction.
  ///
  /// The [model] specifies which model to use (e.g., "gemini-3-flash-preview").
  /// The [input] can be a [String], a [List<InteractionContent>], or
  /// a list of turns for multi-turn conversations.
  ///
  /// Returns the [Interaction] with the model's response.
  Future<Interaction> create({
    required String model,
    Object? input,
    String? systemInstruction,
    List<InteractionTool>? tools,
    Map<String, dynamic>? generationConfig,
    String? previousInteractionId,
    bool? background,
  }) async {
    final url = requestBuilder.buildUrl('/{version}/interactions');

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final body = <String, dynamic>{
      'model': model,
      if (input != null) 'input': _serializeInput(input),
      if (systemInstruction != null) 'system_instruction': systemInstruction,
      if (tools != null) 'tools': tools.map((t) => t.toJson()).toList(),
      if (generationConfig != null) 'generation_config': generationConfig,
      if (previousInteractionId != null)
        'previous_interaction_id': previousInteractionId,
      if (background != null) 'background': background,
    };

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(body);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Interaction.fromJson(responseBody);
  }

  /// Creates an interaction with an agent.
  ///
  /// The [agent] specifies which agent to use (e.g., "deep-research-pro-preview-12-2025").
  ///
  /// Returns the [Interaction] with the agent's response.
  Future<Interaction> createWithAgent({
    required String agent,
    Object? input,
    Map<String, dynamic>? agentConfig,
    String? previousInteractionId,
    bool? background,
  }) async {
    final url = requestBuilder.buildUrl('/{version}/interactions');

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final body = <String, dynamic>{
      'agent': agent,
      if (input != null) 'input': _serializeInput(input),
      if (agentConfig != null) 'agent_config': agentConfig,
      if (previousInteractionId != null)
        'previous_interaction_id': previousInteractionId,
      if (background != null) 'background': background,
    };

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(body);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Interaction.fromJson(responseBody);
  }

  /// Gets an interaction by ID.
  ///
  /// Returns the [Interaction] with its current state and outputs.
  Future<Interaction> get(String id) async {
    final url = requestBuilder.buildUrl('/{version}/interactions/$id');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Interaction.fromJson(responseBody);
  }

  /// Cancels an in-progress interaction.
  ///
  /// This only applies to background interactions that are still running.
  ///
  /// Returns the cancelled [Interaction].
  Future<Interaction> cancel(String id) async {
    final url = requestBuilder.buildUrl('/{version}/interactions/$id/cancel');

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('POST', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Interaction.fromJson(responseBody);
  }

  /// Deletes an interaction.
  Future<void> delete(String id) async {
    final url = requestBuilder.buildUrl('/{version}/interactions/$id');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('DELETE', url)..headers.addAll(headers);

    await interceptorChain.execute(httpRequest);
  }

  /// Creates a streaming interaction.
  ///
  /// Returns a stream of [InteractionEvent]s as the model generates the response.
  Stream<InteractionEvent> createStream({
    required String model,
    Object? input,
    String? systemInstruction,
    List<InteractionTool>? tools,
    Map<String, dynamic>? generationConfig,
    String? previousInteractionId,
  }) async* {
    final url = requestBuilder.buildUrl(
      '/{version}/interactions',
      queryParams: {'stream': 'true', 'alt': 'sse'},
    );

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final body = <String, dynamic>{
      'model': model,
      if (input != null) 'input': _serializeInput(input),
      if (systemInstruction != null) 'system_instruction': systemInstruction,
      if (tools != null) 'tools': tools.map((t) => t.toJson()).toList(),
      if (generationConfig != null) 'generation_config': generationConfig,
      if (previousInteractionId != null)
        'previous_interaction_id': previousInteractionId,
    };

    var httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(body);

    // Apply auth manually for streaming
    final credentials = config.authProvider != null
        ? await config.authProvider!.getCredentials()
        : null;
    httpRequest = _applyAuthToRequestSync(httpRequest, credentials);
    httpRequest = _applyLoggingToRequest(httpRequest);

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await httpClient.send(httpRequest);

      if (streamedResponse.statusCode >= 400) {
        final response = await http.Response.fromStream(streamedResponse);
        throw _mapHttpErrorForStreaming(response);
      }
    } catch (e) {
      _logStreamError(
        e,
        httpRequest.headers['X-Request-ID'] ?? generateRequestId(),
      );
      rethrow;
    }

    final lineStream = bytesToLines(streamedResponse.stream);
    final jsonStream = parseSSE(lineStream);

    await for (final json in jsonStream) {
      yield InteractionEvent.fromJson(json);
    }
  }

  /// Resumes a streaming interaction from a specific event.
  ///
  /// The [lastEventId] is used to resume from the next event after the one
  /// with that ID.
  Stream<InteractionEvent> resumeStream(
    String id, {
    String? lastEventId,
  }) async* {
    final queryParams = <String, String>{
      'stream': 'true',
      'alt': 'sse',
      if (lastEventId != null) 'last_event_id': lastEventId,
    };

    final url = requestBuilder.buildUrl(
      '/{version}/interactions/$id',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders();

    var httpRequest = http.Request('GET', url)..headers.addAll(headers);

    // Apply auth manually for streaming
    final credentials = config.authProvider != null
        ? await config.authProvider!.getCredentials()
        : null;
    httpRequest = _applyAuthToRequestSync(httpRequest, credentials);
    httpRequest = _applyLoggingToRequest(httpRequest);

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await httpClient.send(httpRequest);

      if (streamedResponse.statusCode >= 400) {
        final response = await http.Response.fromStream(streamedResponse);
        throw _mapHttpErrorForStreaming(response);
      }
    } catch (e) {
      _logStreamError(
        e,
        httpRequest.headers['X-Request-ID'] ?? generateRequestId(),
      );
      rethrow;
    }

    final lineStream = bytesToLines(streamedResponse.stream);
    final jsonStream = parseSSE(lineStream);

    await for (final json in jsonStream) {
      yield InteractionEvent.fromJson(json);
    }
  }

  /// Serializes input for the API.
  Object _serializeInput(Object input) {
    if (input is String) {
      return input;
    } else if (input is List<InteractionContent>) {
      return input.map((c) => c.toJson()).toList();
    } else if (input is List) {
      return input;
    } else {
      return input;
    }
  }

  // Helper methods for streaming (same as ModelsResource)

  http.Request _applyAuthToRequestSync(
    http.Request request,
    AuthCredentials? credentials,
  ) {
    if (credentials == null) return request;

    return switch (credentials) {
      ApiKeyCredentials(:final apiKey, :final placement) => _addApiKey(
        request,
        apiKey,
        placement,
      ),
      BearerTokenCredentials(:final token) => _addBearerToken(request, token),
      EphemeralTokenCredentials(:final token) => _addEphemeralToken(
        request,
        token,
      ),
      NoAuthCredentials() => request,
    };
  }

  http.Request _addApiKey(
    http.Request request,
    String apiKey,
    AuthPlacement placement,
  ) {
    if (placement == AuthPlacement.header) {
      if (!request.headers.containsKey('X-Goog-Api-Key')) {
        return http.Request(request.method, request.url)
          ..headers.addAll(request.headers)
          ..headers['X-Goog-Api-Key'] = apiKey
          ..bodyBytes = request.bodyBytes
          ..encoding = request.encoding;
      }
    } else {
      final uri = request.url;
      if (!uri.queryParameters.containsKey('key')) {
        final queryParams = Map<String, dynamic>.from(uri.queryParameters);
        queryParams['key'] = apiKey;
        final newUri = uri.replace(queryParameters: queryParams);

        return http.Request(request.method, newUri)
          ..headers.addAll(request.headers)
          ..bodyBytes = request.bodyBytes
          ..encoding = request.encoding;
      }
    }

    return request;
  }

  http.Request _addBearerToken(http.Request request, String bearerToken) {
    if (!request.headers.containsKey('Authorization')) {
      return http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..headers['Authorization'] = 'Bearer $bearerToken'
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding;
    }

    return request;
  }

  http.Request _addEphemeralToken(http.Request request, String token) {
    final uri = request.url;
    if (uri.queryParameters.containsKey('access_token')) {
      return request;
    }
    final queryParams = Map<String, dynamic>.from(uri.queryParameters);
    queryParams['access_token'] = token;
    final newUri = uri.replace(queryParameters: queryParams);

    return http.Request(request.method, newUri)
      ..headers.addAll(request.headers)
      ..bodyBytes = request.bodyBytes
      ..encoding = request.encoding;
  }

  http.Request _applyLoggingToRequest(http.Request request) {
    if (!request.headers.containsKey('X-Request-ID')) {
      final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
      final updatedRequest = http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..headers['X-Request-ID'] = requestId
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding;

      if (config.logLevel.value <= Level.INFO.value) {
        Logger(
          'GoogleAI.HTTP',
        ).info('REQUEST [$requestId] ${request.method} ${request.url}');
      }

      return updatedRequest;
    }

    return request;
  }

  GoogleAIException _mapHttpErrorForStreaming(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    var message = 'HTTP $statusCode error';
    final details = <Object>[];

    try {
      final errorDetails = jsonDecode(body);
      if (errorDetails is Map<String, dynamic>) {
        final error = errorDetails['error'] as Map<String, dynamic>?;
        message = error?['message']?.toString() ?? message;
        if (error?['details'] != null) {
          final errorDetailsList = error!['details'];
          if (errorDetailsList is List) {
            details.addAll(errorDetailsList.cast<Object>());
          }
        }
      }
    } catch (_) {
      if (body.length < 200 && body.isNotEmpty) {
        message = body;
      }
    }

    if (statusCode == 429) {
      DateTime? retryAfter;
      final retryHeader = response.headers['retry-after'];
      if (retryHeader != null) {
        final seconds = int.tryParse(retryHeader);
        if (seconds != null) {
          retryAfter = DateTime.now().add(Duration(seconds: seconds));
        }
      }

      return RateLimitException(
        code: statusCode,
        message: message,
        details: details,
        retryAfter: retryAfter,
      );
    }

    return ApiException(code: statusCode, message: message, details: details);
  }

  void _logStreamError(Object error, String requestId) {
    if (config.logLevel.value <= Level.SEVERE.value) {
      Logger('GoogleAI.HTTP').severe('STREAM ERROR [$requestId] $error', error);
    }
  }
}
