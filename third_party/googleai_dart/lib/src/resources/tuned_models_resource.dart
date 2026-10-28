import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../auth/auth_provider.dart';
import '../client/config.dart';
import '../errors/exceptions.dart';
import '../models/batch/embed_content_batch.dart';
import '../models/batch/generate_content_batch.dart';
import '../models/generation/generate_content_request.dart';
import '../models/generation/generate_content_response.dart';
import '../models/models/list_tuned_models_response.dart';
import '../models/models/operation.dart';
import '../models/models/tuned_model.dart';
import '../utils/request_id.dart';
import '../utils/streaming_parser.dart';
import 'base_resource.dart';
import 'operations_resource.dart';
import 'permissions_resource.dart';

/// Resource for the Tuned Models API.
///
/// Provides access to tuned model operations including content generation,
/// model management, and permissions.
///
/// **Note**: This resource is only available with the Google AI (Gemini) API.
/// Vertex AI has a different tuning API structure.
///
/// See: https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/tuning
class TunedModelsResource extends ResourceBase {
  /// Creates a [TunedModelsResource].
  TunedModelsResource({
    required super.config,
    required super.httpClient,
    required super.interceptorChain,
    required super.requestBuilder,
  });

  /// Validates that the Tuned Models API is only used with Google AI.
  void _validateGoogleAIOnly() {
    if (config.apiMode == ApiMode.vertexAI) {
      throw UnsupportedError(
        'Tuned Models API is only available with Google AI (Gemini API). '
        'Vertex AI uses a different tuning API structure. '
        'See: https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/tuning',
      );
    }
  }

  /// Generates content using a tuned model.
  ///
  /// The [tunedModel] parameter specifies which tuned model to use (e.g., "my-model-abc123").
  /// The [request] contains the conversation history and generation config.
  /// The optional [abortTrigger] allows canceling the request before completion.
  ///
  /// Returns a [GenerateContentResponse] containing the model's response.
  ///
  /// Throws [AbortedException] if the request is aborted via [abortTrigger].
  Future<GenerateContentResponse> generateContent({
    required String tunedModel,
    required GenerateContentRequest request,
    Future<void>? abortTrigger,
  }) async {
    final url = requestBuilder.buildUrl(
      '/{version}/tunedModels/$tunedModel:generateContent',
    );

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(request.toJson());

    final response = await interceptorChain.execute(
      httpRequest,
      abortTrigger: abortTrigger,
    );

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return GenerateContentResponse.fromJson(responseBody);
  }

  /// Generates streaming content using a tuned model.
  ///
  /// The [tunedModel] parameter specifies which tuned model to use (e.g., "my-model-abc123").
  /// The [request] contains the conversation history and generation config.
  /// The optional [abortTrigger] allows canceling the stream.
  ///
  /// Returns a stream of [GenerateContentResponse] chunks.
  ///
  /// If [abortTrigger] completes while streaming, the stream will emit
  /// an [AbortedException] error and close immediately.
  ///
  /// Note: Streaming applies auth and logging interceptors manually since
  /// StreamedResponse cannot go through the full interceptor chain.
  /// This is an **intentional and spec-compliant design** per spec.md line 60-63.
  /// Streaming responses are consumed incrementally, making full chain impossible.
  Stream<GenerateContentResponse> streamGenerateContent({
    required String tunedModel,
    required GenerateContentRequest request,
    Future<void>? abortTrigger,
  }) async* {
    // Build URL and headers
    final url = requestBuilder.buildUrl(
      '/{version}/tunedModels/$tunedModel:streamGenerateContent',
      queryParams: {'alt': 'sse'},
    );

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    // Create request
    var httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(request.toJson());

    // Apply interceptor logic manually for streaming
    // 1. Auth: Get credentials from provider and add authentication
    final credentials = config.authProvider != null
        ? await config.authProvider!.getCredentials()
        : null;
    httpRequest = _applyAuthToRequestSync(httpRequest, credentials);

    // 2. Logging: Add request ID and log request
    httpRequest = _applyLoggingToRequest(httpRequest);

    // 3. Send streaming request (no retry for streams currently)
    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await httpClient.send(httpRequest);

      // Check for HTTP errors before processing stream
      if (streamedResponse.statusCode >= 400) {
        // Convert streamed response to regular response for error handling
        final response = await http.Response.fromStream(streamedResponse);
        // This will throw the appropriate exception
        throw _mapHttpErrorForStreaming(response);
      }
    } catch (e) {
      // Log error
      _logStreamError(
        e,
        httpRequest.headers['X-Request-ID'] ?? generateRequestId(),
      );
      rethrow;
    }

    // Parse SSE stream
    final lineStream = bytesToLines(streamedResponse.stream);
    final jsonStream = parseSSE(lineStream);

    // Get request ID for abortion tracking
    final requestId =
        httpRequest.headers['X-Request-ID'] ?? generateRequestId();

    if (abortTrigger != null) {
      // Monitor abort trigger during streaming
      yield* _streamWithAbortMonitoring(jsonStream, abortTrigger, requestId);
    } else {
      // No abort trigger, stream normally
      await for (final json in jsonStream) {
        yield GenerateContentResponse.fromJson(json);
      }
    }
  }

  /// Helper to monitor abort trigger while streaming.
  Stream<GenerateContentResponse> _streamWithAbortMonitoring(
    Stream<Map<String, dynamic>> jsonStream,
    Future<void> abortTrigger,
    String requestId,
  ) {
    late StreamController<GenerateContentResponse> controller;
    late StreamSubscription<Map<String, dynamic>> subscription;
    var aborted = false;
    var controllerClosed = false; // Track controller state

    controller = StreamController<GenerateContentResponse>(
      onListen: () {
        // Initialize subscription FIRST (fixes race condition)
        subscription = jsonStream.listen(
          (json) {
            if (!aborted && !controllerClosed) {
              controller.add(GenerateContentResponse.fromJson(json));
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!aborted && !controllerClosed) {
              controller.addError(error, stackTrace);
            }
          },
          onDone: () {
            if (!aborted && !controllerClosed) {
              controllerClosed = true;
              unawaited(controller.close());
            }
          },
          cancelOnError: true,
        );

        // THEN register abort handler (fixes race condition)
        unawaited(
          abortTrigger.then((_) {
            if (!aborted && !controllerClosed) {
              aborted = true;
              // Immediately cancel upstream subscription
              unawaited(subscription.cancel());
              // Double-check before adding error
              if (!controller.isClosed) {
                controller.addError(
                  AbortedException(
                    message: 'Stream aborted by user',
                    correlationId: requestId,
                    timestamp: DateTime.now(),
                    stage: AbortionStage.duringStream,
                  ),
                );
                controllerClosed = true;
                unawaited(controller.close());
              }
            }
          }),
        );
      },
      onCancel: () {
        controllerClosed = true; // Mark as closed BEFORE cancelling
        return subscription.cancel();
      },
    );

    return controller.stream;
  }

  /// Creates a batch of generate content requests using a tuned model.
  ///
  /// The [tunedModel] parameter specifies which tuned model to use (e.g., "my-model-abc123").
  /// The [batch] contains the batch configuration including requests.
  /// If [batch.model] is not set, it will be auto-populated from [tunedModel].
  ///
  /// Returns a [GenerateContentBatch] with the batch job details.
  Future<GenerateContentBatch> batchGenerateContent({
    required String tunedModel,
    required GenerateContentBatch batch,
  }) async {
    // Auto-populate batch.model from method parameter if not set
    final effectiveBatch = batch.model == null
        ? batch.copyWith(model: 'tunedModels/$tunedModel')
        : batch;

    final url = requestBuilder.buildUrl(
      '/{version}/tunedModels/$tunedModel:batchGenerateContent',
    );

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode({'batch': effectiveBatch.toJson()});

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return GenerateContentBatch.fromJson(responseBody);
  }

  /// Enqueues a batch of embed content requests for asynchronous processing using a tuned model.
  ///
  /// This is an asynchronous batch operation that returns immediately with
  /// batch metadata. Use [getEmbedBatch], [listBatches], or [LROPoller] to monitor
  /// the batch processing status.
  ///
  /// The [tunedModel] parameter specifies which tuned model to use (e.g., "my-model-abc123").
  /// The [batch] contains the batch configuration including input configuration.
  /// If [batch.model] is not set, it will be auto-populated from [tunedModel].
  ///
  /// Returns an [EmbedContentBatch] with the batch job details including
  /// the batch name which can be used to track progress.
  Future<EmbedContentBatch> asyncBatchEmbedContent({
    required String tunedModel,
    required EmbedContentBatch batch,
  }) async {
    // Auto-populate batch.model from method parameter if not set
    final effectiveBatch = batch.model == null
        ? batch.copyWith(model: 'tunedModels/$tunedModel')
        : batch;

    final url = requestBuilder.buildUrl(
      '/{version}/tunedModels/$tunedModel:asyncBatchEmbedContent',
    );

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode({'batch': effectiveBatch.toJson()});

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return EmbedContentBatch.fromJson(responseBody);
  }

  /// Creates a tuned model.
  ///
  /// The [tunedModel] contains the model configuration and training data.
  /// The optional [tunedModelId] specifies a custom ID for the model.
  ///
  /// Returns an [Operation] that can be polled for completion status.
  Future<Operation> create({
    required TunedModel tunedModel,
    String? tunedModelId,
  }) async {
    _validateGoogleAIOnly();

    final queryParams = <String, String>{
      if (tunedModelId != null) 'tunedModelId': tunedModelId,
    };

    final url = requestBuilder.buildUrl(
      '/{version}/tunedModels',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(tunedModel.toJson());

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Operation.fromJson(responseBody);
  }

  /// Updates a tuned model.
  ///
  /// The [name] is the resource name of the tuned model.
  /// The [tunedModel] contains the updated model configuration.
  /// The [updateMask] specifies which fields to update.
  ///
  /// Returns the updated [TunedModel].
  Future<TunedModel> patch({
    required String name,
    required TunedModel tunedModel,
    String? updateMask,
  }) async {
    _validateGoogleAIOnly();

    final queryParams = <String, String>{
      if (updateMask != null) 'updateMask': updateMask,
    };

    final url = requestBuilder.buildUrl(
      '/{version}/$name',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('PATCH', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(tunedModel.toJson());

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return TunedModel.fromJson(responseBody);
  }

  /// Deletes a tuned model.
  ///
  /// The [name] is the resource name of the tuned model to delete.
  Future<void> delete({required String name}) async {
    _validateGoogleAIOnly();

    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('DELETE', url)..headers.addAll(headers);

    await interceptorChain.execute(httpRequest);
  }

  /// Lists created tuned models.
  ///
  /// The [pageSize] parameter specifies the maximum number of tuned models to return
  /// (default is 10, max is 1000). The [pageToken] is used for pagination.
  /// The [filter] allows filtering by ownership or sharing status (e.g., "owner:me", "readers:everyone").
  ///
  /// Returns a [ListTunedModelsResponse] with the list of tuned models and a next page token.
  Future<ListTunedModelsResponse> list({
    int? pageSize,
    String? pageToken,
    String? filter,
  }) async {
    _validateGoogleAIOnly();

    final queryParams = <String, String>{
      if (pageSize != null) 'pageSize': pageSize.toString(),
      if (pageToken != null) 'pageToken': pageToken,
      if (filter != null) 'filter': filter,
    };

    final url = requestBuilder.buildUrl(
      '/{version}/tunedModels',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return ListTunedModelsResponse.fromJson(responseBody);
  }

  /// Gets information about a specific tuned model.
  ///
  /// The [name] is the resource name of the tuned model (e.g., "tunedModels/my-model").
  ///
  /// Returns a [TunedModel] with the model's details.
  Future<TunedModel> get({required String name}) async {
    _validateGoogleAIOnly();

    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return TunedModel.fromJson(responseBody);
  }

  /// Access operations for this tuned model.
  OperationsResource operations({required String tunedModel}) {
    return OperationsResource(
      parent: 'tunedModels/$tunedModel',
      config: config,
      httpClient: httpClient,
      interceptorChain: interceptorChain,
      requestBuilder: requestBuilder,
    );
  }

  /// Access permissions for this tuned model or corpus.
  PermissionsResource permissions({required String parent}) {
    return PermissionsResource(
      parent: parent,
      config: config,
      httpClient: httpClient,
      interceptorChain: interceptorChain,
      requestBuilder: requestBuilder,
    );
  }

  // Helper methods for streaming (copied from GoogleAIClient)

  /// Applies authentication to a request (mirrors AuthInterceptor logic).
  ///
  /// Note: This is synchronous for streaming requests. The auth provider's
  /// `getCredentials()` must be awaited by the caller before passing credentials here.
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

  /// Adds ephemeral token to request as query parameter.
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

  /// Adds API key to request based on placement strategy.
  http.Request _addApiKey(
    http.Request request,
    String apiKey,
    AuthPlacement placement,
  ) {
    if (placement == AuthPlacement.header) {
      // Add as header (only if not already present)
      if (!request.headers.containsKey('X-Goog-Api-Key')) {
        return http.Request(request.method, request.url)
          ..headers.addAll(request.headers)
          ..headers['X-Goog-Api-Key'] = apiKey
          ..bodyBytes = request.bodyBytes
          ..encoding = request.encoding;
      }
    } else {
      // Add as query parameter (only if not already present)
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

  /// Adds Bearer token to request headers.
  http.Request _addBearerToken(http.Request request, String bearerToken) {
    // Add Bearer token (only if not already present)
    if (!request.headers.containsKey('Authorization')) {
      return http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..headers['Authorization'] = 'Bearer $bearerToken'
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding;
    }

    return request;
  }

  /// Applies logging to a request (mirrors LoggingInterceptor logic).
  http.Request _applyLoggingToRequest(http.Request request) {
    // Add X-Request-ID if not present
    if (!request.headers.containsKey('X-Request-ID')) {
      final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
      final updatedRequest = http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..headers['X-Request-ID'] = requestId
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding;

      // Log request if logging is enabled
      if (config.logLevel.value <= Level.INFO.value) {
        Logger(
          'GoogleAI.HTTP',
        ).info('REQUEST [$requestId] ${request.method} ${request.url}');
      }

      return updatedRequest;
    }

    return request;
  }

  /// Maps HTTP errors for streaming (mirrors ErrorInterceptor logic).
  GoogleAIException _mapHttpErrorForStreaming(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    // Try to parse error details from response body
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

    // Map to specific exception types
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

  /// Logs streaming errors.
  void _logStreamError(Object error, String requestId) {
    if (config.logLevel.value <= Level.SEVERE.value) {
      Logger('GoogleAI.HTTP').severe('STREAM ERROR [$requestId] $error', error);
    }
  }
}
