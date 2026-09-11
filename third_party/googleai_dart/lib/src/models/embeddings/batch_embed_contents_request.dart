import 'embed_content_request.dart';

/// Batch request to get embeddings from the model for a list of prompts.
class BatchEmbedContentsRequest {
  /// Required. Embed requests for the batch.
  ///
  /// The model in each of these requests must match the model specified
  /// in the API call.
  final List<EmbedContentRequest> requests;

  /// Creates a [BatchEmbedContentsRequest].
  const BatchEmbedContentsRequest({required this.requests});

  /// Creates a [BatchEmbedContentsRequest] from JSON.
  factory BatchEmbedContentsRequest.fromJson(Map<String, dynamic> json) =>
      BatchEmbedContentsRequest(
        requests: ((json['requests'] as List<dynamic>?) ?? [])
            .map((e) => EmbedContentRequest.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'requests': requests.map((e) => e.toJson()).toList(),
  };
}
