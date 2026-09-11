/// State of an uploaded file.
enum FileState {
  /// Unspecified state.
  unspecified,

  /// File is being processed.
  processing,

  /// File is ready to use.
  active,

  /// File processing failed.
  failed,
}

/// Converts a string to a [FileState].
FileState fileStateFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'PROCESSING' => FileState.processing,
    'ACTIVE' => FileState.active,
    'FAILED' => FileState.failed,
    _ => FileState.unspecified,
  };
}

/// Converts a [FileState] to a string.
String fileStateToString(FileState state) {
  return switch (state) {
    FileState.processing => 'PROCESSING',
    FileState.active => 'ACTIVE',
    FileState.failed => 'FAILED',
    FileState.unspecified => 'STATE_UNSPECIFIED',
  };
}
