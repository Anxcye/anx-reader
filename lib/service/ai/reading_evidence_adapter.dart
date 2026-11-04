import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_evidence.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';

abstract final class ReadingEvidenceAdapter {
  static EvidenceEnvelope? fromNoteSource(
    ReadingNoteSource source, {
    required int bookId,
    double visibleFromProgress = 0,
  }) {
    if (source.textSnapshot.trim().isEmpty ||
        (source.chapterHref?.isEmpty ?? true) &&
            (source.cfi?.isEmpty ?? true)) {
      return null;
    }
    final rawVisible = source.metadata['visibleFromProgress'];
    final rawProgress = source.metadata['sourceProgress'];
    if ((rawVisible != null && (rawVisible is! num || !rawVisible.isFinite)) ||
        (rawProgress != null &&
            (rawProgress is! num || !rawProgress.isFinite))) {
      return null;
    }
    if (rawVisible is num && (rawVisible < 0 || rawVisible > 1) ||
        rawProgress is num && (rawProgress < 0 || rawProgress > 1)) {
      return null;
    }
    final sourceProgress = rawProgress is num ? rawProgress.toDouble() : 0.0;
    final storedVisible = rawVisible is num ? rawVisible.toDouble() : 0.0;
    final inherited =
        storedVisible > sourceProgress ? storedVisible : sourceProgress;
    return EvidenceEnvelope(
      id: 'note-source:${source.noteId}:${source.createdAt}',
      sourceKind: EvidenceSourceKind.bookText,
      bookId: bookId,
      chapterHref: source.chapterHref,
      chapterTitle: source.chapterTitle,
      cfi: source.cfi,
      exactText: source.textSnapshot,
      sourceProgress: sourceProgress,
      visibleFromProgress:
          inherited > visibleFromProgress ? inherited : visibleFromProgress,
      producer: 'readingNote',
    );
  }

  static EvidenceEnvelope fromResolution(
    ReadingEvidenceResolution resolution, {
    required String id,
    required int bookId,
    required String chapterHref,
    String? chapterTitle,
    String? cfi,
    required double sourceProgress,
    required double visibleFromProgress,
    required String epistemicStatus,
    required String producer,
    String? model,
    int pipelineVersion = 1,
  }) =>
      EvidenceEnvelope(
        id: id,
        sourceKind: EvidenceSourceKind.bookText,
        bookId: bookId,
        chapterHref: chapterHref,
        chapterTitle: chapterTitle,
        cfi: cfi,
        startOffset: resolution.startOffset,
        endOffset: resolution.endOffset,
        exactText: resolution.exactText,
        sourceProgress: sourceProgress,
        visibleFromProgress: visibleFromProgress,
        matchStrategy: resolution.strategy,
        confidence: resolution.confidence,
        epistemicStatus: epistemicStatus,
        producer: producer,
        model: model,
        pipelineVersion: pipelineVersion,
      );

  static EvidenceEnvelope? fromArtifact(ReadingArtifact artifact) {
    if (artifact.sourceTextSnapshot.trim().isEmpty) return null;
    return EvidenceEnvelope(
      id: 'artifact-source:${artifact.id}',
      sourceKind: EvidenceSourceKind.bookText,
      bookId: artifact.bookId,
      chapterHref: artifact.chapterHref,
      chapterTitle: artifact.chapterTitle,
      cfi: artifact.sourceStartCfi ?? artifact.discoveredAtCfi,
      exactText: artifact.sourceTextSnapshot,
      sourceProgress: artifact.sourceProgress,
      visibleFromProgress: artifact.visibleFromProgress,
      epistemicStatus: artifact.epistemicStatus.name,
      producer: artifact.createdBy,
      pipelineVersion: artifact.schemaVersion,
    );
  }

  static EvidenceEnvelope? fromWikiSource(
    BookWikiSourceRef source, {
    required double visibleFromProgress,
    required String epistemicStatus,
    String producer = 'bookWiki',
    int pipelineVersion = 1,
  }) {
    if (source.textSnapshot.trim().isEmpty) return null;
    return EvidenceEnvelope(
      id: source.id,
      sourceKind: EvidenceSourceKind.bookText,
      bookId: source.bookId,
      chapterHref: source.chapterHref,
      chapterTitle: source.chapterTitle,
      cfi: source.cfi,
      exactText: source.textSnapshot,
      sourceProgress: source.sourceProgress,
      visibleFromProgress: visibleFromProgress,
      epistemicStatus: epistemicStatus,
      producer: producer,
      pipelineVersion: pipelineVersion,
    );
  }

  static List<EvidenceEnvelope> fromExpert(EvidenceObject evidence) {
    final confidence = switch (evidence.confidence) {
      EvidenceConfidence.low => .35,
      EvidenceConfidence.medium => .65,
      EvidenceConfidence.high => .9,
    };
    if (evidence.sourceUrls.isNotEmpty) {
      return [
        for (var i = 0; i < evidence.sourceUrls.length; i++)
          EvidenceEnvelope(
            id: '${evidence.id}:web:$i',
            sourceKind: EvidenceSourceKind.web,
            exactText: evidence.support,
            sourceUrl: evidence.sourceUrls[i],
            confidence: confidence,
            epistemicStatus: 'agentInference',
            producer: evidence.expertId,
          ),
      ];
    }
    return const [];
  }
}
