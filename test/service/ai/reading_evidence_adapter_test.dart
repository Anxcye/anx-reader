import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_evidence.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_evidence_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolved chapter evidence keeps exact offsets and spoiler boundary',
      () {
    final envelope = ReadingEvidenceAdapter.fromResolution(
      const ReadingEvidenceResolution(
        exactText: '原文证据',
        startOffset: 5,
        endOffset: 9,
        strategy: ReadingEvidenceMatchStrategy.exact,
        confidence: 1,
      ),
      id: 'e1',
      bookId: 1,
      chapterHref: 'chapter.xhtml',
      sourceProgress: .2,
      visibleFromProgress: .3,
      epistemicStatus: 'textFact',
      producer: 'resolver',
    );

    expect(envelope.isTraceable, isTrue);
    expect(envelope.startOffset, 5);
    expect(envelope.endOffset, 9);
    expect(envelope.isVisibleAtProgress(.29), isFalse);
    expect(envelope.isVisibleAtProgress(.3), isTrue);
  });

  test('artifact and wiki source adapt without changing source semantics', () {
    final artifact = ReadingArtifact(
      id: 'artifact',
      bookId: 2,
      moduleId: 'fiction.immersion',
      kind: ReadingArtifactKinds.event,
      sourceTextSnapshot: '事件原文',
      chapterHref: 'c1.xhtml',
      sourceProgress: .1,
      visibleFromProgress: .2,
      ingestedAt: 1,
      createdAt: 1,
      updatedAt: 1,
    );
    final wiki = BookWikiSourceRef(
      id: 'wiki-source',
      entryId: 'entry',
      bookId: 2,
      chapterHref: 'c1.xhtml',
      textSnapshot: '概念原文',
      sourceProgress: .1,
      createdAt: 1,
    );

    expect(ReadingEvidenceAdapter.fromArtifact(artifact)?.exactText, '事件原文');
    expect(
      ReadingEvidenceAdapter.fromWikiSource(
        wiki,
        visibleFromProgress: .2,
        epistemicStatus: 'textFact',
      )?.visibleFromProgress,
      .2,
    );
  });

  test('expert web evidence produces one envelope per real source URL', () {
    const evidence = EvidenceObject(
      id: 'expert',
      expertId: 'historian',
      claim: '主张',
      support: '依据',
      confidence: EvidenceConfidence.high,
      sourceUrls: ['https://example.com/a', 'https://example.com/b'],
    );

    final values = ReadingEvidenceAdapter.fromExpert(evidence);

    expect(values, hasLength(2));
    expect(values.every((item) => item.sourceKind == EvidenceSourceKind.web),
        isTrue);
    expect(values.every((item) => item.isTraceable), isTrue);
  });

  test('stored note boundaries cannot be relaxed by a lower caller boundary',
      () {
    const source = ReadingNoteSource(
        noteId: 'note',
        type: ReadingNoteSourceType.aiSession,
        sourceRef: 'session',
        cfi: 'epubcfi(/6/2)',
        textSnapshot: 'Original evidence',
        metadata: {'sourceProgress': .5, 'visibleFromProgress': .7},
        createdAt: 1);
    final evidence = ReadingEvidenceAdapter.fromNoteSource(source,
        bookId: 1, visibleFromProgress: .2);
    expect(evidence?.sourceProgress, .5);
    expect(evidence?.visibleFromProgress, .7);
    expect(evidence?.isVisibleAtProgress(.6), isFalse);
  });

  test('formal note source becomes book-scoped traceable evidence', () {
    const source = ReadingNoteSource(
      noteId: 'note',
      type: ReadingNoteSourceType.aiSession,
      sourceRef: 'session',
      chapterHref: 'chapter.xhtml',
      cfi: 'epubcfi(/6/2)',
      textSnapshot: '笔记原文',
      createdAt: 1,
    );

    final value = ReadingEvidenceAdapter.fromNoteSource(
      source,
      bookId: 9,
      visibleFromProgress: .4,
    );

    expect(value?.bookId, 9);
    expect(value?.exactText, '笔记原文');
    expect(value?.isTraceable, isTrue);
    expect(value?.isVisibleAtProgress(.39), isFalse);
  });

  test('unknown synchronized boundary metadata is conservatively rejected', () {
    for (final invalid in ['0.4', double.nan, double.infinity, -1, 2]) {
      final source = ReadingNoteSource(
          noteId: 'note',
          type: ReadingNoteSourceType.aiSession,
          sourceRef: 'session',
          cfi: 'epubcfi(/6/2)',
          textSnapshot: 'Quote',
          metadata: {'visibleFromProgress': invalid},
          createdAt: 1);
      expect(ReadingEvidenceAdapter.fromNoteSource(source, bookId: 1), isNull);
    }
  });
}
