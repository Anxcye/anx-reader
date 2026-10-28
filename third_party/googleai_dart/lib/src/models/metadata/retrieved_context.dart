import '../copy_with_sentinel.dart';

/// Chunk from context retrieved by the file search tool.
class RetrievedContext {
  /// Optional. URI reference of the semantic retrieval document.
  final String? uri;

  /// Optional. Title of the document.
  final String? title;

  /// Optional. Text of the chunk.
  final String? text;

  /// Optional. Name of the `FileSearchStore` containing the document.
  ///
  /// Example: `fileSearchStores/123`
  final String? fileSearchStore;

  /// Creates a [RetrievedContext].
  const RetrievedContext({
    this.uri,
    this.title,
    this.text,
    this.fileSearchStore,
  });

  /// Creates a [RetrievedContext] from JSON.
  factory RetrievedContext.fromJson(Map<String, dynamic> json) =>
      RetrievedContext(
        uri: json['uri'] as String?,
        title: json['title'] as String?,
        text: json['text'] as String?,
        fileSearchStore: json['fileSearchStore'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (uri != null) 'uri': uri,
    if (title != null) 'title': title,
    if (text != null) 'text': text,
    if (fileSearchStore != null) 'fileSearchStore': fileSearchStore,
  };

  /// Creates a copy with replaced values.
  RetrievedContext copyWith({
    Object? uri = unsetCopyWithValue,
    Object? title = unsetCopyWithValue,
    Object? text = unsetCopyWithValue,
    Object? fileSearchStore = unsetCopyWithValue,
  }) {
    return RetrievedContext(
      uri: uri == unsetCopyWithValue ? this.uri : uri as String?,
      title: title == unsetCopyWithValue ? this.title : title as String?,
      text: text == unsetCopyWithValue ? this.text : text as String?,
      fileSearchStore: fileSearchStore == unsetCopyWithValue
          ? this.fileSearchStore
          : fileSearchStore as String?,
    );
  }

  @override
  String toString() =>
      'RetrievedContext(uri: $uri, title: $title, text: $text, fileSearchStore: $fileSearchStore)';
}
