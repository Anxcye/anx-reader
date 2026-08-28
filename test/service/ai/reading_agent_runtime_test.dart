import 'package:anx_reader/dao/reading_coach.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository extends ReadingAgentRepository {
  final List<ReadingGoal> progressWrites = [];

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
    expect(gateway.returnToPreviousLocation(bookId: 7), isTrue);
    expect(cfiTargets, ['epubcfi(/original)']);
  });
}
