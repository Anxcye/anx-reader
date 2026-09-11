import '../safety/safety_rating.dart';
import 'block_reason.dart';

/// Feedback related to the input data used to answer the question, as opposed
/// to the model-generated response to the question.
///
/// The input data can be one or more of the following:
/// - Question specified by the last entry in `GenerateAnswerRequest.content`
/// - Conversation history specified by the other entries in
///   `GenerateAnswerRequest.content`
/// - Grounding sources (`GenerateAnswerRequest.semantic_retriever` or
///   `GenerateAnswerRequest.inline_passages`)
class InputFeedback {
  /// Optional. If set, the input was blocked and no candidates are returned.
  /// Rephrase the input.
  final BlockReason? blockReason;

  /// Ratings for safety of the input.
  /// There is at most one rating per category.
  final List<SafetyRating>? safetyRatings;

  /// Creates an [InputFeedback].
  const InputFeedback({this.blockReason, this.safetyRatings});

  /// Creates an [InputFeedback] from JSON.
  factory InputFeedback.fromJson(Map<String, dynamic> json) => InputFeedback(
    blockReason: json['blockReason'] != null
        ? blockReasonFromString(json['blockReason'] as String?)
        : null,
    safetyRatings: json['safetyRatings'] != null
        ? (json['safetyRatings'] as List)
              .map((e) => SafetyRating.fromJson(e as Map<String, dynamic>))
              .toList()
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (blockReason != null) 'blockReason': blockReasonToString(blockReason!),
    if (safetyRatings != null)
      'safetyRatings': safetyRatings!.map((e) => e.toJson()).toList(),
  };
}
