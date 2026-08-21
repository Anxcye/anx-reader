import 'dart:convert';

import 'package:anx_reader/enums/ai_reasoning_effort.dart';
import 'package:anx_reader/enums/ai_reasoning_format.dart';
import 'package:anx_reader/service/ai/ai_reasoning_body_interceptor.dart';
import 'package:anx_reader/service/ai/langchain_ai_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:langchain_anthropic/langchain_anthropic.dart';
import 'package:langchain_openai/langchain_openai.dart';

LangchainAiConfig _config({
  AiReasoningEffort effort = AiReasoningEffort.medium,
  bool enabled = false,
  AiReasoningFormat format = AiReasoningFormat.auto,
  int? budget,
}) {
  return LangchainAiConfig(
    identifier: 'test',
    model: 'test-model',
    apiKey: 'test-key',
    reasoningEffort: effort,
    reasoningEnabled: enabled,
    reasoningFormat: format,
    reasoningBudgetTokens: budget,
  );
}

void main() {
  group('LangchainAiConfig.reasoningBodyOverrides', () {
    test('auto format sends nothing regardless of the switch', () {
      expect(
        _config(format: AiReasoningFormat.auto).reasoningBodyOverrides,
        isEmpty,
      );
      expect(
        _config(
          format: AiReasoningFormat.auto,
          enabled: true,
        ).reasoningBodyOverrides,
        isEmpty,
      );
    });

    test('openai format: disabled injects reasoning_effort none', () {
      expect(
        _config(format: AiReasoningFormat.openai).reasoningBodyOverrides,
        {'reasoning_effort': 'none'},
      );
    });

    test('openai format: enabled injects nothing (sent via options)', () {
      expect(
        _config(format: AiReasoningFormat.openai, enabled: true)
            .reasoningBodyOverrides,
        isEmpty,
      );
    });

    test('deepseek format: disabled injects thinking disabled', () {
      expect(
        _config(format: AiReasoningFormat.deepseek).reasoningBodyOverrides,
        {'thinking': {'type': 'disabled'}},
      );
    });

    test('deepseek format: enabled injects thinking enabled + effort', () {
      expect(
        _config(format: AiReasoningFormat.deepseek, enabled: true)
            .reasoningBodyOverrides,
        {
          'thinking': {'type': 'enabled'},
          'reasoning_effort': 'medium',
        },
      );
    });

    test('deepseek with legacy auto effort falls back to medium', () {
      expect(
        _config(
          format: AiReasoningFormat.deepseek,
          enabled: true,
          effort: AiReasoningEffort.auto,
        ).reasoningBodyOverrides,
        {
          'thinking': {'type': 'enabled'},
          'reasoning_effort': 'medium',
        },
      );
    });

    test('claude format injects nothing (sent via options)', () {
      expect(
        _config(format: AiReasoningFormat.claude, enabled: true)
            .reasoningBodyOverrides,
        isEmpty,
      );
    });

    test('gemini format: disabled uses budget 0', () {
      expect(
        _config(format: AiReasoningFormat.gemini).reasoningBodyOverrides,
        {
          'generationConfig': {
            'thinkingConfig': {'thinkingBudget': 0},
          },
        },
      );
    });

    test('gemini format: enabled uses default budget by effort', () {
      expect(
        _config(format: AiReasoningFormat.gemini, enabled: true)
            .reasoningBodyOverrides,
        {
          'generationConfig': {
            'thinkingConfig': {'thinkingBudget': 2048},
          },
        },
      );
      expect(
        _config(
          format: AiReasoningFormat.gemini,
          enabled: true,
          effort: AiReasoningEffort.low,
        ).reasoningBodyOverrides,
        {
          'generationConfig': {
            'thinkingConfig': {'thinkingBudget': 1024},
          },
        },
      );
      expect(
        _config(
          format: AiReasoningFormat.gemini,
          enabled: true,
          effort: AiReasoningEffort.high,
        ).reasoningBodyOverrides,
        {
          'generationConfig': {
            'thinkingConfig': {'thinkingBudget': 4096},
          },
        },
      );
    });

    test('gemini format: custom budget takes precedence', () {
      expect(
        _config(
          format: AiReasoningFormat.gemini,
          enabled: true,
          budget: 5000,
        ).reasoningBodyOverrides,
        {
          'generationConfig': {
            'thinkingConfig': {'thinkingBudget': 5000},
          },
        },
      );
    });
  });

  group('LangchainAiConfig.toOpenAIOptions', () {
    test('openai enabled sends effort through options', () {
      final options = _config(
        format: AiReasoningFormat.openai,
        enabled: true,
        effort: AiReasoningEffort.medium,
      ).toOpenAIOptions();
      expect(options.reasoningEffort, ChatOpenAIReasoningEffort.medium);
    });

    test('openai disabled sends nothing through options', () {
      final options =
          _config(format: AiReasoningFormat.openai).toOpenAIOptions();
      expect(options.reasoningEffort, isNull);
    });

    test('auto format keeps legacy non-auto effort', () {
      final options = _config(
        format: AiReasoningFormat.auto,
        effort: AiReasoningEffort.high,
      ).toOpenAIOptions();
      expect(options.reasoningEffort, ChatOpenAIReasoningEffort.high);
    });

    test('deepseek/claude/gemini formats send nothing through options', () {
      for (final format in [
        AiReasoningFormat.deepseek,
        AiReasoningFormat.claude,
        AiReasoningFormat.gemini,
      ]) {
        final options = _config(
          format: format,
          enabled: true,
        ).toOpenAIOptions();
        expect(options.reasoningEffort, isNull, reason: '$format');
      }
    });
  });

  group('LangchainAiConfig.toAnthropicOptions', () {
    test('claude disabled sends thinking disabled', () {
      final options = _config(
        format: AiReasoningFormat.claude,
      ).toAnthropicOptions();
      expect(options.thinking, isA<ChatAnthropicThinkingDisabled>());
    });

    test('claude enabled sends thinking with default budget', () {
      final options = _config(
        format: AiReasoningFormat.claude,
        enabled: true,
      ).toAnthropicOptions();
      final thinking = options.thinking;
      expect(thinking, isA<ChatAnthropicThinkingEnabled>());
      expect(
        (thinking as ChatAnthropicThinkingEnabled).budgetTokens,
        4096, // medium default
      );
    });

    test('claude enabled sends thinking with custom budget', () {
      final options = _config(
        format: AiReasoningFormat.claude,
        enabled: true,
        budget: 3000,
      ).toAnthropicOptions();
      final thinking = options.thinking;
      expect(thinking, isA<ChatAnthropicThinkingEnabled>());
      expect((thinking as ChatAnthropicThinkingEnabled).budgetTokens, 3000);
    });

    test('non-claude formats send no thinking config', () {
      for (final format in [
        AiReasoningFormat.auto,
        AiReasoningFormat.openai,
        AiReasoningFormat.deepseek,
        AiReasoningFormat.gemini,
      ]) {
        final options = _config(
          format: format,
          enabled: true,
        ).toAnthropicOptions();
        expect(options.thinking, isNull, reason: '$format');
      }
    });
  });

  group('AiReasoningBodyInterceptor', () {
    test('injects top-level fields into the JSON body', () async {
      String? capturedBody;
      final inner = MockClient((request) async {
        capturedBody = request.body;
        return http.Response('{"ok":true}', 200, headers: {
          'content-type': 'application/json',
        });
      });

      final interceptor = AiReasoningBodyInterceptor(
        inner: inner,
        overrides: () => {'thinking': {'type': 'enabled'}},
      );

      await interceptor.post(
        Uri.parse('https://api.test/v1/chat/completions'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'model': 'x', 'messages': []}),
      );

      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['thinking'], {'type': 'enabled'});
      expect(body['model'], 'x');
    });

    test('deep-merges nested maps (generationConfig)', () async {
      String? capturedBody;
      final inner = MockClient((request) async {
        capturedBody = request.body;
        return http.Response('{}', 200);
      });

      final interceptor = AiReasoningBodyInterceptor(
        inner: inner,
        overrides: () => {
          'generationConfig': {
            'thinkingConfig': {'thinkingBudget': 2048},
          },
        },
      );

      await interceptor.post(
        Uri.parse('https://api.test/v1beta/models/x:generateContent'),
        body: jsonEncode({
          'generationConfig': {'temperature': 0.7},
        }),
      );

      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      final generationConfig = body['generationConfig'] as Map<String, dynamic>;
      expect(generationConfig['temperature'], 0.7);
      expect(generationConfig['thinkingConfig'], {'thinkingBudget': 2048});
    });

    test('forwards request unchanged when overrides are empty', () async {
      String? capturedBody;
      final inner = MockClient((request) async {
        capturedBody = request.body;
        return http.Response('{}', 200);
      });

      final interceptor = AiReasoningBodyInterceptor(
        inner: inner,
        overrides: () => const {},
      );

      final original = jsonEncode({'model': 'x'});
      await interceptor.post(
        Uri.parse('https://api.test/v1/chat/completions'),
        body: original,
      );

      expect(capturedBody, original);
    });
  });
}
