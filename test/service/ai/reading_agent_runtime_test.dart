import 'package:anx_reader/dao/reading_coach.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anx_reader/service/ai/agent_action_service.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository extends ReadingAgentRepository {
  final List<ReadingGoal> progressWrites = [];
  final List<ReadingNoteDocument> documents = [];

  @override
  Future<AgentMutation<ReadingNoteDocument>> createNote(
      ReadingNoteDocument document,
      {required String sessionId,
      int? ownedAnnotationId,
      BookNote? ownedAnnotation}) async {
    documents.add(document);
    return AgentMutation(
        value: document,
        action: AgentAction(
            id: 'action',
            type: AgentActionType.note,
            targetId: document.note.id,
            bookId: document.note.bookId,
            beforeSnapshot: null,
            afterSnapshot: const {},
            afterHash: '',
            sessionId: sessionId,
            createdAt: 1,
            expiresAt: 1000000));
  }

  @override
  Future<ReadingGoal?> activeGoal(int bookId) async => null;

  @override
  Future<List<ReaderProfileItem>> confirmedProfile() async => const [];

  @override
  Future<List<ReaderProfileItem>> profileCandidates() async => const [];

  @override
  Future<List<ReadingChapterCheckpoint>> pendingCheckpoints(int bookId) async =>
      const [];
  @override
  Future<List<MasteryState>> masteryStates(int bookId) async => const [];
  @override
  Future<List<KnowledgeCard>> dueKnowledgeCards(int bookId) async => const [];
  @override
  Future<List<ReadingMemoryDocument>> memoryDocuments(int bookId) async =>
      const [];
  @override
  Future<ReadingChapterCheckpoint> upsertCheckpoint(
          ReadingChapterCheckpoint checkpoint) async =>
      checkpoint;

  @override
  Future<void> updateGoalProgress(ReadingGoal goal) async {
    progressWrites.add(goal);
  }
}

class _CoachDao extends ReadingCoachDao {
  @override
  Future<List<ReadingDifficulty>> selectDifficulties(int bookId) async =>
      const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs().initPrefs();
  });
  test('debounces locations and filters duplicate settled events', () async {
    final runtime = ReadingAgentRuntimeController(
      repository: _Repository(),
      readingCoachDao: _CoachDao(),
      locationDebounce: const Duration(milliseconds: 10),
    );
    addTearDown(runtime.dispose);
    await runtime.start(bookId: 1, bookTitle: 'Book');
    final events = <ReadingEvent>[];
    final subscription = runtime.events.listen(events.add);
    addTearDown(subscription.cancel);

    runtime.observeLocation(
      cfi: 'epubcfi(/1)',
      chapterHref: 'one.xhtml',
      chapterTitle: 'One',
      totalProgress: .1,
      chapterProgress: .2,
    );
    runtime.observeLocation(
      cfi: 'epubcfi(/2)',
      chapterHref: 'one.xhtml',
      chapterTitle: 'One',
      totalProgress: .2,
      chapterProgress: .3,
    );
    await Future<void>.delayed(const Duration(milliseconds: 25));

    expect(runtime.state.cfi, 'epubcfi(/2)');
    expect(
      events.where((event) => event.type == ReadingEventType.locationSettled),
      hasLength(1),
    );

    runtime.observeLocation(
      cfi: 'epubcfi(/2)',
      chapterHref: 'one.xhtml',
      chapterTitle: 'One',
      totalProgress: .2,
      chapterProgress: .3,
    );
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(
      events.where((event) => event.type == ReadingEventType.locationSettled),
      hasLength(1),
    );
  });

  test(
      'explicit request captures location immediately and remains deduplicated',
      () async {
    final runtime = ReadingAgentRuntimeController(
      repository: _Repository(),
      readingCoachDao: _CoachDao(),
      locationDebounce: const Duration(seconds: 10),
    );
    addTearDown(runtime.dispose);
    await runtime.start(bookId: 1, bookTitle: 'Book');
    final events = <ReadingEvent>[];
    final subscription = runtime.events.listen(events.add);
    addTearDown(subscription.cancel);
    for (var i = 0; i < 2; i++) {
      runtime.captureRequestLocation(
          cfi: 'epubcfi(/request)',
          chapterHref: 'one.xhtml',
          chapterTitle: 'One',
          totalProgress: .4,
          chapterProgress: .5);
    }
    expect(runtime.state.totalProgress, .4);
    expect(runtime.state.cfi, 'epubcfi(/request)');
    expect(
        events.where((event) => event.type == ReadingEventType.locationSettled),
        hasLength(1));
    await runtime.start(bookId: 2, bookTitle: 'Another book');
    runtime.captureRequestLocation(
        cfi: 'epubcfi(/request)',
        chapterHref: 'one.xhtml',
        chapterTitle: 'One',
        totalProgress: .6,
        chapterProgress: .5);
    expect(runtime.state.bookId, 2);
    expect(runtime.state.totalProgress, .6);
  });

  test(
      'sourced notes retain evidence progress and reject another book or future sources',
      () async {
    final repository = _Repository();
    final runtime = ReadingAgentRuntimeController(
        repository: repository, readingCoachDao: _CoachDao());
    addTearDown(runtime.dispose);
    await runtime.start(bookId: 1, bookTitle: 'Book');
    runtime.captureRequestLocation(
        cfi: 'epubcfi(/current)',
        chapterHref: 'chapter.xhtml',
        chapterTitle: 'Chapter',
        totalProgress: .4,
        chapterProgress: .2);
    final actions =
        AgentActionService(repository: repository, runtime: runtime);
    await actions.createSourcedNote(
        bookId: 1,
        sourceText: 'Original evidence',
        cfi: 'epubcfi(/source)',
        chapterTitle: 'Earlier chapter',
        body: 'My explanation',
        sourceProgress: .2,
        visibleFromProgress: .3);
    expect(
        repository.documents.single.sources.single.metadata['sourceProgress'],
        .2);
    expect(
        repository
            .documents.single.sources.single.metadata['visibleFromProgress'],
        .3);
    expect(
        () => actions.createSourcedNote(
            bookId: 2,
            sourceText: 'Original evidence',
            cfi: 'epubcfi(/source)',
            chapterTitle: 'Earlier chapter',
            body: 'My explanation'),
        throwsStateError);
    expect(
        () => actions.createSourcedNote(
            bookId: 1,
            sourceText: 'Future evidence',
            cfi: 'epubcfi(/future)',
            chapterTitle: 'Later chapter',
            body: 'Future explanation',
            sourceProgress: .7),
        throwsArgumentError);
    expect(repository.documents, hasLength(1));
  });

  test('checkpoint completion rejects future and other-book sources', () async {
    final repository = _Repository();
    final runtime = ReadingAgentRuntimeController(
        repository: repository, readingCoachDao: _CoachDao());
    addTearDown(runtime.dispose);
    await runtime.start(bookId: 1, bookTitle: 'Book');
    runtime.captureRequestLocation(
        cfi: 'epubcfi(/current)',
        chapterHref: 'one.xhtml',
        chapterTitle: 'One',
        totalProgress: .4,
        chapterProgress: .2);
    final actions =
        AgentActionService(repository: repository, runtime: runtime);
    ReadingChapterCheckpoint checkpoint(int bookId, double progress) =>
        ReadingChapterCheckpoint(
            id: 'checkpoint',
            bookId: bookId,
            chapterHref: 'one.xhtml',
            chapterTitle: 'One',
            progress: progress,
            createdAt: 1,
            updatedAt: 1);
    await expectLater(
        actions.finishChapterCheckpoint(
            checkpoint: checkpoint(1, .5), reflection: 'Future'),
        throwsArgumentError);
    await expectLater(
        actions.finishChapterCheckpoint(
            checkpoint: checkpoint(2, .2), reflection: 'Other book'),
        throwsStateError);
  });

  test('practice saves require the current book before repository writes',
      () async {
    final runtime = ReadingAgentRuntimeController(
        repository: _Repository(), readingCoachDao: _CoachDao());
    addTearDown(runtime.dispose);
    final actions =
        AgentActionService(repository: _Repository(), runtime: runtime);
    await expectLater(
        actions.saveInspectionGuide(
            const InspectionReadingGuide(bookId: 1, updatedAt: 1)),
        throwsStateError);
    await runtime.start(bookId: 1, bookTitle: 'Book');
    await expectLater(
        actions.saveInspectionGuide(
            const InspectionReadingGuide(bookId: 2, updatedAt: 1)),
        throwsStateError);
    await expectLater(
        actions.saveDifficulty(
            const ReadingDifficulty(
                id: 'question',
                bookId: 1,
                cfi: 'epubcfi(/6/2)',
                text: 'Why?',
                createdAt: 1,
                updatedAt: 1),
            sourceProgress: .8),
        throwsArgumentError);
  });

  test('chapter checkpoint appears only after the stable delay', () async {
    final runtime = ReadingAgentRuntimeController(
      repository: _Repository(),
      readingCoachDao: _CoachDao(),
      chapterSettleDelay: const Duration(milliseconds: 15),
    );
    addTearDown(runtime.dispose);
    await runtime.start(bookId: 1, bookTitle: 'Book');

    runtime.observeChapterChanged(currentHref: 'one.xhtml');
    runtime.observeChapterChanged(currentHref: 'two.xhtml');
    expect(runtime.state.pendingCheckpointCount, 0);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(runtime.state.pendingCheckpointCount, 1);
  });

  test('command gateway scopes navigation to mounted book and supports return',
      () {
    final cfiTargets = <String>[];
    final hrefTargets = <String>[];
    final gateway = ReaderCommandGateway.instance;
    gateway.register(
      bookId: 7,
      navigateToCfi: cfiTargets.add,
      navigateToHref: hrefTargets.add,
      isValidHref: (href) => href == 'chapter.xhtml',
      currentCfi: () => 'epubcfi(/original)',
      addAnnotation: (_) {},
      removeAnnotation: (_) {},
      addDifficultyAnnotation: ({required id, required cfi}) {},
    );
    addTearDown(() => gateway.unregister(7));

    expect(
      gateway.navigateToCfi(bookId: 8, cfi: 'epubcfi(/other)'),
      isFalse,
    );
    expect(
      gateway.navigateToHref(bookId: 7, href: 'outside.xhtml'),
      isFalse,
    );
    expect(
      gateway.navigateToHref(bookId: 7, href: 'chapter.xhtml'),
      isTrue,
    );
    expect(hrefTargets, ['chapter.xhtml']);
    expect(gateway.canReturnToPreviousLocation(bookId: 7), isTrue);
    expect(gateway.canReturnToPreviousLocation(bookId: 8), isFalse);
    expect(gateway.navigateToCfi(bookId: 7, cfi: 'epubcfi(/second-source)'),
        isTrue);
    expect(gateway.returnToPreviousLocation(bookId: 7), isTrue);
    expect(cfiTargets, ['epubcfi(/second-source)', 'epubcfi(/original)']);
    expect(gateway.canReturnToPreviousLocation(bookId: 7), isFalse);
  });
}
