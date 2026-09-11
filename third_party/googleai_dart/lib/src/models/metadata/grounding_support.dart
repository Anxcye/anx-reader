import '../copy_with_sentinel.dart';
import 'segment.dart';

/// Grounding support.
class GroundingSupport {
  /// Segment of the content this support belongs to.
  final Segment? segment;

  /// Optional. A list of indices (into 'grounding_chunk') specifying the
  /// citations associated with the claim.
  ///
  /// For instance [1,3,4] means that grounding_chunk[1], grounding_chunk[3],
  /// grounding_chunk[4] are the retrieved content attributed to the claim.
  final List<int>? groundingChunkIndices;

  /// Optional. Confidence score of the support references.
  ///
  /// Ranges from 0 to 1. 1 is the most confident. This list must have the
  /// same size as the grounding_chunk_indices.
  final List<double>? confidenceScores;

  /// Creates a [GroundingSupport].
  const GroundingSupport({
    this.segment,
    this.groundingChunkIndices,
    this.confidenceScores,
  });

  /// Creates a [GroundingSupport] from JSON.
  factory GroundingSupport.fromJson(Map<String, dynamic> json) =>
      GroundingSupport(
        segment: json['segment'] != null
            ? Segment.fromJson(json['segment'] as Map<String, dynamic>)
            : null,
        groundingChunkIndices: (json['groundingChunkIndices'] as List?)
            ?.map((e) => e as int)
            .toList(),
        confidenceScores: (json['confidenceScores'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList(),
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (segment != null) 'segment': segment!.toJson(),
    if (groundingChunkIndices != null)
      'groundingChunkIndices': groundingChunkIndices,
    if (confidenceScores != null) 'confidenceScores': confidenceScores,
  };

  /// Creates a copy with replaced values.
  GroundingSupport copyWith({
    Object? segment = unsetCopyWithValue,
    Object? groundingChunkIndices = unsetCopyWithValue,
    Object? confidenceScores = unsetCopyWithValue,
  }) {
    return GroundingSupport(
      segment: segment == unsetCopyWithValue
          ? this.segment
          : segment as Segment?,
      groundingChunkIndices: groundingChunkIndices == unsetCopyWithValue
          ? this.groundingChunkIndices
          : groundingChunkIndices as List<int>?,
      confidenceScores: confidenceScores == unsetCopyWithValue
          ? this.confidenceScores
          : confidenceScores as List<double>?,
    );
  }

  @override
  String toString() =>
      'GroundingSupport(segment: $segment, groundingChunkIndices: $groundingChunkIndices, confidenceScores: $confidenceScores)';
}
