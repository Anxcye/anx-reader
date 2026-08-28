import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/models/reading_note_ai.dart';
import 'package:anx_reader/providers/reading_note_workspace.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/reading_note/reading_note_ai_batch_repository.dart';
import 'package:anx_reader/service/reading_note/reading_note_ai_organizer_service.dart';
import 'package:anx_reader/service/reading_note/reading_note_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain_core/chat_models.dart';

class ReadingNoteAiOrganizerState {
  const ReadingNoteAiOrganizerState({
    this.batches = const [],
    this.activeBatch,
    this.suggestions = const [],
    this.remaining = const [],
    this.isGenerating = false,
  });
  final List<ReadingNoteAiBatch> batches;
  final ReadingNoteAiBatch? activeBatch;
  final List<ReadingNoteAiSuggestion> suggestions;
  final List<ReadingNoteListItem> remaining;
  final bool isGenerating;

  ReadingNoteAiOrganizerState copyWith({
    List<ReadingNoteAiBatch>? batches,
    ReadingNoteAiBatch? activeBatch,
    bool clearActive = false,
    List<ReadingNoteAiSuggestion>? suggestions,
    List<ReadingNoteListItem>? remaining,
    bool? isGenerating,
  }) =>
      ReadingNoteAiOrganizerState(
        batches: batches ?? this.batches,
        activeBatch: clearActive ? null : activeBatch ?? this.activeBatch,
        suggestions: suggestions ?? this.suggestions,
        remaining: remaining ?? this.remaining,
        isGenerating: isGenerating ?? this.isGenerating,
      );
}

final readingNoteAiBatchRepositoryProvider =
    Provider((_) => ReadingNoteAiBatchRepository());

final readingNoteAiOrganizerProvider = AsyncNotifierProviderFamily<
    ReadingNoteAiOrganizerController,
    ReadingNoteAiOrganizerState,
    int>(ReadingNoteAiOrganizerController.new);

class ReadingNoteAiOrganizerController
    extends FamilyAsyncNotifier<ReadingNoteAiOrganizerState, int> {
  late final ReadingNoteAiBatchRepository _repository;
  final _service = ReadingNoteAiOrganizerService();

  @override
  Future<ReadingNoteAiOrganizerState> build(int arg) async {
    _repository = ref.read(readingNoteAiBatchRepositoryProvider);
    final batches = await _repository.batches(arg);
    final active = batches
        .where((batch) => const {
              ReadingNoteAiBatchStatus.reviewing,
              ReadingNoteAiBatchStatus.failed,
              ReadingNoteAiBatchStatus.running,
              ReadingNoteAiBatchStatus.completed,
            }.contains(batch.status))
        .where((batch) =>
            batch.status != ReadingNoteAiBatchStatus.completed ||
            batch.remainingCount > 0)
        .firstOrNull;
    return ReadingNoteAiOrganizerState(
      batches: batches,
      activeBatch: active,
      suggestions:
          active == null ? const [] : await _repository.suggestions(active.id),
    );
  }

  Future<void> start({
    required Book book,
    required ReadingNoteAiScope scope,
    required List<ReadingNoteListItem> visibleItems,
    Set<String> selectedIdentities = const {},
  }) async {
    final notes = ref.read(readingNoteRepositoryProvider);
    final items = switch (scope) {
      ReadingNoteAiScope.inbox => await notes.list(
          ReadingNoteQuery(bookId: book.id, status: ReadingNoteStatus.inbox)),
      ReadingNoteAiScope.filtered => visibleItems,
      ReadingNoteAiScope.selected => visibleItems
          .where((item) => selectedIdentities.contains(item.identity))
          .toList(),
    };
    if (items.isEmpty) throw StateError('No notes selected');
    final prepared = await _repository.prepare(
      book: book,
      scope: scope,
      items: items,
    );
    state = AsyncData(
        (state.valueOrNull ?? const ReadingNoteAiOrganizerState()).copyWith(
      activeBatch: prepared.batch,
      suggestions: const [],
      remaining: prepared.remaining,
      isGenerating: true,
    ));
    await _generate(book, prepared.batch, prepared.inputs);
  }

  Future<void> retry(Book book) async {
    final current = state.valueOrNull;
    final batch = current?.activeBatch;
    if (batch == null) return;
    final notes = await ref.read(readingNoteRepositoryProvider).list(
          ReadingNoteQuery(bookId: book.id),
        );
    final inputs = await _repository.inputsForBatch(batch, items: notes);
    if (inputs.isEmpty) throw StateError('No source notes remain');
    state = AsyncData(current!.copyWith(isGenerating: true));
    await _generate(book, batch, inputs);
  }

  Future<void> _generate(Book book, ReadingNoteAiBatch batch,
      List<ReadingNoteAiInput> inputs) async {
    await _repository.markRunning(batch);
    final keptTopics = await ref
        .read(readingNoteAiBatchRepositoryProvider)
        .keptTopics(book.id);
    final prompt = _service.prompt(
      bookTitle: book.title,
      author: book.author,
      inputs: inputs,
      keptTopics: keptTopics
          .map((topic) => {'id': topic.id, 'title': topic.title})
          .toList(),
    );
    try {
      var generated = await aiGenerateTextWithMetadata(
        [ChatMessage.humanText(prompt)],
        task: AiContextTask.noteOrganizer,
      );
      List<ReadingNoteAiParsedSuggestion> parsed;
      try {
        parsed = _service.parse(
          generated.value,
          allowedSourceIds: inputs.map((item) => item.sourceId).toSet(),
          allowedTopicIds: keptTopics.map((topic) => topic.id).toSet(),
        );
      } on FormatException {
        generated = await aiGenerateTextWithMetadata([
          ChatMessage.humanText(
              _service.correctionPrompt(prompt, generated.value))
        ], task: AiContextTask.noteOrganizer);
        parsed = _service.parse(
          generated.value,
          allowedSourceIds: inputs.map((item) => item.sourceId).toSet(),
          allowedTopicIds: keptTopics.map((topic) => topic.id).toSet(),
        );
      }
      await _repository.saveGenerated(
        batch: batch,
        inputs: inputs,
        parsed: parsed,
        providerId: generated.providerId,
        model: generated.model,
        usedFallback: generated.usedFallback,
      );
      await _reload(batch.id);
    } catch (error) {
      await _repository.markFailed(batch, error);
      await _reload(batch.id);
    }
  }

  Future<void> toggleField(ReadingNoteAiSuggestion suggestion,
      ReadingNoteAiAdoptableField field, bool selected) async {
    final fields = {...suggestion.selectedFields};
    selected ? fields.add(field) : fields.remove(field);
    await _repository.updateSelection(suggestion, fields);
    await _reload(suggestion.batchId);
  }

  Future<void> applyOne(ReadingNoteAiSuggestion suggestion) async {
    final batch = state.valueOrNull?.activeBatch;
    await _repository.apply(
      suggestion,
      providerId: batch?.providerId,
      model: batch?.model,
      usedFallback: batch?.usedFallback ?? false,
    );
    await _reload(suggestion.batchId);
    ref.invalidate(readingNoteWorkspaceProvider);
  }

  Future<void> applyAll() async {
    final current = state.valueOrNull;
    final batch = current?.activeBatch;
    if (batch == null) return;
    for (final suggestion in current!.suggestions.where(
        (item) => item.status == ReadingNoteAiSuggestionStatus.pending)) {
      await _repository.apply(
        suggestion,
        providerId: batch.providerId,
        model: batch.model,
        usedFallback: batch.usedFallback,
      );
    }
    await _reload(batch.id);
    ref.invalidate(readingNoteWorkspaceProvider);
  }

  Future<void> undoBatch() async {
    final batch = state.valueOrNull?.activeBatch;
    if (batch == null) return;
    await _repository.undoBatch(batch.id);
    await _reload(batch.id);
    ref.invalidate(readingNoteWorkspaceProvider);
  }

  Future<void> startNext(Book book) async {
    final current = state.valueOrNull;
    final batch = current?.activeBatch;
    if (batch == null || batch.remainingCount == 0) return;
    final items = await ref
        .read(readingNoteRepositoryProvider)
        .list(ReadingNoteQuery(bookId: book.id));
    final prepared = await _repository.prepareNext(
        book: book, previous: batch, items: items);
    if (prepared == null) throw StateError('No source notes remain');
    state = AsyncData(current!.copyWith(
      activeBatch: prepared.batch,
      suggestions: const [],
      remaining: prepared.remaining,
      isGenerating: true,
    ));
    await _generate(book, prepared.batch, prepared.inputs);
  }

  Future<void> cancel() async {
    final batch = state.valueOrNull?.activeBatch;
    if (batch == null) return;
    cancelActiveAiRequest();
    await _repository.abandon(batch);
    await _reload(batch.id);
  }

  Future<void> clearCompleted() async {
    final batch = state.valueOrNull?.activeBatch;
    if (batch == null) return;
    await _repository.clear(batch);
    await _reload(batch.id);
  }

  Future<void> ignore(ReadingNoteAiSuggestion suggestion) async {
    await _repository.ignore(suggestion);
    await _reload(suggestion.batchId);
  }

  Future<void> undo(ReadingNoteAiSuggestion suggestion) async {
    await _repository.undo(suggestion);
    await _reload(suggestion.batchId);
    ref.invalidate(readingNoteWorkspaceProvider);
  }

  Future<void> abandon() async {
    final batch = state.valueOrNull?.activeBatch;
    if (batch == null) return;
    await _repository.abandon(batch);
    await _reload(batch.id);
  }

  Future<void> _reload(String batchId) async {
    final batches = await _repository.batches(arg);
    final batch = batches.where((item) => item.id == batchId).firstOrNull;
    state = AsyncData(
        (state.valueOrNull ?? const ReadingNoteAiOrganizerState()).copyWith(
      batches: batches,
      activeBatch: batch,
      suggestions:
          batch == null ? const [] : await _repository.suggestions(batch.id),
      isGenerating: batch?.status == ReadingNoteAiBatchStatus.running,
    ));
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
