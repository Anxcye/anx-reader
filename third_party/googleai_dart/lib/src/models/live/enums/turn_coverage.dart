/// How much input is included in a turn.
enum TurnCoverage {
  /// Only detected user activity is included in the turn.
  ///
  /// Silence and non-speech audio are excluded.
  turnIncludesOnlyActivity('TURN_INCLUDES_ONLY_ACTIVITY'),

  /// All input is included in the turn.
  ///
  /// Includes silence and all audio, not just detected speech.
  turnIncludesAllInput('TURN_INCLUDES_ALL_INPUT');

  const TurnCoverage(this.value);

  /// The JSON value.
  final String value;

  /// Creates from JSON value.
  static TurnCoverage fromJson(String json) {
    return TurnCoverage.values.firstWhere(
      (e) => e.value == json,
      orElse: () => throw FormatException('Unknown TurnCoverage: $json'),
    );
  }

  /// Converts to JSON value.
  String toJson() => value;
}
