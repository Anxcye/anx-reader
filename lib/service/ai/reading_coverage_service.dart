import 'dart:math' as math;

import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';

class ReadingCoverageService {
  ReadingCoverageService({
    ReadingAgentRepository? repository,
    int Function()? clock,
  })  : _repository = repository ?? readingAgentRepository,
        _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  static const midwayThreshold = .05;

  final ReadingAgentRepository _repository;
  final int Function() _clock;

  Future<BookReadingCoverage> loadOrInitialize({
    required int bookId,
    required double currentPosition,
    required bool supportsArtifacts,
  }) async {
    final existing = await _repository.bookReadingCoverage(bookId);
    if (existing != null) return existing;
    final now = _clock();
    final position = currentPosition.clamp(0, 1).toDouble();
    final pending = supportsArtifacts && position >= midwayThreshold;
    final coverage = BookReadingCoverage(
      bookId: bookId,
      safeKnowledgeBoundary: position,
      artifactCoverageStart: position,
      artifactCoverageEnd: position,
      setupStatus: pending
          ? ReadingCoverageSetupStatus.pending
          : ReadingCoverageSetupStatus.fromHere,
      initializedAtProgress: position,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveBookReadingCoverage(coverage);
    return coverage;
  }

  Future<BookReadingCoverage> startFromHere(BookReadingCoverage coverage) =>
      _save(coverage.copyWith(
        setupStatus: ReadingCoverageSetupStatus.fromHere,
        artifactCoverageStart: coverage.initializedAtProgress,
        artifactCoverageEnd: math.max(
          coverage.artifactCoverageEnd,
          coverage.initializedAtProgress,
        ),
      ));

  Future<BookReadingCoverage> markBackfilled(
    BookReadingCoverage coverage, {
    required double throughProgress,
  }) =>
      _save(coverage.copyWith(
        safeKnowledgeBoundary:
            math.max(coverage.safeKnowledgeBoundary, throughProgress),
        artifactCoverageStart: 0,
        artifactCoverageEnd:
            math.max(coverage.artifactCoverageEnd, throughProgress),
        setupStatus: ReadingCoverageSetupStatus.backfilled,
      ));

  Future<BookReadingCoverage> markImported(
    BookReadingCoverage coverage, {
    required double coverageStart,
    required double coverageEnd,
  }) =>
      _save(coverage.copyWith(
        artifactCoverageStart:
            math.min(coverage.artifactCoverageStart, coverageStart),
        artifactCoverageEnd:
            math.max(coverage.artifactCoverageEnd, coverageEnd),
        setupStatus: ReadingCoverageSetupStatus.imported,
      ));

  Future<BookReadingCoverage> advanceSafeBoundary(
    BookReadingCoverage coverage,
    double currentPosition,
  ) {
    final position = currentPosition.clamp(0, 1).toDouble();
    if (position <= coverage.safeKnowledgeBoundary) {
      return Future.value(coverage);
    }
    return _save(coverage.copyWith(
      safeKnowledgeBoundary: position,
      artifactCoverageEnd: coverage.setupPending
          ? coverage.artifactCoverageEnd
          : math.max(coverage.artifactCoverageEnd, position),
    ));
  }

  Future<BookReadingCoverage> _save(BookReadingCoverage coverage) async {
    final updated = coverage.copyWith(updatedAt: _clock());
    await _repository.saveBookReadingCoverage(updated);
    return updated;
  }
}

final readingCoverageService = ReadingCoverageService();
