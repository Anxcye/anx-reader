import '../copy_with_sentinel.dart';

/// Metadata related to retrieval in the grounding flow.
class RetrievalMetadata {
  /// Optional. Score indicating how likely information from google search
  /// could help answer the prompt.
  ///
  /// The score is in the range [0, 1], where 0 is the least likely and 1
  /// is the most likely. This score is only populated when google search
  /// grounding and dynamic retrieval is enabled. It will be compared to
  /// the threshold to determine whether to trigger google search.
  final double? googleSearchDynamicRetrievalScore;

  /// Creates a [RetrievalMetadata].
  const RetrievalMetadata({this.googleSearchDynamicRetrievalScore});

  /// Creates a [RetrievalMetadata] from JSON.
  factory RetrievalMetadata.fromJson(Map<String, dynamic> json) =>
      RetrievalMetadata(
        googleSearchDynamicRetrievalScore:
            (json['googleSearchDynamicRetrievalScore'] as num?)?.toDouble(),
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (googleSearchDynamicRetrievalScore != null)
      'googleSearchDynamicRetrievalScore': googleSearchDynamicRetrievalScore,
  };

  /// Creates a copy with replaced values.
  RetrievalMetadata copyWith({
    Object? googleSearchDynamicRetrievalScore = unsetCopyWithValue,
  }) {
    return RetrievalMetadata(
      googleSearchDynamicRetrievalScore:
          googleSearchDynamicRetrievalScore == unsetCopyWithValue
          ? this.googleSearchDynamicRetrievalScore
          : googleSearchDynamicRetrievalScore as double?,
    );
  }

  @override
  String toString() =>
      'RetrievalMetadata(googleSearchDynamicRetrievalScore: $googleSearchDynamicRetrievalScore)';
}
