import 'package:anx_reader/enums/ai_reasoning_effort.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_provider.freezed.dart';
part 'ai_provider.g.dart';

/// AI protocol type enumeration
enum AiProtocol {
  openai('openai'),
  claude('claude'),
  gemini('gemini');

  const AiProtocol(this.code);
  final String code;

  static AiProtocol fromCode(String code) {
    return AiProtocol.values.firstWhere(
      (e) => e.code == code,
      orElse: () => AiProtocol.openai,
    );
  }
}

@freezed
abstract class AiProvider with _$AiProvider {
  const AiProvider._();

  const factory AiProvider({
    required String id, // UUID for custom providers, fixed id for built-in ones
    required String title, // Display name
    String? logoAsset, // Asset path for built-in providers
    required String url, // API endpoint URL
    required AiProtocol protocol, // Protocol type
    @Default(true) bool enabled, // Whether this provider is enabled
    @Default(false)
    bool isBuiltin, // Whether this is a built-in provider (cannot be deleted)
    @Default([]) List<AiApiKey> apiKeys, // List of API keys
    @Default('') String model, // Current selected model
    @Default(AiReasoningEffort.auto)
    AiReasoningEffort reasoningEffort, // OpenAI reasoning effort
    @Default(0) int keyIndex, // Current round-robin key index
    DateTime? createdAt, // Creation time
    DateTime? updatedAt, // Last update time
  }) = _AiProvider;

  factory AiProvider.fromJson(Map<String, dynamic> json) {
    String requireString(String key) {
      final value = json[key];
      if (value == null) {
        throw FormatException('AiProvider.$key is required but was null');
      }
      return value.toString();
    }

    String optionalString(String key, [String fallback = '']) {
      final value = json[key];
      if (value == null) return fallback;
      return value.toString();
    }

    return AiProvider(
      id: requireString('id'),
      title: requireString('title'),
      logoAsset: json['logoAsset']?.toString(),
      url: requireString('url'),
      protocol: AiProtocol.fromCode(
        optionalString('protocol', AiProtocol.openai.code),
      ),
      enabled: json['enabled'] as bool? ?? true,
      isBuiltin: json['isBuiltin'] as bool? ?? false,
      apiKeys: (json['apiKeys'] as List<dynamic>?)
              ?.map((e) {
                if (e is! Map<String, dynamic>) {
                  throw FormatException('AiApiKey entry must be an object');
                }
                final key = e['key'];
                if (key == null) {
                  throw FormatException('AiApiKey.key is required but was null');
                }
                return AiApiKey(
                  id: (e['id'] ?? '').toString().isEmpty
                      ? DateTime.now().microsecondsSinceEpoch.toString()
                      : e['id'].toString(),
                  key: key.toString(),
                  enabled: e['enabled'] as bool? ?? true,
                  label: e['label']?.toString(),
                  createdAt: e['createdAt'] == null
                      ? null
                      : DateTime.tryParse(e['createdAt'].toString()),
                );
              })
              .toList() ??
          const [],
      model: optionalString('model'),
      reasoningEffort: AiReasoningEffort.fromCode(
        json['reasoningEffort']?.toString(),
      ),
      keyIndex: (json['keyIndex'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
    );
  }

  /// Get the current active API key (based on enabled keys and keyIndex)
  String? get currentApiKey {
    final enabledKeys = apiKeys.where((k) => k.enabled).toList();
    if (enabledKeys.isEmpty) return null;
    final index = keyIndex % enabledKeys.length;
    return enabledKeys[index].key;
  }

  /// Check if this provider has any enabled API keys
  bool get hasValidKey {
    return apiKeys.any((k) => k.enabled && k.key.isNotEmpty);
  }
}

@freezed
abstract class AiApiKey with _$AiApiKey {
  const AiApiKey._();

  const factory AiApiKey({
    required String id, // UUID
    required String key, // API key value
    @Default(true) bool enabled, // Whether this key is enabled
    String? label, // Optional label/note for this key
    DateTime? createdAt, // Creation time
  }) = _AiApiKey;

  factory AiApiKey.fromJson(Map<String, dynamic> json) =>
      _$AiApiKeyFromJson(json);
}
