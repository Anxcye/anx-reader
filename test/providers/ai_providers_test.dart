import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/providers/ai_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Prefs().prefs = await SharedPreferences.getInstance();
    Prefs().saveAiProviders([
      _provider('primary').toJson(),
      _provider('translation').toJson(),
      _provider('fallback').toJson(),
    ]);
    Prefs().selectedAiService = 'primary';
    container = ProviderContainer();
    container.read(aiProvidersProvider);
  });

  tearDown(() {
    container.dispose();
  });

  test('changing primary clears conflicting translation and fallback roles',
      () {
    final notifier = container.read(aiProvidersProvider.notifier);
    expect(notifier.setTranslationProvider('translation'), isTrue);
    expect(notifier.setFallbackProvider('fallback'), isTrue);

    expect(notifier.setSelectedProvider('fallback'), isTrue);

    expect(Prefs().selectedAiService, 'fallback');
    expect(Prefs().aiFallbackProvider, isNull);
    expect(Prefs().translationAiProvider, 'translation');

    expect(notifier.setSelectedProvider('translation'), isTrue);
    expect(Prefs().translationAiProvider, isNull);
  });

  test('fallback rejects primary, disabled, and unconfigured providers', () {
    final notifier = container.read(aiProvidersProvider.notifier);

    expect(notifier.setFallbackProvider('primary'), isFalse);
    notifier.toggleProvider('fallback', false);
    expect(notifier.setFallbackProvider('fallback'), isFalse);
    expect(notifier.setFallbackProvider('missing'), isFalse);
    expect(Prefs().aiFallbackProvider, isNull);
  });

  test('disabling a provider clears every role that references it', () {
    final notifier = container.read(aiProvidersProvider.notifier);
    notifier.setTranslationProvider('translation');
    notifier.setFallbackProvider('fallback');

    notifier.toggleProvider('translation', false);
    notifier.toggleProvider('fallback', false);

    expect(Prefs().translationAiProvider, isNull);
    expect(Prefs().aiFallbackProvider, isNull);
  });

  test('translation follows general provider when dedicated id is unset', () {
    final notifier = container.read(aiProvidersProvider.notifier);

    expect(notifier.setTranslationProvider('translation'), isTrue);
    expect(notifier.getRunnableTranslationProvider()?.id, 'translation');

    expect(notifier.setTranslationProvider(null), isTrue);
    expect(Prefs().translationAiProvider, isNull);
    expect(notifier.getRunnableTranslationProvider()?.id, 'primary');
  });

  test('providers without an endpoint or model cannot be assigned', () {
    final notifier = container.read(aiProvidersProvider.notifier);
    final missingUrl = _provider('missing-url', url: '  ');
    final missingModel = _provider('missing-model', model: ' ');

    notifier.addProvider(missingUrl);
    notifier.addProvider(missingModel);

    final storedMissingUrl = container.read(aiProvidersProvider).firstWhere(
          (provider) => provider.title == missingUrl.title,
        );
    final storedMissingModel = container.read(aiProvidersProvider).firstWhere(
          (provider) => provider.title == missingModel.title,
        );
    expect(notifier.isRunnableProvider(storedMissingUrl), isFalse);
    expect(notifier.isRunnableProvider(storedMissingModel), isFalse);
    expect(notifier.setTranslationProvider(storedMissingUrl.id), isFalse);
    expect(notifier.setFallbackProvider(storedMissingModel.id), isFalse);
  });

  test('custom no-auth OpenAI provider is runnable without a fake key', () {
    final provider = AiProvider(
      id: 'lm-studio',
      title: 'LM Studio',
      url: 'http://localhost:1234/v1/chat/completions',
      protocol: AiProtocol.openai,
      authMode: AiProviderAuthMode.none,
      deployment: AiProviderDeployment.localPrivate,
      model: 'qwen3.5-9b-mlx',
    );
    expect(provider.isRunnable, isTrue);

    final builtin = provider.copyWith(isBuiltin: true);
    expect(builtin.isRunnable, isFalse);
    expect(_provider('cloud').copyWith(apiKeys: const []).isRunnable, isFalse);
  });

  test('legacy provider JSON defaults to bearer cloud authentication', () {
    final provider = AiProvider.fromJson({
      'id': 'legacy',
      'title': 'Legacy',
      'url': 'https://example.com/v1',
      'protocol': 'openai',
      'enabled': true,
      'isBuiltin': false,
      'apiKeys': const [],
      'model': 'model',
    });
    expect(provider.authMode, AiProviderAuthMode.bearer);
    expect(provider.deployment, AiProviderDeployment.cloud);
    expect(provider.isRunnable, isFalse);
  });

  test('extraction role is excluded from preferences backup', () async {
    Prefs().aiExtractionConfig = {
      'enabled': true,
      'providerId': 'translation',
    };
    final backup = await Prefs().buildPrefsBackupMap();
    expect(backup, isNot(contains('aiExtractionConfig')));
  });

  test('extraction provider role is independent and device local', () {
    final notifier = container.read(aiProvidersProvider.notifier);
    expect(notifier.setExtractionProvider('translation'), isTrue);
    expect(notifier.getExtractionProvider()?.id, 'translation');
    expect(Prefs().selectedAiService, 'primary');

    notifier.toggleProvider('translation', false);
    expect(notifier.getExtractionProvider(), isNull);
    expect(Prefs().aiExtractionConfig['enabled'], isFalse);
  });

  test('first runnable custom provider becomes the general provider', () async {
    container.dispose();
    SharedPreferences.setMockInitialValues({});
    Prefs().prefs = await SharedPreferences.getInstance();
    Prefs().saveAiProviders([
      _provider('incomplete', model: '').toJson(),
    ]);
    Prefs().selectedAiService = 'missing';
    container = ProviderContainer();
    container.read(aiProvidersProvider);

    final notifier = container.read(aiProvidersProvider.notifier);
    notifier.addProvider(_provider('new-runnable'));

    final selected = notifier.getRunnableSelectedProvider();
    expect(selected?.title, 'new-runnable');
    expect(Prefs().selectedAiService, selected?.id);
  });
}

AiProvider _provider(
  String id, {
  String? url,
  String? model,
}) {
  return AiProvider(
    id: id,
    title: id,
    url: url ?? 'http://localhost:1234/v1',
    protocol: AiProtocol.openai,
    apiKeys: [AiApiKey(id: '$id-key', key: '$id-api-key')],
    model: model ?? '$id-model',
  );
}
