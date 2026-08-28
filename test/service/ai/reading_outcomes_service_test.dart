import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/service/ai/reading_outcomes_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const day = Duration(days: 1);
  final now = DateTime(2026, 8, 19, 12);

  ReadingGoal goal(String id, ReadingGoalStatus status) => ReadingGoal(
        id: id,
        bookId: 1,
        title: id,
        status: status,
        createdAt: 1,
        updatedAt: 1,
      );

  KnowledgeCard card(String id, int dueAt, {String status = 'active'}) =>
      KnowledgeCard(
        id: id,
        bookId: 1,
        front: id,
        back: 'answer',
        dueAt: dueAt,
        status: status,
        createdAt: 1,
        updatedAt: 1,
      );

  test('snapshot exposes the active goal and actionable reading outcomes', () {
    final snapshot = ReadingOutcomesSnapshot(
      goals: [
        goal('old', ReadingGoalStatus.completed),
        goal('current', ReadingGoalStatus.active),
      ],
      difficulties: const [
        ReadingDifficulty(
          id: 'open',
          bookId: 1,
          cfi: 'epubcfi(/6/2)',
          text: 'open',
          createdAt: 1,
          updatedAt: 1,
        ),
        ReadingDifficulty(
          id: 'closed',
          bookId: 1,
          cfi: 'epubcfi(/6/4)',
          text: 'closed',
          status: ReadingDifficultyStatus.resolved,
          createdAt: 1,
          updatedAt: 1,
        ),
      ],
      knowledgeCards: [
        card('older', now.subtract(day * 2).millisecondsSinceEpoch),
        card('newer', now.subtract(day).millisecondsSinceEpoch),
        card('later', now.add(day).millisecondsSinceEpoch),
        card('archived', now.subtract(day).millisecondsSinceEpoch,
            status: 'archived'),
      ],
      loadedAt: now,
    );

    expect(snapshot.activeGoal?.id, 'current');
    expect(snapshot.unresolvedDifficulties.map((item) => item.id), ['open']);
    expect(snapshot.activeCards.map((item) => item.id),
        ['older', 'newer', 'later']);
    expect(snapshot.dueCards.map((item) => item.id), ['older', 'newer']);
    expect(snapshot.isEmpty, isFalse);
  });

  test('mastery progress averages bounded scores', () {
    final snapshot = ReadingOutcomesSnapshot(
      masteryStates: const [
        MasteryState(
          id: 'one',
          bookId: 1,
          topic: 'one',
          score: -1,
          updatedAt: 1,
        ),
        MasteryState(
          id: 'two',
          bookId: 1,
          topic: 'two',
          score: 0.5,
          updatedAt: 1,
        ),
        MasteryState(
          id: 'three',
          bookId: 1,
          topic: 'three',
          score: 2,
          updatedAt: 1,
        ),
      ],
      loadedAt: now,
    );

    expect(snapshot.masteryProgress, closeTo(0.5, 0.0001));
  });
}
