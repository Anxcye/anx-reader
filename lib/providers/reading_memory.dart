import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/providers/reading_coach.dart';
import 'package:anx_reader/providers/current_reading.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:anx_reader/service/ai/reading_memory_projection.dart';
import 'package:anx_reader/service/ai/reading_memory_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadingMemoryState {
  const ReadingMemoryState(
      {this.sources = const [],
      this.topics = const [],
      this.cards = const [],
      this.reviews = const []});
  final List<ReadingMemorySource> sources;
  final List<ReadingMemoryTopic> topics;
  final List<ReadingKnowledgeCard> cards;
  final List<ReadingCardReview> reviews;
  List<ReadingKnowledgeCard> due(int now) {
    final result = cards
        .where((c) =>
            c.status == ReadingMemoryItemStatus.active && c.nextReviewAt <= now)
        .toList();
    result.sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
    return result;
  }
}

final readingMemoryRepositoryProvider =
    Provider((_) => ReadingMemoryRepository());
final readingMemoryProvider = AsyncNotifierProviderFamily<
    ReadingMemoryController,
    ReadingMemoryState,
    int>(ReadingMemoryController.new);

class ReadingMemoryController
    extends FamilyAsyncNotifier<ReadingMemoryState, int> {
  late ReadingMemoryRepository _repository;
  AgentAction? lastAction;
  @override
  Future<ReadingMemoryState> build(int arg) async {
    final location = ref.watch(currentReadingProvider.select((value) => (
          bookId: value.book?.id,
          reading: value.isReading,
          cfi: value.cfi,
          progress: value.percentage
        )));
    _repository = ref.read(readingMemoryRepositoryProvider);
    final values = await Future.wait([
      _repository.sources(arg),
      _repository.topics(arg),
      _repository.cards(arg),
      _repository.reviews(arg)
    ]);
    final runtime = readingAgentRuntime.state;
    final materials =
        await ref.read(readingPracticeMaterialsProvider).loadMaterials(arg,
            visibleAtProgress: location.reading && location.bookId == arg
                ? location.progress ?? 0.0
                : runtime.bookId == arg
                    ? runtime.totalProgress
                    : 0.0,
            currentCfi: location.reading && location.bookId == arg
                ? location.cfi
                : runtime.bookId == arg
                    ? runtime.cfi
                    : null);
    final sources = (values[0] as List<ReadingMemorySource>)
        .where((source) =>
            ReadingMemoryProjection.sourceBoundary(source, materials) != null)
        .toList();
    final sourceIds = sources.map((source) => source.id).toSet();
    bool visible(List<String> refs) =>
        refs.isNotEmpty && refs.every(sourceIds.contains);
    final topics = (values[1] as List<ReadingMemoryTopic>)
        .where((topic) => topic.bookId == arg && visible(topic.sourceIds))
        .toList();
    final topicIds = topics.map((topic) => topic.id).toSet();
    final cards = (values[2] as List<ReadingKnowledgeCard>)
        .where((card) =>
            card.bookId == arg &&
            topicIds.contains(card.topicId) &&
            visible(card.sourceIds))
        .toList();
    final cardIds = cards.map((card) => card.id).toSet();
    return ReadingMemoryState(
        sources: sources,
        topics: topics,
        cards: cards,
        reviews: (values[3] as List<ReadingCardReview>)
            .where((review) =>
                review.bookId == arg && cardIds.contains(review.cardId))
            .toList());
  }

  Future<List<ReadingMemorySource>> collect(
      {bool includeUsed = false, bool includeAiBlocks = true}) async {
    captureReadingPracticeLocation(ref, arg);
    final sources = await _repository.collectSources(arg,
        includeUsed: includeUsed,
        includeAiBlocks: includeAiBlocks,
        persist: false);
    final actions = ref.read(readingPracticeActionsProvider);
    final safeSources = await actions.visibleMemorySources(arg, sources);
    for (final source in safeSources) {
      lastAction = (await actions.saveMemorySource(source)).action;
    }
    ref.invalidateSelf();
    return safeSources;
  }

  Future<void> saveTopics(List<ReadingMemoryTopic> items) async {
    captureReadingPracticeLocation(ref, arg);
    for (final item in items) {
      lastAction =
          (await ref.read(readingPracticeActionsProvider).saveMemoryTopic(item))
              .action;
    }
    ref.invalidateSelf();
  }

  Future<void> saveCards(List<ReadingKnowledgeCard> items) async {
    captureReadingPracticeLocation(ref, arg);
    for (final item in items) {
      lastAction =
          (await ref.read(readingPracticeActionsProvider).saveMemoryCard(item))
              .action;
    }
    ref.invalidateSelf();
  }

  Future<void> setTopicStatus(
      ReadingMemoryTopic item, ReadingMemoryItemStatus status) async {
    captureReadingPracticeLocation(ref, arg);
    lastAction = (await ref
            .read(readingPracticeActionsProvider)
            .saveMemoryTopic(item, status: status))
        .action;
    ref.invalidateSelf();
  }

  Future<void> setCardStatus(
      ReadingKnowledgeCard item, ReadingMemoryItemStatus status) async {
    captureReadingPracticeLocation(ref, arg);
    lastAction = (await ref
            .read(readingPracticeActionsProvider)
            .saveMemoryCard(item, status: status))
        .action;
    ref.invalidateSelf();
  }

  Future<void> review(
      ReadingKnowledgeCard item, ReadingReviewRating rating) async {
    captureReadingPracticeLocation(ref, arg);
    lastAction = (await ref
            .read(readingPracticeActionsProvider)
            .reviewMemoryCard(item, rating))
        .action;
    ref.invalidateSelf();
  }

  Future<void> undoLatest() async {
    captureReadingPracticeLocation(ref, arg);
    await ref
        .read(readingPracticeActionsProvider)
        .undoLatestPracticeReview(arg);
    ref.invalidateSelf();
  }

  Future<void> deleteBookMemory() async {
    captureReadingPracticeLocation(ref, arg);
    lastAction = (await ref
            .read(readingPracticeActionsProvider)
            .deletePracticeMemory(arg))
        .action;
    ref.invalidateSelf();
  }
}
