import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_materials.dart';
import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/service/ai/book_wiki_service.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/service/ai/reading_outcomes_service.dart';
import 'package:flutter_test/flutter_test.dart';

BookWikiEntry wikiEntry(String id,
        {String kind = BookWikiEntryKinds.concept,
        String title = 'A concept',
        double visible = .2,
        double source = .2,
        int bookId = 1,
        List<String> artifactIds = const []}) =>
    BookWikiEntry(
      id: id,
      bookId: bookId,
      kind: kind,
      title: title,
      summary: 'Saved explanation $id',
      visibleFromProgress: visible,
      sourceArtifactIds: artifactIds,
      createdAt: 1,
      updatedAt: 1,
      sources: [
        BookWikiSourceRef(
            id: 's:$id',
            entryId: id,
            bookId: bookId,
            chapterHref: '$id.xhtml',
            cfi: 'epubcfi(/6/2!/$id)',
            textSnapshot: 'Exact text $id',
            sourceProgress: source,
            createdAt: 1)
      ],
    );

ReadingArtifact artifact(String id,
        {double progress = .2, String kind = ReadingArtifactKinds.character}) =>
    ReadingArtifact(
      id: id,
      bookId: 1,
      moduleId: ReadingClosureIds.fictionImmersion,
      kind: kind,
      payload: const {
        'name': 'Same name',
        'summary': 'Source-supported character'
      },
      sourceProgress: progress,
      visibleFromProgress: progress,
      sourceStartCfi: 'epubcfi(/6/2!/$id)',
      chapterHref: '$id.xhtml',
      sourceTextSnapshot: 'Exact text $id',
      ingestedAt: 1,
      createdAt: 1,
      updatedAt: 1,
    );

class MemoryRepository extends ReadingAgentRepository {
  List<BookWikiEntry> entries = [];
  List<ReadingArtifact> story = [];
  List<ReadingMemoryDocument> memories = [];
  @override
  Future<BookWiki?> bookWiki(int bookId) async => null;
  @override
  Future<List<BookWikiEntry>> bookWikiEntries(int bookId,
          {double? visibleAtProgress}) async =>
      entries;
  @override
  Future<List<BookWikiSourceRef>> bookWikiSources(String entryId) async =>
      entries.firstWhere((e) => e.id == entryId).sources;
  @override
  Future<List<ReadingArtifact>> artifacts(int bookId,
          {String? kind,
          ReadingArtifactStatus? status,
          double? visibleAtProgress}) async =>
      story;
  @override
  Future<List<ReadingMemoryDocument>> memoryDocuments(int bookId) async =>
      memories;
}

void main() {
  test(
      'one early source cannot unlock unknown later content in the same chapter',
      () async {
    final repo = MemoryRepository()
      ..story = [
        artifact('early').copyWith(chapterHref: 'same.xhtml'),
      ];
    final service = BookWikiService(repository: repo);
    final wiki = await service.load(1, visibleAtProgress: .4);
    final raw =
        ReadingOutcomesSnapshot(loadedAt: DateTime(2026), difficulties: const [
      ReadingDifficulty(
          id: 'later',
          bookId: 1,
          cfi: 'epubcfi(/6/2!/later)',
          chapterHref: 'same.xhtml',
          text: 'A later reveal',
          createdAt: 1,
          updatedAt: 1)
    ], knowledgeCards: const [
      KnowledgeCard(
          id: 'later',
          bookId: 1,
          chapterHref: 'same.xhtml',
          front: 'Later',
          back: 'Reveal',
          createdAt: 1,
          updatedAt: 1)
    ]);
    final safe = service
        .materialsFrom(
            bookId: 1, visibleAtProgress: .4, wiki: wiki, outcomes: raw)
        .outcomes!;
    expect(safe.difficulties, isEmpty);
    expect(safe.knowledgeCards, isEmpty);
  });

  test('saved questions retain exact source visibility after leaving their CFI',
      () async {
    final repo = MemoryRepository()
      ..story = [
        const ReadingArtifact(
            id: 'anchor',
            bookId: 1,
            moduleId: 'reading',
            kind: ReadingArtifactKinds.sourceAnchor,
            payload: {'sourceKind': 'difficulty', 'sourceId': 'question'},
            sourceStartCfi: 'epubcfi(/6/2!/4)',
            chapterHref: 'chapter.xhtml',
            sourceProgress: .4,
            visibleFromProgress: .4,
            ingestedAt: 1,
            createdAt: 1,
            updatedAt: 1),
      ];
    final service = BookWikiService(repository: repo);
    final wiki = await service.load(1, visibleAtProgress: .7);
    expect(wiki.entries, isEmpty);
    expect(wiki.sourceBoundaries['chapter.xhtml'], isNull);
    const question = ReadingDifficulty(
        id: 'question',
        bookId: 1,
        cfi: 'epubcfi(/6/2!/4)',
        text: 'Why?',
        createdAt: 1,
        updatedAt: 1);
    expect(
        service
            .materialsFrom(
                bookId: 1,
                visibleAtProgress: .7,
                currentCfi: 'epubcfi(/6/8!/4)',
                wiki: wiki,
                difficulties: [question])
            .items
            .single
            .difficulty
            ?.id,
        'question');
    expect(
        service.materialsFrom(
            bookId: 1,
            visibleAtProgress: .2,
            wiki: wiki,
            difficulties: [question]).items,
        isEmpty);
  });

  test('next-action outcomes share the directory spoiler boundary', () {
    final raw = ReadingOutcomesSnapshot(
      loadedAt: DateTime(2026),
      pendingCheckpoints: const [
        ReadingChapterCheckpoint(
            id: 'early',
            bookId: 1,
            chapterHref: 'early.xhtml',
            chapterTitle: 'Early chapter',
            progress: .2,
            createdAt: 1,
            updatedAt: 1),
        ReadingChapterCheckpoint(
            id: 'late',
            bookId: 1,
            chapterHref: 'late.xhtml',
            chapterTitle: 'Future reveal',
            progress: .8,
            createdAt: 1,
            updatedAt: 1),
      ],
      knowledgeCards: const [
        KnowledgeCard(
            id: 'safe',
            bookId: 1,
            front: 'Early question',
            back: 'Early answer',
            chapterHref: 'early.xhtml',
            createdAt: 1,
            updatedAt: 1),
        KnowledgeCard(
            id: 'late',
            bookId: 1,
            front: 'Future question',
            back: 'Future answer',
            chapterHref: 'late.xhtml',
            createdAt: 1,
            updatedAt: 1),
        KnowledgeCard(
            id: 'unknown',
            bookId: 1,
            front: 'Unknown source',
            back: 'Unknown',
            createdAt: 1,
            updatedAt: 1),
      ],
      difficulties: const [
        ReadingDifficulty(
            id: 'safe',
            bookId: 1,
            cfi: 'early',
            chapterHref: 'early.xhtml',
            text: 'Known difficulty',
            createdAt: 1,
            updatedAt: 1),
        ReadingDifficulty(
            id: 'late',
            bookId: 1,
            cfi: 'late',
            chapterHref: 'late.xhtml',
            text: 'Future difficulty',
            createdAt: 1,
            updatedAt: 1),
      ],
      memories: const [
        ReadingMemoryDocument(
            id: 'mixed',
            bookId: 1,
            title: 'Future inference',
            markdown: 'Hidden',
            sourceRefs: ['early.xhtml', 'late.xhtml'],
            createdAt: 1,
            updatedAt: 1),
      ],
    );
    final result = BookWikiService()
        .materialsFrom(
            bookId: 1,
            visibleAtProgress: .4,
            wiki: const BookWikiSnapshot(
                wiki: null,
                entries: [],
                sourceBoundaries: {'early': .2, 'late': .8}),
            outcomes: raw)
        .outcomes!;
    expect(result.pendingCheckpoints.map((item) => item.id), ['early']);
    expect(result.knowledgeCards, isEmpty);
    expect(result.difficulties.map((item) => item.id), ['safe']);
    expect(result.memories, isEmpty);
  });
  test(
      'Wiki projection rejects future source text even when entry boundary is stale',
      () async {
    final repo = MemoryRepository()
      ..entries = [
        wikiEntry('early'),
        wikiEntry('future-source', source: .8),
        wikiEntry('future-entry', visible: .8),
        wikiEntry('foreign', bookId: 2),
        wikiEntry('unknown', kind: 'future.new-kind'),
      ];
    final snapshot =
        await BookWikiService(repository: repo).load(1, visibleAtProgress: .4);
    expect(snapshot.entries.map((e) => e.id), ['early']);
  });

  test(
      'mixed and unresolved memory references never become early-reading facts',
      () async {
    final repo = MemoryRepository()
      ..story = [artifact('early'), artifact('late', progress: .8)]
      ..memories = [
        const ReadingMemoryDocument(
            id: 'mixed',
            bookId: 1,
            title: 'Spoiler',
            markdown: 'Future reveal',
            sourceRefs: ['artifact:early', 'artifact:late'],
            createdAt: 1,
            updatedAt: 1),
        const ReadingMemoryDocument(
            id: 'unknown',
            bookId: 1,
            title: 'Unknown',
            markdown: 'Unknown reveal',
            sourceRefs: ['missing.xhtml'],
            createdAt: 1,
            updatedAt: 1),
        const ReadingMemoryDocument(
            id: 'safe',
            bookId: 1,
            title: 'My thought',
            markdown: 'Early thought',
            sourceRefs: ['artifact:early'],
            createdAt: 1,
            updatedAt: 1),
        const ReadingMemoryDocument(
            id: 'global',
            bookId: 1,
            title: 'My goal',
            markdown: 'Personal goal',
            createdAt: 1,
            updatedAt: 1),
      ];
    final snapshot =
        await BookWikiService(repository: repo).load(1, visibleAtProgress: .4);
    expect(snapshot.entries.map((e) => e.id),
        containsAll(['artifact:early', 'memory:safe']));
    expect(snapshot.entries.map((e) => e.id), isNot(contains('memory:global')));
    expect(snapshot.entries.map((e) => e.id), isNot(contains('memory:mixed')));
    expect(
        snapshot.entries.map((e) => e.id), isNot(contains('memory:unknown')));
  });

  test('memory referencing a Wiki ID inherits all source boundaries', () async {
    final repo = MemoryRepository()
      ..entries = [wikiEntry('mislabelled', source: .8)]
      ..memories = [
        const ReadingMemoryDocument(
            id: 'linked',
            bookId: 1,
            title: 'Future',
            markdown: 'Later reveal',
            sourceRefs: ['wiki:mislabelled'],
            createdAt: 1,
            updatedAt: 1)
      ];
    final snapshot =
        await BookWikiService(repository: repo).load(1, visibleAtProgress: .4);
    expect(snapshot.entries, isEmpty);
  });

  test('unknown or nonfinite sources cannot establish a visible memory',
      () async {
    final repo = MemoryRepository()
      ..story = [
        artifact('unknown', kind: 'future.kind'),
        artifact('invalid', progress: double.nan),
      ]
      ..entries = [wikiEntry('invalid-wiki', source: double.nan)]
      ..memories = [
        for (final ref in ['unknown', 'invalid', 'wiki:invalid-wiki'])
          ReadingMemoryDocument(
              id: ref,
              bookId: 1,
              title: 'Unsafe inference',
              markdown: 'No known source boundary',
              sourceRefs: [ref],
              createdAt: 1,
              updatedAt: 1),
      ];
    final snapshot =
        await BookWikiService(repository: repo).load(1, visibleAtProgress: .4);
    expect(snapshot.entries, isEmpty);
    expect(snapshot.sourceBoundaries, isEmpty);
  });

  test(
      'only stable source identity deduplicates; identical names remain distinct',
      () async {
    final repo = MemoryRepository()
      ..story = [artifact('first'), artifact('second')]
      ..entries = [
        wikiEntry('corrected',
            kind: BookWikiEntryKinds.character,
            title: 'Same name',
            artifactIds: ['first'])
      ];
    final service = BookWikiService(repository: repo);
    final wiki = await service.load(1, visibleAtProgress: .4);
    expect(wiki.entries.map((e) => e.id),
        containsAll(['corrected', 'artifact:second']));
    expect(wiki.entries.map((e) => e.id), isNot(contains('artifact:first')));
    final materials =
        service.materialsFrom(bookId: 1, visibleAtProgress: .4, wiki: wiki);
    expect(materials.sections[BookMaterialSection.characters], hasLength(2));
    expect(materials.search('same name'), hasLength(2));
  });

  test('local search cannot expose future or unknown synchronized content', () {
    final service = BookWikiService();
    final snapshot = service.materialsFrom(
        bookId: 1,
        visibleAtProgress: .4,
        wiki: BookWikiSnapshot(wiki: null, entries: [
          wikiEntry('safe', title: 'Visible target'),
          wikiEntry('late', title: 'Secret target', visible: .8),
          wikiEntry('bad-source', title: 'Secret source', source: .8),
          wikiEntry('unknown',
              title: 'Secret future kind', kind: 'custom.unknown'),
        ]));
    expect(snapshot.search('target').map((e) => e.sourceId), ['safe']);
    expect(snapshot.search('secret'), isEmpty);
  });

  test(
      'structured notes retain original identity and honor explicit source visibility',
      () {
    final book = Book(
        id: 1,
        title: 'Book',
        coverPath: '',
        filePath: '',
        lastReadPosition: '',
        readingPercentage: .4,
        author: '',
        isDeleted: false,
        rating: 0,
        createTime: DateTime(2026),
        updateTime: DateTime(2026));
    ReadingNoteListItem note(String id, {double? visible}) =>
        ReadingNoteListItem(
            book: book,
            document: ReadingNoteDocument(
              note: ReadingNote(
                  id: id,
                  bookId: 1,
                  title: 'Note $id',
                  status: ReadingNoteStatus.active,
                  captureKind: ReadingNoteCaptureKind.manual,
                  isFavorite: false,
                  createdAt: 1,
                  updatedAt: 1),
              blocks: [
                ReadingNoteBlock(
                    id: 'b:$id',
                    noteId: id,
                    type: ReadingNoteBlockType.ai,
                    content: 'AI answer $id',
                    sortOrder: 0,
                    origin: ReadingNoteBlockOrigin.ai,
                    createdAt: 1,
                    updatedAt: 1)
              ],
              sources: [
                ReadingNoteSource(
                    noteId: id,
                    type: ReadingNoteSourceType.aiSession,
                    sourceRef: 'session',
                    cfi: 'epubcfi(/6/2!/4)',
                    textSnapshot: 'Exact quote',
                    metadata: {
                      if (visible != null) 'visibleFromProgress': visible
                    },
                    createdAt: 1)
              ],
            ));
    final snapshot = BookWikiService().materialsFrom(
        bookId: 1,
        visibleAtProgress: .4,
        wiki: const BookWikiSnapshot(wiki: null, entries: []),
        notes: [
          note('safe', visible: .2),
          note('future', visible: .8),
          note('invalid', visible: double.nan),
          note('unknown')
        ]);
    expect(snapshot.items, hasLength(1));
    expect(snapshot.items.single.sourceId, 'safe');
    expect(snapshot.items.single.noteItem?.document?.note.id, 'safe');
    expect(snapshot.search('AI answer safe'), hasLength(1));
  });

  test('unresolved questions need a known source and remain book-scoped', () {
    ReadingDifficulty question(String id, String cfi, {int bookId = 1}) =>
        ReadingDifficulty(
            id: id,
            bookId: bookId,
            cfi: cfi,
            text: 'Question $id',
            createdAt: 1,
            updatedAt: 1);
    final snapshot = BookWikiService().materialsFrom(
        bookId: 1,
        visibleAtProgress: .4,
        currentCfi: 'epubcfi(/6/2!/4)',
        wiki: const BookWikiSnapshot(
            wiki: null,
            entries: [],
            sourceBoundaries: {'late': .8, 'invalid': double.nan}),
        difficulties: [
          question('here', 'epubcfi(/6/2!/4)'),
          question('unknown', 'unknown'),
          question('future', 'late'),
          question('invalid', 'invalid'),
          question('foreign', 'epubcfi(/6/2!/4)', bookId: 2)
        ]);
    expect(snapshot.items.map((item) => item.sourceId), ['here']);
  });

  test('registered capabilities determine available directory sections', () {
    final service = BookWikiService();
    final fiction = service.materialsFrom(
        bookId: 1,
        visibleAtProgress: .4,
        wiki: const BookWikiSnapshot(wiki: null, entries: []),
        closure: ReadingClosurePolicyRegistry.fictionImmersion);
    final knowledge = service.materialsFrom(
        bookId: 1,
        visibleAtProgress: .4,
        wiki: const BookWikiSnapshot(wiki: null, entries: []),
        closure: ReadingClosurePolicyRegistry.knowledgeArgument);
    expect(fiction.availableSections, contains(BookMaterialSection.characters));
    expect(knowledge.availableSections,
        isNot(contains(BookMaterialSection.characters)));
  });
}
