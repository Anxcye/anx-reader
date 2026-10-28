/// Why generation stopped.
enum FinishReason {
  /// Unknown reason.
  unspecified,

  /// Natural stop (e.g., stop sequence, EOS token).
  stop,

  /// Hit max output tokens.
  maxTokens,

  /// Blocked by safety filters.
  safety,

  /// Blocked due to recitation/citation issues.
  recitation,

  /// Other reason.
  other,

  /// Blocked by custom blocklist.
  blocklist,

  /// Prohibited content detected.
  prohibitedContent,

  /// Sensitive PII detected.
  spii,

  /// Malformed function call.
  malformedFunctionCall,
}

/// Converts string to FinishReason enum.
FinishReason finishReasonFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'STOP' => FinishReason.stop,
    'MAX_TOKENS' => FinishReason.maxTokens,
    'SAFETY' => FinishReason.safety,
    'RECITATION' => FinishReason.recitation,
    'OTHER' => FinishReason.other,
    'BLOCKLIST' => FinishReason.blocklist,
    'PROHIBITED_CONTENT' => FinishReason.prohibitedContent,
    'SPII' => FinishReason.spii,
    'MALFORMED_FUNCTION_CALL' => FinishReason.malformedFunctionCall,
    _ => FinishReason.unspecified,
  };
}

/// Converts FinishReason enum to string.
String finishReasonToString(FinishReason reason) {
  return switch (reason) {
    FinishReason.stop => 'STOP',
    FinishReason.maxTokens => 'MAX_TOKENS',
    FinishReason.safety => 'SAFETY',
    FinishReason.recitation => 'RECITATION',
    FinishReason.other => 'OTHER',
    FinishReason.blocklist => 'BLOCKLIST',
    FinishReason.prohibitedContent => 'PROHIBITED_CONTENT',
    FinishReason.spii => 'SPII',
    FinishReason.malformedFunctionCall => 'MALFORMED_FUNCTION_CALL',
    FinishReason.unspecified => 'FINISH_REASON_UNSPECIFIED',
  };
}
