import 'package:googleai_dart/googleai_dart.dart' as g;
import 'package:http/http.dart' as http;
import 'package:langchain_core/documents.dart';
import 'package:langchain_core/embeddings.dart';
import 'package:langchain_core/language_models.dart';
import 'package:langchain_core/utils.dart';

/// {@template google_generative_ai_embeddings}
/// Wrapper around Google AI embedding models API
///
/// Example:
/// ```dart
/// final embeddings = GoogleGenerativeAIEmbeddings(
///   apiKey: 'your-api-key',
/// );
/// final result = await embeddings.embedQuery('Hello world');
/// ```
///
/// Google AI documentation: https://ai.google.dev/
///
/// ### Available models
///
/// - `gemini-embedding-001` (recommended, stable)
///   * Default dimensions: 3072
///   * Supports flexible dimensions: 128-3072 (recommended: 768, 1536, 3072)
///   * Uses Matryoshka Representation Learning (MRL) technique
///
/// Legacy models:
/// - `gemini-embedding-001`
/// - `embedding-gecko-001`
///
/// The previous list of models may not be exhaustive or up-to-date. Check out
/// the [Google AI embeddings documentation](https://ai.google.dev/gemini-api/docs/embeddings)
/// for the latest list of available models.
///
/// ### Task type
///
/// Google AI support specifying a 'task type' when embedding documents.
/// The task type is then used by the model to improve the quality of the
/// embeddings.
///
/// This class uses the specifies the following task type:
/// - `retrievalDocument`: for [embedDocuments]
/// - `retrievalQuery`: for [embedQuery]
///
/// ### Reduced dimensionality
///
/// Some embedding models support specifying a smaller number of dimensions
/// for the resulting embeddings. This can be useful when you want to save
/// computing and storage costs with minor performance loss. Use the
/// [dimensions] parameter to specify the number of dimensions.
///
/// You can also use this feature to reduce the dimensions to 2D or 3D for
/// visualization purposes.
///
/// ### Title
///
/// Google AI support specifying a document title when embedding documents.
/// The title is then used by the model to improve the quality of the
/// embeddings.
///
/// To specify a document title, add the title to the document's metadata.
/// Then, specify the metadata key in the [docTitleKey] parameter.
///
/// Example:
/// ```dart
/// final embeddings = GoogleGenerativeAIEmbeddings(
///   apiKey: 'your-api-key',
/// );
/// final result = await embeddings.embedDocuments([
///   Document(
///     pageContent: 'Hello world',
///     metadata: {'title': 'Hello!'},
///   ),
/// ]);
/// ```
/// {@endtemplate}
class GoogleGenerativeAIEmbeddings extends Embeddings {
  /// Create a new [GoogleGenerativeAIEmbeddings] instance.
  ///
  /// Main configuration options:
  /// - `apiKey`: your Google AI API key. You can find your API key in the
  ///   [Google AI Studio dashboard](https://aistudio.google.com/app/apikey).
  /// - `model`: the embeddings model to use. You can find a list of available
  ///   embedding models here: https://ai.google.dev/models/gemini
  /// - [GoogleGenerativeAIEmbeddings.dimensions]
  /// - [GoogleGenerativeAIEmbeddings.batchSize]
  /// - [GoogleGenerativeAIEmbeddings.docTitleKey]
  ///
  /// Advance configuration options:
  /// - `baseUrl`: the base URL to use. Defaults to Google AI's API URL. You can
  ///   override this to use a different API URL, or to use a proxy.
  /// - `headers`: global headers to send with every request. You can use
  ///   this to set custom headers, or to override the default headers.
  /// - `queryParams`: global query parameters to send with every request. You
  ///   can use this to set custom query parameters.
  /// - `retries`: the number of retries to attempt if a request fails.
  /// - `client`: the HTTP client to use. You can set your own HTTP client if
  ///   you need further customization (e.g. to use a Socks5 proxy).
  GoogleGenerativeAIEmbeddings({
    final String? apiKey,
    final String? baseUrl,
    final Map<String, String>? headers,
    final Map<String, String>? queryParams,
    final int retries = 3,
    final http.Client? client,
    this.model = 'gemini-embedding-001',
    this.dimensions,
    this.batchSize = 100,
    this.docTitleKey = 'title',
  }) {
    _googleAiClient = g.GoogleAIClient(
      config: g.GoogleAIConfig(
        authProvider: apiKey != null ? g.ApiKeyProvider(apiKey) : null,
        baseUrl: baseUrl ?? 'https://generativelanguage.googleapis.com',
        defaultHeaders: headers ?? const {},
        defaultQueryParams: queryParams ?? const {},
        retryPolicy: g.RetryPolicy(maxRetries: retries),
      ),
      httpClient: client,
    );
  }

  /// A client for interacting with Google AI API.
  late g.GoogleAIClient _googleAiClient;

  /// The embeddings model to use.
  String model;

  /// The number of dimensions the resulting output embeddings should have.
  /// Supported in `gemini-embedding-001` and later models (not in legacy `gemini-embedding-001`).
  int? dimensions;

  /// The maximum number of documents to embed in a single batch request.
  int batchSize;

  /// The metadata key used to store the document's (optional) title.
  String docTitleKey;

  @override
  Future<List<List<double>>> embedDocuments(
    final List<Document> documents,
  ) async {
    final batches = chunkList(documents, chunkSize: batchSize);

    final List<List<List<double>>> embeddings = await Future.wait(
      batches.map((final batch) async {
        // Use batch API for better performance
        try {
          final response = await _googleAiClient.models.batchEmbedContents(
            model: model,
            request: g.BatchEmbedContentsRequest(
              requests: batch
                  .map(
                    (final doc) => g.EmbedContentRequest(
                      content: g.Content(parts: [g.TextPart(doc.pageContent)]),
                      taskType: g.TaskType.retrievalDocument,
                      title: doc.metadata[docTitleKey] as String?,
                      outputDimensionality: dimensions,
                    ),
                  )
                  .toList(),
            ),
          );
          return response.embeddings.map((e) => e.values).toList();
        } on g.ApiException catch (e) {
          // Fallback to sequential requests if batch API fails with specific error
          // This can happen if the API expects model field in each request,
          // which is an API/client schema mismatch
          if (e.code == 400 &&
              (e.message.contains('model is not specified') ||
                  e.message.contains('model'))) {
            // Use sequential requests as fallback
            final results = await Future.wait(
              batch.map((final doc) async {
                final response = await _googleAiClient.models.embedContent(
                  model: model,
                  request: g.EmbedContentRequest(
                    content: g.Content(parts: [g.TextPart(doc.pageContent)]),
                    taskType: g.TaskType.retrievalDocument,
                    title: doc.metadata[docTitleKey] as String?,
                    outputDimensionality: dimensions,
                  ),
                );
                return response.embedding.values;
              }),
            );
            return results;
          } else {
            // For other API errors, rethrow to let caller handle them
            rethrow;
          }
        }
      }),
    );

    return embeddings.expand((final e) => e).toList(growable: false);
  }

  @override
  Future<List<double>> embedQuery(final String query) async {
    final response = await _googleAiClient.models.embedContent(
      model: model,
      request: g.EmbedContentRequest(
        content: g.Content(parts: [g.TextPart(query)]),
        taskType: g.TaskType.retrievalQuery,
        outputDimensionality: dimensions,
      ),
    );
    return response.embedding.values;
  }

  /// {@template google_generative_ai_embeddings_list_models}
  /// Returns a list of available embedding models from Google AI.
  ///
  /// This method filters models to return only those that support embeddings
  /// (embedContent method).
  ///
  /// Example:
  /// ```dart
  /// final embeddings = GoogleGenerativeAIEmbeddings(apiKey: '...');
  /// final models = await embeddings.listModels();
  /// for (final model in models) {
  ///   print('${model.id} - ${model.displayName}');
  ///   print('  Input limit: ${model.inputTokenLimit}');
  /// }
  /// ```
  /// {@endtemplate}
  @override
  Future<List<ModelInfo>> listModels() async {
    final models = <g.Model>[];
    String? pageToken;

    // Paginate through all models
    do {
      final response = await _googleAiClient.models.list(pageToken: pageToken);
      models.addAll(response.models);
      pageToken = response.nextPageToken;
    } while (pageToken != null);

    // Filter to only embedding-capable models (those supporting embedContent)
    return models
        .where(_isEmbeddingModel)
        .map(
          (final m) => ModelInfo(
            id: _extractModelId(m.name),
            displayName: m.displayName,
            description: m.description,
            inputTokenLimit: m.inputTokenLimit,
            outputTokenLimit: m.outputTokenLimit,
          ),
        )
        .toList();
  }

  /// Returns true if the model supports embeddings (embedContent).
  static bool _isEmbeddingModel(final g.Model model) {
    return model.supportedGenerationMethods?.contains('embedContent') ?? false;
  }

  /// Extracts the model ID from the full model name.
  static String _extractModelId(final String name) {
    const prefix = 'models/';
    if (name.startsWith(prefix)) {
      return name.substring(prefix.length);
    }
    return name;
  }

  /// Closes the client and cleans up any resources associated with it.
  void close() {
    _googleAiClient.close();
  }
}
