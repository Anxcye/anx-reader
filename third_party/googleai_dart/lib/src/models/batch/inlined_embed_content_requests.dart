import '../copy_with_sentinel.dart';
import 'inlined_embed_content_request.dart';

/// A list of inlined embed requests for batch processing.
class InlinedEmbedContentRequests {
  /// The requests to be processed in the batch.
  final List<InlinedEmbedContentRequest> requests;

  /// Creates an [InlinedEmbedContentRequests].
  const InlinedEmbedContentRequests({required this.requests});

  /// Creates an [InlinedEmbedContentRequests] from JSON.
  factory InlinedEmbedContentRequests.fromJson(Map<String, dynamic> json) =>
      InlinedEmbedContentRequests(
        requests: ((json['requests'] as List?) ?? [])
            .map(
              (e) => InlinedEmbedContentRequest.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'requests': requests.map((e) => e.toJson()).toList(),
  };

  /// Creates a copy with replaced values.
  InlinedEmbedContentRequests copyWith({
    Object? requests = unsetCopyWithValue,
  }) {
    return InlinedEmbedContentRequests(
      requests: requests == unsetCopyWithValue
          ? this.requests
          : requests! as List<InlinedEmbedContentRequest>,
    );
  }
}
