part of 'content.dart';

/// A URL context call content block.
class UrlContextCallContent extends InteractionContent {
  @override
  String get type => 'url_context_call';

  /// A unique ID for this specific tool call.
  final String? id;

  /// The URLs to fetch.
  final List<String>? urls;

  /// Creates a [UrlContextCallContent] instance.
  const UrlContextCallContent({this.id, this.urls});

  /// Creates a [UrlContextCallContent] from JSON.
  factory UrlContextCallContent.fromJson(Map<String, dynamic> json) {
    final arguments = json['arguments'] as Map<String, dynamic>?;
    return UrlContextCallContent(
      id: json['id'] as String?,
      urls: (arguments?['urls'] as List<dynamic>?)?.cast<String>(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (id != null) 'id': id,
    if (urls != null) 'arguments': {'urls': urls},
  };

  /// Creates a copy with replaced values.
  UrlContextCallContent copyWith({
    Object? id = unsetCopyWithValue,
    Object? urls = unsetCopyWithValue,
  }) {
    return UrlContextCallContent(
      id: id == unsetCopyWithValue ? this.id : id as String?,
      urls: urls == unsetCopyWithValue ? this.urls : urls as List<String>?,
    );
  }
}
