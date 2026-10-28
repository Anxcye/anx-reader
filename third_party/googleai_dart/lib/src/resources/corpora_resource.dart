import 'dart:convert';

import 'package:http/http.dart' as http;

import '../client/config.dart';
import '../models/corpus/corpus.dart';
import '../models/corpus/list_corpora_response.dart';
import 'base_resource.dart';
import 'documents_resource.dart';
import 'permissions_resource.dart';

/// Resource for the Corpora API.
///
/// Provides access to corpus management and semantic retrieval operations.
///
/// **Note**: This resource is only available with the Google AI (Gemini) API.
/// Vertex AI uses RAG stores for semantic retrieval.
///
/// See: https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/grounding
class CorporaResource extends ResourceBase {
  /// Creates a [CorporaResource].
  CorporaResource({
    required super.config,
    required super.httpClient,
    required super.interceptorChain,
    required super.requestBuilder,
  });

  /// Validates that the Corpora API is only used with Google AI.
  void _validateGoogleAIOnly() {
    if (config.apiMode == ApiMode.vertexAI) {
      throw UnsupportedError(
        'Corpora API is only available with Google AI (Gemini API). '
        'Vertex AI uses RAG stores for semantic retrieval. '
        'See: https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/grounding',
      );
    }
  }

  /// Creates a new [Corpus] for storing documents and chunks.
  ///
  /// Corpora are collections of documents that can be queried for semantic retrieval.
  /// A project can create up to 10 corpora.
  ///
  /// POST /v1beta/corpora
  Future<Corpus> create({required Corpus corpus}) async {
    _validateGoogleAIOnly();

    final url = requestBuilder.buildUrl('/{version}/corpora');

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(corpus.toJson());

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Corpus.fromJson(responseBody);
  }

  /// Lists all corpora with pagination support.
  ///
  /// GET /v1beta/corpora
  Future<ListCorporaResponse> list({int? pageSize, String? pageToken}) async {
    _validateGoogleAIOnly();

    final queryParams = <String, String>{};
    if (pageSize != null) queryParams['pageSize'] = pageSize.toString();
    if (pageToken != null) queryParams['pageToken'] = pageToken;

    final url = requestBuilder.buildUrl(
      '/{version}/corpora',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return ListCorporaResponse.fromJson(responseBody);
  }

  /// Gets information about a specific corpus.
  ///
  /// GET /v1beta/{name}
  Future<Corpus> get({required String name}) async {
    _validateGoogleAIOnly();

    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Corpus.fromJson(responseBody);
  }

  /// Deletes a corpus.
  ///
  /// If [force] is true, any Documents and objects related to this corpus will
  /// also be deleted. If false (the default), a FAILED_PRECONDITION error will
  /// be returned if the corpus contains any Documents.
  ///
  /// DELETE /v1beta/{name}
  Future<void> delete({required String name, bool? force}) async {
    _validateGoogleAIOnly();

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

  /// Access documents for this corpus.
  DocumentsResource documents({required String corpus}) {
    return DocumentsResource(
      corpus: corpus,
      config: config,
      httpClient: httpClient,
      interceptorChain: interceptorChain,
      requestBuilder: requestBuilder,
    );
  }

  /// Access permissions for this corpus.
  PermissionsResource permissions({required String parent}) {
    return PermissionsResource(
      parent: parent,
      config: config,
      httpClient: httpClient,
      interceptorChain: interceptorChain,
      requestBuilder: requestBuilder,
    );
  }
}
