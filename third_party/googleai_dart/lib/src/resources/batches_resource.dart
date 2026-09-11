import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/batch/embed_content_batch.dart';
import '../models/batch/generate_content_batch.dart';
import '../models/batch/list_batches_response.dart';
import 'base_resource.dart';

/// Resource for the Batches API.
///
/// Provides access to batch operation management.
class BatchesResource extends ResourceBase {
  /// Creates a [BatchesResource].
  BatchesResource({
    required super.config,
    required super.httpClient,
    required super.interceptorChain,
    required super.requestBuilder,
  });

  /// Lists batch operations.
  ///
  /// The [pageSize] parameter specifies the maximum number of batches to return.
  /// The [pageToken] is used for pagination.
  /// The [filter] allows filtering batches (optional).
  /// The [returnPartialSuccess] when set to true, operations that are reachable
  /// are returned as normal, and those that are unreachable are returned in the
  /// unreachable field.
  ///
  /// Returns a [ListBatchesResponse] with the list of batch operations.
  Future<ListBatchesResponse> list({
    int? pageSize,
    String? pageToken,
    String? filter,
    bool? returnPartialSuccess,
  }) async {
    final queryParams = <String, String>{
      if (pageSize != null) 'pageSize': pageSize.toString(),
      if (pageToken != null) 'pageToken': pageToken,
      if (filter != null) 'filter': filter,
      if (returnPartialSuccess != null)
        'returnPartialSuccess': returnPartialSuccess.toString(),
    };

    final url = requestBuilder.buildUrl(
      '/{version}/batches',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return ListBatchesResponse.fromJson(responseBody);
  }

  /// Gets a specific generate content batch operation.
  ///
  /// The [name] is the resource name of the batch (e.g., "batches/abc123").
  ///
  /// Returns a [GenerateContentBatch] with the batch details.
  ///
  /// Note: For embed content batches, use [getEmbedBatch] instead.
  Future<GenerateContentBatch> getGenerateContentBatch({
    required String name,
  }) async {
    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return GenerateContentBatch.fromJson(responseBody);
  }

  /// Gets a specific embed content batch operation.
  ///
  /// The [name] is the resource name of the batch (e.g., "batches/abc123").
  ///
  /// Returns an [EmbedContentBatch] with the batch details.
  Future<EmbedContentBatch> getEmbedBatch({required String name}) async {
    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return EmbedContentBatch.fromJson(responseBody);
  }

  /// Updates a generate content batch.
  ///
  /// The [name] is the resource name of the batch.
  /// The [batch] contains the updated batch configuration.
  /// The [updateMask] specifies which fields to update (e.g., "displayName,priority").
  ///
  /// Returns the updated [GenerateContentBatch].
  Future<GenerateContentBatch> updateGenerateContentBatch({
    required String name,
    required GenerateContentBatch batch,
    String? updateMask,
  }) async {
    final queryParams = <String, String>{
      if (updateMask != null) 'updateMask': updateMask,
    };

    final url = requestBuilder.buildUrl(
      '/{version}/$name:updateGenerateContentBatch',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('PATCH', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(batch.toJson());

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return GenerateContentBatch.fromJson(responseBody);
  }

  /// Updates an embed content batch.
  ///
  /// The [name] is the resource name of the batch.
  /// The [batch] contains the updated batch configuration.
  /// The [updateMask] specifies which fields to update (e.g., "displayName,priority").
  ///
  /// Returns the updated [EmbedContentBatch].
  Future<EmbedContentBatch> updateEmbedContentBatch({
    required String name,
    required EmbedContentBatch batch,
    String? updateMask,
  }) async {
    final queryParams = <String, String>{
      if (updateMask != null) 'updateMask': updateMask,
    };

    final url = requestBuilder.buildUrl(
      '/{version}/$name:updateEmbedContentBatch',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('PATCH', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(batch.toJson());

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return EmbedContentBatch.fromJson(responseBody);
  }

  /// Deletes a batch operation.
  ///
  /// The [name] is the resource name of the batch to delete
  /// (e.g., "batches/abc123").
  Future<void> delete({required String name}) async {
    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('DELETE', url)..headers.addAll(headers);

    await interceptorChain.execute(httpRequest);
  }

  /// Cancels a running batch operation.
  ///
  /// The [name] is the resource name of the batch to cancel
  /// (e.g., "batches/abc123").
  Future<void> cancel({required String name}) async {
    final url = requestBuilder.buildUrl('/{version}/$name:cancel');

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(<String, dynamic>{});

    await interceptorChain.execute(httpRequest);
  }
}
