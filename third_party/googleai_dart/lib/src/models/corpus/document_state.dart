/// State of a Document.
enum DocumentState {
  /// The default value. This value is used if the state is omitted.
  unspecified('STATE_UNSPECIFIED'),

  /// Some chunks of the Document are being processed.
  pending('STATE_PENDING'),

  /// All chunks of the Document are processed and available for querying.
  active('STATE_ACTIVE'),

  /// Some chunks of the Document failed processing.
  failed('STATE_FAILED');

  const DocumentState(this.value);

  /// The string value of the enum.
  final String value;

  /// Creates a [DocumentState] from a string value.
  static DocumentState fromString(String value) {
    return DocumentState.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DocumentState.unspecified,
    );
  }
}
