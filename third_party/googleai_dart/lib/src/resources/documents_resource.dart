import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/corpus/document.dart';
import '../models/corpus/list_documents_response.dart';
import 'base_resource.dart';

/// Resource for the Documents API.
///
/// Provides access to document management within a corpus.
class DocumentsResource extends ResourceBase {
  /// Parent corpus name (e.g., "corpora/my-corpus").
  final String corpus;

  /// Creates a [DocumentsResource].
  DocumentsResource({
    required this.corpus,
    required super.config,
    required super.httpClient,
    required super.interceptorChain,
    required super.requestBuilder,
  });

  /// Creates a new [Document] in a corpus.
  ///
  /// POST /v1beta/{parent}/documents
  Future<Document> create({required Document document}) async {
    final url = requestBuilder.buildUrl('/{version}/$corpus/documents');

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(document.toJson());

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Document.fromJson(responseBody);
  }

  /// Lists documents in a corpus with pagination support.
  ///
  /// GET /v1beta/{parent}/documents
  Future<ListDocumentsResponse> list({int? pageSize, String? pageToken}) async {
    final queryParams = <String, String>{};
    if (pageSize != null) queryParams['pageSize'] = pageSize.toString();
    if (pageToken != null) queryParams['pageToken'] = pageToken;

    final url = requestBuilder.buildUrl(
      '/{version}/$corpus/documents',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return ListDocumentsResponse.fromJson(responseBody);
  }

  /// Gets information about a specific document.
  ///
  /// GET /v1beta/{name}
  Future<Document> get({required String name}) async {
    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Document.fromJson(responseBody);
  }

  /// Updates a document with a field mask.
  ///
  /// The [updateMask] parameter is required and specifies which fields to update.
  /// Currently supports: `displayName` and `customMetadata`.
  ///
  /// Example: `updateMask: 'displayName,customMetadata'`
  ///
  /// PATCH /v1beta/{name}
  Future<Document> update({
    required String name,
    required Document document,
    required String updateMask,
  }) async {
    final queryParams = <String, String>{'updateMask': updateMask};

    final url = requestBuilder.buildUrl(
      '/{version}/$name',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('PATCH', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(document.toJson());

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Document.fromJson(responseBody);
  }

  /// Deletes a document.
  ///
  /// DELETE /v1beta/{name}
  Future<void> delete({required String name, bool? force}) async {
    final queryParams = force != null
        ? {'force': force.toString()}
        : <String, String>{};

    final url = requestBuilder.buildUrl(
      '/{version}/$name',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('DELETE', url)..headers.addAll(headers);

    await interceptorChain.execute(httpRequest);
  }
}
