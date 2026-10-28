/// How the model handles user activity during generation.
enum ActivityHandling {
  /// User activity (speech) interrupts model output.
  ///
  /// When the user starts speaking, the model stops generating.
  startOfActivityInterrupts('START_OF_ACTIVITY_INTERRUPTS'),

  /// User activity does not interrupt model output.
  ///
  /// The model continues generating even when the user speaks.
  noInterruption('NO_INTERRUPTION');

  const ActivityHandling(this.value);

  /// The JSON value.
  final String value;

  /// Creates from JSON value.
  static ActivityHandling fromJson(String json) {
    return ActivityHandling.values.firstWhere(
      (e) => e.value == json,
      orElse: () => throw FormatException('Unknown ActivityHandling: $json'),
    );
  }

  /// Converts to JSON value.
  String toJson() => value;
}
