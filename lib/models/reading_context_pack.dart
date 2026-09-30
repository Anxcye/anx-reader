import 'package:anx_reader/models/book_wiki.dart';

/// Stable, provider-independent kinds used by the AI-only reading context.
/// These are deliberately strings so new book types can add nodes without a
/// database migration or a page change.
abstract final class ReadingContextNodeKinds {
  static const book = 'context.book';
  static const part = 'context.part';
  static const chapter = 'context.chapter';
  static const scene = 'context.scene';
  static const entity = 'context.entity';
  static const summary = 'context.summary';
  static const userMemory = 'context.user_memory';
  static const artifact = 'context.artifact';
}

enum ReadingContextPackStatus { empty, partial, ready, failed }

class ReadingContextNode {
  const ReadingContextNode({
    required this.id,
    required this.bookId,
    required this.kind,
    required this.title,
    this.summary = '',
    this.content = '',
    this.parentId,
    this.sortKey = '',
    this.sourceRefs = const [],
    this.sourceArtifactIds = const [],
    this.sourceProgress = 0,
    this.visibleFromProgress = 0,
    this.epistemicStatus = 'agentInference',
    this.updatedAt = 0,
  });

  final String id;
  final int bookId;
  final String kind;
  final String title;
  final String summary;
  final String content;
  final String? parentId;
  final String sortKey;
  final List<BookWikiSourceRef> sourceRefs;
  final List<String> sourceArtifactIds;
  final double sourceProgress;
  final double visibleFromProgress;
  final String epistemicStatus;
  final int updatedAt;

  bool isVisibleAt(double progress) =>
      visibleFromProgress <= progress.clamp(0, 1) + 0.000001;

  String get compactText {
    final body = content.trim().isNotEmpty ? content.trim() : summary.trim();
    return body.isEmpty ? title : '$title：$body';
  }

  String get sourceLabel {
    final source = sourceRefs.firstWhere(
      (value) =>
          (value.chapterTitle?.trim().isNotEmpty ?? false) ||
          value.chapterHref != null,
      orElse: () => const BookWikiSourceRef(
        id: '',
        entryId: '',
        bookId: 0,
        createdAt: 0,
      ),
    );
    final chapter = source.chapterTitle?.trim().isNotEmpty == true
        ? source.chapterTitle!.trim()
        : source.chapterHref?.split('#').first;
    if (chapter == null || chapter.isEmpty) return '';
    return '$chapter · ${(source.sourceProgress * 100).round()}%';
  }
}

class ReadingContextPack {
  const ReadingContextPack({
    required this.bookId,
    this.version = 1,
    this.pipelineVersion = 'reading-context.v1',
    this.scope = BookWikiGenerationScope.readBoundary,
    this.safeKnowledgeBoundary = 0,
    this.coverageStart = 0,
    this.coverageEnd = 0,
    this.status = ReadingContextPackStatus.empty,
    this.lastGeneratedAt,
    this.updatedAt = 0,
    this.nodes = const [],
  });

  final int bookId;
  final int version;
  final String pipelineVersion;
  final BookWikiGenerationScope scope;
  final double safeKnowledgeBoundary;
  final double coverageStart;
  final double coverageEnd;
  final ReadingContextPackStatus status;
  final int? lastGeneratedAt;
  final int updatedAt;
  final List<ReadingContextNode> nodes;

  bool get isEmpty => nodes.isEmpty;

  ReadingContextPack visibleAt(double progress) {
    final visible = nodes
        .where((node) => node.isVisibleAt(progress))
        .toList(growable: false);
    return ReadingContextPack(
      bookId: bookId,
      version: version,
      pipelineVersion: pipelineVersion,
      scope: scope,
      safeKnowledgeBoundary: safeKnowledgeBoundary,
      coverageStart: coverageStart,
      coverageEnd: coverageEnd,
      status: status,
      lastGeneratedAt: lastGeneratedAt,
      updatedAt: updatedAt,
      nodes: visible,
    );
  }

  /// Bounded text for ContextAssembler. It is intentionally a read-only
  /// projection; it never loads a chapter or invokes a model.
  String toPromptContext({
    required double visibleAtProgress,
    String? chapterHref,
    String? query,
    int maxCharacters = 8000,
  }) {
    final requestedChapter = chapterHref;
    final requestedChapterKey = requestedChapter?.split('#').first ?? '';
    final visible = nodes
        .where((node) {
          if (!node.isVisibleAt(visibleAtProgress)) return false;
          if (requestedChapterKey.isEmpty) return true;
          return node.sourceRefs.any((source) {
            final sourceChapter = source.chapterHref;
            return sourceChapter != null &&
                  sourceChapter.split('#').first == requestedChapterKey;
          });
        })
        .toList(growable: false);
    final candidates = visible.isEmpty
        ? nodes.where((node) => node.isVisibleAt(visibleAtProgress)).toList()
        : visible;
    final needle = query?.trim().toLowerCase() ?? '';
    final ranked = [...candidates]
      ..sort((a, b) {
        final aMatch =
            needle.isNotEmpty && a.compactText.toLowerCase().contains(needle)
            ? 0
            : 1;
        final bMatch =
            needle.isNotEmpty && b.compactText.toLowerCase().contains(needle)
            ? 0
            : 1;
        final byMatch = aMatch.compareTo(bMatch);
        return byMatch != 0 ? byMatch : a.sortKey.compareTo(b.sortKey);
      });
    final output = StringBuffer();
    for (final node in ranked) {
      final source = node.sourceLabel;
      final line = source.isEmpty
          ? '- [${node.kind}] ${node.compactText}'
          : '- [${node.kind}] ${node.compactText}（来源：$source）';
      if (output.length + line.length + 1 > maxCharacters) break;
      output.writeln(line);
    }
    return output.toString().trim();
  }
}
