import 'package:anx_reader/providers/ai_chat.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/current_reading_state.dart';
import 'package:anx_reader/service/ai/ai_history.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain_core/chat_models.dart';

void main() {
  late ProviderContainer contextContainer;
  late AiChat chat;
  late CurrentReadingState reading;
  const selection = ReadingContextSnapshot(
    bookId: '7',
    chapterTitle: 'Selected chapter',
    chapterHref: 'chapter-2.xhtml',
    selectedText: '  原文 e\u0301\n第二行。 ',
    surroundingText: '前文\n原文 e\u0301\n第二行。\n后文',
    progress: 0.25,
    capturedAt: 123,
    metadata: {'cfi': 'epubcfi(/6/4!/4/2:3)', 'revision': 5},
  );

  setUp(() async {
    contextContainer = ProviderContainer();
    await contextContainer.read(aiChatProvider.future);
    chat = contextContainer.read(aiChatProvider.notifier);
    reading = CurrentReadingState(
      isReading: true,
      book: Book.mock()..id = 7,
      percentage: 0.6,
      chapterTitle: 'Later chapter',
      chapterHref: 'chapter-6.xhtml',
      cfi: 'later-cfi',
    );
  });

  tearDown(() => contextContainer.dispose());

  test(
      'selection request freezes exact source and disables live-location tools',
      () {
    chat.setReadingContextOverride(selection);
    final context = chat.takeReadingContext(reading);

    expect(context.useAgent, isFalse);
    expect(context.sourceScope!.bookId, 7);
    expect(context.sourceScope!.chapterHref, 'chapter-2.xhtml');
    expect(context.sourceScope!.safeBoundary, 0.25);
    expect(context.snapshot!.toJson(), selection.toJson());
    expect(context.snapshot!.selectedText, selection.selectedText);
    expect(context.snapshot!.surroundingText, selection.surroundingText);
    expect(context.snapshot!.metadata['cfi'], selection.metadata['cfi']);

    // A later ordinary turn returns to the live reading context.
    final next = chat.takeReadingContext(reading);
    expect(next.useAgent, isTrue);
    expect(next.sourceScope!.chapterHref, 'chapter-6.xhtml');
    expect(next.sourceScope!.safeBoundary, 0.6);
    expect(next.snapshot!.selectedText, isNull);
  });

  test('backtracking cannot widen the visible reading boundary', () {
    chat.setReadingContextOverride(selection);
    final context = chat.takeReadingContext(reading.copyWith(percentage: 0.1));
    expect(context.sourceScope!.safeBoundary, 0.1);
    expect(context.snapshot!.progress, 0.25);
  });

  test('cross-book override is rejected and consumed before any model work',
      () {
    chat.setReadingContextOverride(selection);
    expect(
      () => chat.takeReadingContext(reading.copyWith(book: Book.mock())),
      throwsStateError,
    );
    expect(chat.takeReadingContext(reading).useAgent, isTrue);
  });

  test('unknown or invalid reading boundaries fail closed', () {
    for (final progress in <double?>[
      null,
      double.nan,
      double.infinity,
      -1,
      2
    ]) {
      chat.setReadingContextOverride(selection);
      expect(
        () => chat.takeReadingContext(reading.copyWith(percentage: progress)),
        throwsStateError,
      );
      chat.setReadingContextOverride(ReadingContextSnapshot(
        bookId: '7',
        selectedText: 'source',
        progress: progress,
      ));
      expect(() => chat.takeReadingContext(reading), throwsStateError);
    }
    chat.setReadingContextOverride(selection);
    expect(
      () => chat.takeReadingContext(const CurrentReadingState()),
      throwsStateError,
    );
  });

  test('closing, scope changes, and history restoration clear pending sources',
      () {
    chat.setReadingContextOverride(selection);
    chat.clear();
    expect(chat.takeReadingContext(reading).useAgent, isTrue);

    chat.setReadingContextOverride(selection);
    chat.ensureBookScope(8);
    expect(chat.takeReadingContext(reading).useAgent, isTrue);

    chat.setReadingContextOverride(selection);
    chat.restore([ChatMessage.humanText('Restored question')]);
    expect(chat.takeReadingContext(reading).useAgent, isTrue);

    chat.setReadingContextOverride(selection);
    chat.loadHistoryEntry(AiChatHistoryEntry(
      id: 'restored',
      serviceId: 'local',
      model: 'test',
      createdAt: 1,
      updatedAt: 1,
      messages: [],
      completed: true,
      bookId: 7,
    ));
    expect(chat.takeReadingContext(reading).useAgent, isTrue);
  });

  test('override copies metadata and explicit reset cancels it', () {
    final metadata = <String, dynamic>{'cfi': 'original'};
    chat.setReadingContextOverride(ReadingContextSnapshot(
      bookId: '7',
      selectedText: 'source',
      progress: 0.25,
      metadata: metadata,
    ));
    metadata['cfi'] = 'changed';
    final context = chat.takeReadingContext(reading);
    expect(context.snapshot!.metadata['cfi'], 'original');

    chat.setReadingContextOverride(selection);
    chat.setReadingContextOverride(null);
    expect(chat.takeReadingContext(reading).useAgent, isTrue);
  });

  test('reopening the same book keeps context; another book clears it',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(aiChatProvider.future);
    final chat = container.read(aiChatProvider.notifier);
    chat.ensureBookScope(7);
    chat.loadHistoryEntry(AiChatHistoryEntry(
      id: 'book-seven',
      serviceId: 'local',
      model: 'test',
      createdAt: 1,
      updatedAt: 1,
      messages: [ChatMessage.humanText('Question from book seven')],
      completed: true,
      bookId: 7,
    ));

    chat.ensureBookScope(7);
    expect(container.read(aiChatProvider).requireValue, hasLength(1));
    expect(chat.currentSessionId, 'book-seven');

    chat.ensureBookScope(8);
    expect(container.read(aiChatProvider).requireValue, isEmpty);
    expect(chat.currentSessionId, isNull);
    await chat.sendMessage('Question from book eight');
    chat.ensureBookScope(null);
    expect(container.read(aiChatProvider).requireValue, isEmpty);
  });
}
