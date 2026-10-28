import '../copy_with_sentinel.dart';
import '../generation/generate_content_request.dart';

/// A single request in a batch with optional metadata.
class InlinedRequest {
  /// The request to be processed in the batch.
  final GenerateContentRequest request;

  /// Optional metadata to be associated with the request.
  final Map<String, dynamic>? metadata;

  /// Creates an [InlinedRequest].
  const InlinedRequest({required this.request, this.metadata});

  /// Creates an [InlinedRequest] from JSON.
  factory InlinedRequest.fromJson(Map<String, dynamic> json) => InlinedRequest(
    request: GenerateContentRequest.fromJson(
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
  InlinedRequest copyWith({
    Object? request = unsetCopyWithValue,
    Object? metadata = unsetCopyWithValue,
  }) {
    return InlinedRequest(
      request: request == unsetCopyWithValue
          ? this.request
          : request! as GenerateContentRequest,
      metadata: metadata == unsetCopyWithValue
          ? this.metadata
          : metadata as Map<String, dynamic>?,
    );
  }
}
