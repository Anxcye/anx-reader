import '../copy_with_sentinel.dart';
import 'inlined_response.dart';

/// A list of inlined responses from batch processing.
class InlinedResponses {
  /// The responses to the requests in the batch.
  final List<InlinedResponse>? inlinedResponses;

  /// Creates an [InlinedResponses].
  const InlinedResponses({this.inlinedResponses});

  /// Creates an [InlinedResponses] from JSON.
  factory InlinedResponses.fromJson(Map<String, dynamic> json) =>
      InlinedResponses(
        inlinedResponses: json['inlinedResponses'] != null
            ? (json['inlinedResponses'] as List)
                  .map(
                    (e) => InlinedResponse.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (inlinedResponses != null)
      'inlinedResponses': inlinedResponses!.map((e) => e.toJson()).toList(),
  };

  /// Creates a copy with replaced values.
  InlinedResponses copyWith({Object? inlinedResponses = unsetCopyWithValue}) {
    return InlinedResponses(
      inlinedResponses: inlinedResponses == unsetCopyWithValue
          ? this.inlinedResponses
          : inlinedResponses as List<InlinedResponse>?,
    );
  }
}
