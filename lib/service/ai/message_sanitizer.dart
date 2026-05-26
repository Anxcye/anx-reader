import 'package:anx_reader/utils/ai_reasoning_parser.dart';
import 'package:langchain_core/chat_models.dart';

List<ChatMessage> sanitizeMessagesForPrompt(List<ChatMessage> messages) {
  return messages.map((message) {
    if (message is AIChatMessage) {
      if (message.reasoningContent.isNotEmpty) {
        return AIChatMessage(
          content: message.content,
          reasoningContent: message.reasoningContent,
          toolCalls: message.toolCalls,
        );
      }

      final plainText = reasoningContentToPlainText(message.content);
      if (plainText == message.content) {
        return message;
      }
      return AIChatMessage(
        content: plainText,
        toolCalls: message.toolCalls,
      );
    }
    return message;
  }).toList(growable: false);
}
