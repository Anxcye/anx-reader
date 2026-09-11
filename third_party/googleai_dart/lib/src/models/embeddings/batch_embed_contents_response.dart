import 'content_embedding.dart';

/// The response to a [BatchEmbedContentsRequest].
class BatchEmbedContentsResponse {
  /// Output only. The embeddings for each request, in the same order as
  /// provided in the batch request.
  final List<ContentEmbedding> embeddings;

  /// Creates a [BatchEmbedContentsResponse].
  const BatchEmbedContentsResponse({required this.embeddings});

  /// Creates a [BatchEmbedContentsResponse] from JSON.
  factory BatchEmbedContentsResponse.fromJson(Map<String, dynamic> json) =>
      BatchEmbedContentsResponse(
        embeddings: ((json['embeddings'] as List<dynamic>?) ?? [])
            .map((e) => ContentEmbedding.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'embeddings': embeddings.map((e) => e.toJson()).toList(),
  };
}
