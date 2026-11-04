import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_evidence.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/service/ai/reading_review_scheduler.dart';
import 'package:anx_reader/service/ai/reading_memory_repository.dart';
import 'package:anx_reader/service/ai/book_wiki_service.dart';
import 'package:anx_reader/service/ai/reading_memory_projection.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:anx_reader/service/ai/reading_evidence_adapter.dart';
import 'package:anx_reader/service/ai/validated_ai_mutation.dart';
import 'package:anx_reader/utils/log/common.dart';

/// Single mutation boundary used by Reading Agent tools and UI commands.
/// Repository transactions persist both the mutation and its undo journal.
class AgentActionService {
  AgentActionService({
    ReadingAgentRepository? repository,
    ReadingAgentRuntimeController? runtime,
    BookWikiService? materialsService,
    ReadingMemoryRepository? memoryRepository,
  })  : _repository = repository ?? readingAgentRepository,
        _runtime = runtime ?? readingAgentRuntime,
        _materialsService = materialsService ?? bookWikiService,
        _memoryRepository = memoryRepository ?? ReadingMemoryRepository();

  final ReadingAgentRepository _repository;
  final ReadingAgentRuntimeController _runtime;
  final BookWikiService _materialsService;
  final ReadingMemoryRepository _memoryRepository;

  Future<AgentMutation<T>> applyValidated<T>(
    ValidatedAiMutation<T> mutation,
    Future<AgentMutation<T>> Function() apply,
  ) async {
    _validateMutation(mutation);
    final result = await apply();
    _logAppliedMutation(mutation, result.action.id);
    return result;
  }

  Future<AgentMutation<T>?> applyValidatedNullable<T>(
    ValidatedAiMutation<T> mutation,
    Future<AgentMutation<T>?> Function() apply,
  ) async {
    _validateMutation(mutation);
    final result = await apply();
    if (result != null) _logAppliedMutation(mutation, result.action.id);
    return result;
  }

  void _validateMutation<T>(ValidatedAiMutation<T> mutation) {
    if (!mutation.isAuthorized) {
      throw StateError('Proactive AI suggestions require user confirmation');
    }
    validateEvidenceForMutation(
      evidence: mutation.evidence,
      bookId: mutation.bookId,
      visibleProgress: mutation.visibleProgress,
    );
  }

  void _logAppliedMutation<T>(
    ValidatedAiMutation<T> mutation,
    String actionId,
  ) {
    AnxLog.info(
      'AI mutation applied action=${mutation.actionType} '
      'target=${mutation.targetType} actionId=$actionId '
      'requestId=${mutation.requestId ?? '-'} taskId=${mutation.taskId ?? '-'} '
      'workloadId=${mutation.workloadId ?? '-'}',
    );
  }

  /// Common validation boundary for new AI write commands. Existing typed
  /// methods remain the compatibility facade and continue to own domain
  /// validation and repository transactions.
  void validateEvidenceForMutation({
    required Iterable<EvidenceEnvelope> evidence,
    required int bookId,
    required double visibleProgress,
  }) {
    for (final item in evidence) {
      if (!item.isTraceable) {
        throw ArgumentError('AI mutation contains untraceable evidence');
      }
      if (item.bookId != null && item.bookId != bookId) {
        throw ArgumentError('AI mutation evidence belongs to another book');
      }
      if (!item.isVisibleAtProgress(visibleProgress)) {
        throw ArgumentError('AI mutation evidence exceeds spoiler boundary');
      }
    }
  }

  String get _sessionId {
    final value = _runtime.state.sessionId;
    if (value == null) throw StateError('No active reading session');
    return value;
  }

  Future<AgentMutation<ReadingGoal>> saveGoal(ReadingGoal goal) async {
    final mutation = await applyValidated(
      ValidatedAiMutation<ReadingGoal>(
        actionType: 'reading_goal_save',
        targetType: 'reading_goal',
        targetId: goal.id,
        bookId: goal.bookId,
        value: goal,
        authorization: AiMutationAuthorization.confirmedTask,
        visibleProgress: _runtime.state.totalProgress,
      ),
      () => _repository.saveGoal(goal, sessionId: _sessionId),
    );
    _runtime.goalChanged(goal.status == ReadingGoalStatus.active ? goal : null);
    _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<AgentMutation<ReadingNoteDocument>> createNote(
    ReadingNoteDocument document, {
    int? ownedAnnotationId,
    BookNote? ownedAnnotation,
  }) async {
    _requireCurrentBook(document.note.bookId);
    for (final source in document.sources) {
      if ((source.metadata.containsKey('sourceProgress') ||
              source.metadata.containsKey('visibleFromProgress')) &&
          ReadingEvidenceAdapter.fromNoteSource(source,
                  bookId: document.note.bookId) ==
              null) {
        throw ArgumentError('Note source has an invalid reading boundary');
      }
    }
    final mutation = await applyValidated(
      ValidatedAiMutation<ReadingNoteDocument>(
        actionType: 'reading_note_create',
        targetType: 'reading_note',
        targetId: document.note.id,
        bookId: document.note.bookId,
        value: document,
        authorization: AiMutationAuthorization.confirmedTask,
        evidence: [
          for (final source in document.sources)
            if (ReadingEvidenceAdapter.fromNoteSource(
              source,
              bookId: document.note.bookId,
              visibleFromProgress: _runtime.state.totalProgress,
            )
                case final item?)
              item,
        ],
        visibleProgress: _runtime.state.totalProgress,
      ),
      () => _repository.createNote(
        document,
        sessionId: _sessionId,
        ownedAnnotationId: ownedAnnotationId,
        ownedAnnotation: ownedAnnotation,
      ),
    );
    if (ownedAnnotation != null) {
      ReaderCommandGateway.instance.showAnnotation(ownedAnnotation);
    }
    _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<AgentMutation<ReadingNoteDocument>> createSourcedNote({
    required int bookId,
    required String sourceText,
    required String cfi,
    required String chapterTitle,
    String? chapterHref,
    required String body,
    String title = '',
    String model = 'unknown',
    double? sourceProgress,
    double? visibleFromProgress,
  }) async {
    _requireCurrentBook(bookId);
    final sourceBoundary = sourceProgress ?? _runtime.state.totalProgress;
    final visibleBoundary = visibleFromProgress ?? sourceBoundary;
    if (!sourceBoundary.isFinite ||
        !visibleBoundary.isFinite ||
        sourceBoundary < 0 ||
        sourceBoundary > 1 ||
        visibleBoundary < sourceBoundary ||
        visibleBoundary > 1 ||
        visibleBoundary > _runtime.state.totalProgress + .000001) {
      throw ArgumentError('Note source exceeds the current reading boundary');
    }
    if (sourceText.trim().isEmpty ||
        !cfi.startsWith('epubcfi(') ||
        !cfi.endsWith(')') ||
        body.trim().isEmpty) {
      throw ArgumentError('A valid source, CFI, and note body are required');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final noteId = const Uuid().v4();
    final document = ReadingNoteDocument(
      note: ReadingNote(
        id: noteId,
        bookId: bookId,
        title: title.trim(),
        status: ReadingNoteStatus.active,
        captureKind: ReadingNoteCaptureKind.manual,
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
      ),
      blocks: [
        ReadingNoteBlock(
          id: const Uuid().v4(),
          noteId: noteId,
          type: ReadingNoteBlockType.quote,
          content: sourceText.trim(),
          sortOrder: 0,
          origin: ReadingNoteBlockOrigin.source,
          createdAt: now,
          updatedAt: now,
        ),
        ReadingNoteBlock(
          id: const Uuid().v4(),
          noteId: noteId,
          type: ReadingNoteBlockType.ai,
          content: body.trim(),
          sortOrder: 1,
          origin: ReadingNoteBlockOrigin.ai,
          metadata: {'model': model, 'sessionId': _sessionId},
          createdAt: now,
          updatedAt: now,
        ),
      ],
      sources: [
        ReadingNoteSource(
          noteId: noteId,
          type: ReadingNoteSourceType.aiSession,
          sourceRef: _sessionId,
          chapterHref: chapterHref,
          chapterTitle: chapterTitle,
          cfi: cfi,
          textSnapshot: sourceText.trim(),
          metadata: {
            'model': model,
            'sourceProgress': sourceBoundary,
            'visibleFromProgress': visibleBoundary,
          },
          createdAt: now,
        ),
      ],
    );
    return createNote(
      document,
      ownedAnnotation: BookNote(
        bookId: bookId,
        content: sourceText.trim(),
        cfi: cfi,
        chapter: chapterTitle,
        type: 'highlight',
        color: Prefs().annotationColor,
        readerNote: body.trim(),
        createTime: DateTime.fromMillisecondsSinceEpoch(now),
        updateTime: DateTime.fromMillisecondsSinceEpoch(now),
      ),
    );
  }

  Future<AgentMutation<ReadingDifficulty>> saveDifficulty(
    ReadingDifficulty difficulty, {
    double? sourceProgress,
    double? visibleFromProgress,
  }) async {
    _requireCurrentBook(difficulty.bookId);
    final progress = sourceProgress ??
        (difficulty.cfi == _runtime.state.cfi
            ? _runtime.state.totalProgress
            : null);
    final visible = visibleFromProgress ?? progress;
    if (progress != null &&
        (!progress.isFinite ||
            progress < 0 ||
            progress > 1 ||
            visible == null ||
            !visible.isFinite ||
            visible < progress ||
            visible > _runtime.state.totalProgress + .000001)) {
      throw ArgumentError('Question source exceeds current reading boundary');
    }
    final mutation = await applyValidated(
      ValidatedAiMutation<ReadingDifficulty>(
        actionType: 'reading_difficulty_save',
        targetType: 'reading_difficulty',
        targetId: difficulty.id,
        bookId: difficulty.bookId,
        value: difficulty,
        authorization: AiMutationAuthorization.confirmedTask,
        visibleProgress: _runtime.state.totalProgress,
      ),
      () => _repository.saveDifficulty(difficulty,
          sessionId: _sessionId,
          sourceProgress: progress,
          visibleFromProgress: visible),
    );
    ReaderCommandGateway.instance.showDifficulty(
      id: mutation.value.id,
      cfi: mutation.value.cfi,
    );
    _runtime.actionApplied(mutation.action);
    return mutation;
  }

  void _requireCurrentBook(int bookId) {
    if (_runtime.state.bookId != bookId || !_runtime.isActive) {
      throw StateError('The action requires the current reading session');
    }
  }

  String _explicitSessionForBook(int bookId) {
    if (_runtime.isActive && _runtime.state.bookId != bookId) {
      throw StateError('The action belongs to another book');
    }
    return _runtime.state.sessionId ?? 'outcomes:$bookId';
  }

  Future<AgentMutation<Map<String, Object?>>> _savePracticeRecord({
    required ReadingPracticeRecordKind kind,
    required int bookId,
    required String targetId,
    required Map<String, Object?> values,
    Map<String, Object?>? review,
    List<String>? sourceIds,
    int? expectedUpdatedAt,
    bool createOnly = false,
    List<EvidenceEnvelope> evidence = const [],
  }) async {
    _requireCurrentBook(bookId);
    final session = _explicitSessionForBook(bookId);
    final mutation = await applyValidated(
        ValidatedAiMutation<Map<String, Object?>>(
          actionType: 'reading_practice_${kind.name}',
          targetType: kind.name,
          targetId: targetId,
          bookId: bookId,
          value: values,
          authorization: AiMutationAuthorization.explicitUserRequest,
          visibleProgress: _runtime.state.totalProgress,
          evidence: evidence,
        ),
        () => _repository.savePracticeRecord(
            kind: kind,
            bookId: bookId,
            targetId: targetId,
            values: values,
            review: review,
            sourceIds: sourceIds,
            sessionId: session,
            createOnly: createOnly,
            expectedUpdatedAt: expectedUpdatedAt));
    _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<List<ReadingMemorySource>> visibleMemorySources(
      int bookId, List<ReadingMemorySource> sources) async {
    _requireCurrentBook(bookId);
    final materials = await _materialsService.loadMaterials(bookId,
        visibleAtProgress: _runtime.state.totalProgress,
        currentCfi: _runtime.state.cfi);
    return sources
        .where((source) =>
            ReadingMemoryProjection.sourceBoundary(source, materials) != null)
        .toList();
  }

  Future<List<EvidenceEnvelope>> _memoryEvidence(
      int bookId, List<ReadingMemorySource> sources) async {
    _requireCurrentBook(bookId);
    final materials = await _materialsService.loadMaterials(bookId,
        visibleAtProgress: _runtime.state.totalProgress,
        currentCfi: _runtime.state.cfi);
    return sources.map((source) {
      final boundary =
          ReadingMemoryProjection.sourceBoundary(source, materials);
      if (boundary == null ||
          source.text.trim().isEmpty ||
          source.sourceRef?.isNotEmpty != true) {
        throw StateError(
            'Memory source is unavailable at this reading position');
      }
      return EvidenceEnvelope(
          id: source.id,
          sourceKind: EvidenceSourceKind.readerRecord,
          sourceRef: '${source.type.name}:${source.sourceRef}',
          bookId: bookId,
          cfi: source.cfi,
          chapterHref: source.chapterHref,
          chapterTitle: source.chapterTitle,
          exactText: source.text,
          sourceProgress: boundary,
          visibleFromProgress: boundary,
          epistemicStatus: 'readerRecord',
          producer: 'readingMemory');
    }).toList();
  }

  Future<List<EvidenceEnvelope>> _storedMemoryEvidence(
      int bookId, List<String> ids) async {
    if (ids.isEmpty) throw StateError('Memory content requires known sources');
    final stored = {
      for (final source in await _memoryRepository.sources(bookId))
        source.id: source
    };
    if (ids.any((id) => !stored.containsKey(id))) {
      throw StateError('Unknown memory source');
    }
    return _memoryEvidence(bookId, ids.map((id) => stored[id]!).toList());
  }

  Future<AgentMutation<Map<String, Object?>>> saveMemorySource(
          ReadingMemorySource source) async =>
      _savePracticeRecord(
          kind: ReadingPracticeRecordKind.source,
          bookId: source.bookId,
          targetId: source.id,
          createOnly: true,
          values: source.toDb(),
          evidence: await _memoryEvidence(source.bookId, [source]));

  Future<AgentMutation<Map<String, Object?>>> saveMemoryTopic(
          ReadingMemoryTopic topic,
          {ReadingMemoryItemStatus? status}) async =>
      _savePracticeRecord(
          kind: ReadingPracticeRecordKind.topic,
          bookId: topic.bookId,
          targetId: topic.id,
          values: status == null
              ? topic.toDb()
              : {
                  'book_id': topic.bookId,
                  'status': status.name,
                  'updated_at': DateTime.now().millisecondsSinceEpoch
                },
          sourceIds: topic.sourceIds,
          createOnly: status == null,
          expectedUpdatedAt: status == null ? null : topic.updatedAt,
          evidence: await _storedMemoryEvidence(topic.bookId, topic.sourceIds));

  Future<AgentMutation<Map<String, Object?>>> saveMemoryCard(
          ReadingKnowledgeCard card,
          {ReadingMemoryItemStatus? status}) async =>
      _savePracticeRecord(
          kind: ReadingPracticeRecordKind.card,
          bookId: card.bookId,
          targetId: card.id,
          values: status == null
              ? card.toDb()
              : {
                  'book_id': card.bookId,
                  'status': status.name,
                  'updated_at': DateTime.now().millisecondsSinceEpoch
                },
          sourceIds: card.sourceIds,
          createOnly: status == null,
          expectedUpdatedAt: status == null ? null : card.updatedAt,
          evidence: await _storedMemoryEvidence(card.bookId, card.sourceIds));

  Future<AgentMutation<Map<String, Object?>>> saveInspectionGuide(
          InspectionReadingGuide guide) =>
      _savePracticeRecord(
          kind: ReadingPracticeRecordKind.guide,
          bookId: guide.bookId,
          targetId: guide.bookId.toString(),
          values: guide.toDb());

  Future<AgentMutation<Map<String, Object?>>> saveChapterQuiz(
          ChapterQuiz quiz) =>
      _savePracticeRecord(
          kind: ReadingPracticeRecordKind.quiz,
          bookId: quiz.bookId,
          targetId: quiz.id,
          values: quiz.toDb());

  Future<AgentMutation<ReadingDifficulty>> updateDifficulty(
      ReadingDifficulty difficulty) async {
    _requireCurrentBook(difficulty.bookId);
    final session = _explicitSessionForBook(difficulty.bookId);
    final mutation = await applyValidated(
        ValidatedAiMutation<ReadingDifficulty>(
          actionType: 'reading_difficulty_update',
          targetType: 'reading_difficulty',
          targetId: difficulty.id,
          bookId: difficulty.bookId,
          value: difficulty,
          authorization: AiMutationAuthorization.explicitUserRequest,
        ),
        () => _repository.updateDifficultyStatus(difficulty,
            sessionId: session, includeType: true));
    if (difficulty.status == ReadingDifficultyStatus.resolved) {
      ReaderCommandGateway.instance
          .hideAnnotation('difficulty:${difficulty.id}');
      if (_runtime.state.bookId == difficulty.bookId &&
          mutation.action.beforeSnapshot?['status'] ==
              ReadingDifficultyStatus.unresolved.name) {
        _runtime.difficultyResolved();
      }
    }
    _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<AgentMutation<Map<String, Object?>>> reviewMemoryCard(
      ReadingKnowledgeCard card, ReadingReviewRating rating) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final schedule = ReadingReviewScheduler.schedule(
        currentStage: card.reviewStage, rating: rating, now: now);
    final updated = card.copyWith(
        reviewStage: schedule.stage,
        nextReviewAt: schedule.nextReviewAt,
        hardCount:
            card.hardCount + (rating == ReadingReviewRating.hard ? 1 : 0),
        rememberedCount: card.rememberedCount +
            (rating == ReadingReviewRating.remembered ? 1 : 0),
        masteredCount: card.masteredCount +
            (rating == ReadingReviewRating.mastered ? 1 : 0),
        updatedAt: now);
    final review = ReadingCardReview(
        id: 'review-${card.id}-$now',
        cardId: card.id,
        bookId: card.bookId,
        rating: rating,
        previousStage: card.reviewStage,
        nextStage: schedule.stage,
        previousReviewAt: card.nextReviewAt,
        nextReviewAt: schedule.nextReviewAt,
        reviewedAt: now);
    return _savePracticeRecord(
        kind: ReadingPracticeRecordKind.card,
        bookId: card.bookId,
        targetId: card.id,
        values: updated.toDb(),
        review: review.toDb(),
        evidence: await _storedMemoryEvidence(card.bookId, card.sourceIds),
        expectedUpdatedAt: card.updatedAt);
  }

  Future<UndoResult> undoLatestPracticeReview(int bookId) async {
    _explicitSessionForBook(bookId);
    final actions = await _repository.recentActions(bookId: bookId);
    final action = actions
        .where((item) =>
            item.status == AgentActionStatus.applied &&
            item.afterSnapshot?['practice'] ==
                ReadingPracticeRecordKind.card.name &&
            item.afterSnapshot?['reviewId'] != null)
        .firstOrNull;
    return action == null ? UndoResult.alreadyUndone : undo(action);
  }

  Future<AgentMutation<int>> deletePracticeMemory(int bookId) async {
    _requireCurrentBook(bookId);
    final mutation = await applyValidated(
        ValidatedAiMutation<int>(
          actionType: 'reading_practice_delete',
          targetType: 'reading_memory',
          targetId: '$bookId',
          bookId: bookId,
          value: bookId,
          authorization: AiMutationAuthorization.explicitUserRequest,
        ),
        () => _repository.deletePracticeMemory(bookId, sessionId: _sessionId));
    _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<AgentMutation<ReadingDifficulty>> resolveDifficulty(
    ReadingDifficulty difficulty,
  ) async {
    final sessionId = _explicitSessionForBook(difficulty.bookId);
    final updated = difficulty.copyWith(
      status: ReadingDifficultyStatus.resolved,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final mutation = await applyValidated(
      ValidatedAiMutation<ReadingDifficulty>(
        actionType: 'reading_difficulty_resolve',
        targetType: 'reading_difficulty',
        targetId: updated.id,
        bookId: updated.bookId,
        value: updated,
        authorization: AiMutationAuthorization.explicitUserRequest,
      ),
      () => _repository.updateDifficultyStatus(updated, sessionId: sessionId),
    );
    ReaderCommandGateway.instance.hideAnnotation('difficulty:${updated.id}');
    if (_runtime.state.bookId == difficulty.bookId) {
      if (mutation.action.beforeSnapshot?['status'] ==
          ReadingDifficultyStatus.unresolved.name) {
        _runtime.difficultyResolved();
      }
      _runtime.actionApplied(mutation.action);
    }
    return mutation;
  }

  Future<AgentMutation<KnowledgeCard>> reviewKnowledgeCard(
    KnowledgeCard card, {
    required bool remembered,
  }) async {
    _requireCurrentBook(card.bookId);
    final materials = await _materialsService.loadMaterials(card.bookId,
        visibleAtProgress: _runtime.state.totalProgress,
        currentCfi: _runtime.state.cfi);
    final boundary = materials.sourceBoundaries['knowledgeCard:${card.id}'];
    if (_runtime.state.totalProgress < 1 &&
        (boundary == null ||
            !boundary.isFinite ||
            boundary > _runtime.state.totalProgress + .000001)) {
      throw StateError(
          'Review card source is unavailable at this reading position');
    }
    final sessionId = _explicitSessionForBook(card.bookId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final interval = remembered ? (card.intervalDays * 2).clamp(2, 60) : 1;
    final updated = card.copyWith(
      intervalDays: interval,
      repetitions: card.repetitions + 1,
      dueAt: now + Duration(days: interval).inMilliseconds,
      updatedAt: now,
    );
    final mutation = await applyValidated(
      ValidatedAiMutation<KnowledgeCard>(
        actionType: 'reading_knowledge_card_review',
        targetType: 'knowledge_card',
        targetId: updated.id,
        bookId: updated.bookId,
        value: updated,
        authorization: AiMutationAuthorization.explicitUserRequest,
      ),
      () => _repository.reviewKnowledgeCard(updated,
          sessionId: sessionId, expectedUpdatedAt: card.updatedAt),
    );
    if (_runtime.state.bookId == card.bookId) {
      if (card.dueAt != null && card.dueAt! <= now) {
        _runtime.knowledgeCardReviewed();
      }
      _runtime.actionApplied(mutation.action);
    }
    return mutation;
  }

  Future<AgentMutation<ReadingMemoryDocument>> appendMemory(
      ReadingMemoryDocument document) async {
    final mutation = await applyValidated(
      ValidatedAiMutation<ReadingMemoryDocument>(
        actionType: 'reading_memory_append',
        targetType: 'reading_memory',
        targetId: document.id,
        bookId: document.bookId,
        value: document,
        authorization: AiMutationAuthorization.confirmedTask,
        visibleProgress: _runtime.state.totalProgress,
      ),
      () => _repository.appendMemory(document, sessionId: _sessionId),
    );
    _runtime.memoryAdded(document.title);
    _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<AgentMutation<ReadingChapterCheckpoint>> finishChapterCheckpoint({
    required ReadingChapterCheckpoint checkpoint,
    required String reflection,
    MasteryLevel? masteryLevel,
    bool createKnowledgeCard = false,
    bool saveMemory = false,
    String memoryTitle = '',
  }) async {
    _requireCurrentBook(checkpoint.bookId);
    if (!checkpoint.progress.isFinite ||
        checkpoint.progress < 0 ||
        checkpoint.progress > _runtime.state.totalProgress + .000001) {
      throw ArgumentError('Checkpoint exceeds the current reading boundary');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final text = reflection.trim();
    final mastery = masteryLevel == null
        ? null
        : MasteryState(
            id: '${checkpoint.bookId}-${checkpoint.chapterHref.hashCode}',
            bookId: checkpoint.bookId,
            chapterHref: checkpoint.chapterHref,
            topic: checkpoint.chapterTitle.isEmpty
                ? checkpoint.chapterHref
                : checkpoint.chapterTitle,
            level: masteryLevel,
            score: masteryLevel.index / (MasteryLevel.values.length - 1),
            nextReviewAt: createKnowledgeCard
                ? now + const Duration(days: 1).inMilliseconds
                : null,
            updatedAt: now);
    final card = !createKnowledgeCard || text.isEmpty
        ? null
        : KnowledgeCard(
            id: '${checkpoint.id}-recall',
            bookId: checkpoint.bookId,
            front: '请回忆：${checkpoint.chapterTitle}',
            back: text,
            chapterHref: checkpoint.chapterHref,
            dueAt: now + const Duration(days: 1).inMilliseconds,
            createdAt: now,
            updatedAt: now);
    final memory = !saveMemory || text.isEmpty
        ? null
        : ReadingMemoryDocument(
            id: '${checkpoint.id}-reflection',
            bookId: checkpoint.bookId,
            title: memoryTitle,
            markdown: text,
            sourceRefs: ['checkpoint:${checkpoint.id}'],
            createdAt: now,
            updatedAt: now);
    final mutation = await applyValidated(
        ValidatedAiMutation<ReadingChapterCheckpoint>(
          actionType: 'reading_checkpoint_finish',
          targetType: 'reading_checkpoint',
          targetId: checkpoint.id,
          bookId: checkpoint.bookId,
          value: checkpoint,
          authorization: AiMutationAuthorization.explicitUserRequest,
          visibleProgress: _runtime.state.totalProgress,
        ),
        () => _repository.finishChapterCheckpoint(
            checkpoint: checkpoint.copyWith(reflection: text),
            mastery: mastery,
            card: card,
            memory: memory,
            sessionId: _sessionId));
    _runtime.checkpointResolved();
    if (memory != null) _runtime.memoryAdded(memory.title);
    _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<AgentMutation<ReadingArtifact>> saveArtifact(
      ReadingArtifact artifact) async {
    final source = ReadingEvidenceAdapter.fromArtifact(artifact);
    final mutation = await applyValidated(
      ValidatedAiMutation<ReadingArtifact>(
        actionType: 'reading_artifact_save',
        targetType: 'reading_artifact',
        targetId: artifact.id,
        bookId: artifact.bookId,
        value: artifact,
        authorization: AiMutationAuthorization.confirmedTask,
        evidence: source == null ? const [] : [source],
        visibleProgress: _runtime.state.totalProgress,
      ),
      () => _repository.saveArtifact(artifact, sessionId: _sessionId),
    );
    _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<AgentMutation<BookWikiEntry>> saveWikiEntry(
    BookWikiEntry entry, {
    BookWiki? wiki,
    BookWikiRevision? revision,
    String? sessionId,
  }) async {
    final evidence = [
      for (final source in entry.sources)
        if (ReadingEvidenceAdapter.fromWikiSource(
          source,
          visibleFromProgress: entry.visibleFromProgress,
          epistemicStatus: entry.epistemicStatus,
        )
            case final resolved?)
          resolved,
    ];
    final mutation = await applyValidated(
      ValidatedAiMutation<BookWikiEntry>(
        actionType: 'book_wiki_entry_save',
        targetType: 'book_wiki_entry',
        targetId: entry.id,
        bookId: entry.bookId,
        value: entry,
        authorization: AiMutationAuthorization.confirmedTask,
        evidence: evidence,
        // Full-book Wiki generation is explicitly confirmed and may persist
        // future entries while keeping them hidden by visibleFromProgress.
        visibleProgress: 1,
      ),
      () => _repository.saveWikiEntry(
        entry,
        wiki: wiki,
        revision: revision,
        sessionId: sessionId ??
            _runtime.state.sessionId ??
            'wiki-${entry.bookId}-${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    if (_runtime.state.sessionId != null) {
      _runtime.actionApplied(mutation.action);
    }
    return mutation;
  }

  Future<AgentMutation<ReaderProfileItem>?> recordProfileEvidence({
    required String key,
    required Map<String, dynamic> value,
    bool explicit = false,
  }) async {
    final mutation = await applyValidatedNullable(
      ValidatedAiMutation<ReaderProfileItem>(
        actionType: 'reader_profile_evidence',
        targetType: 'reader_profile',
        targetId: key,
        bookId: _runtime.state.bookId ?? 0,
        value: ReaderProfileItem(
          key: key,
          value: value,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
        authorization: explicit
            ? AiMutationAuthorization.explicitUserRequest
            : AiMutationAuthorization.confirmedTask,
      ),
      () => _repository.recordProfileEvidence(
        key: key,
        value: value,
        sessionId: _sessionId,
        explicit: explicit,
      ),
    );
    if (mutation != null) _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<AgentMutation<ReaderProfileItem>> setProfileStatus({
    required String key,
    required ReaderProfileStatus status,
  }) async {
    final mutation = await applyValidated(
      ValidatedAiMutation<ReaderProfileItem>(
        actionType: 'reader_profile_status',
        targetType: 'reader_profile',
        targetId: key,
        bookId: _runtime.state.bookId ?? 0,
        value: ReaderProfileItem(
          key: key,
          status: status,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
        authorization: AiMutationAuthorization.explicitUserRequest,
      ),
      () => _repository.setProfileStatus(
        key: key,
        status: status,
        sessionId: _sessionId,
      ),
    );
    _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<UndoResult> undo(AgentAction action) async {
    final result = await _repository.undo(action.id);
    if (result == UndoResult.undone) {
      if (action.type == AgentActionType.note) {
        final sources = action.afterSnapshot?['sources'];
        if (sources is List && sources.isNotEmpty && sources.first is Map) {
          final cfi = (sources.first as Map)['cfi']?.toString();
          if (cfi?.isNotEmpty == true) {
            ReaderCommandGateway.instance.hideAnnotation(cfi!);
          }
        }
      } else if (action.type == AgentActionType.difficulty) {
        final before = action.beforeSnapshot;
        if (before != null &&
            before['status'] == ReadingDifficultyStatus.unresolved.name) {
          final difficulty = ReadingDifficulty.fromDb(before);
          ReaderCommandGateway.instance.showDifficulty(
            id: difficulty.id,
            cfi: difficulty.cfi,
          );
          if (action.afterSnapshot?['status'] ==
                  ReadingDifficultyStatus.resolved.name &&
              _runtime.state.bookId == action.bookId) {
            _runtime.difficultyReopened();
          }
        } else {
          ReaderCommandGateway.instance
              .hideAnnotation('difficulty:${action.targetId}');
        }
      } else if (action.type == AgentActionType.memory) {
        if (action.beforeSnapshot?['chapterClosure'] is Map &&
            _runtime.state.bookId == action.bookId) {
          final before = action.beforeSnapshot!;
          if ((before['checkpoint'] as Map?)?['status'] ==
              ReadingCheckpointStatus.pending.name) {
            _runtime.checkpointReopened();
          }
          final memory = action.afterSnapshot?['memory'];
          if (memory is Map && before['memory'] == null) {
            _runtime.memoryRemoved(memory['title']?.toString() ?? '');
          }
        }
        final restoredCard = action.beforeSnapshot?['knowledgeCard'];
        if (restoredCard is Map) {
          final dueAt = restoredCard['due_at'];
          if (_runtime.state.bookId == action.bookId &&
              dueAt is int &&
              dueAt <= DateTime.now().millisecondsSinceEpoch) {
            _runtime.knowledgeCardReviewUndone();
          }
        } else if (action.afterSnapshot?['practice'] == null &&
            action.afterSnapshot?['chapterClosure'] == null) {
          _runtime
              .memoryRemoved(action.afterSnapshot?['title']?.toString() ?? '');
        }
      }
      _runtime.actionUndone(action);
      if (action.type == AgentActionType.goal && action.bookId != null) {
        _runtime.goalChanged(await _repository.activeGoal(action.bookId!));
      }
    }
    return result;
  }
}

final agentActionService = AgentActionService();
