import '../copy_with_sentinel.dart';
import '../metadata/finish_reason.dart';
import '../safety/safety_rating.dart';

/// Feedback on the prompt in the request.
class PromptFeedback {
  /// Block reason for the prompt.
  final FinishReason? blockReason;

  /// Safety ratings for the prompt.
  final List<SafetyRating>? safetyRatings;

  /// Creates a [PromptFeedback].
  const PromptFeedback({this.blockReason, this.safetyRatings});

  /// Creates a [PromptFeedback] from JSON.
  factory PromptFeedback.fromJson(Map<String, dynamic> json) => PromptFeedback(
    blockReason: json['blockReason'] != null
        ? finishReasonFromString(json['blockReason'] as String?)
        : null,
    safetyRatings: json['safetyRatings'] != null
        ? (json['safetyRatings'] as List)
              .map((e) => SafetyRating.fromJson(e as Map<String, dynamic>))
              .toList()
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (blockReason != null) 'blockReason': finishReasonToString(blockReason!),
    if (safetyRatings != null)
      'safetyRatings': safetyRatings!.map((e) => e.toJson()).toList(),
  };

  /// Creates a copy with replaced values.
  PromptFeedback copyWith({
    Object? blockReason = unsetCopyWithValue,
    Object? safetyRatings = unsetCopyWithValue,
  }) {
    return PromptFeedback(
      blockReason: blockReason == unsetCopyWithValue
          ? this.blockReason
          : blockReason as FinishReason?,
      safetyRatings: safetyRatings == unsetCopyWithValue
          ? this.safetyRatings
          : safetyRatings as List<SafetyRating>?,
    );
  }
}
