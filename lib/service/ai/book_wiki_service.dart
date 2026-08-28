import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';

class BookWikiSnapshot {
  const BookWikiSnapshot({required this.wiki, required this.entries});
  final BookWiki? wiki;
  final List<BookWikiEntry> entries;

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
  BookWikiService({ReadingAgentRepository? repository})
      : _repository = repository ?? readingAgentRepository;

  final ReadingAgentRepository _repository;

  Future<BookWikiSnapshot> load(int bookId,
      {required double visibleAtProgress, bool showAll = false}) async {
    final boundary = showAll ? 1.0 : visibleAtProgress.clamp(0, 1).toDouble();
    final values = await Future.wait<dynamic>([
      _repository.bookWiki(bookId),
      _repository.bookWikiEntries(bookId, visibleAtProgress: boundary),
      _repository.artifacts(bookId, visibleAtProgress: boundary),
      _repository.memoryDocuments(bookId),
    ]);
    final stored = <BookWikiEntry>[];
    for (final entry in values[1] as List<BookWikiEntry>) {
      stored.add(
          entry.copyWith(sources: await _repository.bookWikiSources(entry.id)));
    }
    final occupied = stored.map((entry) => '${entry.kind}:${entry.id}').toSet();
    final projections = <BookWikiEntry>[];
    for (final artifact in values[2] as List<ReadingArtifact>) {
      final kind = _artifactKind(artifact.kind);
      if (kind == null || artifact.status == ReadingArtifactStatus.retracted) {
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
    for (final memory in values[3] as List<ReadingMemoryDocument>) {
      projections.add(BookWikiEntry(
        id: 'memory:${memory.id}',
        bookId: bookId,
        kind: BookWikiEntryKinds.memory,
        title: memory.title,
        summary: memory.markdown.split('\n').first,
        contentMarkdown: memory.markdown,
        visibleFromProgress: 0,
        epistemicStatus: 'userReflection',
        createdBy: BookWikiEntryCreatedBy.user,
        createdAt: memory.createdAt,
        updatedAt: memory.updatedAt,
        sources: [
          for (final ref in memory.sourceRefs)
            BookWikiSourceRef(
                id: 'memory-source:${memory.id}:$ref',
                entryId: 'memory:${memory.id}',
                bookId: bookId,
                chapterHref: ref,
                createdAt: memory.createdAt),
        ],
      ));
    }
    final entries = [...stored, ...projections]..sort((a, b) {
        final bySort = a.sortKey.compareTo(b.sortKey);
        return bySort != 0 ? bySort : a.title.compareTo(b.title);
      });
    return BookWikiSnapshot(wiki: values[0] as BookWiki?, entries: entries);
  }

  Future<BookWikiEntry?> entry(String id, int bookId,
      {required double visibleAtProgress, bool showAll = false}) async {
    final snapshot = await load(bookId,
        visibleAtProgress: visibleAtProgress, showAll: showAll);
    return snapshot.entries.where((entry) => entry.id == id).firstOrNull;
  }

  String? _artifactKind(String kind) => switch (kind) {
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
