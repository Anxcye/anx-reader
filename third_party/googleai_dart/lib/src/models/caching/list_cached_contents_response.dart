import '../copy_with_sentinel.dart';
import 'cached_content.dart';

/// Response from listing cached contents.
class ListCachedContentsResponse {
  /// The list of cached contents.
  final List<CachedContent> cachedContents;

  /// Token to retrieve the next page of results.
  final String? nextPageToken;

  /// Creates a [ListCachedContentsResponse].
  const ListCachedContentsResponse({
    required this.cachedContents,
    this.nextPageToken,
  });

  /// Creates a [ListCachedContentsResponse] from JSON.
  factory ListCachedContentsResponse.fromJson(Map<String, dynamic> json) =>
      ListCachedContentsResponse(
        cachedContents:
            (json['cachedContents'] as List<dynamic>?)
                ?.map((e) => CachedContent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        nextPageToken: json['nextPageToken'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'cachedContents': cachedContents.map((e) => e.toJson()).toList(),
    if (nextPageToken != null) 'nextPageToken': nextPageToken,
  };

  /// Creates a copy with replaced values.
  ListCachedContentsResponse copyWith({
    Object? cachedContents = unsetCopyWithValue,
    Object? nextPageToken = unsetCopyWithValue,
  }) {
    return ListCachedContentsResponse(
      cachedContents: cachedContents == unsetCopyWithValue
          ? this.cachedContents
          : cachedContents! as List<CachedContent>,
      nextPageToken: nextPageToken == unsetCopyWithValue
          ? this.nextPageToken
          : nextPageToken as String?,
    );
  }
}
