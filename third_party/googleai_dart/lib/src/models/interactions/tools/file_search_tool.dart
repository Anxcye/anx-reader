part of 'tools.dart';

/// A tool that allows the model to search files.
class FileSearchTool extends InteractionTool {
  @override
  String get type => 'file_search';

  /// The file search store names to search.
  final List<String>? fileSearchStoreNames;

  /// The number of semantic retrieval chunks to retrieve.
  final int? topK;

  /// Metadata filter to apply to the semantic retrieval documents and chunks.
  final String? metadataFilter;

  /// Creates a [FileSearchTool] instance.
  const FileSearchTool({
    this.fileSearchStoreNames,
    this.topK,
    this.metadataFilter,
  });

  /// Creates a [FileSearchTool] from JSON.
  factory FileSearchTool.fromJson(Map<String, dynamic> json) => FileSearchTool(
    fileSearchStoreNames: (json['file_search_store_names'] as List<dynamic>?)
        ?.cast<String>(),
    topK: json['top_k'] as int?,
    metadataFilter: json['metadata_filter'] as String?,
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (fileSearchStoreNames != null)
      'file_search_store_names': fileSearchStoreNames,
    if (topK != null) 'top_k': topK,
    if (metadataFilter != null) 'metadata_filter': metadataFilter,
  };
}
