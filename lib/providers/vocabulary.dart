import 'package:anx_reader/dao/vocabulary.dart';
import 'package:anx_reader/models/vocabulary_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VocabularySummary {
  const VocabularySummary({
    required this.total,
    required this.due,
    required this.mastered,
  });

  final int total;
  final int due;
  final int mastered;
}

final vocabularyProvider =
    StateNotifierProvider<VocabularyNotifier, AsyncValue<List<VocabularyItem>>>(
  (ref) => VocabularyNotifier()..load(),
);

final vocabularySummaryProvider = FutureProvider.autoDispose((ref) async {
  final items = await vocabularyDao.selectAll();
  final due = await vocabularyDao.countDue();
  final mastered = await vocabularyDao.countMastered();

  return VocabularySummary(
    total: items.length,
    due: due,
    mastered: mastered,
  );
});

class VocabularyNotifier
    extends StateNotifier<AsyncValue<List<VocabularyItem>>> {
  VocabularyNotifier() : super(const AsyncLoading());

  bool _dueOnly = false;

  Future<void> load({bool? dueOnly}) async {
    if (dueOnly != null) {
      _dueOnly = dueOnly;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return _dueOnly ? vocabularyDao.selectDue() : vocabularyDao.selectAll();
    });
  }

  Future<void> markHard(VocabularyItem item) async {
    final now = DateTime.now();
    await vocabularyDao.updateItem(
      item.copyWith(
        familiarity: VocabularyFamiliarity.hard,
        wrongCount: item.wrongCount + 1,
        isMastered: false,
        lastReviewedAt: now,
        nextReviewAt: now.add(const Duration(days: 1)),
      ),
    );
    await load();
  }

  Future<void> markFamiliar(VocabularyItem item) async {
    final now = DateTime.now();
    final nextStage = (item.reviewStage + 1).clamp(1, 5);
    await vocabularyDao.updateItem(
      item.copyWith(
        familiarity: VocabularyFamiliarity.familiar,
        reviewStage: nextStage,
        correctCount: item.correctCount + 1,
        isMastered: false,
        lastReviewedAt: now,
        nextReviewAt: now.add(Duration(days: _intervalDays(nextStage))),
      ),
    );
    await load();
  }

  Future<void> markMastered(VocabularyItem item) async {
    final now = DateTime.now();
    await vocabularyDao.updateItem(
      item.copyWith(
        familiarity: VocabularyFamiliarity.mastered,
        reviewStage: 5,
        correctCount: item.correctCount + 1,
        isMastered: true,
        lastReviewedAt: now,
        nextReviewAt: now.add(const Duration(days: 365)),
      ),
    );
    await load();
  }

  Future<void> remove(VocabularyItem item) async {
    await vocabularyDao.deleteById(item.id);
    await load();
  }

  int _intervalDays(int stage) {
    const intervals = [1, 3, 7, 14, 30];
    final index = (stage - 1).clamp(0, intervals.length - 1);
    return intervals[index];
  }
}
