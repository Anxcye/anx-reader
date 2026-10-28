import '../copy_with_sentinel.dart';

/// The FileSearch tool that retrieves knowledge from Semantic Retrieval
/// corpora.
///
/// Files are imported to Semantic Retrieval corpora using the ImportFile API.
class FileSearch {
  /// Required. The names of the file_search_stores to retrieve from.
  ///
  /// Example: `fileSearchStores/my-file-search-store-123`
  final List<String> fileSearchStoreNames;

  /// Optional. The number of semantic retrieval chunks to retrieve.
  final int? topK;

  /// Optional. Metadata filter to apply to the semantic retrieval documents
  /// and chunks.
  final String? metadataFilter;

  /// Creates a [FileSearch].
  const FileSearch({
    required this.fileSearchStoreNames,
    this.topK,
    this.metadataFilter,
  });

  /// Creates a [FileSearch] from JSON.
  factory FileSearch.fromJson(Map<String, dynamic> json) => FileSearch(
    fileSearchStoreNames: (json['fileSearchStoreNames'] as List)
        .map((e) => e as String)
        .toList(),
    topK: json['topK'] as int?,
    metadataFilter: json['metadataFilter'] as String?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'fileSearchStoreNames': fileSearchStoreNames,
    if (topK != null) 'topK': topK,
    if (metadataFilter != null) 'metadataFilter': metadataFilter,
  };

  /// Creates a copy with replaced values.
  FileSearch copyWith({
    List<String>? fileSearchStoreNames,
    Object? topK = unsetCopyWithValue,
    Object? metadataFilter = unsetCopyWithValue,
  }) {
    return FileSearch(
      fileSearchStoreNames: fileSearchStoreNames ?? this.fileSearchStoreNames,
      topK: topK == unsetCopyWithValue ? this.topK : topK as int?,
      metadataFilter: metadataFilter == unsetCopyWithValue
          ? this.metadataFilter
          : metadataFilter as String?,
    );
  }

  @override
  String toString() =>
      'FileSearch(fileSearchStoreNames: $fileSearchStoreNames, topK: $topK, metadataFilter: $metadataFilter)';
}
