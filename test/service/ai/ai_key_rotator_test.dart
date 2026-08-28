import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/service/ai/ai_key_rotator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round robin ignores enabled keys that are blank', () {
    final provider = _provider(
      keyIndex: 1,
      keys: const [
        AiApiKey(id: 'blank', key: '   '),
        AiApiKey(id: 'first', key: ' first-key '),
        AiApiKey(id: 'second', key: 'second-key'),
      ],
    );

    expect(AiKeyRotator.hasValidKey(provider), isTrue);
    expect(AiKeyRotator.getNextKey(provider), 'second-key');
    expect(provider.currentApiKey, 'second-key');
  });

  test('returns null when all enabled keys are blank', () {
    final provider = _provider(
      keys: const [
        AiApiKey(id: 'blank', key: ' '),
        AiApiKey(id: 'disabled', key: 'key', enabled: false),
      ],
    );

    expect(AiKeyRotator.hasValidKey(provider), isFalse);
    expect(AiKeyRotator.getNextKey(provider), isNull);
    expect(provider.currentApiKey, isNull);
  });

  test('runnable provider also requires URL and model', () {
    final provider = _provider(
      keys: const [AiApiKey(id: 'key', key: 'valid')],
    );

    expect(provider.isRunnable, isTrue);
    expect(provider.copyWith(url: '').isRunnable, isFalse);
    expect(provider.copyWith(model: '  ').isRunnable, isFalse);
    expect(provider.copyWith(enabled: false).isRunnable, isFalse);
  });
}

AiProvider _provider({
  required List<AiApiKey> keys,
  int keyIndex = 0,
}) {
  return AiProvider(
    id: 'provider',
    title: 'Provider',
    url: 'http://localhost:1234/v1',
    protocol: AiProtocol.openai,
    apiKeys: keys,
    model: 'model',
    keyIndex: keyIndex,
  );
}
