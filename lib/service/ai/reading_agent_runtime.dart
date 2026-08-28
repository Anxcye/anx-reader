import 'dart:async';

import 'package:anx_reader/dao/reading_coach.dart' as coach_dao;
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:anx_reader/utils/log/common.dart';

enum ReadingEventType {
  sessionStarted,
  sessionEnded,
  locationSettled,
  chapterChanged,
  selectionCreated,
  selectionCleared,
  goalChanged,
  agentActionApplied,
  agentActionUndone,
}

class ReadingEvent {
  const ReadingEvent({
    required this.type,
    required this.sessionId,
    required this.occurredAt,
    this.data = const {},
  });

  final ReadingEventType type;
  final String sessionId;
  final DateTime occurredAt;
  final Map<String, Object?> data;
}

class ReadingSelectionState {
  const ReadingSelectionState({
    required this.text,
    required this.cfi,
    this.surroundingText,
  });

  final String text;
  final String cfi;
  final String? surroundingText;
}

@immutable
class ReadingWorldState {
  const ReadingWorldState({
    this.bookId,
    this.bookTitle,
    this.chapterTitle,
    this.chapterHref,
    this.cfi,
    this.totalProgress = 0,
    this.chapterProgress = 0,
    this.selection,
    this.sessionId,
    this.sessionStartedAt,
    this.activeGoal,
    this.unresolvedDifficultyCount = 0,
    this.pendingProfileCount = 0,
    this.pendingCheckpointCount = 0,
    this.dueKnowledgeCardCount = 0,
    this.masterySummary = const {},
    this.markdownMemorySummary = const [],
    this.lastAgentAction,
    this.confirmedProfileSummary = const {},
  });

  final int? bookId;
  final String? bookTitle;
  final String? chapterTitle;
  final String? chapterHref;
  final String? cfi;
  final double totalProgress;
  final double chapterProgress;
  final ReadingSelectionState? selection;
  final String? sessionId;
  final DateTime? sessionStartedAt;
  final ReadingGoal? activeGoal;
  final int unresolvedDifficultyCount;
  final int pendingProfileCount;
  final int pendingCheckpointCount;
  final int dueKnowledgeCardCount;
  final Map<String, MasteryLevel> masterySummary;
  final List<String> markdownMemorySummary;
  final AgentAction? lastAgentAction;
  final Map<String, Map<String, dynamic>> confirmedProfileSummary;

  Duration get currentReadingDuration => sessionStartedAt == null
      ? Duration.zero
      : DateTime.now().difference(sessionStartedAt!);

  bool get hasCapsuleState =>
      activeGoal != null ||
      unresolvedDifficultyCount > 0 ||
      pendingProfileCount > 0 ||
      pendingCheckpointCount > 0 ||
      dueKnowledgeCardCount > 0 ||
      lastAgentAction != null;
  bool get isUsableForAgent => bookId != null && sessionId != null;

  ReadingWorldState copyWith({
    String? chapterTitle,
    String? chapterHref,
    String? cfi,
    double? totalProgress,
    double? chapterProgress,
    ReadingSelectionState? selection,
    bool clearSelection = false,
    ReadingGoal? activeGoal,
    bool clearActiveGoal = false,
    int? unresolvedDifficultyCount,
    int? pendingProfileCount,
    int? pendingCheckpointCount,
    int? dueKnowledgeCardCount,
    Map<String, MasteryLevel>? masterySummary,
    List<String>? markdownMemorySummary,
    AgentAction? lastAgentAction,
    bool clearLastAgentAction = false,
  }) =>
      ReadingWorldState(
        bookId: bookId,
        bookTitle: bookTitle,
        chapterTitle: chapterTitle ?? this.chapterTitle,
        chapterHref: chapterHref ?? this.chapterHref,
        cfi: cfi ?? this.cfi,
        totalProgress: totalProgress ?? this.totalProgress,
        chapterProgress: chapterProgress ?? this.chapterProgress,
        selection: clearSelection ? null : selection ?? this.selection,
        sessionId: sessionId,
        sessionStartedAt: sessionStartedAt,
        activeGoal: clearActiveGoal ? null : activeGoal ?? this.activeGoal,
        unresolvedDifficultyCount:
            unresolvedDifficultyCount ?? this.unresolvedDifficultyCount,
        pendingProfileCount: pendingProfileCount ?? this.pendingProfileCount,
        pendingCheckpointCount:
            pendingCheckpointCount ?? this.pendingCheckpointCount,
        dueKnowledgeCardCount:
            dueKnowledgeCardCount ?? this.dueKnowledgeCardCount,
        masterySummary: Map.unmodifiable(masterySummary ?? this.masterySummary),
        markdownMemorySummary: List.unmodifiable(
            markdownMemorySummary ?? this.markdownMemorySummary),
        lastAgentAction: clearLastAgentAction
            ? null
            : lastAgentAction ?? this.lastAgentAction,
        confirmedProfileSummary: Map.unmodifiable(confirmedProfileSummary),
      );
}

/// Local, event-driven reading state. It deliberately owns no model client.
class ReadingAgentRuntimeController extends ChangeNotifier {
  ReadingAgentRuntimeController({
    ReadingAgentRepository? repository,
    coach_dao.ReadingCoachDao? readingCoachDao,
    this.locationDebounce = const Duration(milliseconds: 750),
    this.chapterSettleDelay = const Duration(seconds: 2),
  })  : _repository = repository ?? readingAgentRepository,
        _readingCoachDao = readingCoachDao ?? coach_dao.readingCoachDao;

  final ReadingAgentRepository _repository;
  final coach_dao.ReadingCoachDao _readingCoachDao;
  final Duration locationDebounce;
  final Duration chapterSettleDelay;
  final StreamController<ReadingEvent> _events =
      StreamController<ReadingEvent>.broadcast(sync: true);
  Timer? _locationTimer;
  Timer? _chapterTimer;
  Map<String, Object?>? _pendingLocation;
  String? _lastSettledKey;
  String? _pendingChapterHref;
  ReadingChapterCheckpoint? _pendingCheckpoint;
  Future<void> _lastProgressWrite = Future<void>.value();
  ReadingWorldState _state = const ReadingWorldState();

  ReadingWorldState get state => _state;
  Stream<ReadingEvent> get events => _events.stream;
  bool get isActive => _state.sessionId != null;

  Future<void> start({required int bookId, required String bookTitle}) async {
    await finish();
    aiContextAssembler.cache.invalidateScope('reading-world:$bookId');
    final now = DateTime.now();
    final sessionId = '$bookId-${now.microsecondsSinceEpoch}';
    final results = await Future.wait<dynamic>([
      _repository.activeGoal(bookId),
      _repository.confirmedProfile(),
      _repository.profileCandidates(),
      _readingCoachDao.selectDifficulties(bookId),
      _repository.pendingCheckpoints(bookId),
      _repository.masteryStates(bookId),
      _repository.dueKnowledgeCards(bookId),
      _repository.memoryDocuments(bookId),
    ]);
    final confirmed = results[1] as List<ReaderProfileItem>;
    final candidates = results[2] as List<ReaderProfileItem>;
    final difficulties = results[3] as List<ReadingDifficulty>;
    final checkpoints = results[4] as List<ReadingChapterCheckpoint>;
    final mastery = results[5] as List<MasteryState>;
    final dueCards = results[6] as List<KnowledgeCard>;
    final memories = results[7] as List<ReadingMemoryDocument>;
    _state = ReadingWorldState(
      bookId: bookId,
      bookTitle: bookTitle,
      sessionId: sessionId,
      sessionStartedAt: now,
      activeGoal: results[0] as ReadingGoal?,
      unresolvedDifficultyCount: difficulties
          .where((item) => item.status == ReadingDifficultyStatus.unresolved)
          .length,
      pendingProfileCount: candidates
          .where((item) => item.evidenceCount >= 3 || item.confidence >= 1)
          .length,
      pendingCheckpointCount: checkpoints.length,
      dueKnowledgeCardCount: dueCards.length,
      masterySummary: {
        for (final item in mastery.take(8)) item.topic: item.level
      },
      markdownMemorySummary:
          memories.take(5).map((item) => item.title).toList(growable: false),
      confirmedProfileSummary: {
        for (final item in confirmed) item.key: item.value,
      },
    );
    _emit(ReadingEventType.sessionStarted, {'bookId': bookId});
    notifyListeners();
  }

  void observeLocation({
    required String cfi,
    required String chapterHref,
    required String chapterTitle,
    required double totalProgress,
    required double chapterProgress,
  }) {
    if (!isActive) return;
    // Raw page-turn observations remain memory-only until they settle.
    _pendingLocation = {
      'cfi': cfi,
      'chapterHref': chapterHref,
      'chapterTitle': chapterTitle,
      'totalProgress': totalProgress.clamp(0, 1).toDouble(),
      'chapterProgress': chapterProgress.clamp(0, 1).toDouble(),
    };
    _locationTimer?.cancel();
    _locationTimer = Timer(locationDebounce, _settleLocation);
  }

  void observeChapterChanged(
      {required String currentHref,
      String? completedHref,
      String? completedTitle,
      double completedProgress = 0}) {
    if (!isActive || currentHref.isEmpty) return;
    _pendingChapterHref = currentHref;
    if (completedHref?.isNotEmpty == true && completedHref != currentHref) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _pendingCheckpoint = ReadingChapterCheckpoint(
          id: '${_state.bookId}:$completedHref',
          bookId: _state.bookId!,
          chapterHref: completedHref!,
          chapterTitle: completedTitle ?? '',
          progress: completedProgress.clamp(0, 1),
          createdAt: now,
          updatedAt: now);
    }
    _chapterTimer?.cancel();
    _chapterTimer = Timer(chapterSettleDelay, () async {
      if (_pendingChapterHref != currentHref || !isActive) return;
      final checkpoint = _pendingCheckpoint;
      _pendingCheckpoint = null;
      var checkpointCount = _state.pendingCheckpointCount + 1;
      if (checkpoint != null) {
        await _repository.upsertCheckpoint(checkpoint);
        checkpointCount =
            (await _repository.pendingCheckpoints(checkpoint.bookId)).length;
      }
      _state = _state.copyWith(
        pendingCheckpointCount: checkpointCount,
      );
      _emit(ReadingEventType.chapterChanged, {'href': currentHref});
      notifyListeners();
    });
  }

  void selectionCreated(ReadingSelectionState selection) {
    if (!isActive) return;
    _state = _state.copyWith(selection: selection);
    _emit(ReadingEventType.selectionCreated, {'cfi': selection.cfi});
    notifyListeners();
  }

  void selectionCleared() {
    if (!isActive || _state.selection == null) return;
    _state = _state.copyWith(clearSelection: true);
    _emit(ReadingEventType.selectionCleared);
    notifyListeners();
  }

  void goalChanged(ReadingGoal? goal) {
    _state = _state.copyWith(
      activeGoal: goal,
      clearActiveGoal: goal == null,
    );
    _emit(ReadingEventType.goalChanged, {'goalId': goal?.id});
    notifyListeners();
  }

  void actionApplied(AgentAction action) {
    _state = _state.copyWith(lastAgentAction: action);
    _emit(ReadingEventType.agentActionApplied, {'actionId': action.id});
    notifyListeners();
  }

  void actionUndone(AgentAction action) {
    if (_state.lastAgentAction?.id == action.id) {
      _state = _state.copyWith(clearLastAgentAction: true);
    }
    _emit(ReadingEventType.agentActionUndone, {'actionId': action.id});
    notifyListeners();
  }

  void consumeCheckpoints() {
    if (_state.pendingCheckpointCount == 0) return;
    _state = _state.copyWith(pendingCheckpointCount: 0);
    notifyListeners();
  }

  void checkpointResolved() {
    if (_state.pendingCheckpointCount == 0) return;
    _state = _state.copyWith(
        pendingCheckpointCount: _state.pendingCheckpointCount - 1);
    notifyListeners();
  }

  void knowledgeCardReviewed() {
    if (_state.dueKnowledgeCardCount == 0) return;
    _state = _state.copyWith(
        dueKnowledgeCardCount: _state.dueKnowledgeCardCount - 1);
    notifyListeners();
  }

  void difficultyResolved() {
    if (_state.unresolvedDifficultyCount == 0) return;
    _state = _state.copyWith(
        unresolvedDifficultyCount: _state.unresolvedDifficultyCount - 1);
    notifyListeners();
  }

  void memoryAdded(String title) {
    if (title.trim().isEmpty) return;
    final titles = <String>{title.trim(), ..._state.markdownMemorySummary}
        .take(5)
        .toList(growable: false);
    _state = _state.copyWith(markdownMemorySummary: titles);
    notifyListeners();
  }

  void memoryRemoved(String title) {
    final titles = _state.markdownMemorySummary
        .where((value) => value != title)
        .toList(growable: false);
    _state = _state.copyWith(markdownMemorySummary: titles);
    notifyListeners();
  }

  void profileCandidateResolved() {
    if (_state.pendingProfileCount == 0) return;
    _state = _state.copyWith(
      pendingProfileCount: _state.pendingProfileCount - 1,
    );
    notifyListeners();
  }

  Future<void> finish() async {
    _locationTimer?.cancel();
    _chapterTimer?.cancel();
    _locationTimer = null;
    _chapterTimer = null;
    _pendingChapterHref = null;
    _pendingCheckpoint = null;
    if (!isActive) return;
    final bookId = _state.bookId;
    // Flush only the last observed position so goal progress survives exit;
    // intermediate page turns remain memory-only.
    _settleLocation();
    await _lastProgressWrite;
    _emit(ReadingEventType.sessionEnded, {
      'durationSeconds': _state.currentReadingDuration.inSeconds,
    });
    _pendingLocation = null;
    _state = const ReadingWorldState();
    if (bookId != null) {
      aiContextAssembler.cache.invalidateScope('reading-world:$bookId');
    }
    notifyListeners();
  }

  void _settleLocation() {
    final location = _pendingLocation;
    _pendingLocation = null;
    if (location == null || !isActive) return;
    final key = '${location['cfi']}|${location['chapterHref']}';
    if (key == _lastSettledKey) return;
    _lastSettledKey = key;
    _state = _state.copyWith(
      cfi: location['cfi'] as String,
      chapterHref: location['chapterHref'] as String,
      chapterTitle: location['chapterTitle'] as String,
      totalProgress: location['totalProgress'] as double,
      chapterProgress: location['chapterProgress'] as double,
    );
    final goal = _state.activeGoal;
    if (goal != null) {
      final chapterScoped = goal.range['chapterHref'] == _state.chapterHref;
      final observed =
          chapterScoped ? _state.chapterProgress : _state.totalProgress;
      if (observed > goal.progress) {
        final updatedGoal = goal.copyWith(
          progress: observed,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        _state = _state.copyWith(activeGoal: updatedGoal);
        _lastProgressWrite =
            _repository.updateGoalProgress(updatedGoal).catchError(
          (Object error, StackTrace stack) {
            AnxLog.warning(
              'ReadingAgent: failed to persist goal progress: $error\n$stack',
            );
          },
        );
        unawaited(_lastProgressWrite);
      }
    }
    _emit(ReadingEventType.locationSettled, location);
    notifyListeners();
  }

  void _emit(ReadingEventType type, [Map<String, Object?> data = const {}]) {
    final sessionId = _state.sessionId;
    if (sessionId == null || _events.isClosed) return;
    _events.add(ReadingEvent(
      type: type,
      sessionId: sessionId,
      occurredAt: DateTime.now(),
      data: data,
    ));
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _chapterTimer?.cancel();
    _events.close();
    super.dispose();
  }
}

typedef ReaderNavigation = void Function(String target);

/// Capability boundary between tools and the currently mounted WebView.
class ReaderCommandGateway {
  ReaderCommandGateway._();
  static final ReaderCommandGateway instance = ReaderCommandGateway._();

  int? _bookId;
  ReaderNavigation? _navigateToCfi;
  ReaderNavigation? _navigateToHref;
  bool Function(String href)? _isValidHref;
  String? Function()? _currentCfi;
  String? _returnCfi;
  void Function(BookNote note)? _addAnnotation;
  void Function(String key)? _removeAnnotation;
  void Function({required String id, required String cfi})?
      _addDifficultyAnnotation;

  void register({
    required int bookId,
    required ReaderNavigation navigateToCfi,
    required ReaderNavigation navigateToHref,
    required bool Function(String href) isValidHref,
    required String? Function() currentCfi,
    required void Function(BookNote note) addAnnotation,
    required void Function(String key) removeAnnotation,
    required void Function({required String id, required String cfi})
        addDifficultyAnnotation,
  }) {
    _bookId = bookId;
    _navigateToCfi = navigateToCfi;
    _navigateToHref = navigateToHref;
    _isValidHref = isValidHref;
    _currentCfi = currentCfi;
    _addAnnotation = addAnnotation;
    _removeAnnotation = removeAnnotation;
    _addDifficultyAnnotation = addDifficultyAnnotation;
    _returnCfi = null;
  }

  void unregister(int bookId) {
    if (_bookId != bookId) return;
    _bookId = null;
    _navigateToCfi = null;
    _navigateToHref = null;
    _isValidHref = null;
    _currentCfi = null;
    _addAnnotation = null;
    _removeAnnotation = null;
    _addDifficultyAnnotation = null;
    _returnCfi = null;
  }

  bool navigateToCfi({required int bookId, required String cfi}) {
    if (bookId != _bookId ||
        _navigateToCfi == null ||
        !cfi.startsWith('epubcfi(') ||
        !cfi.endsWith(')')) {
      return false;
    }
    _rememberReturnPosition();
    _navigateToCfi!(cfi);
    return true;
  }

  bool navigateToHref({required int bookId, required String href}) {
    if (bookId != _bookId ||
        _navigateToHref == null ||
        href.isEmpty ||
        _isValidHref?.call(href) != true) {
      return false;
    }
    _rememberReturnPosition();
    _navigateToHref!(href);
    return true;
  }

  bool returnToPreviousLocation({required int bookId}) {
    final target = _returnCfi;
    if (bookId != _bookId || target == null || _navigateToCfi == null) {
      return false;
    }
    _returnCfi = null;
    _navigateToCfi!(target);
    return true;
  }

  void _rememberReturnPosition() {
    _returnCfi ??= _currentCfi?.call();
  }

  void showAnnotation(BookNote note) => _addAnnotation?.call(note);

  void hideAnnotation(String key) => _removeAnnotation?.call(key);

  void showDifficulty({required String id, required String cfi}) =>
      _addDifficultyAnnotation?.call(id: id, cfi: cfi);
}

final readingAgentRuntime = ReadingAgentRuntimeController();
