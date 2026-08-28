import 'package:anx_reader/service/ai/langchain_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain/langchain.dart';

void main() {
  test('runner estimates input and output when provider omits usage', () async {
    int? receivedInput;
    int? receivedOutput;
    bool? receivedEstimated;
    final runner = CancelableLangchainRunner(
      onTokenUsage: ({
        required inputTokens,
        required outputTokens,
        required estimated,
      }) {
        receivedInput = inputTokens;
        receivedOutput = outputTokens;
        receivedEstimated = estimated;
      },
    );

    final chunks = await runner
        .stream(
          model: FakeChatModel(responses: const ['回答']),
          prompt: PromptValue.chat([ChatMessage.humanText('问题')]),
        )
        .toList();

    expect(chunks.last, '回答');
    expect(receivedInput, 2);
    expect(receivedOutput, 2);
    expect(receivedEstimated, isTrue);
  });

  test('runner estimates input when provider reports output only', () async {
    int? receivedInput;
    int? receivedOutput;
    bool? receivedEstimated;
    final runner = CancelableLangchainRunner(
      onTokenUsage: ({
        required inputTokens,
        required outputTokens,
        required estimated,
      }) {
        receivedInput = inputTokens;
        receivedOutput = outputTokens;
        receivedEstimated = estimated;
      },
    );

    await runner
        .stream(
          model: _OutputOnlyUsageChatModel(),
          prompt: PromptValue.chat([ChatMessage.humanText('输入内容')]),
        )
        .drain<void>();

    expect(receivedInput, 4);
    expect(receivedOutput, 7);
    expect(receivedEstimated, isTrue);
  });
}

class _OutputOnlyUsageChatModel extends FakeChatModel {
  _OutputOnlyUsageChatModel() : super(responses: const ['回答']);

  @override
  Stream<ChatResult> stream(
    PromptValue input, {
    FakeChatModelOptions? options,
  }) {
    return Stream.value(
      ChatResult(
        id: 'output-only',
        output: AIChatMessage(content: '回答'),
        finishReason: FinishReason.stop,
        metadata: const {},
        usage: const LanguageModelUsage(
          promptTokens: 0,
          responseTokens: 7,
          totalTokens: 7,
        ),
        streaming: true,
      ),
    );
  }
}
