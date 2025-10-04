import 'package:anx_reader/service/ai/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:langchain_core/chat_models.dart';

part 'ai_chat.g.dart';

@Riverpod(keepAlive: true)
class AiChat extends _$AiChat {
  @override
  FutureOr<List<ChatMessage>> build() async {
    return List<ChatMessage>.empty();
  }

  Future<void> sendMessage(String message) async {
    state = AsyncData([
      ...state.whenOrNull(data: (data) => data) ?? [],
      ChatMessage.humanText(message),
    ]);
  }

  void restore(List<ChatMessage> history) {
    state = AsyncData(history);
  }

  Stream<List<ChatMessage>> sendMessageStream(
    String message,
    WidgetRef widgetRef,
    bool isRegenerate,
  ) async* {
    List<ChatMessage> messages = [
      ...state.whenOrNull(data: (data) => data) ?? [],
      ChatMessage.humanText(message),
    ];

    state = AsyncData(messages);

    List<ChatMessage> updatedMessages = [
      ...messages,
      ChatMessage.ai(''),
    ];

    yield updatedMessages;

    String assistantResponse = "";
    await for (final chunk in aiGenerateStream(
      widgetRef,
      messages,
      regenerate: isRegenerate,
    )) {
      assistantResponse = chunk;

      final updatedMessagesWithResponse =
          List<ChatMessage>.from(updatedMessages);
      updatedMessagesWithResponse[updatedMessagesWithResponse.length - 1] =
          ChatMessage.ai(assistantResponse);

      yield updatedMessagesWithResponse;

      state = AsyncData(updatedMessagesWithResponse);
    }
  }

  void clear() {
    state = AsyncData(List<ChatMessage>.empty());
  }
}
