part of 'content.dart';

/// A Google Search call content block.
class GoogleSearchCallContent extends InteractionContent {
  @override
  String get type => 'google_search_call';

  /// A unique ID for this specific tool call.
  final String? id;

  /// Web search queries for the following-up web search.
  final List<String>? queries;

  /// Creates a [GoogleSearchCallContent] instance.
  const GoogleSearchCallContent({this.id, this.queries});

  /// Creates a [GoogleSearchCallContent] from JSON.
  factory GoogleSearchCallContent.fromJson(Map<String, dynamic> json) {
    final arguments = json['arguments'] as Map<String, dynamic>?;
    return GoogleSearchCallContent(
      id: json['id'] as String?,
      queries: (arguments?['queries'] as List<dynamic>?)?.cast<String>(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (id != null) 'id': id,
    if (queries != null) 'arguments': {'queries': queries},
  };

  /// Creates a copy with replaced values.
  GoogleSearchCallContent copyWith({
    Object? id = unsetCopyWithValue,
    Object? queries = unsetCopyWithValue,
  }) {
    return GoogleSearchCallContent(
      id: id == unsetCopyWithValue ? this.id : id as String?,
      queries: queries == unsetCopyWithValue
          ? this.queries
          : queries as List<String>?,
    );
  }
}
