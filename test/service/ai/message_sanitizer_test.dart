import 'package:anx_reader/service/ai/message_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain_core/chat_models.dart';

void main() {
  group('sanitizeMessagesForPrompt', () {
    test('preserves reasoning content for assistant messages', () {
      final messages = <ChatMessage>[
        ChatMessage.humanText('天气怎么样？'),
        AIChatMessage(
          content: '我来查一下。',
          reasoningContent: '需要调用天气工具。',
          toolCalls: [
            AIChatMessageToolCall(
              id: 'call_1',
              name: 'get_weather',
              argumentsRaw: '{"location":"Hangzhou"}',
              arguments: const {'location': 'Hangzhou'},
            ),
          ],
        ),
      ];

      final result = sanitizeMessagesForPrompt(messages);
      final assistant = result.last as AIChatMessage;

      expect(assistant.content, '我来查一下。');
      expect(assistant.reasoningContent, '需要调用天气工具。');
      expect(assistant.toolCalls, hasLength(1));
    });

    test('preserves empty assistant content with tool calls', () {
      final messages = <ChatMessage>[
        AIChatMessage(
          content: '',
          reasoningContent: '继续使用工具。',
          toolCalls: [
            AIChatMessageToolCall(
              id: 'call_2',
              name: 'book_content_search',
              argumentsRaw: '{"query":"DeepSeek"}',
              arguments: const {'query': 'DeepSeek'},
            ),
          ],
        ),
      ];

      final result = sanitizeMessagesForPrompt(messages);
      final assistant = result.single as AIChatMessage;

      expect(assistant.content, isEmpty);
      expect(assistant.reasoningContent, '继续使用工具。');
      expect(assistant.toolCalls.single.id, 'call_2');
    });

    test(
        'converts display reasoning envelope to plain text when no structured reasoning exists',
        () {
      final messages = <ChatMessage>[
        AIChatMessage(content: '<think>推理内容</think>\n最终答案'),
      ];

      final result = sanitizeMessagesForPrompt(messages);
      final assistant = result.single as AIChatMessage;

      expect(assistant.content, '最终答案');
      expect(assistant.reasoningContent, isEmpty);
    });
  });
}
