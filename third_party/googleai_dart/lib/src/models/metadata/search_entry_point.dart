import '../copy_with_sentinel.dart';

/// Google search entry point.
class SearchEntryPoint {
  /// Optional. Web content snippet that can be embedded in a web page or
  /// an app webview.
  final String? renderedContent;

  /// Optional. Base64 encoded JSON representing array of tuple.
  final String? sdkBlob;

  /// Creates a [SearchEntryPoint].
  const SearchEntryPoint({this.renderedContent, this.sdkBlob});

  /// Creates a [SearchEntryPoint] from JSON.
  factory SearchEntryPoint.fromJson(Map<String, dynamic> json) =>
      SearchEntryPoint(
        renderedContent: json['renderedContent'] as String?,
        sdkBlob: json['sdkBlob'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (renderedContent != null) 'renderedContent': renderedContent,
    if (sdkBlob != null) 'sdkBlob': sdkBlob,
  };

  /// Creates a copy with replaced values.
  SearchEntryPoint copyWith({
    Object? renderedContent = unsetCopyWithValue,
    Object? sdkBlob = unsetCopyWithValue,
  }) {
    return SearchEntryPoint(
      renderedContent: renderedContent == unsetCopyWithValue
          ? this.renderedContent
          : renderedContent as String?,
      sdkBlob: sdkBlob == unsetCopyWithValue
          ? this.sdkBlob
          : sdkBlob as String?,
    );
  }

  @override
  String toString() =>
      'SearchEntryPoint(renderedContent: $renderedContent, sdkBlob: $sdkBlob)';
}
