/// Sensitivity for detecting the end of user speech.
enum EndSensitivity {
  /// High sensitivity - more likely to detect speech end quickly.
  ///
  /// May cut off speech prematurely.
  high('HIGH'),

  /// Low sensitivity - waits longer before detecting speech end.
  ///
  /// May include more silence at the end.
  low('LOW');

  const EndSensitivity(this.value);

  /// The JSON value.
  final String value;

  /// Creates from JSON value.
  static EndSensitivity fromJson(String json) {
    return EndSensitivity.values.firstWhere(
      (e) => e.value == json,
      orElse: () => throw FormatException('Unknown EndSensitivity: $json'),
    );
  }

  /// Converts to JSON value.
  String toJson() => value;
}
