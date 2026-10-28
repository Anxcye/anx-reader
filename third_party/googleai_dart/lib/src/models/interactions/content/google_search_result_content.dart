part of 'content.dart';

/// A Google Search result content block.
class GoogleSearchResultContent extends InteractionContent {
  @override
  String get type => 'google_search_result';

  /// ID to match the ID from the Google Search call block.
  final String? callId;

  /// The results of the Google Search.
  final List<GoogleSearchResult>? result;

  /// Whether the Google Search resulted in an error.
  final bool? isError;

  /// The signature of the Google Search result.
  final String? signature;

  /// Creates a [GoogleSearchResultContent] instance.
  const GoogleSearchResultContent({
    this.callId,
    this.result,
    this.isError,
    this.signature,
  });

  /// Creates a [GoogleSearchResultContent] from JSON.
  factory GoogleSearchResultContent.fromJson(Map<String, dynamic> json) =>
      GoogleSearchResultContent(
        callId: json['call_id'] as String?,
        result: (json['result'] as List<dynamic>?)
            ?.map((e) => GoogleSearchResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        isError: json['is_error'] as bool?,
        signature: json['signature'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (callId != null) 'call_id': callId,
    if (result != null) 'result': result!.map((e) => e.toJson()).toList(),
    if (isError != null) 'is_error': isError,
    if (signature != null) 'signature': signature,
  };

  /// Creates a copy with replaced values.
  GoogleSearchResultContent copyWith({
    Object? callId = unsetCopyWithValue,
    Object? result = unsetCopyWithValue,
    Object? isError = unsetCopyWithValue,
    Object? signature = unsetCopyWithValue,
  }) {
    return GoogleSearchResultContent(
      callId: callId == unsetCopyWithValue ? this.callId : callId as String?,
      result: result == unsetCopyWithValue
          ? this.result
          : result as List<GoogleSearchResult>?,
      isError: isError == unsetCopyWithValue ? this.isError : isError as bool?,
      signature: signature == unsetCopyWithValue
          ? this.signature
          : signature as String?,
    );
  }
}

/// A Google Search result item.
class GoogleSearchResult {
  /// The URL of the search result.
  final String? url;

  /// The title of the search result.
  final String? title;

  /// Creates a [GoogleSearchResult] instance.
  const GoogleSearchResult({this.url, this.title});

  /// Creates a [GoogleSearchResult] from JSON.
  factory GoogleSearchResult.fromJson(Map<String, dynamic> json) =>
      GoogleSearchResult(
        url: json['url'] as String?,
        title: json['title'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (url != null) 'url': url,
    if (title != null) 'title': title,
  };

  /// Creates a copy with replaced values.
  GoogleSearchResult copyWith({
    Object? url = unsetCopyWithValue,
    Object? title = unsetCopyWithValue,
  }) {
    return GoogleSearchResult(
      url: url == unsetCopyWithValue ? this.url : url as String?,
      title: title == unsetCopyWithValue ? this.title : title as String?,
    );
  }
}
