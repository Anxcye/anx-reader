/// Style in which answers should be returned.
enum AnswerStyle {
  /// Unspecified answer style.
  unspecified,

  /// Succinct but abstract style.
  abstractive,

  /// Very brief and extractive style.
  extractive,

  /// Verbose style including extra details. The response may be formatted as a
  /// sentence, paragraph, multiple paragraphs, or bullet points, etc.
  verbose,
}

/// Converts string to AnswerStyle enum.
AnswerStyle answerStyleFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'ABSTRACTIVE' => AnswerStyle.abstractive,
    'EXTRACTIVE' => AnswerStyle.extractive,
    'VERBOSE' => AnswerStyle.verbose,
    _ => AnswerStyle.unspecified,
  };
}

/// Converts AnswerStyle enum to string.
String answerStyleToString(AnswerStyle style) {
  return switch (style) {
    AnswerStyle.abstractive => 'ABSTRACTIVE',
    AnswerStyle.extractive => 'EXTRACTIVE',
    AnswerStyle.verbose => 'VERBOSE',
    AnswerStyle.unspecified => 'ANSWER_STYLE_UNSPECIFIED',
  };
}
