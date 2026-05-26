import 'package:anx_reader/service/ai/openai_url_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deriveOpenAiBaseUrl', () {
    test('keeps DeepSeek official base URL unchanged', () {
      expect(deriveOpenAiBaseUrl('https://api.deepseek.com'),
          'https://api.deepseek.com');
    });

    test('strips chat completions endpoint', () {
      expect(
        deriveOpenAiBaseUrl('https://api.deepseek.com/v1/chat/completions'),
        'https://api.deepseek.com/v1',
      );
    });

    test('builds models endpoint from normalized base URL', () {
      expect(
        buildOpenAiModelsUrl('https://api.deepseek.com/v1/chat/completions')
            .toString(),
        'https://api.deepseek.com/v1/models',
      );
    });
  });
}
