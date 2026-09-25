import '../copy_with_sentinel.dart';
import '../embeddings/embed_content_response.dart';
import 'status.dart';

/// A single embed response in a batch with optional metadata and error.
class InlinedEmbedContentResponse {
  /// The error encountered while processing the request (if any).
  final Status? error;

  /// The response to the request (if successful).
  final EmbedContentResponse? response;

  /// Metadata associated with the request.
  final Map<String, dynamic>? metadata;

  /// Creates an [InlinedEmbedContentResponse].
  const InlinedEmbedContentResponse({this.error, this.response, this.metadata});

  /// Creates an [InlinedEmbedContentResponse] from JSON.
  factory InlinedEmbedContentResponse.fromJson(Map<String, dynamic> json) =>
      InlinedEmbedContentResponse(
        error: json['error'] != null
            ? Status.fromJson(json['error'] as Map<String, dynamic>)
            : null,
        response: json['response'] != null
            ? EmbedContentResponse.fromJson(
                json['response'] as Map<String, dynamic>,
              )
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (error != null) 'error': error!.toJson(),
    if (response != null) 'response': response!.toJson(),
    if (metadata != null) 'metadata': metadata,
  };

  /// Creates a copy with replaced values.
  InlinedEmbedContentResponse copyWith({
    Object? error = unsetCopyWithValue,
    Object? response = unsetCopyWithValue,
    Object? metadata = unsetCopyWithValue,
  }) {
    return InlinedEmbedContentResponse(
      error: error == unsetCopyWithValue ? this.error : error as Status?,
      response: response == unsetCopyWithValue
          ? this.response
          : response as EmbedContentResponse?,
      metadata: metadata == unsetCopyWithValue
          ? this.metadata
          : metadata as Map<String, dynamic>?,
    );
  }
}
