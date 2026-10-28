import 'package:anx_reader/service/ai/ai_services.dart';
import 'package:anx_reader/service/ai/langchain_ai_config.dart';
import 'package:anx_reader/service/ai/langchain_registry.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain_openai/langchain_openai.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('API Route resolves its endpoint through the OpenAI pipeline', () {
    final services = buildDefaultAiServices();
    final option = services.singleWhere((s) => s.identifier == 'api-route');
    expect(services.first.identifier, 'openai');
    expect(option.defaultApiKey, 'YOUR_API_KEY');
    final config = LangchainAiConfig.fromProvider(
      providerId: option.identifier,
      model: option.defaultModel,
      apiKey: 'test-key',
      url: option.defaultUrl,
    );
    expect(config.baseUrl, 'https://global.api-route.com/v1');
    expect(config.toOpenAIOptions().model, 'gpt-6.1-sol');
    final pipeline = const LangchainAiRegistry(null).resolve(config);
    expect(pipeline.model, isA<ChatOpenAI>());
    expect(pipeline.tools, isEmpty);
  });

  test('API Route logo is bundled', () async {
    final option = buildDefaultAiServices()
        .singleWhere((s) => s.identifier == 'api-route');
    expect((await rootBundle.load(option.logo)).lengthInBytes, greaterThan(0));
  });
}
