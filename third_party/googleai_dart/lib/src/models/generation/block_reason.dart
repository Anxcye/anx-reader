/// Specifies the reason why the input was blocked.
enum BlockReason {
  /// Default value. This value is unused.
  unspecified,

  /// Input was blocked due to safety reasons. Inspect
  /// `safety_ratings` to understand which safety category blocked it.
  safety,

  /// Input was blocked due to other reasons.
  other,
}

/// Converts string to BlockReason enum.
BlockReason blockReasonFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'SAFETY' => BlockReason.safety,
    'OTHER' => BlockReason.other,
    _ => BlockReason.unspecified,
  };
}

/// Converts BlockReason enum to string.
String blockReasonToString(BlockReason reason) {
  return switch (reason) {
    BlockReason.safety => 'SAFETY',
    BlockReason.other => 'OTHER',
    BlockReason.unspecified => 'BLOCK_REASON_UNSPECIFIED',
  };
}
