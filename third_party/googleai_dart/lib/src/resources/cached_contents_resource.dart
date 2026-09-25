import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/caching/cached_content.dart';
import '../models/caching/list_cached_contents_response.dart';
import 'base_resource.dart';

/// Resource for the Cached Contents API.
///
/// Provides access to caching operations for model contexts.
class CachedContentsResource extends ResourceBase {
  /// Creates a [CachedContentsResource].
  CachedContentsResource({
    required super.config,
    required super.httpClient,
    required super.interceptorChain,
    required super.requestBuilder,
  });

  /// Creates cached content.
  ///
  /// The [cachedContent] contains the content to cache including model,
  /// system instruction, and contents. Set [expireTime] or [ttl] to control
  /// cache expiration (default TTL is 1 hour, max 24 hours).
  ///
  /// Returns the created [CachedContent] with its resource name.
  Future<CachedContent> create({required CachedContent cachedContent}) async {
    final url = requestBuilder.buildUrl('/{version}/cachedContents');

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(cachedContent.toJson());

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return CachedContent.fromJson(responseBody);
  }

  /// Gets cached content.
  ///
  /// The [name] is the resource name of the cached content
  /// (e.g., "cachedContents/abc123").
  ///
  /// Returns the [CachedContent] with its current metadata.
  Future<CachedContent> get({required String name}) async {
    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return CachedContent.fromJson(responseBody);
  }

  /// Updates cached content expiration.
  ///
  /// **Important**: Only expiration fields can be updated. All other fields
  /// (model, contents, system instruction, tools) are immutable after creation.
  ///
  /// The [name] is the resource name of the cached content
  /// (e.g., "cachedContents/abc123").
  ///
  /// The [cachedContent] should contain the updated expiration setting:
  /// - Set [ttl] to extend by a duration (e.g., "3600s" for 1 hour)
  /// - Set [expireTime] to set an absolute expiration timestamp
  /// - Use only one of [ttl] or [expireTime], not both
  ///
  /// The [updateMask] is optional but recommended for clarity. It specifies
  /// which fields to update:
  /// - Use "ttl" when updating with a duration
  /// - Use "expireTime" when updating with a timestamp
  ///
  /// Example:
  /// ```dart
  /// // Extend cache by 2 hours using TTL
  /// await client.updateCachedContent(
  ///   name: cache.name!,
  ///   cachedContent: CachedContent(ttl: '7200s'),
  ///   updateMask: 'ttl',
  /// );
  ///
  /// // Set absolute expiration time
  /// final newExpiry = DateTime.now().add(Duration(hours: 3));
  /// await client.updateCachedContent(
  ///   name: cache.name!,
  ///   cachedContent: CachedContent(expireTime: newExpiry),
  ///   updateMask: 'expireTime',
  /// );
  /// ```
  ///
  /// Returns the updated [CachedContent] with the new expiration time.
  Future<CachedContent> update({
    required String name,
    required CachedContent cachedContent,
    String? updateMask,
  }) async {
    final queryParams = <String, String>{
      if (updateMask != null) 'updateMask': updateMask,
    };

    final url = requestBuilder.buildUrl(
      '/{version}/$name',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('PATCH', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(cachedContent.toJson());

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return CachedContent.fromJson(responseBody);
  }

  /// Deletes cached content.
  ///
  /// The [name] is the resource name of the cached content to delete
  /// (e.g., "cachedContents/abc123").
  Future<void> delete({required String name}) async {
    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('DELETE', url)..headers.addAll(headers);

    await interceptorChain.execute(httpRequest);
  }

  /// Lists cached contents.
  ///
  /// The [pageSize] parameter specifies the maximum number of cached contents
  /// to return (default is 50). The [pageToken] is used for pagination.
  ///
  /// Returns a [ListCachedContentsResponse] with the list of cached contents
  /// and a next page token.
  Future<ListCachedContentsResponse> list({
    int? pageSize,
    String? pageToken,
  }) async {
    final queryParams = <String, String>{
      if (pageSize != null) 'pageSize': pageSize.toString(),
      if (pageToken != null) 'pageToken': pageToken,
    };

    final url = requestBuilder.buildUrl(
      '/{version}/cachedContents',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return ListCachedContentsResponse.fromJson(responseBody);
  }
}
