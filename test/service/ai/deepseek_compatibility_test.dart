import 'package:anx_reader/enums/ai_thinking_mode.dart';
import 'package:anx_reader/service/ai/deepseek_compatibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepSeek compatibility', () {
    test('detects built-in DeepSeek provider', () {
      expect(
        isDeepSeekProvider(
          identifier: 'deepseek',
          model: 'deepseek-v4-flash',
          baseUrl: 'https://api.deepseek.com',
        ),
        isTrue,
      );
    });

    test('detects DeepSeek by official API host', () {
      expect(
        isDeepSeekProvider(
          identifier: 'custom',
          model: 'custom-model',
          baseUrl: 'https://api.deepseek.com',
        ),
        isTrue,
      );
    });

    test('detects DeepSeek by v4 model prefix', () {
      expect(
        isDeepSeekProvider(
          identifier: 'custom',
          model: 'deepseek-v4-pro',
          baseUrl: 'https://example.com',
        ),
        isTrue,
      );
    });

    test('builds explicit thinking body only for enabled or disabled', () {
      expect(deepSeekThinkingExtraBody(AiThinkingMode.auto), isNull);
      expect(deepSeekThinkingExtraBody(AiThinkingMode.enabled), {
        'thinking': {'type': 'enabled'},
      });
      expect(deepSeekThinkingExtraBody(AiThinkingMode.disabled), {
        'thinking': {'type': 'disabled'},
      });
    });
  });
}
