import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/providers/reading_memory.dart';
import 'package:anx_reader/providers/reading_coach.dart';
import 'package:anx_reader/providers/current_reading.dart';
import 'package:anx_reader/models/current_reading_state.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_materials.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/agent_action_service.dart';
import 'package:anx_reader/service/ai/reading_memory_repository.dart';
import 'package:anx_reader/service/ai/book_wiki_service.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/service/ai/reading_outcomes_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryRepository extends ReadingMemoryRepository {
  @override
  Future<List<ReadingMemorySource>> sources(int bookId) async => [
        ReadingMemorySource(
            id: 'source',
            bookId: bookId,
            type: ReadingMemorySourceType.difficulty,
            sourceRef: 'question',
            cfi: 'epubcfi(/source)',
            text: 'Earlier note',
            contentHash: 'hash',
            createdAt: 1)
      ];
  @override
  Future<List<ReadingMemoryTopic>> topics(int bookId) async => [
        ReadingMemoryTopic(
            id: 'topic',
            bookId: bookId,
            title: 'Topic',
            summary: 'Summary',
            status: ReadingMemoryItemStatus.kept,
            batchId: 'batch',
            sourceIds: ['source'],
            createdAt: 1,
            updatedAt: 1)
      ];
  @override
  Future<List<ReadingKnowledgeCard>> cards(int bookId) async => [
        ReadingKnowledgeCard(
            id: 'card',
            bookId: bookId,
            topicId: 'topic',
            question: 'Q',
            answer: 'A',
            status: ReadingMemoryItemStatus.active,
            sourceIds: ['source'],
            nextReviewAt: 1,
            createdAt: 1,
            updatedAt: 1)
      ];
  @override
  Future<List<ReadingCardReview>> reviews(int bookId) async => [];
}

class _MaterialsService extends BookWikiService {
  @override
  Future<BookMaterialsSnapshot> loadMaterials(int bookId,
          {required double visibleAtProgress,
          ReadingClosurePolicyDefinition? closure,
          ReadingOutcomesSnapshot? outcomes,
          String? currentCfi}) async =>
      BookMaterialsSnapshot(
          bookId: bookId,
          visibleAtProgress: visibleAtProgress,
          sourceBoundaries: const {'epubcfi(/source)': .5});
}

class _Actions extends AgentActionService {
  ReadingMemoryItemStatus? savedStatus;
  @override
  Future<AgentMutation<Map<String, Object?>>> saveMemoryCard(
      ReadingKnowledgeCard card,
      {ReadingMemoryItemStatus? status}) async {
    savedStatus = status;
    return AgentMutation(
        value: card.toDb(),
        action: AgentAction(
            id: 'action',
            type: AgentActionType.memory,
            targetId: card.id,
            bookId: card.bookId,
            beforeSnapshot: const {},
            afterSnapshot: const {},
            afterHash: '',
            sessionId: 'session',
            createdAt: 1,
            expiresAt: 1000000));
  }
}

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

  test(
      'practice source visibility follows immediate reader progress and writes use actions',
      () async {
    final actions = _Actions();
    final container = ProviderContainer(overrides: [
      readingMemoryRepositoryProvider.overrideWithValue(_MemoryRepository()),
      readingPracticeMaterialsProvider.overrideWithValue(_MaterialsService()),
      readingPracticeActionsProvider.overrideWithValue(actions),
    ]);
    addTearDown(container.dispose);
    final book = Book(
        id: 1,
        title: 'Book',
        author: '',
        coverPath: '',
        filePath: '',
        lastReadPosition: '',
        readingPercentage: .6,
        isDeleted: false,
        rating: 0,
        createTime: DateTime(2026),
        updateTime: DateTime(2026));
    container.read(currentReadingProvider.notifier).start(CurrentReadingState(
        book: book, percentage: .6, cfi: 'epubcfi(/current)'));
    final subscription = container.listen(readingMemoryProvider(1), (_, __) {});
    addTearDown(subscription.close);
    final initial = await container.read(readingMemoryProvider(1).future);
    expect(initial.cards, hasLength(1));
    await container
        .read(readingMemoryProvider(1).notifier)
        .setCardStatus(initial.cards.single, ReadingMemoryItemStatus.archived);
    expect(actions.savedStatus, ReadingMemoryItemStatus.archived);
    expect(container.read(readingMemoryProvider(1).notifier).lastAction?.id,
        'action');
    await container.read(readingMemoryProvider(1).future);
    container
        .read(currentReadingProvider.notifier)
        .update(percentage: .2, cfi: 'epubcfi(/earlier)');
    expect(
        container.read(readingMemoryProvider(1)).when(
            data: (_) => 'stale content',
            error: (_, __) => 'error',
            loading: () => 'loading'),
        'loading');
    final earlier = await container.read(readingMemoryProvider(1).future);
    expect(earlier.sources, isEmpty);
    expect(earlier.topics, isEmpty);
    expect(earlier.cards, isEmpty);
  });
}
