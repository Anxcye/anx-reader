import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/langchain_ai_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain_core/chat_models.dart';

void main() {
  const compactBudget = AiContextBudget(
    maxInputTokens: 90,
    reservedOutputTokens: 40,
    recentMessages: 2,
    summaryTokens: 30,
  );

  group('AiContextAssembler', () {
    test('keeps a short conversation unchanged', () {
      final assembler = AiContextAssembler();
      final source = <ChatMessage>[
        ChatMessage.system('system'),
        ChatMessage.humanText('question'),
        ChatMessage.ai('answer'),
      ];

      final result = assembler.assemble(
        source,
        task: AiContextTask.general,
      );

      expect(result.messages, source);
      expect(result.rollingSummary, isNull);
      expect(result.summarizedMessages, 0);
      expect(result.droppedMessages, 0);
    });

    test('summarizes old messages and keeps the recent window', () {
      final assembler = AiContextAssembler(
        budgets: const {AiContextTask.general: compactBudget},
      );
      final source = <ChatMessage>[
        ChatMessage.humanText('old question'),
        ChatMessage.ai('old answer'),
        ChatMessage.humanText('recent question'),
        ChatMessage.ai('recent answer'),
      ];

      final result = assembler.assemble(
        source,
        task: AiContextTask.general,
        cacheScope: 'book:1',
      );

      expect(result.summarizedMessages, 2);
      expect(result.rollingSummary, contains('old question'));
      expect(result.messages.last.contentAsString, 'recent answer');
      expect(
        result.messages.any(
          (message) => message.contentAsString.contains('rolling summary'),
        ),
        isTrue,
      );
    });

    test('never truncates the newest explicit user request', () {
      final assembler = AiContextAssembler(
        budgets: const {AiContextTask.general: compactBudget},
      );
      final latest = 'latest request ${'x' * 600}';
      final source = <ChatMessage>[
        ChatMessage.humanText('old'),
        ChatMessage.ai('answer'),
        ChatMessage.humanText(latest),
      ];

      final result = assembler.assemble(
        source,
        task: AiContextTask.general,
      );

      expect(result.messages.last.contentAsString, latest);
      expect(source.last.contentAsString, latest);
      expect(result.isOverBudget, isTrue);
      expect(result.rollingSummary, isNull);
    });

    test('does not split an assistant tool call from its tool result', () {
      final assembler = AiContextAssembler(
        budgets: const {AiContextTask.general: compactBudget},
      );
      const toolCall = AIChatMessageToolCall(
        id: 'call-1',
        name: 'lookup',
        argumentsRaw: '{}',
        arguments: {},
      );
      final result = assembler.assemble(
        <ChatMessage>[
          ChatMessage.humanText('old question'),
          ChatMessage.ai('', toolCalls: const [toolCall]),
          ChatMessage.tool(toolCallId: 'call-1', content: 'tool result'),
          ChatMessage.humanText('latest question'),
        ],
        task: AiContextTask.general,
      );

      final toolIndex = result.messages.indexWhere(
        (message) => message is ToolChatMessage,
      );
      if (toolIndex >= 0) {
        expect(toolIndex, greaterThan(0));
        expect(result.messages[toolIndex - 1], isA<AIChatMessage>());
        expect(
          (result.messages[toolIndex - 1] as AIChatMessage).toolCalls,
          isNotEmpty,
        );
      }
      expect(result.messages.last.contentAsString, 'latest question');
    });

    test('deduplicates equivalent system messages', () {
      final assembler = AiContextAssembler();
      final result = assembler.assemble(
        <ChatMessage>[
          ChatMessage.system('same  instructions'),
          ChatMessage.system('same instructions'),
          ChatMessage.humanText('question'),
        ],
        task: AiContextTask.general,
      );

      expect(result.messages.whereType<SystemChatMessage>(), hasLength(1));
    });

    test('deduplicates normalized catalog sections', () {
      final assembler = AiContextAssembler();

      expect(
        assembler.composeSections(
          const ['Skill catalog', ' skill   catalog ', '', null, 'Closure'],
        ),
        'Skill catalog\n\nClosure',
      );
    });

    test('uses task-specific input and output budgets', () {
      final assembler = AiContextAssembler();

      expect(
        assembler.budgetFor(AiContextTask.translation).maxInputTokens,
        isNot(assembler.budgetFor(AiContextTask.readingChat).maxInputTokens),
      );
    });

    test('applies the default output limit and clamps provider settings', () {
      final assembler = AiContextAssembler(
        budgets: const {AiContextTask.general: compactBudget},
      );
      final unset = _config();
      final lower = _config(maxTokens: 12, maxOutputTokens: 10);
      final higher = _config(maxTokens: 100, maxOutputTokens: 120);

      expect(
          assembler.applyOutputBudget(unset, AiContextTask.general).maxTokens,
          40);
      expect(
        assembler
            .applyOutputBudget(unset, AiContextTask.general)
            .maxOutputTokens,
        40,
      );
      expect(
          assembler.applyOutputBudget(lower, AiContextTask.general).maxTokens,
          12);
      expect(
        assembler
            .applyOutputBudget(lower, AiContextTask.general)
            .maxOutputTokens,
        10,
      );
      expect(
          assembler.applyOutputBudget(higher, AiContextTask.general).maxTokens,
          40);
      expect(
        assembler
            .applyOutputBudget(higher, AiContextTask.general)
            .maxOutputTokens,
        40,
      );
    });
  });

  group('AiContextCache', () {
    test('reuses fingerprints and invalidates only the requested scope', () {
      final cache = AiContextCache();
      var creates = 0;
      String create() => 'value-${++creates}';

      expect(
        cache.getOrCreate(scope: 'book:1', fingerprint: 'a', create: create),
        'value-1',
      );
      expect(
        cache.getOrCreate(scope: 'book:1', fingerprint: 'a', create: create),
        'value-1',
      );
      cache.getOrCreate(scope: 'book:2', fingerprint: 'a', create: create);
      cache.invalidateScope('book:1');

      expect(
        cache.getOrCreate(scope: 'book:1', fingerprint: 'a', create: create),
        'value-3',
      );
      expect(
        cache.getOrCreate(scope: 'book:2', fingerprint: 'a', create: create),
        'value-2',
      );
    });

    test('evicts the least recently used entry', () {
      final cache = AiContextCache(maxEntries: 2);
      cache.getOrCreate(scope: 's', fingerprint: 'a', create: () => 'a');
      cache.getOrCreate(scope: 's', fingerprint: 'b', create: () => 'b');
      cache.getOrCreate(scope: 's', fingerprint: 'a', create: () => 'unused');
      cache.getOrCreate(scope: 's', fingerprint: 'c', create: () => 'c');
      var recreated = false;

      cache.getOrCreate(
        scope: 's',
        fingerprint: 'b',
        create: () {
          recreated = true;
          return 'new-b';
        },
      );

      expect(recreated, isTrue);
      expect(cache.length, 2);
    });
  });
}

LangchainAiConfig _config({int? maxTokens, int? maxOutputTokens}) =>
    LangchainAiConfig(
      identifier: 'test',
      model: 'test',
      apiKey: 'test',
      maxTokens: maxTokens,
      maxOutputTokens: maxOutputTokens,
    );
