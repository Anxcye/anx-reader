import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/agent_action_service.dart';
import 'package:anx_reader/service/ai/book_wiki_service.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:anx_reader/service/ai/reading_practice_projection.dart';
import 'package:anx_reader/providers/current_reading.dart';
import 'package:anx_reader/service/ai/reading_coach_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadingCoachState {
  const ReadingCoachState({
    required this.guide,
    this.quizzes = const [],
    this.difficulties = const [],
  });

  final InspectionReadingGuide guide;
  final List<ChapterQuiz> quizzes;
  final List<ReadingDifficulty> difficulties;

  int get unresolvedDifficultyCount => difficulties
      .where((item) => item.status == ReadingDifficultyStatus.unresolved)
      .length;
}

final readingCoachRepositoryProvider = Provider<ReadingCoachRepository>(
  (_) => ReadingCoachRepository(),
);
final readingPracticeActionsProvider =
    Provider<AgentActionService>((_) => agentActionService);
final readingPracticeMaterialsProvider =
    Provider<BookWikiService>((_) => bookWikiService);

void captureReadingPracticeLocation(Ref ref, int bookId) {
  final current = ref.read(currentReadingProvider);
  if (!current.isReading ||
      current.book?.id != bookId ||
      readingAgentRuntime.state.bookId != bookId ||
      current.cfi?.isNotEmpty != true ||
      current.percentage == null) {
    return;
  }
  readingAgentRuntime.captureRequestLocation(
      cfi: current.cfi!,
      chapterHref: current.chapterHref ?? '',
      chapterTitle: current.chapterTitle ?? '',
      totalProgress: current.percentage!,
      chapterProgress: (current.chapterTotalPages ?? 0) > 0
          ? (current.chapterCurrentPage ?? 0) / current.chapterTotalPages!
          : readingAgentRuntime.state.chapterProgress);
}

final readingCoachProvider =
    AsyncNotifierProviderFamily<ReadingCoachNotifier, ReadingCoachState, int>(
        ReadingCoachNotifier.new);

class ReadingCoachNotifier extends FamilyAsyncNotifier<ReadingCoachState, int> {
  late ReadingCoachRepository _repository;
  AgentAction? lastAction;

  @override
  Future<ReadingCoachState> build(int arg) async {
    final location = ref.watch(currentReadingProvider.select((value) => (
          bookId: value.book?.id,
          reading: value.isReading,
          cfi: value.cfi,
          progress: value.percentage
        )));
    final runtime = readingAgentRuntime.state;
    final progress = location.reading && location.bookId == arg
        ? location.progress ?? 0.0
        : runtime.bookId == arg
            ? runtime.totalProgress
            : 0.0;
    final cfi = location.reading && location.bookId == arg
        ? location.cfi
        : runtime.bookId == arg
            ? runtime.cfi
            : null;
    _repository = ref.read(readingCoachRepositoryProvider);
    final values = await Future.wait([
      _repository.loadGuide(arg),
      _repository.loadQuizzes(arg),
      _repository.loadDifficulties(arg),
    ]);
    final materials = await ref
        .read(readingPracticeMaterialsProvider)
        .loadMaterials(arg, visibleAtProgress: progress, currentCfi: cfi);
    return ReadingCoachState(
      guide: ReadingPracticeProjection.visibleGuide(
          values[0] as InspectionReadingGuide, progress),
      quizzes: (values[1] as List<ChapterQuiz>)
          .where((quiz) =>
              quiz.bookId == arg &&
              ReadingPracticeProjection.quizVisible(quiz, progress))
          .toList(),
      difficulties: (values[2] as List<ReadingDifficulty>).where((difficulty) {
        final at = materials.sourceBoundaries[difficulty.cfi];
        return difficulty.bookId == arg &&
            at != null &&
            at.isFinite &&
            at <= progress + .000001;
      }).toList(),
    );
  }

  Future<void> saveGuide(InspectionReadingGuide guide) async {
    captureReadingPracticeLocation(ref, arg);
    lastAction = (await ref
            .read(readingPracticeActionsProvider)
            .saveInspectionGuide(guide))
        .action;
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        ReadingCoachState(
          guide: ReadingPracticeProjection.visibleGuide(
              guide, readingAgentRuntime.state.totalProgress),
          quizzes: current.quizzes,
          difficulties: current.difficulties,
        ),
      );
    }
  }

  Future<void> saveQuiz(ChapterQuiz quiz) async {
    captureReadingPracticeLocation(ref, arg);
    lastAction =
        (await ref.read(readingPracticeActionsProvider).saveChapterQuiz(quiz))
            .action;
    ref.invalidateSelf();
  }

  Future<ReadingDifficulty> saveDifficulty(ReadingDifficulty difficulty) async {
    captureReadingPracticeLocation(ref, arg);
    final mutation = await ref
        .read(readingPracticeActionsProvider)
        .saveDifficulty(difficulty);
    lastAction = mutation.action;
    ref.invalidateSelf();
    return mutation.value;
  }

  Future<void> updateDifficulty(ReadingDifficulty difficulty) async {
    captureReadingPracticeLocation(ref, arg);
    lastAction = (await ref
            .read(readingPracticeActionsProvider)
            .updateDifficulty(difficulty))
        .action;
    ref.invalidateSelf();
  }
}
