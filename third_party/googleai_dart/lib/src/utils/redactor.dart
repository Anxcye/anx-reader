/// Utility for redacting sensitive data from logs.
class Redactor {
  /// Fields to redact (case-insensitive).
  final List<String> redactionList;

  /// Replacement text for redacted values.
  final String replacement;

  /// Creates a [Redactor].
  const Redactor({
    required this.redactionList,
    this.replacement = '***REDACTED***',
  });

  /// Redacts sensitive fields from a map.
  ///
  /// Returns a new map with sensitive values replaced.
  Map<String, String> redactMap(Map<String, String> input) {
    final redacted = <String, String>{};
    final lowercaseFields = redactionList.map((f) => f.toLowerCase()).toSet();

    for (final entry in input.entries) {
      if (lowercaseFields.contains(entry.key.toLowerCase())) {
        redacted[entry.key] = replacement;
      } else {
        redacted[entry.key] = entry.value;
      }
    }

    return redacted;
  }

  /// Redacts sensitive data from a string.
  ///
  /// This is a simple implementation that looks for key=value patterns.
  String redactString(String input) {
    var result = input;

    for (final field in redactionList) {
      // Redact JSON-style: "field": "value"
      result = result.replaceAllMapped(
        RegExp('"$field":\\s*"([^"]*)"', caseSensitive: false),
        (match) => '"$field": "$replacement"',
      );

      // Redact query param style: field=value
      result = result.replaceAllMapped(
        RegExp('$field=([^&\\s]*)', caseSensitive: false),
        (match) => '$field=$replacement',
      );

      // Redact header style: field: value
      result = result.replaceAllMapped(
        RegExp('$field:\\s*([^\\n]*)', caseSensitive: false),
        (match) => '$field: $replacement',
      );
    }

    return result;
  }

  /// Truncates a string to a maximum length.
  String truncate(String input, int maxLength) {
    if (input.length <= maxLength) return input;
    return '${input.substring(0, maxLength)}... [truncated]';
  }
}
