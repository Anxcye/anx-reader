part of 'content.dart';

/// A URL context result content block.
class UrlContextResultContent extends InteractionContent {
  @override
  String get type => 'url_context_result';

  /// ID to match the ID from the URL context call block.
  final String? callId;

  /// The results of the URL context.
  final List<UrlContextResult>? result;

  /// Whether the URL context resulted in an error.
  final bool? isError;

  /// The signature of the URL context result.
  final String? signature;

  /// Creates a [UrlContextResultContent] instance.
  const UrlContextResultContent({
    this.callId,
    this.result,
    this.isError,
    this.signature,
  });

  /// Creates a [UrlContextResultContent] from JSON.
  factory UrlContextResultContent.fromJson(Map<String, dynamic> json) =>
      UrlContextResultContent(
        callId: json['call_id'] as String?,
        result: (json['result'] as List<dynamic>?)
            ?.map((e) => UrlContextResult.fromJson(e as Map<String, dynamic>))
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
  UrlContextResultContent copyWith({
    Object? callId = unsetCopyWithValue,
    Object? result = unsetCopyWithValue,
    Object? isError = unsetCopyWithValue,
    Object? signature = unsetCopyWithValue,
  }) {
    return UrlContextResultContent(
      callId: callId == unsetCopyWithValue ? this.callId : callId as String?,
      result: result == unsetCopyWithValue
          ? this.result
          : result as List<UrlContextResult>?,
      isError: isError == unsetCopyWithValue ? this.isError : isError as bool?,
      signature: signature == unsetCopyWithValue
          ? this.signature
          : signature as String?,
    );
  }
}

/// A URL context result item.
class UrlContextResult {
  /// The URL that was fetched.
  final String? url;

  /// The status of the URL fetch.
  final String? status;

  /// Creates a [UrlContextResult] instance.
  const UrlContextResult({this.url, this.status});

  /// Creates a [UrlContextResult] from JSON.
  factory UrlContextResult.fromJson(Map<String, dynamic> json) =>
      UrlContextResult(
        url: json['url'] as String?,
        status: json['status'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (url != null) 'url': url,
    if (status != null) 'status': status,
  };

  /// Creates a copy with replaced values.
  UrlContextResult copyWith({
    Object? url = unsetCopyWithValue,
    Object? status = unsetCopyWithValue,
  }) {
    return UrlContextResult(
      url: url == unsetCopyWithValue ? this.url : url as String?,
      status: status == unsetCopyWithValue ? this.status : status as String?,
    );
  }
}
