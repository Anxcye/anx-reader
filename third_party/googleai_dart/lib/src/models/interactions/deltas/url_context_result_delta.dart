part of 'deltas.dart';

/// A URL context result delta update.
class UrlContextResultDelta extends InteractionDelta {
  @override
  String get type => 'url_context_result';

  /// ID to match the ID from the URL context call.
  final String? callId;

  /// The results of the URL context.
  final List<UrlContextResult>? result;

  /// Whether the URL context resulted in an error.
  final bool? isError;

  /// The signature of the URL context result.
  final String? signature;

  /// Creates a [UrlContextResultDelta] instance.
  const UrlContextResultDelta({
    this.callId,
    this.result,
    this.isError,
    this.signature,
  });

  /// Creates a [UrlContextResultDelta] from JSON.
  factory UrlContextResultDelta.fromJson(Map<String, dynamic> json) =>
      UrlContextResultDelta(
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
}
