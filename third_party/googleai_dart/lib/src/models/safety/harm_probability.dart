/// The probability that content is harmful.
enum HarmProbability {
  /// Probability unspecified.
  unspecified,

  /// Negligible probability.
  negligible,

  /// Low probability.
  low,

  /// Medium probability.
  medium,

  /// High probability.
  high,
}

/// Converts string to HarmProbability enum.
HarmProbability harmProbabilityFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'NEGLIGIBLE' => HarmProbability.negligible,
    'LOW' => HarmProbability.low,
    'MEDIUM' => HarmProbability.medium,
    'HIGH' => HarmProbability.high,
    _ => HarmProbability.unspecified,
  };
}

/// Converts HarmProbability enum to string.
String harmProbabilityToString(HarmProbability probability) {
  return switch (probability) {
    HarmProbability.negligible => 'NEGLIGIBLE',
    HarmProbability.low => 'LOW',
    HarmProbability.medium => 'MEDIUM',
    HarmProbability.high => 'HIGH',
    HarmProbability.unspecified => 'HARM_PROBABILITY_UNSPECIFIED',
  };
}
