import '../copy_with_sentinel.dart';
import 'file_search_store.dart';

/// Response from `ListFileSearchStores` containing a paginated list of
/// `FileSearchStores`.
///
/// The results are sorted by ascending `file_search_store.create_time`.
class ListFileSearchStoresResponse {
  /// The returned file search stores.
  final List<FileSearchStore>? fileSearchStores;

  /// A token, which can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no more pages.
  final String? nextPageToken;

  /// Creates a [ListFileSearchStoresResponse].
  const ListFileSearchStoresResponse({
    this.fileSearchStores,
    this.nextPageToken,
  });

  /// Creates a [ListFileSearchStoresResponse] from JSON.
  factory ListFileSearchStoresResponse.fromJson(Map<String, dynamic> json) =>
      ListFileSearchStoresResponse(
        fileSearchStores: (json['fileSearchStores'] as List?)
            ?.map((e) => FileSearchStore.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextPageToken: json['nextPageToken'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (fileSearchStores != null)
      'fileSearchStores': fileSearchStores!.map((e) => e.toJson()).toList(),
    if (nextPageToken != null) 'nextPageToken': nextPageToken,
  };

  /// Creates a copy with replaced values.
  ListFileSearchStoresResponse copyWith({
    Object? fileSearchStores = unsetCopyWithValue,
    Object? nextPageToken = unsetCopyWithValue,
  }) {
    return ListFileSearchStoresResponse(
      fileSearchStores: fileSearchStores == unsetCopyWithValue
          ? this.fileSearchStores
          : fileSearchStores as List<FileSearchStore>?,
      nextPageToken: nextPageToken == unsetCopyWithValue
          ? this.nextPageToken
          : nextPageToken as String?,
    );
  }

  @override
  String toString() =>
      'ListFileSearchStoresResponse(fileSearchStores: $fileSearchStores, nextPageToken: $nextPageToken)';
}
