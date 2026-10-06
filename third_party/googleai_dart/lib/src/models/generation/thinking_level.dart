/// Controls the depth of reasoning before generating responses.
enum ThinkingLevel {
  /// Default value.
  unspecified,

  /// Constrains the model to use minimal tokens for thinking.
  /// Best for low-complexity tasks. (Gemini 3 Flash only)
  minimal,

  /// Minimizes latency and cost.
  /// Best for simple instruction following or high-throughput apps.
  low,

  /// Balanced approach for moderate complexity tasks.
  /// (Gemini 3 Flash only)
  medium,

  /// Allows deep reasoning with more tokens.
  /// Default for Gemini 3 models.
  high,
}

/// Converts string to ThinkingLevel enum.
ThinkingLevel thinkingLevelFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'MINIMAL' => ThinkingLevel.minimal,
    'LOW' => ThinkingLevel.low,
    'MEDIUM' => ThinkingLevel.medium,
    'HIGH' => ThinkingLevel.high,
    _ => ThinkingLevel.unspecified,
  };
}

/// Converts ThinkingLevel enum to string.
String thinkingLevelToString(ThinkingLevel level) {
  return switch (level) {
    ThinkingLevel.minimal => 'MINIMAL',
    ThinkingLevel.low => 'LOW',
    ThinkingLevel.medium => 'MEDIUM',
    ThinkingLevel.high => 'HIGH',
    ThinkingLevel.unspecified => 'THINKING_LEVEL_UNSPECIFIED',
  };
}
