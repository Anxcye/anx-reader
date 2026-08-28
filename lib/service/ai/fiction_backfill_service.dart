import 'dart:convert';

import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/fiction_hybrid_extraction_service.dart';
import 'package:anx_reader/service/ai/reading_chunker.dart';
import 'package:anx_reader/service/ai/reading_evidence_resolver.dart';
import 'package:crypto/crypto.dart';

class FictionBackfillChapter {
  const FictionBackfillChapter({
    required this.href,
    required this.title,
    required this.startProgress,
    this.endProgress,
    this.workId,
    this.workTitle,
    this.volumeId,
    this.arcId,
    this.sceneId,
    this.tocDepth = 0,
    this.hasChildren = false,
    this.isNavigationDocument = false,
  });

  final String href;
  final String title;
  final double startProgress;
  final double? endProgress;
  final String? workId;
  final String? workTitle;
  final String? volumeId;
  final String? arcId;
  final String? sceneId;
  final int tocDepth;
  final bool hasChildren;
  final bool isNavigationDocument;
}

typedef FictionChapterLoader = Future<String> Function(String href);
typedef FictionBackfillGenerator = Future<String> Function(String prompt);
typedef FictionBackfillCandidateValidator = Future<Map<String, dynamic>?>
    Function({
  required String kind,
  required Map<String, dynamic> payload,
  required String chapterContent,
});
typedef FictionBackfillBatchWriter = Future<void> Function({
  required List<ReadingArtifact> artifacts,
  required List<ReadingArtifact> checkpoints,
  required int completedChapters,
  required int totalChapters,
});

typedef _PreparedChapter = ({
  FictionBackfillChapter chapter,
  String content,
  String hash,
});

class _BackfillBatchResult {
  const _BackfillBatchResult({required this.artifacts, required this.chapters});

  final List<ReadingArtifact> artifacts;
  final List<_PreparedChapter> chapters;
}

class _BackfillBatchAttempt {
  const _BackfillBatchAttempt.success(this.results) : error = null;
  const _BackfillBatchAttempt.failure(this.error) : results = const [];

  final List<_BackfillBatchResult> results;
  final Object? error;
}

/// Explicit, bounded fiction backfill. It never reads a chapter whose start is
/// beyond [safeBoundary], and it does no work until the caller invokes it after
/// user confirmation.
class FictionBackfillService {
  const FictionBackfillService();

  static const extractorVersion = 7;
  static const _chunker = ReadingChunker();
  static const _evidenceResolver = ReadingEvidenceResolver();

  Future<List<ReadingArtifact>> build({
    required int bookId,
    required String moduleId,
    required double safeBoundary,
    required List<FictionBackfillChapter> chapters,
    required FictionChapterLoader loadChapter,
    required FictionBackfillGenerator generate,
    required String sessionId,
    required int ingestedAt,
    double fromProgress = 0,
    int batchSize = 1,
    // Keep prompts bounded so a malformed/slow model response only affects a
    // small chapter fragment. This is a character budget (not a token limit).
    int maxInputCharacters = 7200,
    int concurrency = 1,
    FictionBackfillBatchWriter? onBatchCompleted,
    Iterable<ReadingArtifact> existingArtifacts = const [],
    FictionBackfillCandidateValidator? validateCandidate,
    Map<String, dynamic> artifactMetadata = const {},
  }) async {
    final lowerBound = fromProgress.clamp(0, safeBoundary).toDouble();
    final checkpointHashes = <String, String>{
      for (final artifact in existingArtifacts)
        if (artifact.kind == ReadingArtifactKinds.backfillCheckpoint &&
            artifact.chapterHref?.isNotEmpty == true &&
            artifact.payload['extractorVersion'] == extractorVersion)
          artifact.chapterHref!.split('#').first:
              artifact.payload['contentHash']?.toString() ?? '',
    };
    final eligible = chapters
        .where((chapter) =>
            chapter.startProgress >= lowerBound - .000001 &&
            chapter.startProgress <= safeBoundary + .000001 &&
            (chapter.endProgress ?? chapter.startProgress) <=
                safeBoundary + .000001)
        .toList()
      ..sort((a, b) => a.startProgress.compareTo(b.startProgress));
    final result = <ReadingArtifact>[];
    final existingIds = existingArtifacts.map((item) => item.id).toSet();
    final knownCharacterNames = existingArtifacts
        .where((item) => item.kind == ReadingArtifactKinds.character)
        .expand((item) => [
              item.payload['name'],
              if (item.payload['aliases'] is List)
                ...(item.payload['aliases'] as List),
            ])
        .map(_normalizeCharacterName)
        .where((name) => name.isNotEmpty)
        .toSet();
    final pending = <_PreparedChapter>[];
    for (final chapter in eligible) {
      final content = (await loadChapter(chapter.href)).trim();
      if (content.isEmpty) continue;
      final hash = _contentHash(content);
      if (checkpointHashes[chapter.href.split('#').first] == hash) continue;
      pending.add((chapter: chapter, content: content, hash: hash));
    }
    final batches = _makeBatches(
      pending,
      batchSize: batchSize.clamp(1, 20),
      maxInputCharacters: maxInputCharacters.clamp(4000, 100000),
    );
    var completed = 0;
    final workerCount = concurrency.clamp(1, 3);
    for (var offset = 0; offset < batches.length; offset += workerCount) {
      final window = batches.skip(offset).take(workerCount);
      // A failed request must not discard successful requests in the same
      // concurrency window: their checkpoints are emitted before the error
      // is rethrown, so a retry resumes from the last completed batch.
      final attempts = await Future.wait([
        for (final batch in window)
          _attemptBatch(
            batch: batch,
            bookId: bookId,
            moduleId: moduleId,
            lowerBound: lowerBound,
            safeBoundary: safeBoundary,
            sessionId: sessionId,
            ingestedAt: ingestedAt,
            generate: generate,
            existingIds: existingIds,
            knownCharacterNames: knownCharacterNames,
            validateCandidate: validateCandidate,
            artifactMetadata: artifactMetadata,
            maxSegmentCharacters:
                validateCandidate == null ? null : maxInputCharacters,
          )
      ]);
      Object? firstError;
      for (final attempt in attempts) {
        if (attempt.error != null) {
          firstError ??= attempt.error;
          continue;
        }
        for (final completedBatch in attempt.results) {
          result.addAll(completedBatch.artifacts);
          completed += completedBatch.chapters.length;
          if (onBatchCompleted != null) {
            await onBatchCompleted(
              artifacts: completedBatch.artifacts,
              checkpoints: [
                for (final item in completedBatch.chapters)
                  _checkpointArtifact(
                    bookId: bookId,
                    moduleId: moduleId,
                    chapter: item.chapter,
                    contentHash: item.hash,
                    sessionId: sessionId,
                    now: ingestedAt,
                    metadata: artifactMetadata,
                  ),
              ],
              completedChapters: completed,
              totalChapters: pending.length,
            );
          }
        }
      }
      if (firstError != null) throw firstError;
    }
    return result;
  }

  Future<_BackfillBatchAttempt> _attemptBatch({
    required List<_PreparedChapter> batch,
    required int bookId,
    required String moduleId,
    required double lowerBound,
    required double safeBoundary,
    required String sessionId,
    required int ingestedAt,
    required FictionBackfillGenerator generate,
    required Set<String> existingIds,
    required Set<String> knownCharacterNames,
    required FictionBackfillCandidateValidator? validateCandidate,
    required Map<String, dynamic> artifactMetadata,
    required int? maxSegmentCharacters,
  }) async {
    final attemptIds = Set<String>.of(existingIds);
    final attemptCharacterNames = Set<String>.of(knownCharacterNames);
    try {
      final results = await _processBatchWithFallback(
          batch: batch,
          bookId: bookId,
          moduleId: moduleId,
          lowerBound: lowerBound,
          safeBoundary: safeBoundary,
          sessionId: sessionId,
          ingestedAt: ingestedAt,
          generate: generate,
          existingIds: attemptIds,
          knownCharacterNames: attemptCharacterNames,
          validateCandidate: validateCandidate,
          artifactMetadata: artifactMetadata,
          maxSegmentCharacters: maxSegmentCharacters);
      for (final result in results) {
        existingIds.addAll(result.artifacts.map((artifact) => artifact.id));
      }
      knownCharacterNames.addAll(attemptCharacterNames);
      return _BackfillBatchAttempt.success(results);
    } catch (error) {
      return _BackfillBatchAttempt.failure(error);
    }
  }

  Future<List<_BackfillBatchResult>> _processBatchWithFallback({
    required List<_PreparedChapter> batch,
    required int bookId,
    required String moduleId,
    required double lowerBound,
    required double safeBoundary,
    required String sessionId,
    required int ingestedAt,
    required FictionBackfillGenerator generate,
    required Set<String> existingIds,
    required Set<String> knownCharacterNames,
    required FictionBackfillCandidateValidator? validateCandidate,
    required Map<String, dynamic> artifactMetadata,
    required int? maxSegmentCharacters,
  }) async {
    if (batch.length == 1 &&
        maxSegmentCharacters != null &&
        batch.single.content.length > maxSegmentCharacters) {
      final original = batch.single;
      final artifacts = <ReadingArtifact>[];
      final chunks = _chunker.split(
        bookId: bookId,
        chapterHref: original.chapter.href,
        chapterTitle: original.chapter.title,
        content: original.content,
        sourceProgress: original.chapter.startProgress,
        maxCharacters: maxSegmentCharacters,
      );
      for (final chunk in chunks) {
        final fragment = (
          chapter: original.chapter,
          content: chunk.content,
          hash: original.hash,
        );
        final results = await _processBatchWithFallback(
          batch: [fragment],
          bookId: bookId,
          moduleId: moduleId,
          lowerBound: lowerBound,
          safeBoundary: safeBoundary,
          sessionId: sessionId,
          ingestedAt: ingestedAt,
          generate: generate,
          existingIds: existingIds,
          knownCharacterNames: knownCharacterNames,
          validateCandidate: validateCandidate,
          artifactMetadata: artifactMetadata,
          maxSegmentCharacters: null,
        );
        artifacts.addAll(results.expand((result) => result.artifacts));
      }
      return [
        _BackfillBatchResult(artifacts: artifacts, chapters: [original]),
      ];
    }
    try {
      return [
        await _processBatch(
          batch: batch,
          bookId: bookId,
          moduleId: moduleId,
          lowerBound: lowerBound,
          safeBoundary: safeBoundary,
          sessionId: sessionId,
          ingestedAt: ingestedAt,
          generate: generate,
          existingIds: existingIds,
          knownCharacterNames: knownCharacterNames,
          validateCandidate: validateCandidate,
          artifactMetadata: artifactMetadata,
        ),
      ];
    } catch (_) {
      if (batch.length == 1) {
        final smaller = _bisectChapter(batch.single);
        if (smaller.length > 1) {
          final artifacts = <ReadingArtifact>[];
          // A malformed response is retried only for the current chapter and
          // with smaller inputs. Both halves must succeed before the original
          // chapter receives a completed checkpoint.
          for (final part in smaller) {
            final result = await _processBatch(
              batch: [part],
              bookId: bookId,
              moduleId: moduleId,
              lowerBound: lowerBound,
              safeBoundary: safeBoundary,
              sessionId: sessionId,
              ingestedAt: ingestedAt,
              generate: generate,
              existingIds: existingIds,
              knownCharacterNames: knownCharacterNames,
              validateCandidate: validateCandidate,
              artifactMetadata: artifactMetadata,
            );
            artifacts.addAll(result.artifacts);
          }
          return [
            _BackfillBatchResult(artifacts: artifacts, chapters: batch),
          ];
        }
        // Very short chapters have no safe split point. Retry the same small
        // request once so recovery cannot grow into an unbounded loop.
        return [
          await _processBatch(
            batch: batch,
            bookId: bookId,
            moduleId: moduleId,
            lowerBound: lowerBound,
            safeBoundary: safeBoundary,
            sessionId: sessionId,
            ingestedAt: ingestedAt,
            generate: generate,
            existingIds: existingIds,
            knownCharacterNames: knownCharacterNames,
            validateCandidate: validateCandidate,
            artifactMetadata: artifactMetadata,
          ),
        ];
      }
      // Large multi-chapter prompts are more likely to be truncated or
      // rejected by provider content filters. Retry two smaller, bounded
      // batches so one bad combined request does not discard valid chapters.
      final middle = (batch.length / 2).ceil();
      final results = <_BackfillBatchResult>[];
      for (final part in [batch.sublist(0, middle), batch.sublist(middle)]) {
        results.addAll(await _processBatchWithFallback(
          batch: part,
          bookId: bookId,
          moduleId: moduleId,
          lowerBound: lowerBound,
          safeBoundary: safeBoundary,
          sessionId: sessionId,
          ingestedAt: ingestedAt,
          generate: generate,
          existingIds: existingIds,
          knownCharacterNames: knownCharacterNames,
          validateCandidate: validateCandidate,
          artifactMetadata: artifactMetadata,
          maxSegmentCharacters: maxSegmentCharacters,
        ));
      }
      return results;
    }
  }

  Future<_BackfillBatchResult> _processBatch({
    required List<_PreparedChapter> batch,
    required int bookId,
    required String moduleId,
    required double lowerBound,
    required double safeBoundary,
    required String sessionId,
    required int ingestedAt,
    required FictionBackfillGenerator generate,
    required Set<String> existingIds,
    required Set<String> knownCharacterNames,
    required FictionBackfillCandidateValidator? validateCandidate,
    required Map<String, dynamic> artifactMetadata,
  }) async {
    final response = await generate(_batchPrompt(batch, knownCharacterNames));
    final grouped = _decodeBatch(response, batch);
    final expected =
        batch.map((item) => item.chapter.href.split('#').first).toSet();
    if (!grouped.keys.toSet().containsAll(expected)) {
      throw const FormatException('模型未返回完整的章节批次');
    }
    final artifacts = <ReadingArtifact>[];
    for (final entry in grouped.entries) {
      final chapter = batch.firstWhere(
          (item) => item.chapter.href.split('#').first == entry.key);
      for (final value in entry.value) {
        final kind = _kind(value['kind']?.toString());
        if (kind == null) continue;
        final payload = value['payload'];
        if (payload is! Map || payload.isEmpty) continue;
        var normalizedPayload = FictionCandidateRuleValidator.normalizePayload(
          kind,
          Map<String, dynamic>.from(payload),
        );
        if (!_isValid(kind, normalizedPayload)) continue;
        final evidence = normalizedPayload['evidence']?.toString() ?? '';
        if (evidence.isNotEmpty) {
          final resolvedEvidence = _evidenceResolver.resolve(
            sourceText: chapter.content,
            evidence: evidence,
          );
          if (resolvedEvidence == null) continue;
          normalizedPayload['evidence'] = resolvedEvidence.exactText;
        }
        if (validateCandidate != null) {
          final validated = await validateCandidate(
            kind: kind,
            payload: normalizedPayload,
            chapterContent: chapter.content,
          );
          if (validated == null) continue;
          normalizedPayload = validated;
        }
        normalizedPayload.addAll(artifactMetadata);
        normalizedPayload.addAll({
          if (chapter.chapter.workId != null) 'workId': chapter.chapter.workId,
          if (chapter.chapter.workTitle != null)
            'workTitle': chapter.chapter.workTitle,
          if (chapter.chapter.volumeId != null)
            'volumeId': chapter.chapter.volumeId,
          if (chapter.chapter.arcId != null) 'arcId': chapter.chapter.arcId,
          if (chapter.chapter.sceneId != null)
            'sceneId': chapter.chapter.sceneId,
          'scope': chapter.chapter.arcId == null ? 'chapter' : 'case',
          if (kind == ReadingArtifactKinds.character)
            'role': _characterRole(normalizedPayload),
        });
        if (kind == ReadingArtifactKinds.character) {
          final normalizedName =
              _normalizeCharacterName(normalizedPayload['name']);
          if (normalizedName.isEmpty ||
              knownCharacterNames.contains(normalizedName)) {
            continue;
          }
          knownCharacterNames.add(normalizedName);
          final aliases = normalizedPayload['aliases'];
          if (aliases is List) {
            knownCharacterNames.addAll(
              aliases
                  .map(_normalizeCharacterName)
                  .where((name) => name.isNotEmpty),
            );
          }
        }
        final sourceProgress =
            chapter.chapter.startProgress.clamp(lowerBound, safeBoundary);
        final id =
            _stableId(bookId, chapter.chapter.href, kind, normalizedPayload);
        if (existingIds.contains(id)) continue;
        existingIds.add(id);
        final confidenceSource =
            normalizedPayload['confidenceSource']?.toString();
        final sourceSnapshot =
            normalizedPayload['evidence']?.toString().trim() ?? '';
        artifacts.add(ReadingArtifact(
          id: id,
          bookId: bookId,
          moduleId: moduleId,
          kind: kind,
          payload: normalizedPayload,
          epistemicStatus: confidenceSource == 'evidenceValidated' ||
                  confidenceSource == 'explicitText'
              ? ReadingArtifactEpistemicStatus.textFact
              : ReadingArtifactEpistemicStatus.agentInference,
          sourceTextSnapshot: sourceSnapshot.isNotEmpty
              ? sourceSnapshot
              : chapter.content.length > 500
                  ? chapter.content.substring(0, 500)
                  : chapter.content,
          chapterHref: chapter.chapter.href,
          chapterTitle: chapter.chapter.title,
          sourceProgress: sourceProgress.toDouble(),
          visibleFromProgress: sourceProgress.toDouble(),
          ingestedAt: ingestedAt,
          ingestionMode: ReadingArtifactIngestionMode.backfill,
          sessionId: sessionId,
          createdBy: 'agent',
          createdAt: ingestedAt,
          updatedAt: ingestedAt,
        ));
      }
    }
    return _BackfillBatchResult(artifacts: artifacts, chapters: batch);
  }

  String _characterRole(Map<String, dynamic> payload) {
    final supplied = payload['role']?.toString().trim().toLowerCase();
    if (supplied == 'protagonist' ||
        supplied == 'main' ||
        supplied == 'main_character') {
      return 'protagonist';
    }
    final role = payload['role']?.toString() ?? '';
    if (role.contains('死者') || role.contains('受害')) return 'case_victim';
    if (role.contains('背景') || role.contains('典故')) return 'background';
    return 'case';
  }

  List<List<_PreparedChapter>> _makeBatches(
    List<_PreparedChapter> chapters, {
    required int batchSize,
    required int maxInputCharacters,
  }) {
    final result = <List<_PreparedChapter>>[];
    var current = <_PreparedChapter>[];
    var characters = 0;
    for (final chapter in chapters) {
      final wouldOverflow = current.isNotEmpty &&
          (current.length >= batchSize ||
              characters + chapter.content.length > maxInputCharacters);
      if (wouldOverflow) {
        result.add(current);
        current = [];
        characters = 0;
      }
      current.add(chapter);
      characters += chapter.content.length;
    }
    if (current.isNotEmpty) result.add(current);
    return result;
  }

  List<_PreparedChapter> _bisectChapter(_PreparedChapter item) {
    if (item.content.length < 2000) return [item];
    var middle = item.content.length ~/ 2;
    final boundary = item.content.lastIndexOf(
      RegExp(r'[\n。！？]'),
      middle,
    );
    if (boundary >= item.content.length ~/ 4) middle = boundary + 1;
    final left = item.content.substring(0, middle).trim();
    final right = item.content.substring(middle).trim();
    if (left.isEmpty || right.isEmpty) return [item];
    return [
      (chapter: item.chapter, content: left, hash: item.hash),
      (chapter: item.chapter, content: right, hash: item.hash),
    ];
  }

  ReadingArtifact _checkpointArtifact({
    required int bookId,
    required String moduleId,
    required FictionBackfillChapter chapter,
    required String contentHash,
    required String sessionId,
    required int now,
    Map<String, dynamic> metadata = const {},
  }) {
    final href = chapter.href.split('#').first;
    final idHash = sha256.convert(utf8.encode('$bookId|$href'));
    return ReadingArtifact(
      id: 'fiction-backfill-checkpoint-$idHash',
      bookId: bookId,
      moduleId: moduleId,
      kind: ReadingArtifactKinds.backfillCheckpoint,
      payload: {
        'contentHash': contentHash,
        'extractorVersion': extractorVersion,
        'status': 'completed',
        if (chapter.workId != null) 'workId': chapter.workId,
        if (chapter.workTitle != null) 'workTitle': chapter.workTitle,
        ...metadata,
      },
      epistemicStatus: ReadingArtifactEpistemicStatus.textFact,
      chapterHref: chapter.href,
      chapterTitle: chapter.title,
      sourceProgress: chapter.startProgress,
      visibleFromProgress: chapter.startProgress,
      ingestedAt: now,
      ingestionMode: ReadingArtifactIngestionMode.backfill,
      sessionId: sessionId,
      createdBy: 'system',
      createdAt: now,
      updatedAt: now,
    );
  }

  String _batchPrompt(
    List<_PreparedChapter> batch,
    Set<String> knownCharacterNames,
  ) =>
      '''
你正在为用户已经读过的小说章节建立前情档案。只依据下方正文，不补充常识，不预测后文。
请对每章分别提取，返回严格 JSON 数组，每项格式：
{"chapterHref":"章节 href","items":[{"kind":"character|relationship|event","payload":{...}}]}
每个 payload 必须增加 evidence：从本章正文逐字复制、最多 80 字的连续原文；不得改写或用摘要代替证据。
人物 payload 使用 namingSystem(chinese|western)、name、summary、aliases、role(protagonist|case|case_victim|background)、entityType(entity.person|entity.intelligent_nonhuman|entity.organization|entity.concept|entity.technology|entity.species|entity.place)。只有 entity.person 和具备稳定身份、能持续参与情节的 entity.intelligent_nonhuman 才能输出为 character；文明、组织、技术、物种、地点和思想概念不得输出为 character。框架故事中观察、采访或转述他人故事的“我”是外层叙述者：输出 name=叙述者、entityId=narrator.outer、narrativeLayer=narrative.outer。故事内人物以第一人称讲述自身经历时，必须使用该人物姓名，输出 narrativeLayer=narrative.inner、narratorRole=first_person，并把“我”放入 aliases；不得把外层叙述者和内层人物合并。中文历史/古典人物可补充 courtesyNames（字）、artNames（号）、titles（官职、尊称）；英文人物可补充 givenName、familyName、titles。若正文明确“诸葛亮，字孔明，号卧龙”，只输出一个 character，name 用完整正式姓名，孔明/卧龙进入对应字段。每个人物在同一批次只输出一次，放在其首次出现的章节，后续章节不要重复输出。每章最多输出 4 个人物。
关系 from、to 和事件 participants 必须使用人物完整规范姓名；外层叙述者尚无姓名时统一使用“叙述者”。关系端点只能是 entity.person 或 entity.intelligent_nonhuman，并分别用 fromEntityType、toEntityType 标注；文明、组织、技术、物种、地点和概念不得成为人物关系端点。关系使用 relation、relationType(relation.mentor|relation.partner|relation.schoolmate|relation.colleague|relation.comrade|relation.family|relation.spouse|relation.romantic|relation.parent_child|relation.ally|relation.rival|relation.other)、summary、state(active|changed|ended)、previousRelation，只输出正文明确支持且对理解人物网络有价值的持久关系；搭档、同桌、同学、老师属于有效关系，同行、对话、尸检对象不属于关系。每章最多输出 2 条关系。事件使用 title、summary、eventType、track(story.case|story.family|story.historical|story.character|story.relationship|story.mystery|story.social|story.worldbuilding|story.general)、stage(stage.opening|stage.incident|stage.investigation|stage.autopsy|stage.development|stage.conflict|stage.revelation|stage.climax|stage.resolution|stage.turning_point|stage.background|stage.other)、storyTimeLabel（不确定则空）、participants、importance(normal|major)。科学发现、宇宙规则、技术造成的情势变化和文明危机使用 story.worldbuilding；人物选择与成长仍使用 story.character。每章最多输出 4 个事件。
中文历史人物的数字姓（如第五、第八、第一）必须作为完整姓名保留，不得截成单字简称。不同数字姓之间不得自行推断为同宗、同族或兄弟；若正文明确写出“同宗兄弟”等关系，则按原文保留。
人物完整性优先，但分层展示：主线人物标 protagonist，当前案件人物标 case，死者/受害者标 case_victim，只在回忆或背景说明出现且不参与当前事件的人物标 background。稳定称谓只有能唯一指向同一人物时才放 aliases/titles，不得把“众人、男人、侍从”等泛称生成人物。事件只提取推动案件、悬念、关系或人物成长的重要节点，不生成流水账，不猜测日期。摘要保持一句话，避免重复正文，以节约 Token。
${knownCharacterNames.isEmpty ? '' : '已建档人物（关系和事件可引用，但不要再次输出 character）：${knownCharacterNames.join('、')}\n'}
${batch.map((item) => '章节 href：${item.chapter.href}\n章节：${item.chapter.title}\n正文：\n${item.content}').join('\n\n---\n\n')}
''';

  String _normalizeCharacterName(Object? value) =>
      value?.toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), '') ??
      '';

  Map<String, List<Map<String, dynamic>>> _decodeBatch(
      String raw, List<_PreparedChapter> batch) {
    final start = raw.indexOf('[');
    final end = raw.lastIndexOf(']');
    if (start < 0 || end <= start) return {};
    try {
      final decoded = jsonDecode(raw.substring(start, end + 1));
      if (decoded is! List) return {};
      final result = <String, List<Map<String, dynamic>>>{};
      if (batch.length == 1 &&
          decoded.every((item) => item is Map && item['kind'] != null)) {
        result[batch.single.chapter.href.split('#').first] = decoded
            .whereType<Map>()
            .map((value) => Map<String, dynamic>.from(value))
            .toList();
        return result;
      }
      for (final item in decoded.whereType<Map>()) {
        final href = item['chapterHref']?.toString().split('#').first ?? '';
        final values = item['items'];
        if (href.isEmpty || values is! List) continue;
        result[href] = values
            .whereType<Map>()
            .map((value) => Map<String, dynamic>.from(value))
            .toList();
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  String _contentHash(String content) =>
      sha256.convert(utf8.encode(content)).toString();

  String? _kind(String? value) => switch (value) {
        'character' => ReadingArtifactKinds.character,
        'relationship' => ReadingArtifactKinds.relationship,
        'event' => ReadingArtifactKinds.event,
        'mystery' => ReadingArtifactKinds.mystery,
        'clue' => ReadingArtifactKinds.clue,
        'scene' => ReadingArtifactKinds.scene,
        _ => null,
      };

  bool _isValid(String kind, Map<String, dynamic> payload) => switch (kind) {
        ReadingArtifactKinds.character => _has(payload, 'name'),
        ReadingArtifactKinds.relationship => _has(payload, 'from') &&
            _has(payload, 'to') &&
            _has(payload, 'relation'),
        ReadingArtifactKinds.event => _has(payload, 'title'),
        ReadingArtifactKinds.mystery => _has(payload, 'question'),
        ReadingArtifactKinds.scene => _has(payload, 'summary'),
        ReadingArtifactKinds.clue =>
          _has(payload, 'summary') || _has(payload, 'title'),
        _ => false,
      };

  bool _has(Map<String, dynamic> payload, String key) =>
      payload[key]?.toString().trim().isNotEmpty == true;

  String _stableId(
    int bookId,
    String href,
    String kind,
    Map<String, dynamic> payload,
  ) {
    final signature = jsonEncode(_canonical(payload));
    final digest = sha256.convert(utf8.encode(
      '$bookId|${href.split('#').first.trim()}|$kind|$signature',
    ));
    return 'fiction-backfill-$digest';
  }

  Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    if (value is List) return value.map(_canonical).toList(growable: false);
    return value;
  }
}

const fictionBackfillService = FictionBackfillService();
