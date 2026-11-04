import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/models/book_materials.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/service/ai/reading_coach_repository.dart';
import 'package:anx_reader/service/ai/reading_outcomes_service.dart';
import 'package:anx_reader/service/ai/reading_structure_parser.dart';
import 'package:anx_reader/service/ai/reading_source_anchor_validator.dart';
import 'package:anx_reader/service/reading_note/reading_note_repository.dart';

class BookWikiSnapshot {
  const BookWikiSnapshot({
    required this.wiki,
    required this.entries,
    this.sourceBoundaries = const {},
  });
  final BookWiki? wiki;
  final List<BookWikiEntry> entries;

  /// Includes future sources so a mixed-source memory cannot inherit only its
  /// earliest, currently visible reference. This map contains no source text.
  final Map<String, double> sourceBoundaries;

  double get coverageEnd {
    var value = wiki?.coverageEnd ?? 0;
    for (final entry in entries) {
      for (final source in entry.sources) {
        final progress = source.sourceProgress;
        if (progress > value) value = progress;
      }
    }
    return value.clamp(0, 1).toDouble();
  }

  Map<String, List<BookWikiEntry>> get sections {
    final result = <String, List<BookWikiEntry>>{};
    for (final entry in entries) {
      result.putIfAbsent(entry.kind, () => []).add(entry);
    }
    return result;
  }
}

/// Single read projection for Wiki pages. Persisted Wiki entries are combined
/// with existing Story Atlas and Markdown memory without duplicating either
/// source of truth.
class BookWikiService {
  BookWikiService({
    ReadingAgentRepository? repository,
    ReadingNoteRepository? noteRepository,
    ReadingCoachRepository? coachRepository,
  })  : _repository = repository ?? readingAgentRepository,
        _noteRepository = noteRepository ?? ReadingNoteRepository(),
        _coachRepository = coachRepository ?? ReadingCoachRepository();

  final ReadingAgentRepository _repository;
  final ReadingNoteRepository _noteRepository;
  final ReadingCoachRepository _coachRepository;

  Future<BookWikiSnapshot> load(int bookId,
      {required double visibleAtProgress, bool showAll = false}) async {
    final boundary = showAll ? 1.0 : _safeBoundary(visibleAtProgress);
    final values = await Future.wait<dynamic>([
      _repository.bookWiki(bookId),
      _repository.bookWikiEntries(bookId),
      _repository.artifacts(bookId),
      _repository.memoryDocuments(bookId),
    ]);
    final stored = <BookWikiEntry>[];
    for (final entry in values[1] as List<BookWikiEntry>) {
      stored.add(
          entry.copyWith(sources: await _repository.bookWikiSources(entry.id)));
    }
    final artifacts = values[2] as List<ReadingArtifact>;
    final sourceBoundaries = _sourceBoundaries(bookId, stored, artifacts);
    stored.removeWhere((entry) => !_wikiVisible(entry, bookId, boundary,
        sourceBoundaries: sourceBoundaries));
    final occupied = stored.map((entry) => '${entry.kind}:${entry.id}').toSet();
    final representedArtifacts = {
      for (final entry in stored)
        for (final id in entry.sourceArtifactIds) '${entry.kind}:$id',
    };
    final projections = <BookWikiEntry>[];
    for (final artifact in artifacts) {
      final chapterTitle = artifact.chapterTitle?.trim() ?? '';
      if (chapterTitle.isNotEmpty &&
          ReadingStructureParser.isNonStoryTitle(chapterTitle)) {
        continue;
      }
      final kind = _artifactKind(artifact.kind);
      if (kind == null ||
          artifact.bookId != bookId ||
          artifact.status != ReadingArtifactStatus.active ||
          !artifact.visibleFromProgress.isFinite ||
          !artifact.sourceProgress.isFinite ||
          artifact.visibleFromProgress > boundary + 0.000001 ||
          artifact.sourceProgress > boundary + 0.000001 ||
          representedArtifacts.contains('$kind:${artifact.id}')) {
        continue;
      }
      final id = 'artifact:${artifact.id}';
      if (!occupied.add('$kind:$id')) continue;
      projections.add(BookWikiEntry(
        id: id,
        bookId: bookId,
        kind: kind,
        title: _artifactTitle(artifact),
        summary: _artifactSummary(artifact),
        contentMarkdown: _artifactSummary(artifact),
        sourceArtifactIds: [artifact.id],
        visibleFromProgress: artifact.visibleFromProgress,
        epistemicStatus: artifact.epistemicStatus.name,
        createdBy: BookWikiEntryCreatedBy.system,
        createdAt: artifact.createdAt,
        updatedAt: artifact.updatedAt,
        sources: [
          BookWikiSourceRef(
            id: 'artifact-source:${artifact.id}',
            entryId: id,
            bookId: bookId,
            artifactId: artifact.id,
            chapterHref: artifact.chapterHref,
            chapterTitle: artifact.chapterTitle,
            cfi: artifact.sourceStartCfi,
            textSnapshot: artifact.sourceTextSnapshot,
            sourceProgress: artifact.sourceProgress,
            createdAt: artifact.createdAt,
          ),
        ],
      ));
    }
    final sourceLookup = <String, List<BookWikiSourceRef>>{};
    for (final artifact in artifacts) {
      if (artifact.kind == ReadingArtifactKinds.sourceAnchor) {
        final ref =
            '${artifact.payload['sourceKind']}:${artifact.payload['sourceId']}';
        if (sourceBoundaries.containsKey(ref)) {
          sourceLookup[ref] = [
            BookWikiSourceRef(
              id: 'anchor-source:${artifact.id}',
              entryId: ref,
              bookId: bookId,
              chapterHref: artifact.chapterHref,
              chapterTitle: artifact.chapterTitle,
              cfi: artifact.sourceStartCfi,
              sourceProgress: artifact.sourceProgress,
              createdAt: artifact.createdAt,
            ),
          ];
        }
        continue;
      }
      if (!sourceBoundaries.containsKey('artifact:${artifact.id}')) continue;
      final sources = [
        BookWikiSourceRef(
          id: 'artifact-source:${artifact.id}',
          entryId: 'artifact:${artifact.id}',
          bookId: bookId,
          artifactId: artifact.id,
          chapterHref: artifact.chapterHref,
          chapterTitle: artifact.chapterTitle,
          cfi: artifact.sourceStartCfi,
          textSnapshot: artifact.sourceTextSnapshot,
          sourceProgress: artifact.sourceProgress,
          createdAt: artifact.createdAt,
        ),
      ];
      sourceLookup[artifact.id] = sources;
      sourceLookup['artifact:${artifact.id}'] = sources;
    }
    for (final entry in stored) {
      final sources = entry.sources.isNotEmpty
          ? entry.sources
          : [
              for (final ref in entry.sourceArtifactIds) ...?sourceLookup[ref],
            ];
      sourceLookup[entry.id] = sources;
      sourceLookup['wiki:${entry.id}'] = sources;
    }
    for (final memory in values[3] as List<ReadingMemoryDocument>) {
      // Legacy memory documents do not distinguish a source-free user
      // reflection from a generated summary. Do not infer a safe boundary.
      if (memory.bookId != bookId || memory.sourceRefs.isEmpty) continue;
      final visibleFrom = _refsBoundary(memory.sourceRefs, sourceBoundaries);
      if (visibleFrom == null || visibleFrom > boundary + 0.000001) continue;
      projections.add(BookWikiEntry(
        id: 'memory:${memory.id}',
        bookId: bookId,
        kind: BookWikiEntryKinds.memory,
        title: memory.title,
        summary: memory.markdown.split('\n').first,
        contentMarkdown: memory.markdown,
        visibleFromProgress: visibleFrom,
        epistemicStatus: 'userReflection',
        createdBy: BookWikiEntryCreatedBy.user,
        createdAt: memory.createdAt,
        updatedAt: memory.updatedAt,
        sources: [
          for (final ref in memory.sourceRefs)
            for (final source in sourceLookup[ref] ??
                (ref.startsWith('epubcfi(')
                    ? [
                        BookWikiSourceRef(
                          id: ref,
                          entryId: 'memory:${memory.id}',
                          bookId: bookId,
                          cfi: ref,
                          sourceProgress: sourceBoundaries[ref]!,
                          createdAt: memory.createdAt,
                        ),
                      ]
                    : <BookWikiSourceRef>[]))
              BookWikiSourceRef(
                id: 'memory-source:${memory.id}:${source.id}',
                entryId: 'memory:${memory.id}',
                bookId: bookId,
                artifactId: source.artifactId,
                chapterHref: source.chapterHref,
                chapterTitle: source.chapterTitle,
                cfi: source.cfi,
                textSnapshot: source.textSnapshot,
                sourceProgress: source.sourceProgress,
                createdAt: source.createdAt,
              ),
        ],
      ));
    }
    final entries = [...stored, ...projections]..sort((a, b) {
        final bySort = a.sortKey.compareTo(b.sortKey);
        return bySort != 0 ? bySort : a.title.compareTo(b.title);
      });
    return BookWikiSnapshot(
      wiki: values[0] as BookWiki?,
      entries: entries,
      sourceBoundaries: sourceBoundaries,
    );
  }

  Future<BookWikiEntry?> entry(String id, int bookId,
      {required double visibleAtProgress, bool showAll = false}) async {
    final snapshot = await load(bookId,
        visibleAtProgress: visibleAtProgress, showAll: showAll);
    return snapshot.entries.where((entry) => entry.id == id).firstOrNull;
  }

  /// The reader's unified directory is a projection over the Wiki and existing
  /// note/outcome repositories. Loading it never loads a chapter or runs AI.
  Future<BookMaterialsSnapshot> loadMaterials(
    int bookId, {
    required double visibleAtProgress,
    ReadingClosurePolicyDefinition? closure,
    ReadingOutcomesSnapshot? outcomes,
    String? currentCfi,
  }) async {
    final values = await Future.wait<dynamic>([
      load(bookId, visibleAtProgress: visibleAtProgress),
      _noteRepository.list(ReadingNoteQuery(bookId: bookId)),
      outcomes != null
          ? Future.value(outcomes.difficulties)
          : _coachRepository.loadDifficulties(bookId),
    ]);
    return materialsFrom(
      bookId: bookId,
      visibleAtProgress: visibleAtProgress,
      wiki: values[0] as BookWikiSnapshot,
      notes: values[1] as List<ReadingNoteListItem>,
      difficulties: values[2] as List<ReadingDifficulty>,
      closure: closure,
      currentCfi: currentCfi,
      outcomes: outcomes,
    );
  }

  /// Public deterministic projection so every directory and local search uses
  /// the same identity and spoiler checks, including test/custom repositories.
  BookMaterialsSnapshot materialsFrom({
    required int bookId,
    required double visibleAtProgress,
    required BookWikiSnapshot wiki,
    List<ReadingNoteListItem> notes = const [],
    List<ReadingDifficulty> difficulties = const [],
    ReadingClosurePolicyDefinition? closure,
    String? currentCfi,
    ReadingOutcomesSnapshot? outcomes,
  }) {
    final boundary = _safeBoundary(visibleAtProgress);
    final known = Map<String, double>.from(wiki.sourceBoundaries);
    if (currentCfi?.isNotEmpty == true) {
      known.update(currentCfi!, (value) => value > boundary ? value : boundary,
          ifAbsent: () => boundary);
    }
    final items = <BookMaterialItem>[];
    final identities = <String>{};
    for (final entry in wiki.entries) {
      final section = sectionForKind[entry.kind];
      final globalReflection = entry.kind == BookWikiEntryKinds.memory &&
          entry.createdBy == BookWikiEntryCreatedBy.user &&
          entry.sources.isEmpty &&
          entry.sourceArtifactIds.isEmpty;
      if (section == null ||
          entry.bookId != bookId ||
          entry.status != BookWikiEntryStatus.active ||
          !entry.visibleFromProgress.isFinite ||
          entry.visibleFromProgress > boundary + 0.000001 ||
          entry.sources.any((source) =>
              source.bookId != bookId ||
              !source.sourceProgress.isFinite ||
              source.sourceProgress > boundary + 0.000001) ||
          (!globalReflection &&
              !_wikiVisible(entry, bookId, boundary,
                  sourceBoundaries: known)) ||
          !identities.add('wiki:${entry.kind}:${entry.id}')) {
        continue;
      }
      items.add(BookMaterialItem(
        id: 'wiki:${entry.id}',
        sourceId: entry.id,
        section: section,
        title: entry.title,
        summary: entry.summary,
        wikiEntry: entry,
      ));
    }
    for (final note in notes) {
      if (note.book.id != bookId ||
          note.document?.note.status == ReadingNoteStatus.trashed ||
          !_noteVisible(note, known, boundary) ||
          !identities.add('note:${note.identity}')) {
        continue;
      }
      final text = note.document?.blocks
              .where((block) => block.type != ReadingNoteBlockType.quote)
              .map((block) => block.content)
              .where((value) => value.trim().isNotEmpty)
              .join('\n') ??
          note.body;
      items.add(BookMaterialItem(
        id: 'note:${note.identity}',
        sourceId: note.identity,
        section: BookMaterialSection.records,
        title: note.title.trim().isNotEmpty
            ? note.title
            : (text.trim().isNotEmpty ? text : note.quote).split('\n').first,
        summary:
            [note.quote, text].where((value) => value.isNotEmpty).join('\n'),
        noteItem: note,
      ));
    }
    for (final difficulty in difficulties) {
      final progress = known[difficulty.cfi];
      if (difficulty.bookId != bookId ||
          difficulty.status != ReadingDifficultyStatus.unresolved ||
          progress == null ||
          !progress.isFinite ||
          progress > boundary + 0.000001 ||
          !identities.add('difficulty:${difficulty.id}')) {
        continue;
      }
      items.add(BookMaterialItem(
        id: 'difficulty:${difficulty.id}',
        sourceId: difficulty.id,
        section: BookMaterialSection.records,
        title: difficulty.text,
        summary: difficulty.note ?? difficulty.chapterTitle ?? '',
        difficulty: difficulty,
      ));
    }
    return BookMaterialsSnapshot(
      bookId: bookId,
      visibleAtProgress: boundary,
      currentCfi: currentCfi,
      sourceBoundaries: Map.unmodifiable(known),
      outcomes: outcomes == null
          ? null
          : filterOutcomes(outcomes,
              bookId: bookId,
              visibleAtProgress: boundary,
              sourceBoundaries: known,
              currentCfi: currentCfi),
      items: List.unmodifiable(items),
      availableSections: {
        BookMaterialSection.chapters,
        BookMaterialSection.concepts,
        BookMaterialSection.records,
        if (closure?.supports(ReadingClosureCapability.storyAtlas) == true) ...{
          BookMaterialSection.characters,
          BookMaterialSection.plot,
        },
        ...items.map((item) => item.section),
      },
    );
  }

  /// The next-action resolver and legacy outcomes view consume this same safe
  /// projection. Counts, titles and snippets must obey the directory boundary.
  ReadingOutcomesSnapshot filterOutcomes(
    ReadingOutcomesSnapshot raw, {
    required int bookId,
    required double visibleAtProgress,
    Map<String, double> sourceBoundaries = const {},
    String? currentCfi,
  }) {
    final boundary = _safeBoundary(visibleAtProgress);
    final known = Map<String, double>.from(sourceBoundaries);
    if (currentCfi?.isNotEmpty == true) {
      known.update(currentCfi!, (value) => value > boundary ? value : boundary,
          ifAbsent: () => boundary);
    }
    bool visibleRef(String? ref) {
      final progress = known[ref];
      return progress != null &&
          progress.isFinite &&
          progress <= boundary + 0.000001;
    }

    return ReadingOutcomesSnapshot(
      goals: raw.goals.where((item) => item.bookId == bookId).toList(),
      pendingCheckpoints: raw.pendingCheckpoints
          .where((item) =>
              item.bookId == bookId &&
              item.progress.isFinite &&
              item.progress <= boundary + 0.000001)
          .toList(),
      masteryStates: raw.masteryStates
          .where((item) =>
              item.bookId == bookId &&
              (boundary >= 1 || visibleRef('mastery:${item.id}')))
          .toList(),
      difficulties: raw.difficulties
          .where((item) => item.bookId == bookId && visibleRef(item.cfi))
          .toList(),
      // Legacy cards have only a chapter href, which cannot establish which
      // part of that chapter their derived answer includes.
      knowledgeCards: raw.knowledgeCards
          .where((item) =>
              item.bookId == bookId &&
              (boundary >= 1 || visibleRef('knowledgeCard:${item.id}')))
          .toList(),
      memories: raw.memories.where((item) {
        final inherited = _refsBoundary(item.sourceRefs, known);
        return item.bookId == bookId &&
            item.sourceRefs.isNotEmpty &&
            inherited != null &&
            inherited <= boundary + 0.000001;
      }).toList(),
      artifacts: raw.artifacts
          .where((item) =>
              item.bookId == bookId &&
              item.status == ReadingArtifactStatus.active &&
              _artifactKind(item.kind) != null &&
              item.sourceProgress.isFinite &&
              item.visibleFromProgress.isFinite &&
              item.sourceProgress <= boundary + 0.000001 &&
              item.visibleFromProgress <= boundary + 0.000001)
          .toList(),
      loadedAt: raw.loadedAt,
    );
  }

  /// Stable content kinds determine presentation, independently of book genre.
  static const sectionForKind = <String, BookMaterialSection>{
    BookWikiEntryKinds.overview: BookMaterialSection.chapters,
    BookWikiEntryKinds.chapter: BookMaterialSection.chapters,
    BookWikiEntryKinds.part: BookMaterialSection.chapters,
    BookWikiEntryKinds.character: BookMaterialSection.characters,
    BookWikiEntryKinds.relationship: BookMaterialSection.characters,
    BookWikiEntryKinds.event: BookMaterialSection.plot,
    BookWikiEntryKinds.question: BookMaterialSection.plot,
    BookWikiEntryKinds.concept: BookMaterialSection.concepts,
    BookWikiEntryKinds.argument: BookMaterialSection.concepts,
    BookWikiEntryKinds.theme: BookMaterialSection.concepts,
    BookWikiEntryKinds.method: BookMaterialSection.concepts,
    BookWikiEntryKinds.memory: BookMaterialSection.records,
  };

  bool _noteVisible(
      ReadingNoteListItem note, Map<String, double> known, double boundary) {
    final sources = note.document?.sources;
    if (sources == null) {
      final progress = known[note.cfi];
      return progress != null &&
          progress.isFinite &&
          progress <= boundary + 0.000001;
    }
    if (sources.isEmpty) {
      return !note.document!.blocks
          .any((block) => block.origin == ReadingNoteBlockOrigin.ai);
    }
    for (final source in sources) {
      final explicit = source.metadata['visibleFromProgress'];
      final sourceProgress = source.metadata['sourceProgress'];
      double? progress = explicit is num ? explicit.toDouble() : null;
      if (sourceProgress is num &&
          (progress == null || sourceProgress > progress)) {
        progress = sourceProgress.toDouble();
      }
      progress ??= known[source.cfi] ?? known[source.sourceRef];
      if (progress == null ||
          !progress.isFinite ||
          progress > boundary + 0.000001) {
        return false;
      }
    }
    return true;
  }

  Map<String, double> _sourceBoundaries(int bookId, List<BookWikiEntry> entries,
      List<ReadingArtifact> artifacts) {
    final boundaries = <String, double>{};
    void remember(String? ref, double progress) {
      if (ref == null || ref.isEmpty || !progress.isFinite) return;
      boundaries.update(ref, (value) => value > progress ? value : progress,
          ifAbsent: () => progress);
    }

    for (final artifact in artifacts) {
      if (artifact.kind == ReadingArtifactKinds.sourceAnchor) {
        if (artifact.bookId != bookId ||
            artifact.status != ReadingArtifactStatus.active ||
            !const {'difficulty', 'checkpoint', 'mastery', 'knowledgeCard'}
                .contains(artifact.payload['sourceKind'])) {
          continue;
        }
        try {
          ReadingSourceAnchorValidator.validate(artifact);
        } on ArgumentError {
          continue;
        }
        remember(artifact.sourceStartCfi, artifact.visibleFromProgress);
        remember(
            '${artifact.payload['sourceKind']}:${artifact.payload['sourceId']}',
            artifact.visibleFromProgress);
        // A locator within a chapter does not establish its end boundary.
        continue;
      }
      if (artifact.bookId != bookId ||
          artifact.status != ReadingArtifactStatus.active ||
          _artifactKind(artifact.kind) == null ||
          !artifact.visibleFromProgress.isFinite ||
          !artifact.sourceProgress.isFinite) {
        continue;
      }
      final progress = artifact.visibleFromProgress > artifact.sourceProgress
          ? artifact.visibleFromProgress
          : artifact.sourceProgress;
      remember(artifact.id, progress);
      remember('artifact:${artifact.id}', progress);
      remember(artifact.sourceStartCfi, progress);
    }
    for (final entry in entries) {
      if (entry.bookId != bookId ||
          entry.status != BookWikiEntryStatus.active ||
          !entry.visibleFromProgress.isFinite ||
          !BookWikiEntryKinds.supported.contains(entry.kind)) {
        continue;
      }
      if (entry.sources.isEmpty && entry.sourceArtifactIds.isEmpty) continue;
      final inherited = _entryArtifactBoundary(entry, boundaries);
      if (inherited == null) continue;
      var entryBoundary = entry.visibleFromProgress > inherited
          ? entry.visibleFromProgress
          : inherited;
      for (final source in entry.sources) {
        if (source.bookId != bookId || !source.sourceProgress.isFinite) {
          entryBoundary = double.infinity;
          break;
        }
        if (source.sourceProgress > entryBoundary) {
          entryBoundary = source.sourceProgress;
        }
      }
      if (!entryBoundary.isFinite) continue;
      remember(entry.id, entryBoundary);
      remember('wiki:${entry.id}', entryBoundary);
      for (final source in entry.sources) {
        if (source.bookId != bookId) continue;
        remember(source.cfi, entryBoundary);
      }
    }
    return boundaries;
  }

  double? _refsBoundary(List<String> refs, Map<String, double> known) {
    var latest = 0.0;
    for (final ref in refs) {
      final progress = known[ref];
      if (progress == null || !progress.isFinite) return null;
      if (progress > latest) latest = progress;
    }
    return latest;
  }

  double? _entryArtifactBoundary(
      BookWikiEntry entry, Map<String, double> known) {
    // Generation fingerprints identify an input version; generated Wiki
    // entries carry their actual evidence separately in sources.
    final fingerprint = RegExp(r'^(content|generation):[a-f0-9]{40}$');
    final refs = entry.sourceArtifactIds
        .where((ref) => !fingerprint.hasMatch(ref))
        .toList(growable: false);
    if (refs.length != entry.sourceArtifactIds.length &&
        entry.sources.isEmpty) {
      return null;
    }
    return _refsBoundary(refs, known);
  }

  double _safeBoundary(double progress) =>
      progress.isFinite ? progress.clamp(0, 1).toDouble() : 0;

  bool _wikiVisible(BookWikiEntry entry, int bookId, double boundary,
      {required Map<String, double> sourceBoundaries}) {
    if (entry.bookId != bookId ||
        entry.status != BookWikiEntryStatus.active ||
        !BookWikiEntryKinds.supported.contains(entry.kind) ||
        !entry.visibleFromProgress.isFinite ||
        entry.visibleFromProgress > boundary + 0.000001) {
      return false;
    }
    if (entry.sources.isEmpty && entry.sourceArtifactIds.isEmpty) return false;
    for (final source in entry.sources) {
      if (source.bookId != bookId ||
          !source.sourceProgress.isFinite ||
          source.sourceProgress > boundary + 0.000001) {
        return false;
      }
    }
    final refsBoundary = _entryArtifactBoundary(entry, sourceBoundaries);
    return refsBoundary != null && refsBoundary <= boundary + 0.000001;
  }

  String? _artifactKind(String kind) => switch (kind) {
        ReadingArtifactKinds.resumeContext ||
        ReadingArtifactKinds.contextBook =>
          BookWikiEntryKinds.overview,
        ReadingArtifactKinds.contextChapter => BookWikiEntryKinds.chapter,
        ReadingArtifactKinds.contextPart => BookWikiEntryKinds.part,
        ReadingArtifactKinds.contextEntity => BookWikiEntryKinds.concept,
        ReadingArtifactKinds.character => BookWikiEntryKinds.character,
        ReadingArtifactKinds.relationship => BookWikiEntryKinds.relationship,
        ReadingArtifactKinds.event ||
        ReadingArtifactKinds.scene =>
          BookWikiEntryKinds.event,
        ReadingArtifactKinds.mystery ||
        ReadingArtifactKinds.clue =>
          BookWikiEntryKinds.question,
        _ => null,
      };

  String _artifactTitle(ReadingArtifact item) => (item.payload['name'] ??
          item.payload['title'] ??
          item.payload['question'] ??
          item.chapterTitle ??
          '阅读档案')
      .toString();
  String _artifactSummary(ReadingArtifact item) => (item.payload['summary'] ??
          item.payload['description'] ??
          item.payload['detail'] ??
          item.sourceTextSnapshot)
      .toString();
}

final bookWikiService = BookWikiService();
