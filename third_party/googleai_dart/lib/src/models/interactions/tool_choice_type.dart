/// The type of tool choice.
enum InteractionToolChoiceType {
  /// The model automatically decides whether to use tools.
  auto,

  /// The model must use at least one tool.
  any,

  /// The model must not use any tools.
  none,

  /// Use only validated tools.
  validated,
}

/// Converts a string to [InteractionToolChoiceType].
InteractionToolChoiceType interactionToolChoiceTypeFromString(String? value) {
  return switch (value) {
    'auto' => InteractionToolChoiceType.auto,
    'any' => InteractionToolChoiceType.any,
    'none' => InteractionToolChoiceType.none,
    'validated' => InteractionToolChoiceType.validated,
    _ => InteractionToolChoiceType.auto,
  };
}

/// Converts [InteractionToolChoiceType] to a string.
String interactionToolChoiceTypeToString(InteractionToolChoiceType type) {
  return switch (type) {
    InteractionToolChoiceType.auto => 'auto',
    InteractionToolChoiceType.any => 'any',
    InteractionToolChoiceType.none => 'none',
    InteractionToolChoiceType.validated => 'validated',
  };
}
