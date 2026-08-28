import 'package:anx_reader/models/reading_note_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('batch and suggestion persist scope, execution metadata and fields', () {
    final batch = ReadingNoteAiBatch(
      id: 'batch-1',
      bookId: 7,
      scope: ReadingNoteAiScope.filtered,
      sourceSnapshot: const ['n1', 'n2'],
      status: ReadingNoteAiBatchStatus.reviewing,
      providerId: 'fallback',
      model: 'model-b',
      usedFallback: true,
      totalCount: 2,
      remainingCount: 0,
      createdAt: 1,
      updatedAt: 2,
    );
    final restoredBatch = ReadingNoteAiBatch.fromDb(batch.toDb());
    expect(restoredBatch.scope, ReadingNoteAiScope.filtered);
    expect(restoredBatch.sourceSnapshot, ['n1', 'n2']);
    expect(restoredBatch.providerId, 'fallback');
    expect(restoredBatch.model, 'model-b');
    expect(restoredBatch.usedFallback, isTrue);

    final suggestion = ReadingNoteAiSuggestion(
      id: 'suggestion-1',
      batchId: batch.id,
      bookId: 7,
      sourceType: ReadingNoteAiSourceType.readingNote,
      sourceRef: 'n1',
      contentHash: 'hash',
      suggestedTitle: 'Title',
      suggestedBody: 'Body',
      suggestedTags: const ['tag'],
      existingTopicIds: const ['topic-1'],
      newTopics: const [
        {'title': 'New', 'summary': 'Summary'}
      ],
      selectedFields: const {
        ReadingNoteAiAdoptableField.title,
        ReadingNoteAiAdoptableField.aiBlock,
      },
      status: ReadingNoteAiSuggestionStatus.pending,
      createdAt: 1,
      updatedAt: 2,
    );
    final restoredSuggestion =
        ReadingNoteAiSuggestion.fromDb(suggestion.toDb());
    expect(restoredSuggestion.selectedFields, suggestion.selectedFields);
    expect(restoredSuggestion.newTopics.single['title'], 'New');
  });
}
