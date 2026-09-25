import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../auth/auth_provider.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/error_interceptor.dart';
import '../interceptors/logging_interceptor.dart';
import '../live/live_client.dart';
import '../models/models/operation.dart';
import '../resources/auth_tokens_resource.dart';
import '../resources/batches_resource.dart';
import '../resources/cached_contents_resource.dart';
import '../resources/corpora_resource.dart';
import '../resources/file_search_stores/file_search_stores_resource.dart';
import '../resources/files/files_resource.dart';
import '../resources/generated_files_resource.dart';
import '../resources/interactions_resource.dart';
import '../resources/models_resource.dart';
import '../resources/tuned_models_resource.dart';
import 'config.dart';
import 'interceptor_chain.dart';
import 'request_builder.dart';
import 'retry_wrapper.dart';

/// Main client for the GoogleAI API.
///
/// Provides access to all GoogleAI (Gemini) API resources through a
/// resource-based organization that mirrors the official REST API structure.
///
/// ## Resource Organization
///
/// API methods are grouped into logical resources:
/// - [models] - Content generation, embeddings, predictions, model info
/// - [tunedModels] - Custom tuned model management and generation
/// - [files] - File upload and management
/// - [generatedFiles] - Generated file (video) output management
/// - [cachedContents] - Context caching for cost/latency optimization
/// - [batches] - Batch operation management
/// - [corpora] - Corpus management for semantic retrieval
/// - [fileSearchStores] - File search store management for file-based retrieval
/// - [interactions] - Server-side state management for conversations (experimental)
/// - [authTokens] - Ephemeral token management for secure client-side auth
///
/// ## Example Usage
///
/// ```dart
/// final client = GoogleAIClient(
///   config: GoogleAIConfig(
///     authProvider: ApiKeyProvider('YOUR_API_KEY'),
///   ),
/// );
///
/// // Generate content
/// final response = await client.models.generateContent(
///   model: 'gemini-3-flash-preview',
///   request: GenerateContentRequest(
///     contents: [
///       Content(parts: [TextPart('Hello!')], role: 'user'),
///     ],
///   ),
/// );
///
/// // Upload a file
/// final file = await client.files.upload(
///   filePath: '/path/to/image.jpg',
///   mimeType: 'image/jpeg',
/// );
///
/// // Create a corpus
/// final corpus = await client.corpora.create(
///   corpus: Corpus(displayName: 'My Knowledge Base'),
/// );
///
/// client.close();
/// ```
class GoogleAIClient {
  /// Configuration.
  final GoogleAIConfig config;

  /// HTTP client.
  final http.Client _httpClient;

  /// Request builder.
  late final RequestBuilder _requestBuilder;

  /// Interceptor chain.
  late final InterceptorChain _interceptorChain;

  /// Resource for models API (generation, embeddings, predictions).
  late final ModelsResource models;

  /// Resource for tuned models API (custom model management).
  late final TunedModelsResource tunedModels;

  /// Resource for files API (file upload and management).
  late final FilesResource files;

  /// Resource for generated files API (video outputs).
  late final GeneratedFilesResource generatedFiles;

  /// Resource for cached contents API (context caching).
  late final CachedContentsResource cachedContents;

  /// Resource for batches API (batch operation management).
  late final BatchesResource batches;

  /// Resource for corpora API (semantic retrieval).
  late final CorporaResource corpora;

  /// Resource for file search stores API (file-based retrieval).
  late final FileSearchStoresResource fileSearchStores;

  /// Resource for interactions API (experimental).
  ///
  /// The Interactions API provides server-side state management for conversations
  /// with Gemini models. It enables multi-turn conversations with managed state,
  /// function calling with automatic result handling, and streaming responses.
  ///
  /// This is an experimental API and is subject to change.
  late final InteractionsResource interactions;

  /// Resource for ephemeral authentication token management.
  ///
  /// Ephemeral tokens allow secure, short-lived authentication for client-side
  /// applications. Create tokens server-side and pass them to clients without
  /// exposing the main API key.
  ///
  /// Currently only compatible with Live API.
  late final AuthTokensResource authTokens;

  /// Creates a [GoogleAIClient].
  ///
  /// Optionally accepts custom [config] for authentication and endpoint settings,
  /// and a custom [httpClient] for testing or advanced use cases.
  GoogleAIClient({GoogleAIConfig? config, http.Client? httpClient})
    : config = config ?? const GoogleAIConfig(),
      _httpClient = httpClient ?? http.Client() {
    _requestBuilder = RequestBuilder(config: this.config);

    // Interceptor order is Auth → Logging → Error
    // Retry wraps the transport layer, not in the interceptor chain
    _interceptorChain = InterceptorChain(
      httpClient: _httpClient,
      interceptors: [
        AuthInterceptor(config: this.config),
        LoggingInterceptor(config: this.config),
        const ErrorInterceptor(),
      ],
      retryWrapper: RetryWrapper(config: this.config),
    );

    // Initialize all API resources
    models = ModelsResource(
      config: this.config,
      httpClient: _httpClient,
      interceptorChain: _interceptorChain,
      requestBuilder: _requestBuilder,
    );

    tunedModels = TunedModelsResource(
      config: this.config,
      httpClient: _httpClient,
      interceptorChain: _interceptorChain,
      requestBuilder: _requestBuilder,
    );

    files = FilesResource(
      config: this.config,
      httpClient: _httpClient,
      interceptorChain: _interceptorChain,
      requestBuilder: _requestBuilder,
    );

    generatedFiles = GeneratedFilesResource(
      config: this.config,
      httpClient: _httpClient,
      interceptorChain: _interceptorChain,
      requestBuilder: _requestBuilder,
    );

    cachedContents = CachedContentsResource(
      config: this.config,
      httpClient: _httpClient,
      interceptorChain: _interceptorChain,
      requestBuilder: _requestBuilder,
    );

    batches = BatchesResource(
      config: this.config,
      httpClient: _httpClient,
      interceptorChain: _interceptorChain,
      requestBuilder: _requestBuilder,
    );

    corpora = CorporaResource(
      config: this.config,
      httpClient: _httpClient,
      interceptorChain: _interceptorChain,
      requestBuilder: _requestBuilder,
    );

    fileSearchStores = FileSearchStoresResource(
      config: this.config,
      httpClient: _httpClient,
      interceptorChain: _interceptorChain,
      requestBuilder: _requestBuilder,
    );

    interactions = InteractionsResource(
      config: this.config,
      httpClient: _httpClient,
      interceptorChain: _interceptorChain,
      requestBuilder: _requestBuilder,
    );

    authTokens = AuthTokensResource(
      config: this.config,
      httpClient: _httpClient,
      interceptorChain: _interceptorChain,
      requestBuilder: _requestBuilder,
    );
  }

  /// Creates a [GoogleAIClient] from an environment variable.
  ///
  /// By default, uses `GOOGLE_GENAI_API_KEY` (matching the official js-genai SDK).
  ///
  /// Throws a [StateError] if the environment variable is not set or empty.
  ///
  /// Example:
  /// ```dart
  /// // Uses GOOGLE_GENAI_API_KEY by default
  /// final client = GoogleAIClient.fromEnvironment();
  ///
  /// // Or specify a custom environment variable
  /// final client = GoogleAIClient.fromEnvironment(envVarName: 'MY_API_KEY');
  /// ```
  factory GoogleAIClient.fromEnvironment({
    String envVarName = 'GOOGLE_GENAI_API_KEY',
    ApiVersion apiVersion = ApiVersion.v1beta,
    Duration timeout = const Duration(minutes: 2),
    RetryPolicy retryPolicy = RetryPolicy.defaultPolicy,
    http.Client? httpClient,
  }) {
    final apiKey = Platform.environment[envVarName];
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError(
        'Environment variable $envVarName is not set. '
        'Set it to your Google AI API key.',
      );
    }
    return GoogleAIClient(
      config: GoogleAIConfig(
        authProvider: ApiKeyProvider(apiKey),
        apiVersion: apiVersion,
        timeout: timeout,
        retryPolicy: retryPolicy,
      ),
      httpClient: httpClient,
    );
  }

  /// Gets the status of a long-running operation.
  ///
  /// This is a convenience method that works with any operation name, regardless
  /// of which resource it belongs to. For resource-specific operation methods,
  /// use the operations sub-resource on the parent resource (e.g.,
  /// `models.operations(model: ...).get()` or `tunedModels.operations(parent: ...).get()`).
  ///
  /// The [name] is the operation resource name (e.g., "operations/abc123",
  /// "tunedModels/my-model/operations/abc123").
  ///
  /// Returns the [Operation] with its current status.
  Future<Operation> getOperation({required String name}) async {
    final url = _requestBuilder.buildUrl('/v1beta/$name');

    final headers = _requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await _interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Operation.fromJson(responseBody);
  }

  /// Creates a [LiveClient] for the Gemini Live API.
  ///
  /// The Live API provides real-time bidirectional WebSocket streaming
  /// for audio, video, and text conversations.
  ///
  /// ## Example
  ///
  /// ```dart
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
  /// // Send text
  /// session.sendText('Hello!');
  ///
  /// // Handle responses
  /// await for (final message in session.messages) {
  ///   switch (message) {
  ///     case BidiGenerateContentServerContent(:final modelTurn):
  ///       // Handle response
  ///     case BidiGenerateContentToolCall(:final functionCalls):
  ///       session.sendToolResponse(responses);
  ///   }
  /// }
  ///
  /// await session.close();
  /// await liveClient.close();
  /// ```
  LiveClient createLiveClient() {
    return LiveClient(config: config);
  }

  /// Closes the HTTP client and releases resources.
  ///
  /// Call this method when you're done using the client to free up resources.
  void close() {
    _httpClient.close();
  }
}
