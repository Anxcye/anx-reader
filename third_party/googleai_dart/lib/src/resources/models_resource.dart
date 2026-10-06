import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../auth/auth_provider.dart';
import '../client/config.dart';
import '../errors/exceptions.dart';
import '../models/batch/embed_content_batch.dart';
import '../models/batch/generate_content_batch.dart';
import '../models/content/part.dart';
import '../models/embeddings/batch_embed_contents_request.dart';
import '../models/embeddings/batch_embed_contents_response.dart';
import '../models/embeddings/content_embedding.dart';
import '../models/embeddings/embed_content_request.dart';
import '../models/embeddings/embed_content_response.dart';
import '../models/embeddings/task_type.dart';
import '../models/generation/count_tokens_request.dart';
import '../models/generation/count_tokens_response.dart';
import '../models/generation/generate_answer_request.dart';
import '../models/generation/generate_answer_response.dart';
import '../models/generation/generate_content_request.dart';
import '../models/generation/generate_content_response.dart';
import '../models/models/list_models_response.dart';
import '../models/models/model.dart';
import '../models/prediction/predict_long_running_operation.dart';
import '../models/prediction/predict_long_running_request.dart';
import '../models/prediction/predict_request.dart';
import '../models/prediction/predict_response.dart';
import '../utils/request_id.dart';
import '../utils/streaming_parser.dart';
import 'base_resource.dart';
import 'operations_resource.dart';

/// Resource for the Models API.
///
/// Provides access to model-related operations including content generation,
/// token counting, embeddings, and model information retrieval.
class ModelsResource extends ResourceBase {
  /// Creates a [ModelsResource].
  ModelsResource({
    required super.config,
    required super.httpClient,
    required super.interceptorChain,
    required super.requestBuilder,
  });

  /// Generates content using the specified model.
  ///
  /// The [model] parameter specifies which model to use (e.g., "gemini-pro").
  /// The [request] contains the conversation history and generation config.
  /// The optional [abortTrigger] allows canceling the request before completion.
  ///
  /// Returns a [GenerateContentResponse] containing the model's response.
  ///
  /// Throws [AbortedException] if the request is aborted via [abortTrigger].
  Future<GenerateContentResponse> generateContent({
    required String model,
    required GenerateContentRequest request,
    Future<void>? abortTrigger,
  }) async {
    final url = requestBuilder.buildUrl(
      '/{version}/models/$model:generateContent',
      // No endpoint-specific config needed for basic generation
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

  /// Generates content using streaming.
  ///
  /// The [model] parameter specifies which model to use.
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
    required String model,
    required GenerateContentRequest request,
    Future<void>? abortTrigger,
  }) async* {
    // Build URL and headers (uses endpoint config precedence)
    final url = requestBuilder.buildUrl(
      '/{version}/models/$model:streamGenerateContent',
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

  /// Counts tokens in the provided content.
  ///
  /// The [model] parameter specifies which model to use for token counting.
  /// The [request] contains the content to count tokens for.
  /// The optional [abortTrigger] allows canceling the request before completion.
  ///
  /// Returns a [CountTokensResponse] with the token count.
  ///
  /// Throws [AbortedException] if the request is aborted via [abortTrigger].
  Future<CountTokensResponse> countTokens({
    required String model,
    required CountTokensRequest request,
    Future<void>? abortTrigger,
  }) async {
    final url = requestBuilder.buildUrl('/{version}/models/$model:countTokens');

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
    return CountTokensResponse.fromJson(responseBody);
  }

  /// Generates content using a dynamic model ID.
  ///
  /// This method is similar to [generateContent] but accepts a dynamicId parameter
  /// for models that use dynamic identifiers (e.g., live content generation).
  ///
  /// The [dynamicId] specifies the model to use (format: "models/{model}").
  /// The [request] contains the content generation parameters.
  /// The optional [abortTrigger] allows canceling the request before completion.
  ///
  /// Returns a [GenerateContentResponse] with the generated content.
  ///
  /// Throws [AbortedException] if the request is aborted via [abortTrigger].
  Future<GenerateContentResponse> dynamicGenerateContent({
    required String dynamicId,
    required GenerateContentRequest request,
    Future<void>? abortTrigger,
  }) async {
    final url = requestBuilder.buildUrl(
      '/{version}/dynamic/$dynamicId:generateContent',
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

  /// Generates streaming content using a dynamic model ID.
  ///
  /// This method is similar to [streamGenerateContent] but accepts a dynamicId parameter
  /// for models that use dynamic identifiers (e.g., live content generation).
  ///
  /// The [dynamicId] specifies the model to use (format: "models/{model}").
  /// The [request] contains the content generation parameters.
  /// The optional [abortTrigger] allows canceling the stream mid-generation.
  ///
  /// Returns a stream of [GenerateContentResponse] chunks.
  ///
  /// Throws [AbortedException] if the request is aborted via [abortTrigger].
  Stream<GenerateContentResponse> dynamicStreamGenerateContent({
    required String dynamicId,
    required GenerateContentRequest request,
    Future<void>? abortTrigger,
  }) async* {
    // Build URL and headers
    final url = requestBuilder.buildUrl(
      '/{version}/dynamic/$dynamicId:streamGenerateContent',
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

  /// Embeds content.
  ///
  /// The [model] parameter specifies which embedding model to use.
  /// The [request] contains the content to embed.
  /// The optional [abortTrigger] allows canceling the request before completion.
  ///
  /// Returns an [EmbedContentResponse] with the embedding.
  ///
  /// Throws [AbortedException] if the request is aborted via [abortTrigger].
  Future<EmbedContentResponse> embedContent({
    required String model,
    required EmbedContentRequest request,
    Future<void>? abortTrigger,
  }) async {
    // Vertex AI uses the predict endpoint for embeddings
    if (config.apiMode == ApiMode.vertexAI) {
      return _embedContentViaPredict(model, request, abortTrigger);
    }

    // Google AI uses the embedContent endpoint
    final url = requestBuilder.buildUrl(
      '/{version}/models/$model:embedContent',
      // No endpoint-specific config needed
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
    return EmbedContentResponse.fromJson(responseBody);
  }

  /// Embeds content using Vertex AI's predict endpoint.
  ///
  /// Vertex AI uses a different endpoint structure for embeddings compared to
  /// Google AI. This method transforms the request/response to maintain API compatibility.
  Future<EmbedContentResponse> _embedContentViaPredict(
    String model,
    EmbedContentRequest request,
    Future<void>? abortTrigger,
  ) async {
    // Extract text from content parts
    final textParts = request.content.parts.whereType<TextPart>();
    if (textParts.isEmpty) {
      throw ArgumentError('Content must contain at least one text part');
    }
    final text = textParts.first.text;

    // Build instance in Vertex AI format
    final instance = <String, dynamic>{
      'content': text,
      if (request.taskType != null)
        'task_type': taskTypeToString(request.taskType!),
      if (request.title != null) 'title': request.title,
    };

    // Build parameters
    final parameters = <String, dynamic>{
      if (request.outputDimensionality != null)
        'outputDimensionality': request.outputDimensionality,
    };

    // Call predict endpoint
    final predictResponse = await predict(
      model: model,
      instances: [instance],
      parameters: parameters.isNotEmpty ? parameters : null,
    );

    // Transform response: predictions[0].embeddings.values -> embedding.values
    if (predictResponse.predictions.isEmpty) {
      throw const ApiException(
        code: 500,
        message: 'No predictions returned from Vertex AI embedding endpoint',
      );
    }

    final prediction =
        predictResponse.predictions.first as Map<String, dynamic>;
    final embeddings = prediction['embeddings'] as Map<String, dynamic>;
    final valuesList = embeddings['values'] as List;
    final values = valuesList.map((e) => (e as num).toDouble()).toList();

    return EmbedContentResponse(embedding: ContentEmbedding(values: values));
  }

  /// Generates multiple embedding vectors from the input content.
  ///
  /// This is a synchronous batch operation that returns embeddings immediately.
  /// For asynchronous batch processing, use [asyncBatchEmbedContent].
  ///
  /// The [model] parameter specifies which embedding model to use
  /// (e.g., "text-embedding-004").
  /// The [request] contains a list of embed content requests.
  ///
  /// Returns a [BatchEmbedContentsResponse] with embeddings for each request,
  /// in the same order as provided.
  ///
  /// Note: Vertex AI does not support batch embeddings via a single API call.
  /// Use [embedContent] in a loop instead, or let the client library handle
  /// the fallback automatically.
  Future<BatchEmbedContentsResponse> batchEmbedContents({
    required String model,
    required BatchEmbedContentsRequest request,
  }) async {
    // Vertex AI doesn't have a batch embeddings endpoint
    // Throw ApiException so the fallback in langchain_google can catch it
    if (config.apiMode == ApiMode.vertexAI) {
      throw const ApiException(
        code: 400,
        message:
            'model is not specified', // Trigger fallback in langchain_google
      );
    }

    final url = requestBuilder.buildUrl(
      '/{version}/models/$model:batchEmbedContents',
    );

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    // Add model to each request as required by the API
    final requestJson = request.toJson();
    final requests = (requestJson['requests'] as List<dynamic>).map((r) {
      final requestMap = r as Map<String, dynamic>;
      return {...requestMap, 'model': 'models/$model'};
    }).toList();

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode({'requests': requests});

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return BatchEmbedContentsResponse.fromJson(responseBody);
  }

  /// Enqueues a batch of embed content requests for asynchronous processing.
  ///
  /// This is an asynchronous batch operation that returns immediately with
  /// batch metadata. Use [getEmbedBatch], [listBatches], or [LROPoller] to monitor
  /// the batch processing status.
  ///
  /// The [model] parameter specifies which embedding model to use
  /// (e.g., "text-embedding-004").
  /// The [batch] contains the batch configuration including input configuration.
  /// If [batch.model] is not set, it will be auto-populated from [model].
  ///
  /// Returns an [EmbedContentBatch] with the batch job details including
  /// the batch name which can be used to track progress.
  Future<EmbedContentBatch> asyncBatchEmbedContent({
    required String model,
    required EmbedContentBatch batch,
  }) async {
    // Auto-populate batch.model from method parameter if not set
    final effectiveBatch = batch.model == null
        ? batch.copyWith(model: 'models/$model')
        : batch;

    final url = requestBuilder.buildUrl(
      '/{version}/models/$model:asyncBatchEmbedContent',
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

  /// Generates a grounded answer from the model.
  ///
  /// The [model] parameter specifies which model to use (e.g., "aqa").
  /// The [request] contains the question, grounding sources, and configuration.
  /// The optional [abortTrigger] allows canceling the request before completion.
  ///
  /// Grounding sources can be:
  /// - Inline passages provided in the request
  /// - Content from the Semantic Retriever API
  ///
  /// Returns a [GenerateAnswerResponse] with the grounded answer and metadata.
  ///
  /// Note: Only supports queries in English.
  ///
  /// Throws [AbortedException] if the request is aborted via [abortTrigger].
  Future<GenerateAnswerResponse> generateAnswer({
    required String model,
    required GenerateAnswerRequest request,
    Future<void>? abortTrigger,
  }) async {
    if (config.apiMode == ApiMode.vertexAI) {
      throw UnsupportedError(
        'generateAnswer is only available with Google AI (Gemini API). '
        'Vertex AI uses grounding with Vertex AI Search instead. '
        'See: https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/grounding',
      );
    }

    final url = requestBuilder.buildUrl(
      '/{version}/models/$model:generateAnswer',
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
    return GenerateAnswerResponse.fromJson(responseBody);
  }

  /// Performs a synchronous prediction request.
  ///
  /// Used for models like Veo for video generation. The [model] parameter
  /// specifies which model to use (e.g., "veo-001").
  ///
  /// The [instances] are the required input data for the prediction,
  /// and [parameters] are optional prediction parameters.
  ///
  /// Returns a [PredictResponse] with the prediction outputs.
  Future<PredictResponse> predict({
    required String model,
    required List<dynamic> instances,
    dynamic parameters,
  }) async {
    final url = requestBuilder.buildUrl('/{version}/models/$model:predict');

    final headers = requestBuilder.buildHeaders();

    final request = PredictRequest(
      instances: instances,
      parameters: parameters,
    );

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(request.toJson());

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return PredictResponse.fromJson(responseBody);
  }

  /// Performs an asynchronous prediction request that returns a long-running operation.
  ///
  /// Used for models like Veo for video generation that take longer to process.
  /// The [model] parameter specifies which model to use (e.g., "veo-001").
  ///
  /// The [instances] are the required input data for the prediction,
  /// and [parameters] are optional prediction parameters.
  ///
  /// Returns a [PredictLongRunningOperation] that can be polled for status and results.
  /// Use the Operations API to check the status of the long-running operation.
  Future<PredictLongRunningOperation> predictLongRunning({
    required String model,
    required List<dynamic> instances,
    dynamic parameters,
  }) async {
    final url = requestBuilder.buildUrl(
      '/{version}/models/$model:predictLongRunning',
    );

    final headers = requestBuilder.buildHeaders();

    final request = PredictLongRunningRequest(
      instances: instances,
      parameters: parameters,
    );

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(request.toJson());

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return PredictLongRunningOperation.fromJson(responseBody);
  }

  /// Lists all available models.
  ///
  /// The [pageSize] parameter specifies the maximum number of models to return
  /// (default is 50). The [pageToken] is used for pagination.
  ///
  /// Returns a [ListModelsResponse] with the list of models and a next page token.
  Future<ListModelsResponse> list({int? pageSize, String? pageToken}) async {
    final queryParams = <String, String>{
      if (pageSize != null) 'pageSize': pageSize.toString(),
      if (pageToken != null) 'pageToken': pageToken,
    };

    final url = requestBuilder.buildUrl(
      '/{version}/models',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return ListModelsResponse.fromJson(responseBody);
  }

  /// Gets details for a specific model.
  ///
  /// The [model] parameter specifies which model to retrieve (e.g., "gemini-pro").
  ///
  /// Returns a [Model] with the model's details.
  Future<Model> get({required String model}) async {
    final url = requestBuilder.buildUrl('/{version}/models/$model');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Model.fromJson(responseBody);
  }

  /// Creates a batch of generate content requests.
  ///
  /// The [model] parameter specifies which model to use (e.g., "gemini-pro").
  /// The [batch] contains the batch configuration including requests.
  /// If [batch.model] is not set, it will be auto-populated from [model].
  ///
  /// Returns a [GenerateContentBatch] with the batch job details.
  Future<GenerateContentBatch> batchGenerateContent({
    required String model,
    required GenerateContentBatch batch,
  }) async {
    // Auto-populate batch.model from method parameter if not set
    final effectiveBatch = batch.model == null
        ? batch.copyWith(model: 'models/$model')
        : batch;

    final url = requestBuilder.buildUrl(
      '/{version}/models/$model:batchGenerateContent',
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

  /// Access operations for this model.
  OperationsResource operations({required String model}) {
    return OperationsResource(
      parent: 'models/$model',
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

  /// Adds ephemeral token to request as query parameter.
  http.Request _addEphemeralToken(http.Request request, String token) {
    final uri = request.url;
    // Don't overwrite existing 'access_token' query parameter
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
