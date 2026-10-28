import '../copy_with_sentinel.dart';

/// Chunk from the web.
class Web {
  /// URI reference of the chunk.
  final String? uri;

  /// Title of the chunk.
  final String? title;

  /// Creates a [Web].
  const Web({this.uri, this.title});

  /// Creates a [Web] from JSON.
  factory Web.fromJson(Map<String, dynamic> json) =>
      Web(uri: json['uri'] as String?, title: json['title'] as String?);

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (uri != null) 'uri': uri,
    if (title != null) 'title': title,
  };

  /// Creates a copy with replaced values.
  Web copyWith({
    Object? uri = unsetCopyWithValue,
    Object? title = unsetCopyWithValue,
  }) {
    return Web(
      uri: uri == unsetCopyWithValue ? this.uri : uri as String?,
      title: title == unsetCopyWithValue ? this.title : title as String?,
    );
  }

  @override
  String toString() => 'Web(uri: $uri, title: $title)';
}
