import 'dart:convert';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/ai_reasoning_effort.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

AiProvider _fullProvider() => AiProvider(
      id: 'custom-1',
      title: 'My Provider',
      logoAsset: 'assets/logo.png',
      url: 'https://example.com/v1',
      protocol: AiProtocol.claude,
      enabled: false,
      isBuiltin: true,
      apiKeys: [
        AiApiKey(
          id: 'k1',
          key: 'sk-1',
          enabled: false,
          label: 'main',
          createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
        ),
        const AiApiKey(id: 'k2', key: 'sk-2'),
      ],
      model: 'claude-x',
      reasoningEffort: AiReasoningEffort.high,
      keyIndex: 3,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 2, 1, 12),
    );

void main() {
  group('AiProvider JSON', () {
    test('round-trips through toJson / fromJson', () {
      final provider = _fullProvider();
      expect(AiProvider.fromJson(provider.toJson()), provider);
    });

    test('round-trips through jsonEncode / jsonDecode', () {
      final provider = _fullProvider();
      final decoded =
          jsonDecode(jsonEncode(provider.toJson())) as Map<String, dynamic>;
      expect(AiProvider.fromJson(decoded), provider);
    });

    test('toJson uses the stored format (enum codes, ISO dates, key maps)', () {
      final json = _fullProvider().toJson();
      expect(json['protocol'], 'claude');
      expect(json['reasoningEffort'], 'high');
      expect(json['createdAt'], '2026-01-01T00:00:00.000Z');
      expect(json['apiKeys'], isA<List<dynamic>>());
      expect((json['apiKeys'] as List).first, isA<Map<String, dynamic>>());
      expect((json['apiKeys'] as List).first['key'], 'sk-1');
      expect(json.containsKey('logoAsset'), isTrue);
    });

    test('parses JSON stored by the old generated format', () {
      // Shape written by json_serializable before 950ddc27.
      const stored = '''
      {"id":"openai","title":"OpenAI","logoAsset":"assets/images/openai.png",
       "url":"https://api.openai.com/v1","protocol":"openai","enabled":true,
       "isBuiltin":true,
       "apiKeys":[{"id":"3f1c","key":"sk-old","enabled":true,"label":null,
                   "createdAt":"2025-12-01T08:30:00.000"}],
       "model":"gpt-4o-mini","reasoningEffort":"medium","keyIndex":1,
       "createdAt":"2025-12-01T08:30:00.000",
       "updatedAt":"2025-12-02T09:00:00.000"}
      ''';
      final provider =
          AiProvider.fromJson(jsonDecode(stored) as Map<String, dynamic>);
      expect(provider.id, 'openai');
      expect(provider.protocol, AiProtocol.openai);
      expect(provider.reasoningEffort, AiReasoningEffort.medium);
      expect(provider.keyIndex, 1);
      expect(provider.apiKeys.single.key, 'sk-old');
      expect(provider.apiKeys.single.label, isNull);
      expect(provider.apiKeys.single.createdAt, DateTime(2025, 12, 1, 8, 30));
      expect(provider.updatedAt, DateTime(2025, 12, 2, 9));
    });

    test('fills defaults for missing optional fields', () {
      final provider = AiProvider.fromJson({
        'id': 'x',
        'title': 'X',
        'url': 'https://x',
      });
      expect(provider.logoAsset, isNull);
      expect(provider.protocol, AiProtocol.openai);
      expect(provider.enabled, isTrue);
      expect(provider.isBuiltin, isFalse);
      expect(provider.apiKeys, isEmpty);
      expect(provider.model, '');
      expect(provider.reasoningEffort, AiReasoningEffort.auto);
      expect(provider.keyIndex, 0);
      expect(provider.createdAt, isNull);
      expect(provider.updatedAt, isNull);
    });

    test('treats explicit nulls in optional fields as defaults', () {
      final provider = AiProvider.fromJson({
        'id': 'x',
        'title': 'X',
        'url': 'https://x',
        'logoAsset': null,
        'protocol': null,
        'enabled': null,
        'isBuiltin': null,
        'apiKeys': null,
        'model': null,
        'reasoningEffort': null,
        'keyIndex': null,
        'createdAt': null,
        'updatedAt': null,
      });
      expect(provider.protocol, AiProtocol.openai);
      expect(provider.enabled, isTrue);
      expect(provider.apiKeys, isEmpty);
      expect(provider.model, '');
      expect(provider.reasoningEffort, AiReasoningEffort.auto);
      expect(provider.keyIndex, 0);
    });

    test('coerces non-string scalars to strings', () {
      final provider = AiProvider.fromJson({
        'id': 42,
        'title': true,
        'url': 1.5,
        'logoAsset': 7,
        'model': 4,
        'keyIndex': 2.0,
        'apiKeys': [
          {'id': 9, 'key': 12345, 'label': 1},
        ],
      });
      expect(provider.id, '42');
      expect(provider.title, 'true');
      expect(provider.url, '1.5');
      expect(provider.logoAsset, '7');
      expect(provider.model, '4');
      expect(provider.keyIndex, 2);
      expect(provider.apiKeys.single.id, '9');
      expect(provider.apiKeys.single.key, '12345');
      expect(provider.apiKeys.single.label, '1');
    });

    test('falls back on unknown protocol and reasoning effort', () {
      final provider = AiProvider.fromJson({
        'id': 'x',
        'title': 'X',
        'url': 'https://x',
        'protocol': 'mistral',
        'reasoningEffort': 'extreme',
      });
      expect(provider.protocol, AiProtocol.openai);
      expect(provider.reasoningEffort, AiReasoningEffort.auto);
    });

    test('ignores unparseable dates', () {
      final provider = AiProvider.fromJson({
        'id': 'x',
        'title': 'X',
        'url': 'https://x',
        'createdAt': 'not a date',
        'updatedAt': 123,
        'apiKeys': [
          {'id': 'k', 'key': 'sk', 'createdAt': 'yesterday'},
        ],
      });
      expect(provider.createdAt, isNull);
      expect(provider.updatedAt, isNull);
      expect(provider.apiKeys.single.createdAt, isNull);
    });

    test('generates an id for API keys with empty or missing id', () {
      final provider = AiProvider.fromJson({
        'id': 'x',
        'title': 'X',
        'url': 'https://x',
        'apiKeys': [
          {'id': '', 'key': 'a'},
          {'key': 'b'},
          {'id': null, 'key': 'c', 'enabled': null},
        ],
      });
      for (final key in provider.apiKeys) {
        expect(key.id, isNotEmpty);
        expect(int.tryParse(key.id), isNotNull);
        expect(key.enabled, isTrue);
      }
    });

    test('throws when a required provider field is missing or null', () {
      final base = {'id': 'x', 'title': 'X', 'url': 'https://x'};
      for (final field in ['id', 'title', 'url']) {
        final missing = Map<String, dynamic>.of(base)..remove(field);
        expect(() => AiProvider.fromJson(missing),
            throwsA(isA<BadKeyException>()),
            reason: 'missing $field');
        final nulled = Map<String, dynamic>.of(base)..[field] = null;
        expect(() => AiProvider.fromJson(nulled),
            throwsA(isA<BadKeyException>()),
            reason: 'null $field');
      }
    });

    test('throws when an API key value is missing or null', () {
      Map<String, dynamic> withKeys(List<dynamic> keys) =>
          {'id': 'x', 'title': 'X', 'url': 'https://x', 'apiKeys': keys};
      expect(
          () => AiProvider.fromJson(withKeys([
                {'id': 'k'}
              ])),
          throwsA(isA<BadKeyException>()));
      expect(
          () => AiProvider.fromJson(withKeys([
                {'id': 'k', 'key': null}
              ])),
          throwsA(isA<BadKeyException>()));
    });

    test('throws on non-object API key entries', () {
      expect(
          () => AiProvider.fromJson({
                'id': 'x',
                'title': 'X',
                'url': 'https://x',
                'apiKeys': ['sk-plain'],
              }),
          throwsA(anything));
    });
  });

  group('Prefs.saveAiProviders', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Prefs().initPrefs();
    });

    test('serializes a provider list and reads it back', () {
      final providers = [
        _fullProvider(),
        const AiProvider(
          id: 'gemini',
          title: 'Gemini',
          url: 'https://g',
          protocol: AiProtocol.gemini,
        ),
      ];
      Prefs().saveAiProviders(providers);

      final raw = Prefs().getAiProviders();
      expect(raw, hasLength(2));
      final restored = raw
          .map((json) => AiProvider.fromJson(json as Map<String, dynamic>))
          .toList();
      expect(restored, providers);
    });

    test('accepts already-serialized maps mixed with providers', () {
      final provider = _fullProvider();
      Prefs().saveAiProviders([provider.toJson(), provider]);
      final restored = Prefs()
          .getAiProviders()
          .map((json) => AiProvider.fromJson(json as Map<String, dynamic>))
          .toList();
      expect(restored, [provider, provider]);
    });
  });
}
