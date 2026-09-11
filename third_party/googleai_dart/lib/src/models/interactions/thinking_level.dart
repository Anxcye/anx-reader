/// Controls the level of thought tokens the model should generate.
enum InteractionThinkingLevel {
  /// Little to no thinking.
  minimal,

  /// Low thinking level.
  low,

  /// Medium thinking level.
  medium,

  /// High thinking level.
  high,
}

/// Converts a string to [InteractionThinkingLevel].
InteractionThinkingLevel interactionThinkingLevelFromString(String? value) {
  return switch (value) {
    'minimal' => InteractionThinkingLevel.minimal,
    'low' => InteractionThinkingLevel.low,
    'medium' => InteractionThinkingLevel.medium,
    'high' => InteractionThinkingLevel.high,
    _ => InteractionThinkingLevel.medium,
  };
}

/// Converts [InteractionThinkingLevel] to a string.
String interactionThinkingLevelToString(InteractionThinkingLevel level) {
  return switch (level) {
    InteractionThinkingLevel.minimal => 'minimal',
    InteractionThinkingLevel.low => 'low',
    InteractionThinkingLevel.medium => 'medium',
    InteractionThinkingLevel.high => 'high',
  };
}
