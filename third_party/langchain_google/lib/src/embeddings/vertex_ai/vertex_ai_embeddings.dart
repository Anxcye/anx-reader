import 'package:googleai_dart/googleai_dart.dart' as g;
import 'package:langchain_core/documents.dart';
import 'package:langchain_core/embeddings.dart';
import 'package:langchain_core/language_models.dart';
import 'package:langchain_core/utils.dart';

import '../../utils/auth/http_client_auth_provider.dart';

/// {@template vertex_ai_embeddings}
/// Wrapper around GCP Vertex AI text embedding models API (Gemini embeddings).
///
/// Example:
/// ```dart
/// final authProvider = HttpClientAuthProvider(
///   credentials: ServiceAccountCredentials.fromJson({...}),
///   scopes: ['https://www.googleapis.com/auth/cloud-platform'],
/// );
/// final embeddings = VertexAIEmbeddings(
///   authProvider: authProvider,
///   project: 'your-project-id',
/// );
/// final result = await embeddings.embedQuery('Hello world');
/// ```
///
/// Vertex AI documentation:
/// https://cloud.google.com/vertex-ai/generative-ai/docs/embeddings/get-text-embeddings
///
/// ### Set up your Google Cloud Platform project
///
/// 1. [Select or create a Google Cloud project](https://console.cloud.google.com/cloud-resource-manager).
/// 2. [Make sure that billing is enabled for your project](https://cloud.google.com/billing/docs/how-to/modify-project).
/// 3. [Enable the Vertex AI API](https://console.cloud.google.com/flows/enableapi?apiid=aiplatform.googleapis.com).
/// 4. [Configure the Vertex AI location](https://cloud.google.com/vertex-ai/docs/general/locations).
///
/// ### Authentication
///
/// To create an instance of `VertexAIEmbeddings` you need to provide an
/// [HttpClientAuthProvider] that wraps your service account credentials.
///
/// Example using a service account JSON:
///
/// ```dart
/// final serviceAccountCredentials = ServiceAccountCredentials.fromJson(
///   json.decode(serviceAccountJson),
/// );
/// final authProvider = HttpClientAuthProvider(
///   credentials: serviceAccountCredentials,
///   scopes: ['https://www.googleapis.com/auth/cloud-platform'],
/// );
/// final embeddings = VertexAIEmbeddings(
///   authProvider: authProvider,
///   project: 'your-project-id',
/// );
/// ```
///
/// The service account should have the following
/// [permission](https://cloud.google.com/vertex-ai/docs/general/iam-permissions):
/// - `aiplatform.endpoints.predict`
///
/// The required [OAuth2 scope](https://developers.google.com/identity/protocols/oauth2/scopes)
/// is:
/// - `https://www.googleapis.com/auth/cloud-platform` (you can use the
///   constant [VertexAIEmbeddings.cloudPlatformScope])
///
/// See: https://cloud.google.com/vertex-ai/docs/generative-ai/access-control
///
/// ### Available models
///
/// **Latest stable models:**
///
/// - `text-embedding-005` (recommended):
///   * Output dimensions: 768 (default)
///   * Max input tokens: 3,072
///   * Supports task types and custom output dimensions
///
/// - `text-multilingual-embedding-002`:
///   * Supports 100+ languages
///   * Output dimensions: 768
///   * Max input tokens: 2,048
///
/// **Legacy models:**
/// - `textembedding-gecko@003`
/// - `textembedding-gecko@002`
/// - `textembedding-gecko@001`
///
/// The previous list may not be exhaustive or up-to-date. Check out
/// the [Vertex AI documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions)
/// for the latest stable models.
///
/// ### Task type
///
/// Embedding models support specifying a 'task type' when embedding documents.
/// The task type is used by the model to improve the quality of the embeddings.
///
/// This class automatically uses:
/// - `RETRIEVAL_DOCUMENT`: for [embedDocuments]
/// - `RETRIEVAL_QUERY`: for [embedQuery]
///
/// ### Output dimensionality
///
/// Some models support specifying a smaller number of dimensions for the
/// resulting embeddings. This can reduce storage costs with minimal
/// performance loss. Use the [dimensions] parameter to specify custom
/// dimensions.
///
/// ### Title
///
/// Embedding models support specifying a document title when embedding
/// documents. The title is used by the model to improve embedding quality.
///
/// To specify a document title, add the title to the document's metadata.
/// Then, specify the metadata key in the [docTitleKey] parameter.
///
/// Example:
/// ```dart
/// final embeddings = VertexAIEmbeddings(
///   authProvider: authProvider,
///   project: 'your-project-id',
///   docTitleKey: 'title',
/// );
/// final result = await embeddings.embedDocuments([
///   Document(
///     pageContent: 'Hello world',
///     metadata: {'title': 'Hello!'},
///   ),
/// ]);
/// ```
/// {@endtemplate}
class VertexAIEmbeddings extends Embeddings {
  /// {@macro vertex_ai_embeddings}
  VertexAIEmbeddings({
    required final HttpClientAuthProvider authProvider,
    required final String project,
    final String location = 'us-central1',
    this.model = 'text-embedding-005',
    this.dimensions,
    this.batchSize = 100,
    this.docTitleKey = 'title',
  }) : _client = g.GoogleAIClient(
         config: g.GoogleAIConfig.vertexAI(
           projectId: project,
           location: location,
           authProvider: authProvider,
         ),
       );

  /// A client for interacting with Vertex AI API.
  final g.GoogleAIClient _client;

  /// The embeddings model to use.
  ///
  /// To use the latest stable model version, specify the model name without
  /// a version number (e.g. `text-embedding-005`).
  /// To use a specific model version, specify the model version number
  /// (e.g. `text-embedding-004`).
  ///
  /// You can find a list of available models here:
  /// https://cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions#latest-stable
  final String model;

  /// The number of dimensions the resulting output embeddings should have.
  ///
  /// Supported in newer models like `text-embedding-005`.
  /// If not specified, the model's default dimensions will be used.
  final int? dimensions;

  /// The maximum number of documents to embed in a single batch request.
  ///
  /// Newer models support up to 100 or more texts per request.
  final int batchSize;

  /// The metadata key used to store the document's (optional) title.
  final String docTitleKey;

  /// Scope required for Vertex AI API calls.
  static const String cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  @override
  Future<List<List<double>>> embedDocuments(
    final List<Document> documents,
  ) async {
    final batches = chunkList(documents, chunkSize: batchSize);

    final List<List<List<double>>> embeddings = await Future.wait(
      batches.map((final batch) async {
        // Use batch API for better performance
        try {
          final response = await _client.models.batchEmbedContents(
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
          // Fallback to sequential requests if batch API fails
          if (e.code == 400 &&
              (e.message.contains('model is not specified') ||
                  e.message.contains('model'))) {
            final results = await Future.wait(
              batch.map((final doc) async {
                final response = await _client.models.embedContent(
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
            rethrow;
          }
        }
      }),
    );

    return embeddings.expand((final e) => e).toList(growable: false);
  }

  @override
  Future<List<double>> embedQuery(final String query) async {
    final response = await _client.models.embedContent(
      model: model,
      request: g.EmbedContentRequest(
        content: g.Content(parts: [g.TextPart(query)]),
        taskType: g.TaskType.retrievalQuery,
        outputDimensionality: dimensions,
      ),
    );
    return response.embedding.values;
  }

  /// {@template vertex_ai_embeddings_list_models}
  /// Returns a list of available embedding models from Vertex AI.
  ///
  /// This method filters models to return only those that support embeddings
  /// (embedContent method).
  ///
  /// Example:
  /// ```dart
  /// final embeddings = VertexAIEmbeddings(
  ///   authProvider: authProvider,
  ///   project: 'your-project-id',
  /// );
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
      final response = await _client.models.list(pageToken: pageToken);
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
    _client.close();
  }
}
