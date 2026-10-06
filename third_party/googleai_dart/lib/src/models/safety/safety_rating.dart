import '../copy_with_sentinel.dart';
import 'harm_category.dart';
import 'harm_probability.dart';

/// Safety rating for a piece of content.
class SafetyRating {
  /// The category for this rating.
  final HarmCategory category;

  /// The probability of harm for this content.
  final HarmProbability probability;

  /// Was this content blocked because of this rating?
  final bool? blocked;

  /// Creates a [SafetyRating].
  const SafetyRating({
    required this.category,
    required this.probability,
    this.blocked,
  });

  /// Creates a [SafetyRating] from JSON.
  factory SafetyRating.fromJson(Map<String, dynamic> json) => SafetyRating(
    category: harmCategoryFromString(json['category'] as String?),
    probability: harmProbabilityFromString(json['probability'] as String?),
    blocked: json['blocked'] as bool?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'category': harmCategoryToString(category),
    'probability': harmProbabilityToString(probability),
    if (blocked != null) 'blocked': blocked,
  };

  /// Creates a copy with replaced values.
  SafetyRating copyWith({
    Object? category = unsetCopyWithValue,
    Object? probability = unsetCopyWithValue,
    Object? blocked = unsetCopyWithValue,
  }) {
    return SafetyRating(
      category: category == unsetCopyWithValue
          ? this.category
          : category! as HarmCategory,
      probability: probability == unsetCopyWithValue
          ? this.probability
          : probability! as HarmProbability,
      blocked: blocked == unsetCopyWithValue ? this.blocked : blocked as bool?,
    );
  }
}
