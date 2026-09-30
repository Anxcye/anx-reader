import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_context_pack.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';

/// Builds the AI-facing context projection from existing, traceable sources.
/// Wiki, Story Atlas and Markdown memory remain their own user-facing sources;
/// this service only composes bounded nodes for ContextAssembler.
class ReadingContextPackService {
  ReadingContextPackService({ReadingAgentRepository? repository})
    : _repository = repository ?? readingAgentRepository;

  final ReadingAgentRepository _repository;

  Future<ReadingContextPack> load(
    int bookId, {
    required double visibleAtProgress,
    String? chapterHref,
    String? query,
  }) async {
    final boundary = visibleAtProgress.clamp(0, 1).toDouble();
    final values = await Future.wait<dynamic>([
      _repository.bookWiki(bookId),
      _repository.bookWikiEntries(bookId, visibleAtProgress: boundary),
      _repository.artifacts(bookId, visibleAtProgress: boundary),
      _repository.memoryDocuments(bookId),
    ]);
    final wiki = values[0] as BookWiki?;
    final entries = <BookWikiEntry>[];
    for (final entry in values[1] as List<BookWikiEntry>) {
      entries.add(
        entry.copyWith(sources: await _repository.bookWikiSources(entry.id)),
      );
    }
    final nodes = <ReadingContextNode>[];
    for (final entry in entries) {
      final sources = entry.sources;
      final sourceProgress = sources.isEmpty
          ? entry.visibleFromProgress
          : sources
                .map((source) => source.sourceProgress)
                .reduce((a, b) => a < b ? a : b);
      nodes.add(
        ReadingContextNode(
          id: 'wiki:${entry.id}',
          bookId: bookId,
          kind: _wikiKind(entry.kind),
          title: entry.title,
          summary: entry.summary,
          content: entry.contentMarkdown,
          parentId: entry.parentId,
          sortKey: entry.sortKey,
          sourceRefs: sources,
          sourceArtifactIds: entry.sourceArtifactIds,
          sourceProgress: sourceProgress,
          visibleFromProgress: entry.visibleFromProgress,
          epistemicStatus: entry.epistemicStatus,
          updatedAt: entry.updatedAt,
        ),
      );
    }
    for (final artifact in values[2] as List<ReadingArtifact>) {
      if (artifact.status == ReadingArtifactStatus.retracted) continue;
      final hasLocation =
          artifact.chapterHref?.trim().isNotEmpty == true ||
          artifact.sourceStartCfi?.trim().isNotEmpty == true;
      if (artifact.sourceTextSnapshot.trim().isEmpty || !hasLocation) {
        continue;
      }
      final title =
          (artifact.payload['title'] ??
                  artifact.payload['name'] ??
                  artifact.payload['question'] ??
                  artifact.chapterTitle ??
                  '阅读档案')
              .toString();
      final summary =
          (artifact.payload['summary'] ??
                  artifact.payload['description'] ??
                  artifact.sourceTextSnapshot)
              .toString();
      nodes.add(
        ReadingContextNode(
          id: 'artifact:${artifact.id}',
          bookId: bookId,
          kind: ReadingContextNodeKinds.artifact,
          title: title,
          summary: summary,
          content: summary,
          sourceArtifactIds: [artifact.id],
          sourceProgress: artifact.sourceProgress,
          visibleFromProgress: artifact.visibleFromProgress,
          epistemicStatus: artifact.epistemicStatus.name,
          updatedAt: artifact.updatedAt,
          sourceRefs: [
            BookWikiSourceRef(
              id: 'artifact-context:${artifact.id}',
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
          ],
        ),
      );
    }
    for (final memory in values[3] as List<ReadingMemoryDocument>) {
      // A memory without source refs is an explicitly user-authored global
      // note. It is safe to use at every boundary; linked memories inherit
      // the most conservative source boundary.
      if (memory.sourceRefs.isEmpty) {
        nodes.add(
          ReadingContextNode(
            id: 'memory:${memory.id}',
            bookId: bookId,
            kind: ReadingContextNodeKinds.userMemory,
            title: memory.title,
            summary: memory.markdown.split('\n').first,
            content: memory.markdown,
            epistemicStatus: 'userReflection',
            updatedAt: memory.updatedAt,
          ),
        );
        continue;
      }
      final linked = <ReadingContextNode>[
        for (final node in nodes)
          if (node.sourceRefs.any(
            (source) => memory.sourceRefs.any(
              (ref) =>
                  source.chapterHref == ref ||
                  source.cfi == ref ||
                  source.artifactId == ref,
            ),
          ))
            node,
      ];
      if (linked.isEmpty) continue;
      final visibleFrom = linked.fold<double>(
        0,
        (latest, node) =>
            node.visibleFromProgress > latest
                ? node.visibleFromProgress
                : latest,
      );
      nodes.add(
        ReadingContextNode(
          id: 'memory:${memory.id}',
          bookId: bookId,
          kind: ReadingContextNodeKinds.userMemory,
          title: memory.title,
          summary: memory.markdown.split('\n').first,
          content: memory.markdown,
          sourceProgress: visibleFrom,
          visibleFromProgress: visibleFrom,
          epistemicStatus: 'userReflection',
          updatedAt: memory.updatedAt,
        ),
      );
    }
    nodes.sort((a, b) {
      final byProgress = a.sourceProgress.compareTo(b.sourceProgress);
      return byProgress != 0 ? byProgress : a.sortKey.compareTo(b.sortKey);
    });
    final visible = ReadingContextPack(
      bookId: bookId,
      version: wiki?.version ?? 1,
      scope: wiki?.generationScope ?? BookWikiGenerationScope.readBoundary,
      safeKnowledgeBoundary: wiki?.safeKnowledgeBoundary ?? boundary,
      coverageStart: wiki?.coverageStart ?? 0,
      coverageEnd: wiki?.coverageEnd ?? 0,
      status: nodes.isEmpty
          ? ReadingContextPackStatus.empty
          : wiki?.status == BookWikiStatus.ready
          ? ReadingContextPackStatus.ready
          : ReadingContextPackStatus.partial,
      lastGeneratedAt: wiki?.lastGeneratedAt,
      updatedAt: wiki?.updatedAt ?? 0,
      nodes: nodes,
    ).visibleAt(boundary);
    // Apply chapter filtering only when a chapter-specific projection exists;
    // otherwise retain the book/part/entity context as a fallback.
    if (chapterHref == null || chapterHref.isEmpty) return visible;
    return ReadingContextPack(
      bookId: visible.bookId,
      version: visible.version,
      pipelineVersion: visible.pipelineVersion,
      scope: visible.scope,
      safeKnowledgeBoundary: visible.safeKnowledgeBoundary,
      coverageStart: visible.coverageStart,
      coverageEnd: visible.coverageEnd,
      status: visible.status,
      lastGeneratedAt: visible.lastGeneratedAt,
      updatedAt: visible.updatedAt,
      nodes: visible.nodes,
    );
  }

  Future<String> promptContext(
    int bookId, {
    required double visibleAtProgress,
    String? chapterHref,
    String? query,
    int maxCharacters = 8000,
  }) async {
    final pack = await load(
      bookId,
      visibleAtProgress: visibleAtProgress,
      chapterHref: chapterHref,
      query: query,
    );
    return pack.toPromptContext(
      visibleAtProgress: visibleAtProgress,
      chapterHref: chapterHref,
      query: query,
      maxCharacters: maxCharacters,
    );
  }

  String _wikiKind(String kind) => switch (kind) {
    BookWikiEntryKinds.chapter => ReadingContextNodeKinds.chapter,
    BookWikiEntryKinds.part => ReadingContextNodeKinds.part,
    BookWikiEntryKinds.overview => ReadingContextNodeKinds.book,
    BookWikiEntryKinds.memory => ReadingContextNodeKinds.userMemory,
    BookWikiEntryKinds.character || BookWikiEntryKinds.relationship =>
      ReadingContextNodeKinds.entity,
    BookWikiEntryKinds.event => ReadingContextNodeKinds.scene,
    _ => ReadingContextNodeKinds.summary,
  };
}

final readingContextPackService = ReadingContextPackService();
