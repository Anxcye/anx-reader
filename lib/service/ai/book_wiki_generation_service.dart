import 'package:anx_reader/models/ai_provider.dart';
import 'dart:convert';
import 'package:anx_reader/models/reading_chunk.dart';
import 'package:crypto/crypto.dart';
import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/service/ai/agent_action_service.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/ai_request.dart';
import 'package:anx_reader/service/ai/ai_request_gateway.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_chunker.dart';
import 'package:anx_reader/service/ai/reading_evidence_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain_core/chat_models.dart';

class BookWikiChapter {
  const BookWikiChapter({
    required this.href,
    required this.title,
    required this.progress,
    required this.content,
  });
  final String href, title, content;
  final double progress;
}

typedef BookWikiTextGenerator = Future<String> Function(String prompt);
typedef BookWikiProgressCallback = Future<void> Function(
    int completed, int total, String chapterHref);
typedef BookWikiStageCallback = Future<void> Function({
  required int completedUnits,
  required int totalUnits,
  required String chapterHref,
  required String chapterTitle,
  required int chunkIndex,
  required int chunkCount,
  required String stage,
});

/// Bounded, user-triggered Wiki generation. The service never loads chapters
/// itself, so opening a page cannot accidentally invoke a model.
class BookWikiGenerationService {
  BookWikiGenerationService({
    AgentActionService? actions,
    ReadingAgentRepository? repository,
    AiRequestGateway gateway = aiRequestGateway,
    AiContextAssembler? assembler,
  })  : _actions = actions ?? agentActionService,
        _repository = repository ?? readingAgentRepository,
        _gateway = gateway,
        _assembler = assembler ?? AiContextAssembler();
  final AgentActionService _actions;
  final ReadingAgentRepository _repository;
  final AiRequestGateway _gateway;
  final AiContextAssembler _assembler;
  AiProvider? previewProvider([WidgetRef? ref]) =>
      _gateway.generalProvider(ref);

  static const _chunker = ReadingChunker();
  static const _evidenceResolver = ReadingEvidenceResolver();
  static const _pipelineVersion = 'book-wiki.v2';

  static bool isEligibleChapterTitle(String title) {
    final normalized =
        title.replaceAll(RegExp(r'\s+'), '').trim().toLowerCase();
    return !{
      '封面',
      '版权',
      '版权信息',
      '作品简介',
      '内容简介',
      '作者简介',
      '译序',
      '译者序',
      '出版说明',
      '目录',
      'contents',
    }.contains(normalized);
  }

  Future<int> generate({
    required int bookId,
    required List<BookWikiChapter> chapters,
    required double safeBoundary,
    BookWikiTextGenerator? generate,
    required String sessionId,
    String? taskId,
    String? providerId,
    WidgetRef? ref,
    BookWikiGenerationScope scope = BookWikiGenerationScope.readBoundary,
    BookWikiProgressCallback? onProgress,
    BookWikiStageCallback? onStage,
  }) async {
    var count = 0;
    final existing = await _repository.bookWikiEntries(bookId);
    final eligible = chapters
        .where(
          (item) =>
              item.progress <= safeBoundary &&
              isEligibleChapterTitle(item.title),
        )
        .toList(growable: false);
    // Split once up front so the scheduler can expose progress while a
    // chapter is still being processed. This is a local deterministic
    // operation and does not change the model input or token budget.
    final prepared = [
      for (final chapter in eligible)
        (
          chapter: chapter,
          chunks: _chunker.split(
            bookId: bookId,
            chapterHref: chapter.href,
            chapterTitle: chapter.title,
            content: chapter.content,
            sourceProgress: chapter.progress,
          ),
        ),
    ];
    final totalUnits = prepared.fold<int>(
      0,
      (sum, item) => sum + item.chunks.length,
    );
    var completedUnits = 0;
    var completed = 0;
    for (final item in prepared) {
      final chapter = item.chapter;
      final chunks = item.chunks;
      final contentHash = sha1.convert(utf8.encode(chapter.content)).toString();
      final generationHash = sha1
          .convert(
            utf8.encode(
              '$_pipelineVersion|${ReadingChunk.currentPipelineVersion}|${chapter.content}',
            ),
          )
          .toString();
      if (existing.any(
        (e) =>
            e.sources.any((source) => source.chapterHref == chapter.href) &&
            e.sourceArtifactIds.contains('generation:$generationHash'),
      )) {
        completedUnits += chunks.length;
        await onStage?.call(
          completedUnits: completedUnits,
          totalUnits: totalUnits,
          chapterHref: chapter.href,
          chapterTitle: chapter.title,
          chunkIndex: chunks.length,
          chunkCount: chunks.length,
          stage: 'skipped',
        );
        completed++;
        await onProgress?.call(completed, eligible.length, chapter.href);
        continue;
      }
      await onStage?.call(
        completedUnits: completedUnits,
        totalUnits: totalUnits,
        chapterHref: chapter.href,
        chapterTitle: chapter.title,
        chunkIndex: 0,
        chunkCount: chunks.length,
        stage: 'chapter_started',
      );
      final entriesForChapter = <String, BookWikiEntry>{};
      for (var chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
        final chunk = chunks[chunkIndex];
        // Keep long Wiki jobs cooperative with the reader UI and scheduler.
        await Future<void>.delayed(Duration.zero);
        await onStage?.call(
          completedUnits: completedUnits,
          totalUnits: totalUnits,
          chapterHref: chapter.href,
          chapterTitle: chapter.title,
          chunkIndex: chunkIndex + 1,
          chunkCount: chunks.length,
          stage: 'chunk_started',
        );
        final prompt =
            '将以下章节片段整理为 JSON 数组，每项字段 kind,title,summary,contentMarkdown,evidence。evidence 必须是原文逐字短证据。kind 只能是 wiki.chapter/wiki.concept/wiki.argument/wiki.method/wiki.theme/wiki.question。不要创造原文不存在的事实。章节：${chapter.title}\n片段：\n${chunk.content}';
        final decoded = await _decodeChunkWithRetry(
          generate: generate ??
              (prompt) => _generateText(
                    prompt,
                    bookId: bookId,
                    sessionId: sessionId,
                    taskId: taskId,
                    providerId: providerId,
                    chapterHref: chapter.href,
                    safeBoundary: safeBoundary,
                    ref: ref,
                  ),
          prompt: prompt,
          chunk: chunk,
          chapterTitle: chapter.title,
        );
        for (final item in decoded ?? const <Map<String, dynamic>>[]) {
          final kind = item['kind']?.toString() ?? '';
          final title = item['title']?.toString().trim() ?? '';
          if (title.isEmpty || !BookWikiEntryKinds.supported.contains(kind)) {
            continue;
          }
          final evidence = item['evidence']?.toString() ?? '';
          final resolvedEvidence = _evidenceResolver.resolve(
            sourceText: chapter.content,
            evidence: evidence,
            preferredChunk: chunk,
          );
          if (resolvedEvidence == null) continue;
          final id =
              'wiki-${sha1.convert(utf8.encode('$bookId|${chapter.href}|$kind|$title'))}';
          final entry = BookWikiEntry(
            id: id,
            bookId: bookId,
            kind: kind,
            title: title,
            summary: item['summary']?.toString() ?? '',
            contentMarkdown: item['contentMarkdown']?.toString() ??
                item['summary']?.toString() ??
                '',
            sortKey:
                '${chapter.progress.toStringAsFixed(6)}|${chapter.href}|${chunk.index}',
            sourceArtifactIds: [
              'content:$contentHash',
              'generation:$generationHash',
            ],
            visibleFromProgress: chapter.progress,
            epistemicStatus: 'agentInference',
            createdBy: BookWikiEntryCreatedBy.agent,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            sources: [
              BookWikiSourceRef(
                id: '$id-source-${chunk.index}-${resolvedEvidence.startOffset}',
                entryId: id,
                bookId: bookId,
                chapterHref: chapter.href,
                chapterTitle: chapter.title,
                textSnapshot: resolvedEvidence.exactText,
                sourceProgress: chapter.progress,
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ),
            ],
          );
          final previous = entriesForChapter[id];
          entriesForChapter[id] = previous == null
              ? entry
              : entry.copyWith(
                  sources: [...previous.sources, ...entry.sources],
                );
        }
        completedUnits++;
        await onStage?.call(
          completedUnits: completedUnits,
          totalUnits: totalUnits,
          chapterHref: chapter.href,
          chapterTitle: chapter.title,
          chunkIndex: chunkIndex + 1,
          chunkCount: chunks.length,
          stage: 'chunk_completed',
        );
      }
      for (final entry in entriesForChapter.values) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await _actions.saveWikiEntry(
          entry,
          sessionId: sessionId,
          wiki: BookWiki(
            bookId: bookId,
            generationScope: scope,
            safeKnowledgeBoundary: safeBoundary,
            coverageEnd: safeBoundary,
            status: safeBoundary >= .999
                ? BookWikiStatus.ready
                : BookWikiStatus.partial,
            lastGeneratedAt: now,
            updatedAt: now,
          ),
        );
        count++;
      }
      completed++;
      await onProgress?.call(completed, eligible.length, chapter.href);
      await onStage?.call(
        completedUnits: completedUnits,
        totalUnits: totalUnits,
        chapterHref: chapter.href,
        chapterTitle: chapter.title,
        chunkIndex: chunks.length,
        chunkCount: chunks.length,
        stage: 'chapter_completed',
      );
    }
    return count;
  }

  Future<String> _generateText(
    String prompt, {
    required int bookId,
    required String sessionId,
    required String? taskId,
    String? providerId,
    required String chapterHref,
    required double safeBoundary,
    WidgetRef? ref,
  }) {
    const workload = 'wiki.book_generate';
    final descriptor = AiWorkloadDescriptorRegistry.find(workload)!;
    final messages = _assembler.assemble([ChatMessage.humanText(prompt)],
        task: descriptor.contextTask,
        cacheScope: 'wiki:$bookId:${taskId ?? sessionId}').messages;
    return _gateway.executeText(AiRequest(
      messages: messages,
      workloadId: workload,
      trace: AiTraceContext(
          workloadId: workload,
          taskId: taskId,
          sessionId: sessionId,
          bookId: bookId),
      contextTask: descriptor.contextTask,
      providerId: providerId,
      providerRole: descriptor.providerRole,
      outputContract: descriptor.outputContract,
      // The caller already confirmed this source scope. An unavailable
      // provider must not silently send its chapter text to another one.
      fallbackPolicy: AiFallbackPolicy.none,
      failureDelivery: AiFailureDelivery.streamError,
      sourceScope: AiSourceScope(
          bookId: bookId,
          chapterHref: chapterHref,
          chapterRefs: [chapterHref],
          safeBoundary: safeBoundary),
      readingMode: ReadingAiMode.general,
      ref: ref,
    ));
  }

  /// A malformed or length-truncated response must only retry the current
  /// chunk. It must never restart a completed chapter or silently send the
  /// whole book through another provider. The retry reduces the candidate
  /// count and input window so a provider with a small output budget can
  /// finish its JSON envelope.
  Future<List<Map<String, dynamic>>?> _decodeChunkWithRetry({
    required BookWikiTextGenerator generate,
    required String prompt,
    required ReadingChunk chunk,
    required String chapterTitle,
  }) async {
    final first = decodeResponse(await generate(prompt));
    if (first != null) return first;
    if (chunk.content.length <= 900) return null;
    final shortened = chunk.content.substring(
      0,
      (chunk.content.length * .62).round(),
    );
    final retryPrompt =
        '上一轮当前分片的 JSON 不完整。只处理这个分片，最多输出 2 条最重要条目，必须输出完整 JSON 数组；不要解释，不要 Markdown 围栏。'
        'kind,title,summary,contentMarkdown,evidence 字段保持不变；evidence 必须是下面正文的逐字连续子串。'
        '章节：$chapterTitle\n分片正文：\n$shortened';
    return decodeResponse(await generate(retryPrompt));
  }

  /// Parses structured model output. Public for contract tests because provider
  /// responses vary in whether they wrap JSON in Markdown fences.
  List<Map<String, dynamic>>? decodeResponse(String raw) {
    try {
      var normalized = raw.trim();
      // Models commonly wrap otherwise valid JSON in a Markdown code fence or
      // add a short preamble. Strip those wrappers before decoding so a valid
      // response is not silently discarded.
      if (normalized.startsWith('```')) {
        final firstNewline = normalized.indexOf('\n');
        if (firstNewline >= 0) {
          normalized = normalized.substring(firstNewline + 1);
        }
        final fence = normalized.lastIndexOf('```');
        if (fence >= 0) normalized = normalized.substring(0, fence);
        normalized = normalized.trim();
      }
      dynamic value;
      try {
        value = jsonDecode(normalized);
      } catch (_) {
        // Be tolerant of a brief explanatory sentence around the JSON while
        // still requiring the extracted portion itself to be valid JSON.
        final start = normalized.indexOf('[');
        final end = normalized.lastIndexOf(']');
        if (start < 0 || end <= start) rethrow;
        value = jsonDecode(normalized.substring(start, end + 1));
      }
      if (value is List) {
        return value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      if (value is Map && value['entries'] is List) {
        return (value['entries'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}
    return null;
  }
}

final bookWikiGenerationService = BookWikiGenerationService();
