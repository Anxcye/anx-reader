import '../copy_with_sentinel.dart';
import 'thinking_level.dart';

/// Configuration for thinking features.
class ThinkingConfig {
  /// Whether to include thoughts in the response.
  final bool? includeThoughts;

  /// Number of thought tokens the model should generate.
  /// Use for Gemini 2.5 models. Cannot be used with [thinkingLevel].
  final int? thinkingBudget;

  /// Controls reasoning depth. Use for Gemini 3+ models.
  /// Cannot be used with [thinkingBudget].
  final ThinkingLevel? thinkingLevel;

  /// Creates a [ThinkingConfig].
  const ThinkingConfig({
    this.includeThoughts,
    this.thinkingBudget,
    this.thinkingLevel,
  });

  /// Creates a [ThinkingConfig] from JSON.
  factory ThinkingConfig.fromJson(Map<String, dynamic> json) => ThinkingConfig(
    includeThoughts: json['includeThoughts'] as bool?,
    thinkingBudget: json['thinkingBudget'] as int?,
    thinkingLevel: json['thinkingLevel'] != null
        ? thinkingLevelFromString(json['thinkingLevel'] as String?)
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (includeThoughts != null) 'includeThoughts': includeThoughts,
    if (thinkingBudget != null) 'thinkingBudget': thinkingBudget,
    if (thinkingLevel != null)
      'thinkingLevel': thinkingLevelToString(thinkingLevel!),
  };

  /// Creates a copy with replaced values.
  ThinkingConfig copyWith({
    Object? includeThoughts = unsetCopyWithValue,
    Object? thinkingBudget = unsetCopyWithValue,
    Object? thinkingLevel = unsetCopyWithValue,
  }) {
    return ThinkingConfig(
      includeThoughts: includeThoughts == unsetCopyWithValue
          ? this.includeThoughts
          : includeThoughts as bool?,
      thinkingBudget: thinkingBudget == unsetCopyWithValue
          ? this.thinkingBudget
          : thinkingBudget as int?,
      thinkingLevel: thinkingLevel == unsetCopyWithValue
          ? this.thinkingLevel
          : thinkingLevel as ThinkingLevel?,
    );
  }
}
