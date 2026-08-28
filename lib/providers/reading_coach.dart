import 'package:anx_reader/models/reading_coach.dart';
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

final readingCoachProvider =
    AsyncNotifierProviderFamily<ReadingCoachNotifier, ReadingCoachState, int>(
        ReadingCoachNotifier.new);

class ReadingCoachNotifier extends FamilyAsyncNotifier<ReadingCoachState, int> {
  late final ReadingCoachRepository _repository;

  @override
  Future<ReadingCoachState> build(int arg) async {
    _repository = ref.read(readingCoachRepositoryProvider);
    final values = await Future.wait([
      _repository.loadGuide(arg),
      _repository.loadQuizzes(arg),
      _repository.loadDifficulties(arg),
    ]);
    return ReadingCoachState(
      guide: values[0] as InspectionReadingGuide,
      quizzes: values[1] as List<ChapterQuiz>,
      difficulties: values[2] as List<ReadingDifficulty>,
    );
  }

  Future<void> saveGuide(InspectionReadingGuide guide) async {
    await _repository.saveGuide(guide);
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        ReadingCoachState(
          guide: guide,
          quizzes: current.quizzes,
          difficulties: current.difficulties,
        ),
      );
    }
  }

  Future<void> saveQuiz(ChapterQuiz quiz) async {
    await _repository.saveQuiz(quiz);
    ref.invalidateSelf();
  }

  Future<ReadingDifficulty> saveDifficulty(ReadingDifficulty difficulty) async {
    final saved = await _repository.saveDifficulty(difficulty);
    ref.invalidateSelf();
    return saved;
  }

  Future<void> updateDifficulty(ReadingDifficulty difficulty) async {
    await _repository.updateDifficulty(difficulty);
    ref.invalidateSelf();
  }
}
