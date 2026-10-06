/// Controls whether to include thought summaries in the response.
enum InteractionThinkingSummaries {
  /// Automatically include thought summaries.
  auto,

  /// Do not include thought summaries.
  none,
}

/// Converts a string to [InteractionThinkingSummaries].
InteractionThinkingSummaries interactionThinkingSummariesFromString(
  String? value,
) {
  return switch (value) {
    'auto' => InteractionThinkingSummaries.auto,
    'none' => InteractionThinkingSummaries.none,
    _ => InteractionThinkingSummaries.auto,
  };
}

/// Converts [InteractionThinkingSummaries] to a string.
String interactionThinkingSummariesToString(
  InteractionThinkingSummaries summaries,
) {
  return switch (summaries) {
    InteractionThinkingSummaries.auto => 'auto',
    InteractionThinkingSummaries.none => 'none',
  };
}
