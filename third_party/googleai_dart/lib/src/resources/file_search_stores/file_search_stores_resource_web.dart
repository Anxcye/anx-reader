import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/auth_provider.dart';
import '../../client/config.dart';
import '../../errors/exceptions.dart';
import '../../models/corpus/document.dart';
import '../../models/corpus/list_documents_response.dart';
import '../../models/files/file_search_store.dart';
import '../../models/files/import_file_request.dart';
import '../../models/files/import_file_response.dart';
import '../../models/files/list_file_search_stores_response.dart';
import '../../models/files/upload_to_file_search_store_request.dart';
import '../../models/files/upload_to_file_search_store_response.dart';
import '../base_resource.dart';

/// Resource for the FileSearchStores API (Web/WASM implementation).
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
  /// Web/WASM implementation - only supports bytes-based uploads.
  ///
  /// Required parameters:
  /// - [bytes]: The file content as a list of bytes
  /// - [fileName]: The name of the file
  /// - [mimeType]: The MIME type of the file
  ///
  /// Not supported on web/WASM:
  /// - [filePath]: Not available (no file system access)
  /// - [contentStream]: Not available (no streaming from file system)
  ///
  /// POST /v1beta/{parent}:upload (resumable upload)
  Future<UploadToFileSearchStoreResponse> upload({
    required String parent,
    String? filePath,
    Stream<List<int>>? contentStream,
    List<int>? bytes,
    String? fileName,
    required String mimeType,
    UploadToFileSearchStoreRequest? request,
  }) async {
    _validateGoogleAIOnly();

    // Validate web-specific constraints
    if (filePath != null || contentStream != null) {
      throw UnsupportedError(
        'filePath and contentStream are not supported on web/WASM platforms. '
        'Use bytes parameter instead.',
      );
    }

    if (bytes == null || fileName == null) {
      throw const ValidationException(
        message: 'bytes and fileName are required on web/WASM platforms',
        fieldErrors: {
          'upload': ['Provide both bytes and fileName for web/WASM uploads'],
        },
      );
    }

    // FileSearchStores uses resumable upload protocol
    // Step 1: Initiate the upload and get upload URL
    final uploadUrl = Uri.parse(
      '${config.baseUrl}/upload/${config.apiVersion.value}/$parent:upload',
    );

    final initiationHeaders = <String, String>{
      'X-Goog-Upload-Protocol': 'resumable',
      'X-Goog-Upload-Command': 'start',
      'X-Goog-Upload-Header-Content-Length': bytes.length.toString(),
      'X-Goog-Upload-Header-Content-Type': mimeType,
      'Content-Type': 'application/json',
    };

    // Apply authentication to initiation request
    if (config.authProvider != null) {
      final credentials = await config.authProvider!.getCredentials();
      switch (credentials) {
        case ApiKeyCredentials(:final apiKey, :final placement):
          if (placement == AuthPlacement.header) {
            initiationHeaders['X-Goog-Api-Key'] = apiKey;
          }
        case BearerTokenCredentials(:final token):
          initiationHeaders['Authorization'] = 'Bearer $token';
        case EphemeralTokenCredentials(:final token, :final placement):
          if (placement == EphemeralTokenPlacement.header) {
            initiationHeaders['Authorization'] = 'Token $token';
          }
        // Query param handled below
        case NoAuthCredentials():
          // No auth needed
          break;
      }
    }

    // Add API key or ephemeral token as query param if needed
    final Uri uploadUrlWithAuth;
    if (config.authProvider != null) {
      final credentials = await config.authProvider!.getCredentials();
      if (credentials is ApiKeyCredentials &&
          credentials.placement == AuthPlacement.queryParam) {
        uploadUrlWithAuth = uploadUrl.replace(
          queryParameters: {'key': credentials.apiKey},
        );
      } else if (credentials is EphemeralTokenCredentials &&
          credentials.placement == EphemeralTokenPlacement.queryParam) {
        uploadUrlWithAuth = uploadUrl.replace(
          queryParameters: {'access_token': credentials.token},
        );
      } else {
        uploadUrlWithAuth = uploadUrl;
      }
    } else {
      uploadUrlWithAuth = uploadUrl;
    }

    // Build request body with metadata
    final requestBody = <String, dynamic>{
      if (request?.displayName != null) 'displayName': request!.displayName,
      if (request?.customMetadata != null)
        'customMetadata': request!.customMetadata!
            .map((e) => e.toJson())
            .toList(),
      if (request?.chunkingConfig != null)
        'chunkingConfig': request!.chunkingConfig!.toJson(),
      if (request?.mimeType != null) 'mimeType': request!.mimeType,
    };

    final initiationRequest = http.Request('POST', uploadUrlWithAuth)
      ..headers.addAll(initiationHeaders)
      ..body = jsonEncode(requestBody);

    final initiationResponse = await httpClient.send(initiationRequest);
    final initResponse = await http.Response.fromStream(initiationResponse);

    if (initResponse.statusCode >= 400) {
      throw _mapHttpErrorForStreaming(initResponse);
    }

    // Extract upload URL from response headers
    final uploadUrlHeader = initResponse.headers['x-goog-upload-url'];
    if (uploadUrlHeader == null) {
      throw const ApiException(
        code: 500,
        message: 'Upload URL not returned in initiation response',
      );
    }

    // Step 2: Upload the file bytes
    final uploadHeaders = <String, String>{
      'Content-Length': bytes.length.toString(),
      'X-Goog-Upload-Offset': '0',
      'X-Goog-Upload-Command': 'upload, finalize',
    };

    final uploadRequest = http.Request('POST', Uri.parse(uploadUrlHeader))
      ..headers.addAll(uploadHeaders)
      ..bodyBytes = bytes;

    final uploadResponse = await httpClient.send(uploadRequest);
    final finalResponse = await http.Response.fromStream(uploadResponse);

    if (finalResponse.statusCode >= 400) {
      throw _mapHttpErrorForStreaming(finalResponse);
    }

    final responseBody = jsonDecode(finalResponse.body) as Map<String, dynamic>;
    return UploadToFileSearchStoreResponse.fromJson(responseBody);
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
}
