enum ReadingEvidenceMatchStrategy {
  exact,
  normalized,
  sentenceWindow,
}

enum EvidenceSourceKind { bookText, web, readerRecord }

/// Shared source semantics for specialist evidence, resolved book text,
/// ReadingArtifact sources and Book Wiki sources. Domain payloads stay in
/// their own models; this envelope only standardizes attribution.
class EvidenceEnvelope {
  const EvidenceEnvelope({
    required this.id,
    required this.sourceKind,
    this.bookId,
    this.chapterHref,
    this.chapterTitle,
    this.cfi,
    this.startOffset,
    this.endOffset,
    this.exactText = '',
    this.sourceUrl,
    this.sourceRef,
    this.sourceProgress = 0,
    this.visibleFromProgress = 0,
    this.matchStrategy = ReadingEvidenceMatchStrategy.exact,
    this.confidence = 1,
    this.epistemicStatus = 'textFact',
    required this.producer,
    this.model,
    this.pipelineVersion = 1,
  });

  final String id;
  final EvidenceSourceKind sourceKind;
  final int? bookId;
  final String? chapterHref;
  final String? chapterTitle;
  final String? cfi;
  final int? startOffset;
  final int? endOffset;
  final String exactText;
  final String? sourceUrl;
  final String? sourceRef;
  final double sourceProgress;
  final double visibleFromProgress;
  final ReadingEvidenceMatchStrategy matchStrategy;
  final double confidence;
  final String epistemicStatus;
  final String producer;
  final String? model;
  final int pipelineVersion;

  bool get isTraceable => switch (sourceKind) {
        EvidenceSourceKind.bookText => bookId != null &&
            (chapterHref?.isNotEmpty == true || cfi?.isNotEmpty == true) &&
            exactText.isNotEmpty,
        EvidenceSourceKind.web => sourceUrl?.isNotEmpty == true,
        EvidenceSourceKind.readerRecord => bookId != null &&
            sourceRef?.isNotEmpty == true &&
            exactText.isNotEmpty,
      };

  bool isVisibleAtProgress(double progress) =>
      visibleFromProgress <= progress.clamp(0, 1) + 0.000001;
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
