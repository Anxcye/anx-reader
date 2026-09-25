import '../copy_with_sentinel.dart';
import '../embeddings/embed_content_request.dart';

/// A single embed request in a batch with optional metadata.
class InlinedEmbedContentRequest {
  /// The request to be processed in the batch.
  final EmbedContentRequest request;

  /// Optional metadata to be associated with the request.
  final Map<String, dynamic>? metadata;

  /// Creates an [InlinedEmbedContentRequest].
  const InlinedEmbedContentRequest({required this.request, this.metadata});

  /// Creates an [InlinedEmbedContentRequest] from JSON.
  factory InlinedEmbedContentRequest.fromJson(Map<String, dynamic> json) =>
      InlinedEmbedContentRequest(
        request: EmbedContentRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        ),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'request': request.toJson(),
    if (metadata != null) 'metadata': metadata,
  };

  /// Creates a copy with replaced values.
  InlinedEmbedContentRequest copyWith({
    Object? request = unsetCopyWithValue,
    Object? metadata = unsetCopyWithValue,
  }) {
    return InlinedEmbedContentRequest(
      request: request == unsetCopyWithValue
          ? this.request
          : request! as EmbedContentRequest,
      metadata: metadata == unsetCopyWithValue
          ? this.metadata
          : metadata as Map<String, dynamic>?,
    );
  }
}
