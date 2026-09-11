part of 'content.dart';

/// A File Search result content block.
class FileSearchResultContent extends InteractionContent {
  @override
  String get type => 'file_search_result';

  /// The results of the File Search.
  final List<FileSearchResult>? result;

  /// Creates a [FileSearchResultContent] instance.
  const FileSearchResultContent({this.result});

  /// Creates a [FileSearchResultContent] from JSON.
  factory FileSearchResultContent.fromJson(Map<String, dynamic> json) =>
      FileSearchResultContent(
        result: (json['result'] as List<dynamic>?)
            ?.map((e) => FileSearchResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (result != null) 'result': result!.map((e) => e.toJson()).toList(),
  };

  /// Creates a copy with replaced values.
  FileSearchResultContent copyWith({Object? result = unsetCopyWithValue}) {
    return FileSearchResultContent(
      result: result == unsetCopyWithValue
          ? this.result
          : result as List<FileSearchResult>?,
    );
  }
}

/// A File Search result item.
class FileSearchResult {
  /// The title of the search result.
  final String? title;

  /// The text of the search result.
  final String? text;

  /// The name of the file search store.
  final String? fileSearchStore;

  /// Creates a [FileSearchResult] instance.
  const FileSearchResult({this.title, this.text, this.fileSearchStore});

  /// Creates a [FileSearchResult] from JSON.
  factory FileSearchResult.fromJson(Map<String, dynamic> json) =>
      FileSearchResult(
        title: json['title'] as String?,
        text: json['text'] as String?,
        fileSearchStore: json['file_search_store'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title,
    if (text != null) 'text': text,
    if (fileSearchStore != null) 'file_search_store': fileSearchStore,
  };

  /// Creates a copy with replaced values.
  FileSearchResult copyWith({
    Object? title = unsetCopyWithValue,
    Object? text = unsetCopyWithValue,
    Object? fileSearchStore = unsetCopyWithValue,
  }) {
    return FileSearchResult(
      title: title == unsetCopyWithValue ? this.title : title as String?,
      text: text == unsetCopyWithValue ? this.text : text as String?,
      fileSearchStore: fileSearchStore == unsetCopyWithValue
          ? this.fileSearchStore
          : fileSearchStore as String?,
    );
  }
}
