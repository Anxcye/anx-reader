import '../copy_with_sentinel.dart';
import 'inlined_embed_content_response.dart';

/// A list of inlined embed responses from batch processing.
class InlinedEmbedContentResponses {
  /// The responses to the requests in the batch.
  final List<InlinedEmbedContentResponse>? inlinedResponses;

  /// Creates an [InlinedEmbedContentResponses].
  const InlinedEmbedContentResponses({this.inlinedResponses});

  /// Creates an [InlinedEmbedContentResponses] from JSON.
  factory InlinedEmbedContentResponses.fromJson(Map<String, dynamic> json) =>
      InlinedEmbedContentResponses(
        inlinedResponses: json['inlinedResponses'] != null
            ? (json['inlinedResponses'] as List)
                  .map(
                    (e) => InlinedEmbedContentResponse.fromJson(
                      e as Map<String, dynamic>,
                    ),
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
  InlinedEmbedContentResponses copyWith({
    Object? inlinedResponses = unsetCopyWithValue,
  }) {
    return InlinedEmbedContentResponses(
      inlinedResponses: inlinedResponses == unsetCopyWithValue
          ? this.inlinedResponses
          : inlinedResponses as List<InlinedEmbedContentResponse>?,
    );
  }
}
