import '../copy_with_sentinel.dart';
import 'content_embedding.dart';

/// Response from embedding content.
class EmbedContentResponse {
  /// The embedding for the content.
  final ContentEmbedding embedding;

  /// Creates an [EmbedContentResponse].
  const EmbedContentResponse({required this.embedding});

  /// Creates an [EmbedContentResponse] from JSON.
  factory EmbedContentResponse.fromJson(Map<String, dynamic> json) =>
      EmbedContentResponse(
        embedding: ContentEmbedding.fromJson(
          json['embedding'] as Map<String, dynamic>,
        ),
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {'embedding': embedding.toJson()};

  /// Creates a copy with replaced values.
  EmbedContentResponse copyWith({Object? embedding = unsetCopyWithValue}) {
    return EmbedContentResponse(
      embedding: embedding == unsetCopyWithValue
          ? this.embedding
          : embedding! as ContentEmbedding,
    );
  }
}
