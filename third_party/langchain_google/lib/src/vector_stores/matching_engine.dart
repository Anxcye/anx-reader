import 'dart:convert';

import 'package:gcloud/storage.dart';
import 'package:http/http.dart' as http;
import 'package:langchain_core/documents.dart';
import 'package:langchain_core/exceptions.dart';
import 'package:langchain_core/vector_stores.dart';
import 'package:uuid/uuid.dart';
import 'package:vertex_ai/vertex_ai.dart';

import 'types.dart';

/// A vector store that uses Vertex AI Vector Search
/// (former Vertex AI Matching Engine).
///
/// Vertex AI Vector Search provides a high-scale low latency vector database.
///
/// This vector stores relies on two GCP services:
/// - Vertex AI Matching Engine: to store the vectors and perform similarity
///   searches.
/// - Google Cloud Storage: to store the documents and the vectors to add to
///   the index.
///
/// Vertex AI Matching Engine documentation:
/// https://cloud.google.com/vertex-ai/docs/matching-engine/overview
///
/// Currently it only supports Batch Updates, it doesn't support Streaming
/// Updates. Batch Updates take around 1h to be applied to the index. See:
/// https://cloud.google.com/vertex-ai/docs/matching-engine/update-rebuild-index#update_index_content_with_batch_updates
///
/// ### Set up your Google Cloud Platform project
///
/// 1. [Select or create a Google Cloud project](https://console.cloud.google.com/cloud-resource-manager).
/// 2. [Make sure that billing is enabled for your project](https://cloud.google.com/billing/docs/how-to/modify-project).
/// 3. [Enable the Vertex AI API](https://console.cloud.google.com/flows/enableapi?apiid=aiplatform.googleapis.com).
/// 4. [Configure the Vertex AI location](https://cloud.google.com/vertex-ai/docs/general/locations).
///
/// ### Create your Vertex AI Vector Search index
///
/// To use this vector store, first you need to create a Vertex AI Vector
/// Search index and expose it in a Vertex AI index endpoint.
///
/// You can use [vertex_ai](https://pub.dev/packages/vertex_ai) Dart package
/// to do that.
///
/// Check out this sample script that creates the index and index endpoint
/// ready to be used with LangChains.dart:
/// https://github.com/davidmigloz/langchain_dart/tree/main/examples/vertex_ai_matching_engine_setup
///
/// ### Authentication
///
/// To create an instance of `VertexAIMatchingEngine` you need to provide an
/// HTTP client that handles authentication. The easiest way to do this is to
/// use [`AuthClient`](https://pub.dev/documentation/googleapis_auth/latest/googleapis_auth/AuthClient-class.html)
/// from the [googleapis_auth](https://pub.dev/packages/googleapis_auth)
/// package.
///
/// There are several ways to obtain an `AuthClient` depending on your use case.
/// Check out the [googleapis_auth](https://pub.dev/packages/googleapis_auth)
/// package documentation for more details.
///
/// Example using a service account JSON:
///
/// ```dart
/// final serviceAccountCredentials = ServiceAccountCredentials.fromJson(
///   json.decode(serviceAccountJson),
/// );
/// final authClient = await clientViaServiceAccount(
///   serviceAccountCredentials,
///   VertexAIMatchingEngine.cloudPlatformScopes,
/// );
/// final vectorStore = VertexAIMatchingEngine(
///   httpClient: authClient,
///   project: 'your-project-id',
///   location: 'europe-west1',
///   indexId: 'your-index-id',
///   gcsBucketName: 'your-gcs-bucket-name',
///   embeddings: embeddings,
/// );
/// ```
///
/// The minimum required permissions for the service account if you just need
/// to query the index are:
/// - `aiplatform.indexes.get`
/// - `aiplatform.indexEndpoints.get`
/// - `aiplatform.indexEndpoints.queryVectors`
/// - `storage.objects.get`
///
/// If you also need to add new vectors to the index, the service account
/// should have the following permissions as well:
/// - `aiplatform.indexes.update`
/// - `storage.objects.create`
/// - `storage.objects.update`
///
/// The required[OAuth2 scope](https://developers.google.com/identity/protocols/oauth2/scopes)
/// is:
/// - `https://www.googleapis.com/auth/cloud-platform`
/// - `https://www.googleapis.com/auth/devstorage.full_control`
///
/// You can use the constant `VertexAIMatchingEngine.cloudPlatformScopes`.
///
/// ### Vector attributes filtering
///
/// Vertex AI Matching Engine allows you to add attributes to the vectors that
/// you can later use to restrict vector matching searches to a subset of the
/// index.
///
/// To add attributes to the vectors, add a `restricts` key to the document
/// metadata with the attributes that you want to add. For example:
/// ```dart
/// final doc = Document(
///  id: 'doc1',
///  pageContent: 'The cat is a domestic species of small carnivorous mammal',
///  metadata: {
///    'restricts': [
///      {
///        'namespace': 'class',
///        'allow': ['cat', 'pet']
///      },
///      {
///        'namespace': 'category',
///        'allow': ['feline']
///      }
///    ],
///    'otherMetadata': '...',
///  },
/// );
/// ```
///
/// Check out the documentation for more details:
/// https://cloud.google.com/vertex-ai/docs/matching-engine/filtering
///
/// After adding the attributes to the documents, you can use the use them to
/// restrict the similarity search results. Example:
///
/// ```dart
/// final vectorStore = VertexAIMatchingEngine(...);
/// final res = await vectorStore.similaritySearch(
///   query: 'What should I feed my cat?',
///   config: VertexAIMatchingEngineSimilaritySearch(
///     k: 5,
///     scoreThreshold: 0.8,
///     filters: [
///       const VertexAIMatchingEngineFilter(
///         namespace: 'class',
///         allowList: ['cat'],
///       ),
///     ],
///   ),
/// );
/// ```
class VertexAIMatchingEngine extends VectorStore {
  /// Creates a new Vertex AI Matching Engine vector store.
  ///
  /// - [httpClient] An authenticated HTTP client.
  /// - [project] The ID of the Google Cloud project to use.
  /// - [location] The Google Cloud location to use. Vertex AI and
  ///   Cloud Storage should have the same location.
  /// - [rootUrl] The root URL of the Vertex AI API. By default it uses
  ///   `https://$location-aiplatform.googleapis.com/`.
  /// - [queryRootUrl] The root URL of the Vertex AI Matching Engine index
  ///   endpoint. For example: `https://your-query-root-url.vdb.vertexai.goog/`.
  ///   Only needed if you have multiple endpoints for the same index.
  /// - [indexId] The ID of the index to use. You can find this ID when you
  ///   create the index or in the Vertex AI console.
  /// - [indexEndpointId] The ID of the IndexEndpoint to use. Only needed if
  ///   you have multiple endpoints for the same index.
  /// - [deployedIndexId] The ID of the DeployedIndex to use. Only needed if
  ///   you have multiple deployed indexes for the same index.
  /// - [gcsBucketName] The name of the Google Cloud Storage bucket to use to
  ///   store the documents and the vectors to add to the index.
  /// - [gcsDocumentsFolder] The folder in the Google Cloud Storage bucket where
  ///   the documents are stored.
  /// - [gcsIndexesFolder] The folder in the Google Cloud Storage bucket where
  ///   the vectors to add to the index are stored.
  /// - [completeOverwriteWhenAdding] If true, when new vectors are added to
  ///   the index, the previous ones are deleted. If false, the new vectors are
  ///   added to the index without deleting the previous ones.
  VertexAIMatchingEngine({
    required final http.Client httpClient,
    required this.project,
    required this.location,
    final String? rootUrl,
    final String? queryRootUrl,
    required this.indexId,
    final String? indexEndpointId,
    final String? deployedIndexId,
    required this.gcsBucketName,
    this.gcsDocumentsFolder = 'documents',
    this.gcsIndexesFolder = 'indexes',
    this.completeOverwriteWhenAdding = false,
    required super.embeddings,
  }) : _httpClient = httpClient,
       _managementClient = VertexAIMatchingEngineClient(
         httpClient: httpClient,
         project: project,
         location: location,
         rootUrl: rootUrl ?? 'https://$location-aiplatform.googleapis.com/',
       ),
       _storageClient = Storage(httpClient, project),
       _queryRootUrl = queryRootUrl,
       _indexEndpointId = indexEndpointId,
       _deployedIndexId = deployedIndexId;

  /// An authenticated HTTP client.
  final http.Client _httpClient;

  /// A client for querying the Vertex AI Matching Engine index.
  VertexAIMatchingEngineClient? _queryClient;

  /// A client for managing the Vertex AI Matching Engine index.
  final VertexAIMatchingEngineClient _managementClient;

  /// A client for interacting with Google Cloud Storage.
  final Storage _storageClient;

  /// The ID of the Google Cloud project to use.
  final String project;

  /// The Google Cloud location to use. Vertex AI and Cloud Storage should have
  /// the same location.
  final String location;

  /// The id of the index to use.
  final String indexId;

  /// The Google Cloud Storage bucket to use.
  final String gcsBucketName;

  /// The folder in the Google Cloud Storage bucket where the documents are
  /// stored.
  final String gcsDocumentsFolder;

  /// The folder in the Google Cloud Storage bucket where the vectors to add
  /// to the index are stored.
  final String gcsIndexesFolder;

  /// If true, when new vectors are added to the index, the previous ones are
  /// deleted. If false, the new vectors are added to the index without
  /// deleting the previous ones.
  final bool completeOverwriteWhenAdding;

  /// The root URL of the Vertex AI Matching Engine index endpoint.
  String? _queryRootUrl;

  /// The ID of the index endpoint to use.
  String? _indexEndpointId;

  /// The ID of the deployed index to use.
  String? _deployedIndexId;

  /// A UUID generator.
  final _uuid = const Uuid();

  /// Scopes required for Vertex AI and Cloud Storage API calls.
  static const List<String> cloudPlatformScopes = [
    VertexAIGenAIClient.cloudPlatformScope,
    ...Storage.SCOPES,
  ];

  @override
  Future<List<String>> addVectors({
    required final List<List<double>> vectors,
    required final List<Document> documents,
  }) async {
    assert(vectors.length == documents.length);

    final bucket = _storageClient.bucket(gcsBucketName);
    final List<String> ids = [];
    final List<String> vectorsJsons = [];

    // Write each document to GCS (in gcsDocumentsFolder)
    for (var i = 0; i < documents.length; i++) {
      Document doc = documents[i];
      if (doc.id == null) {
        doc = doc.copyWith(id: _uuid.v4());
      }
      final id = doc.id!;
      final vector = vectors[i];
      final docPath = '$gcsDocumentsFolder/$id.json';
      final docJson = json.encode(doc.toMap());
      final vectorMap = {
        'id': id,
        'embedding': vector,
        if (doc.metadata['restricts'] != null)
          'restricts': doc.metadata['restricts'],
      };
      final vectorJson = json.encode(vectorMap);

      ids.add(id);
      vectorsJsons.add(vectorJson);
      await bucket.writeBytes(
        docPath,
        utf8.encode(docJson),
        contentType: 'application/json',
      );
    }

    // Write JSON lines index file to GCS (in indexFolder)
    final now = DateTime.now().toIso8601String();
    final indexFolder = '$gcsIndexesFolder/$now';
    final indexPath = '$indexFolder/${_uuid.v4()}.json';
    await bucket.writeBytes(
      indexPath,
      utf8.encode(vectorsJsons.join('\n')),
      contentType: 'application/json',
    );

    // Trigger a batch update of the index
    await _managementClient.indexes.update(
      id: indexId,
      metadata: VertexAIIndexRequestMetadata(
        contentsDeltaUri: 'gs://$gcsBucketName/$indexFolder/',
        isCompleteOverwrite: completeOverwriteWhenAdding,
      ),
    );
    return ids;
  }

  @override
  Future<void> delete({required final List<String> ids}) {
    throw UnimplementedError(
      'To delete vectors from Matching Engine you just need to sets '
      '`completeOverwriteWhenAdding` to true and add new ones. '
      'Each new batch will replace the previous one.',
    );
  }

  @override
  Future<List<(Document, double scores)>> similaritySearchByVectorWithScores({
    required final List<double> embedding,
    final VectorStoreSimilaritySearch config =
        const VectorStoreSimilaritySearch(),
  }) async {
    final (queryRootUrl, indexEndpointId, deployedIndexId) =
        await _getIndexIds();
    final queryClient = _getQueryClient(queryRootUrl);
    final queryRes = await queryClient.indexEndpoints.findNeighbors(
      indexEndpointId: indexEndpointId,
      deployedIndexId: deployedIndexId,
      queries: [
        VertexAIFindNeighborsRequestQuery(
          datapoint: VertexAIIndexDatapoint(
            datapointId: _uuid.v4(),
            featureVector: embedding,
            restricts: config
                .filter?[VertexAIMatchingEngineSimilaritySearch.filterKey],
          ),
          neighborCount: config.k,
        ),
      ],
    );

    Iterable<VertexAIFindNeighborsResponseNeighbor> neighbors =
        queryRes.nearestNeighbors.firstOrNull?.neighbors ?? [];
    if (neighbors.isEmpty) {
      return const [];
    }

    if (config.scoreThreshold != null) {
      final threshold = config.scoreThreshold!;
      neighbors = neighbors.where(
        (final neighbor) => neighbor.distance >= threshold,
      );
    }

    final List<(Document, double)> results = [];
    for (final neighbor in neighbors) {
      final id = neighbor.datapoint.datapointId;
      final document = await _getDocument(id);
      final score = neighbor.distance;
      results.add((document, score));
    }

    return results;
  }

  /// Returns the index endpoint and deployed index ids.
  Future<(String queryRootUrl, String indexEndpointId, String deployedIndexId)>
  _getIndexIds() async {
    if (_queryRootUrl != null &&
        _indexEndpointId != null &&
        _deployedIndexId != null) {
      return (_queryRootUrl!, _indexEndpointId!, _deployedIndexId!);
    }

    final index = await _managementClient.indexes.get(id: indexId);
    if (index.deployedIndexes.isEmpty) {
      throw LangChainException(
        message: 'No deployed indexes found for index $indexId',
      );
    } else if (index.deployedIndexes.length > 1) {
      throw LangChainException(
        message:
            'Multiple deployed indexes found for index $indexId. '
            'Please specify the `indexEndpointId` and `deployedIndexId` '
            'that you want to use.',
      );
    }
    final deployedIndex = index.deployedIndexes.first;
    final indexEndpoint = await _managementClient.indexEndpoints.get(
      id: deployedIndex.indexEndpointId,
    );

    _queryRootUrl = 'http://${indexEndpoint.publicEndpointDomainName}/';
    _indexEndpointId = deployedIndex.indexEndpointId;
    _deployedIndexId = deployedIndex.deployedIndexId;
    return (_queryRootUrl!, _indexEndpointId!, _deployedIndexId!);
  }

  /// Returns a client for querying the Vertex AI Matching Engine index.
  VertexAIMatchingEngineClient _getQueryClient(final String queryRootUrl) {
    return _queryClient ??= VertexAIMatchingEngineClient(
      httpClient: _httpClient,
      project: project,
      location: location,
      rootUrl: queryRootUrl,
    );
  }

  /// Returns the document with the given id from the Storage bucket.
  Future<Document> _getDocument(final String id) async {
    final bucket = _storageClient.bucket(gcsBucketName);
    final path = '$gcsDocumentsFolder/$id.json';
    final jsonFile =
        (await bucket
                .read('documents/$id.json')
                .transform(utf8.decoder)
                .transform(json.decoder)
                .toList())
            .firstOrNull;
    if (jsonFile == null) {
      throw LangChainException(
        message: 'No document found in gs://$gcsBucketName/$path',
      );
    }
    return Document.fromMap(jsonFile as Map<String, dynamic>);
  }
}
