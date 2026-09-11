import '../copy_with_sentinel.dart';
import 'harm_category.dart';

/// Threshold for blocking harmful content.
enum HarmBlockThreshold {
  /// Unspecified threshold.
  unspecified,

  /// Block low and above.
  blockLowAndAbove,

  /// Block medium and above.
  blockMediumAndAbove,

  /// Block only high.
  blockOnlyHigh,

  /// Block none.
  blockNone,

  /// Off (no blocking).
  off,
}

/// Converts string to HarmBlockThreshold enum.
HarmBlockThreshold harmBlockThresholdFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'BLOCK_LOW_AND_ABOVE' => HarmBlockThreshold.blockLowAndAbove,
    'BLOCK_MEDIUM_AND_ABOVE' => HarmBlockThreshold.blockMediumAndAbove,
    'BLOCK_ONLY_HIGH' => HarmBlockThreshold.blockOnlyHigh,
    'BLOCK_NONE' => HarmBlockThreshold.blockNone,
    'OFF' => HarmBlockThreshold.off,
    _ => HarmBlockThreshold.unspecified,
  };
}

/// Converts HarmBlockThreshold enum to string.
String harmBlockThresholdToString(HarmBlockThreshold threshold) {
  return switch (threshold) {
    HarmBlockThreshold.blockLowAndAbove => 'BLOCK_LOW_AND_ABOVE',
    HarmBlockThreshold.blockMediumAndAbove => 'BLOCK_MEDIUM_AND_ABOVE',
    HarmBlockThreshold.blockOnlyHigh => 'BLOCK_ONLY_HIGH',
    HarmBlockThreshold.blockNone => 'BLOCK_NONE',
    HarmBlockThreshold.off => 'OFF',
    HarmBlockThreshold.unspecified => 'HARM_BLOCK_THRESHOLD_UNSPECIFIED',
  };
}

/// Safety setting to block content at different thresholds.
class SafetySetting {
  /// The category for this setting.
  final HarmCategory category;

  /// The threshold for blocking.
  final HarmBlockThreshold threshold;

  /// Creates a [SafetySetting].
  const SafetySetting({required this.category, required this.threshold});

  /// Creates a [SafetySetting] from JSON.
  factory SafetySetting.fromJson(Map<String, dynamic> json) => SafetySetting(
    category: harmCategoryFromString(json['category'] as String?),
    threshold: harmBlockThresholdFromString(json['threshold'] as String?),
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'category': harmCategoryToString(category),
    'threshold': harmBlockThresholdToString(threshold),
  };

  /// Creates a copy with replaced values.
  SafetySetting copyWith({
    Object? category = unsetCopyWithValue,
    Object? threshold = unsetCopyWithValue,
  }) {
    return SafetySetting(
      category: category == unsetCopyWithValue
          ? this.category
          : category! as HarmCategory,
      threshold: threshold == unsetCopyWithValue
          ? this.threshold
          : threshold! as HarmBlockThreshold,
    );
  }
}
