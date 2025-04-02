import 'package:anx_reader/enums/ai_role.dart';
import 'package:anx_reader/models/ai_message.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_chat.g.dart';

@Riverpod(keepAlive: true)
class AiChat extends _$AiChat {
  @override
  FutureOr<List<AiMessage>> build() async {
    return List<AiMessage>.empty();
  }

  Future<void> sendMessage(String message) async {
    state = AsyncData([
      ...state.whenOrNull(data: (data) => data) ?? [],
      AiMessage(content: message, role: AiRole.user),
    ]);
  }

  Stream<List<AiMessage>> sendMessageStream(
    String message,
    WidgetRef widgetRef,
    bool isRegenerate,
  ) async* {
    List<AiMessage> messages = [
      ...state.whenOrNull(data: (data) => data) ?? [],
      AiMessage(content: message, role: AiRole.user),
    ];

    state = AsyncData(messages);

    List<AiMessage> updatedMessages = [
      ...messages,
      const AiMessage(content: "", role: AiRole.assistant),
    ];

    yield updatedMessages;

    String assistantResponse = "";
    await for (final chunk in aiGenerateStream(
      widgetRef,
      messages,
      regenerate: isRegenerate,
    )) {
      assistantResponse = chunk;

      final updatedMessagesWithResponse = List<AiMessage>.from(updatedMessages);
      updatedMessagesWithResponse[updatedMessagesWithResponse.length - 1] =
          AiMessage(content: assistantResponse, role: AiRole.assistant);

      yield updatedMessagesWithResponse;

      state = AsyncData(updatedMessagesWithResponse);
    }
  }

  void clear() {
    state = AsyncData(List<AiMessage>.empty());
  }
}
