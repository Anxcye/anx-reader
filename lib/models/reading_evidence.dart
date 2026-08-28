enum ReadingEvidenceMatchStrategy {
  exact,
  normalized,
  sentenceWindow,
}

class ReadingEvidenceResolution {
  const ReadingEvidenceResolution({
    required this.exactText,
    required this.startOffset,
    required this.endOffset,
    required this.strategy,
    required this.confidence,
  });

  /// Exact text sliced from the original chapter, never model-authored text.
  final String exactText;
  final int startOffset;
  final int endOffset;
  final ReadingEvidenceMatchStrategy strategy;
  final double confidence;
}
