import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../client/config.dart';
import '../../models/corpus/document.dart';
import '../../models/corpus/list_documents_response.dart';
import '../../models/files/file_search_store.dart';
import '../../models/files/import_file_request.dart';
import '../../models/files/import_file_response.dart';
import '../../models/files/list_file_search_stores_response.dart';
import '../../models/files/upload_to_file_search_store_request.dart';
import '../../models/files/upload_to_file_search_store_response.dart';
import '../base_resource.dart';

/// Resource for the FileSearchStores API (stub implementation).
///
/// Provides access to file search store management operations including
/// creating stores, uploading files, and managing documents.
///
/// **Note**: This resource is only available with the Google AI (Gemini) API.
/// Vertex AI uses RAG stores for similar functionality.
///
/// See: https://ai.google.dev/api/files#v1beta.fileSearchStores
class FileSearchStoresResource extends ResourceBase {
  /// Creates a [FileSearchStoresResource].
  FileSearchStoresResource({
    required super.config,
    required super.httpClient,
    required super.interceptorChain,
    required super.requestBuilder,
  });

  /// Validates that the FileSearchStores API is only used with Google AI.
  void _validateGoogleAIOnly() {
    if (config.apiMode == ApiMode.vertexAI) {
      throw UnsupportedError(
        'FileSearchStores API is only available with Google AI (Gemini API). '
        'Vertex AI uses RAG stores for similar functionality. '
        'See: https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/grounding',
      );
    }
  }

  /// Creates a new [FileSearchStore].
  ///
  /// [displayName] is an optional human-readable display name for the store.
  /// The display name must be no more than 512 characters in length.
  ///
  /// POST /v1beta/fileSearchStores
  Future<FileSearchStore> create({String? displayName}) async {
    _validateGoogleAIOnly();

    final url = requestBuilder.buildUrl('/{version}/fileSearchStores');

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(body);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return FileSearchStore.fromJson(responseBody);
  }

  /// Lists file search stores with pagination support.
  ///
  /// The [pageSize] parameter specifies the maximum number of stores to return
  /// (default is 10, max is 100). The [pageToken] is used for pagination.
  ///
  /// GET /v1beta/fileSearchStores
  Future<ListFileSearchStoresResponse> list({
    int? pageSize,
    String? pageToken,
  }) async {
    _validateGoogleAIOnly();

    final queryParams = <String, String>{
      if (pageSize != null) 'pageSize': pageSize.toString(),
      if (pageToken != null) 'pageToken': pageToken,
    };

    final url = requestBuilder.buildUrl(
      '/{version}/fileSearchStores',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return ListFileSearchStoresResponse.fromJson(responseBody);
  }

  /// Gets information about a specific file search store.
  ///
  /// The [name] is the resource name of the store
  /// (e.g., "fileSearchStores/my-store-123").
  ///
  /// GET /v1beta/{name}
  Future<FileSearchStore> get({required String name}) async {
    _validateGoogleAIOnly();

    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return FileSearchStore.fromJson(responseBody);
  }

  /// Deletes a file search store.
  ///
  /// The [name] is the resource name of the store to delete
  /// (e.g., "fileSearchStores/my-store-123").
  ///
  /// DELETE /v1beta/{name}
  Future<void> delete({required String name}) async {
    _validateGoogleAIOnly();

    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('DELETE', url)..headers.addAll(headers);

    await interceptorChain.execute(httpRequest);
  }

  /// Imports a file from the Files API into a file search store.
  ///
  /// The [parent] is the resource name of the store
  /// (e.g., "fileSearchStores/my-store-123").
  ///
  /// The [request] contains the file to import and optional configuration.
  ///
  /// POST /v1beta/{parent}:importFile
  Future<ImportFileResponse> importFile({
    required String parent,
    required ImportFileRequest request,
  }) async {
    _validateGoogleAIOnly();

    final url = requestBuilder.buildUrl('/{version}/$parent:importFile');

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(request.toJson());

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return ImportFileResponse.fromJson(responseBody);
  }

  /// Uploads data directly to a file search store.
  ///
  /// This method is not supported on this platform.
  ///
  /// Throws [UnsupportedError] always.
  Future<UploadToFileSearchStoreResponse> upload({
    required String parent,
    String? filePath,
    Stream<List<int>>? contentStream,
    List<int>? bytes,
    String? fileName,
    required String mimeType,
    UploadToFileSearchStoreRequest? request,
  }) {
    throw UnsupportedError(
      'File upload is not supported on this platform. '
      'Use dart:io or web platform.',
    );
  }

  /// Lists documents in a file search store with pagination support.
  ///
  /// The [parent] is the resource name of the store
  /// (e.g., "fileSearchStores/my-store-123").
  ///
  /// GET /v1beta/{parent}/documents
  Future<ListDocumentsResponse> listDocuments({
    required String parent,
    int? pageSize,
    String? pageToken,
  }) async {
    _validateGoogleAIOnly();

    final queryParams = <String, String>{
      if (pageSize != null) 'pageSize': pageSize.toString(),
      if (pageToken != null) 'pageToken': pageToken,
    };

    final url = requestBuilder.buildUrl(
      '/{version}/$parent/documents',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return ListDocumentsResponse.fromJson(responseBody);
  }

  /// Gets information about a specific document in a file search store.
  ///
  /// The [name] is the resource name of the document
  /// (e.g., "fileSearchStores/my-store-123/documents/doc-456").
  ///
  /// GET /v1beta/{name}
  Future<Document> getDocument({required String name}) async {
    _validateGoogleAIOnly();

    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Document.fromJson(responseBody);
  }

  /// Deletes a document from a file search store.
  ///
  /// The [name] is the resource name of the document to delete
  /// (e.g., "fileSearchStores/my-store-123/documents/doc-456").
  ///
  /// DELETE /v1beta/{name}
  Future<void> deleteDocument({required String name}) async {
    _validateGoogleAIOnly();

    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('DELETE', url)..headers.addAll(headers);

    await interceptorChain.execute(httpRequest);
  }
}
