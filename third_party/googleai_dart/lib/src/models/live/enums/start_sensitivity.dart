/// Sensitivity for detecting the start of user speech.
enum StartSensitivity {
  /// High sensitivity - more likely to detect speech start.
  ///
  /// May result in more false positives (detecting non-speech as speech).
  high('HIGH'),

  /// Low sensitivity - less likely to detect speech start.
  ///
  /// May result in more false negatives (missing actual speech start).
  low('LOW');

  const StartSensitivity(this.value);

  /// The JSON value.
  final String value;

  /// Creates from JSON value.
  static StartSensitivity fromJson(String json) {
    return StartSensitivity.values.firstWhere(
      (e) => e.value == json,
      orElse: () => throw FormatException('Unknown StartSensitivity: $json'),
    );
  }

  /// Converts to JSON value.
  String toJson() => value;
}
