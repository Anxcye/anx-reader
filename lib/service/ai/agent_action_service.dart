import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';

/// Single mutation boundary used by Reading Agent tools and UI commands.
/// Repository transactions persist both the mutation and its undo journal.
class AgentActionService {
  AgentActionService({
    ReadingAgentRepository? repository,
    ReadingAgentRuntimeController? runtime,
  })  : _repository = repository ?? readingAgentRepository,
        _runtime = runtime ?? readingAgentRuntime;

  final ReadingAgentRepository _repository;
  final ReadingAgentRuntimeController _runtime;

  String get _sessionId {
    final value = _runtime.state.sessionId;
    if (value == null) throw StateError('No active reading session');
    return value;
  }

  Future<AgentMutation<ReadingGoal>> saveGoal(ReadingGoal goal) async {
    final mutation = await _repository.saveGoal(
      goal,
      sessionId: _sessionId,
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
    final mutation = await _repository.createNote(
      document,
      sessionId: _sessionId,
      ownedAnnotationId: ownedAnnotationId,
      ownedAnnotation: ownedAnnotation,
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
  }) async {
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
          metadata: {'model': model},
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
    ReadingDifficulty difficulty,
  ) async {
    final mutation = await _repository.saveDifficulty(
      difficulty,
      sessionId: _sessionId,
    );
    ReaderCommandGateway.instance.showDifficulty(
      id: mutation.value.id,
      cfi: mutation.value.cfi,
    );
    _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<AgentMutation<ReadingMemoryDocument>> appendMemory(
      ReadingMemoryDocument document) async {
    final mutation =
        await _repository.appendMemory(document, sessionId: _sessionId);
    _runtime.memoryAdded(document.title);
    _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<AgentMutation<ReadingArtifact>> saveArtifact(
      ReadingArtifact artifact) async {
    final mutation =
        await _repository.saveArtifact(artifact, sessionId: _sessionId);
    _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<AgentMutation<BookWikiEntry>> saveWikiEntry(
    BookWikiEntry entry, {
    BookWiki? wiki,
    BookWikiRevision? revision,
    String? sessionId,
  }) async {
    final mutation = await _repository.saveWikiEntry(
      entry,
      wiki: wiki,
      revision: revision,
      sessionId: sessionId ??
          _runtime.state.sessionId ??
          'wiki-${entry.bookId}-${DateTime.now().millisecondsSinceEpoch}',
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
    final mutation = await _repository.recordProfileEvidence(
      key: key,
      value: value,
      sessionId: _sessionId,
      explicit: explicit,
    );
    if (mutation != null) _runtime.actionApplied(mutation.action);
    return mutation;
  }

  Future<AgentMutation<ReaderProfileItem>> setProfileStatus({
    required String key,
    required ReaderProfileStatus status,
  }) async {
    final mutation = await _repository.setProfileStatus(
      key: key,
      status: status,
      sessionId: _sessionId,
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
        ReaderCommandGateway.instance.hideAnnotation(
          'difficulty:${action.targetId}',
        );
      } else if (action.type == AgentActionType.memory) {
        _runtime
            .memoryRemoved(action.afterSnapshot?['title']?.toString() ?? '');
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
