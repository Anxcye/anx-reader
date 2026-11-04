import 'package:anx_reader/providers/ai_chat.dart';
import 'package:anx_reader/service/ai/ai_history.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain_core/chat_models.dart';

void main() {
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
