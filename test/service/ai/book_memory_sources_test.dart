import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/book_wiki_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'book_materials_test.dart' as fixtures;

void main() {
  test('Wiki generation fingerprints use exact evidence for visibility',
      () async {
    final hash = 'a' * 40;
    final repository = fixtures.MemoryRepository()
      ..entries = [
        fixtures.wikiEntry('generated',
            artifactIds: ['content:$hash', 'generation:$hash']),
        fixtures.wikiEntry('missing', artifactIds: ['unknown:source']),
        fixtures.wikiEntry('unproven', artifactIds: ['content:$hash']).copyWith(
            sources: []),
      ];
    final service = BookWikiService(repository: repository);
    final visible = await service.load(1, visibleAtProgress: .4);
    expect(visible.entries.map((e) => e.id), ['generated']);
    expect(visible.sourceBoundaries['wiki:generated'], .2);
    final earlier = await service.load(1, visibleAtProgress: .1);
    expect(earlier.entries, isEmpty);
  });

  test('checkpoint anchors expose exact stable refs without chapter inference',
      () async {
    final repository = fixtures.MemoryRepository()
      ..story = [
        for (final kind in ['checkpoint', 'mastery', 'knowledgeCard'])
          ReadingArtifact(
            id: 'anchor:$kind',
            bookId: 1,
            moduleId: 'test',
            kind: ReadingArtifactKinds.sourceAnchor,
            payload: {
              'sourceKind': kind,
              'sourceId': 'saved',
              'checkpointId': 'saved',
            },
            chapterHref: 'chapter.xhtml',
            sourceProgress: .4,
            visibleFromProgress: .4,
            ingestedAt: 1,
            createdAt: 1,
            updatedAt: 1,
          ),
      ]
      ..memories = [
        const ReadingMemoryDocument(
          id: 'reflection',
          bookId: 1,
          title: 'My reflection',
          markdown: 'I understood this chapter',
          sourceRefs: ['checkpoint:saved'],
          createdAt: 1,
          updatedAt: 1,
        ),
      ];
    final service = BookWikiService(repository: repository);
    final visible = await service.load(1, visibleAtProgress: .5);
    expect(visible.sourceBoundaries['checkpoint:saved'], .4);
    expect(visible.sourceBoundaries['mastery:saved'], .4);
    expect(visible.sourceBoundaries['knowledgeCard:saved'], .4);
    expect(visible.sourceBoundaries, isNot(contains('chapter.xhtml')));
    final source = visible.entries.single.sources.single;
    expect(source.chapterHref, 'chapter.xhtml');
    expect(source.textSnapshot, isEmpty);
    final earlier = await service.load(1, visibleAtProgress: .3);
    expect(earlier.entries, isEmpty);
  });

  test('memory stable refs preserve real original source navigation', () async {
    final repository = fixtures.MemoryRepository()
      ..story = [fixtures.artifact('character')]
      ..entries = [fixtures.wikiEntry('concept')]
      ..memories = [
        const ReadingMemoryDocument(
          id: 'saved',
          bookId: 1,
          title: 'My reading',
          markdown: 'A saved reflection',
          sourceRefs: ['artifact:character', 'wiki:concept'],
          createdAt: 1,
          updatedAt: 1,
        ),
      ];
    final snapshot = await BookWikiService(repository: repository)
        .load(1, visibleAtProgress: .4);
    final memory = snapshot.entries.singleWhere((e) => e.id == 'memory:saved');
    expect(memory.sources.map((s) => s.cfi),
        ['epubcfi(/6/2!/character)', 'epubcfi(/6/2!/concept)']);
    expect(memory.sources.map((s) => s.chapterHref),
        ['character.xhtml', 'concept.xhtml']);
    expect(memory.sources.map((s) => s.textSnapshot),
        ['Exact text character', 'Exact text concept']);
    expect(memory.sources.first.artifactId, 'character');
    expect(memory.sources.every((s) => s.sourceProgress == .2), isTrue);
  });
}
