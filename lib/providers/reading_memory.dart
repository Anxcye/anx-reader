import 'package:anx_reader/models/reading_memory.dart';
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
  late final ReadingMemoryRepository _repository;
  @override
  Future<ReadingMemoryState> build(int arg) async {
    _repository = ref.read(readingMemoryRepositoryProvider);
    final values = await Future.wait([
      _repository.sources(arg),
      _repository.topics(arg),
      _repository.cards(arg),
      _repository.reviews(arg)
    ]);
    return ReadingMemoryState(
        sources: values[0] as List<ReadingMemorySource>,
        topics: values[1] as List<ReadingMemoryTopic>,
        cards: values[2] as List<ReadingKnowledgeCard>,
        reviews: values[3] as List<ReadingCardReview>);
  }

  Future<List<ReadingMemorySource>> collect(
      {bool includeUsed = false, bool includeAiBlocks = true}) async {
    final sources = await _repository.collectSources(arg,
        includeUsed: includeUsed, includeAiBlocks: includeAiBlocks);
    ref.invalidateSelf();
    return sources;
  }

  Future<void> saveTopics(List<ReadingMemoryTopic> items) async {
    await _repository.saveTopics(items);
    ref.invalidateSelf();
  }

  Future<void> saveCards(List<ReadingKnowledgeCard> items) async {
    await _repository.saveCards(items);
    ref.invalidateSelf();
  }

  Future<void> setTopicStatus(
      ReadingMemoryTopic item, ReadingMemoryItemStatus status) async {
    await _repository.setTopicStatus(item, status);
    ref.invalidateSelf();
  }

  Future<void> setCardStatus(
      ReadingKnowledgeCard item, ReadingMemoryItemStatus status) async {
    await _repository.setCardStatus(item, status);
    ref.invalidateSelf();
  }

  Future<void> review(
      ReadingKnowledgeCard item, ReadingReviewRating rating) async {
    await _repository.review(item, rating);
    ref.invalidateSelf();
  }

  Future<void> undoLatest() async {
    await _repository.undoLatest(arg);
    ref.invalidateSelf();
  }

  Future<void> deleteBookMemory() async {
    await _repository.deleteBookMemory(arg);
    ref.invalidateSelf();
  }
}
