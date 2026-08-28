import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/providers/reading_memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ReadingKnowledgeCard card(String id, int dueAt,
          {ReadingMemoryItemStatus status = ReadingMemoryItemStatus.active}) =>
      ReadingKnowledgeCard(
        id: id,
        bookId: 1,
        topicId: 'topic',
        question: id,
        answer: 'answer',
        status: status,
        nextReviewAt: dueAt,
        createdAt: 1,
        updatedAt: 1,
      );

  test('due cards include active cards only and order oldest first', () {
    final state = ReadingMemoryState(cards: [
      card('future', 400),
      card('newer-due', 200),
      card('ignored', 50, status: ReadingMemoryItemStatus.ignored),
      card('oldest-due', 100),
    ]);

    expect(state.due(300).map((item) => item.id), [
      'oldest-due',
      'newer-due',
    ]);
  });
}
