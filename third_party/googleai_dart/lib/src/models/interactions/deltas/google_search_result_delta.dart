part of 'deltas.dart';

/// A Google Search result delta update.
class GoogleSearchResultDelta extends InteractionDelta {
  @override
  String get type => 'google_search_result';

  /// ID to match the ID from the Google Search call.
  final String? callId;

  /// The results of the Google Search.
  final List<GoogleSearchResult>? result;

  /// Whether the Google Search resulted in an error.
  final bool? isError;

  /// The signature of the Google Search result.
  final String? signature;

  /// Creates a [GoogleSearchResultDelta] instance.
  const GoogleSearchResultDelta({
    this.callId,
    this.result,
    this.isError,
    this.signature,
  });

  /// Creates a [GoogleSearchResultDelta] from JSON.
  factory GoogleSearchResultDelta.fromJson(Map<String, dynamic> json) =>
      GoogleSearchResultDelta(
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
}
