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

enum AiProviderAuthMode {
  bearer,
  none;

  static AiProviderAuthMode fromJson(Object? value) => values.firstWhere(
        (item) => item.name == value?.toString(),
        orElse: () => AiProviderAuthMode.bearer,
      );
}

enum AiProviderDeployment {
  cloud,
  localPrivate;

  static AiProviderDeployment fromJson(Object? value) => values.firstWhere(
        (item) => item.name == value?.toString(),
        orElse: () => AiProviderDeployment.cloud,
      );
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
    @Default(AiProviderAuthMode.bearer) AiProviderAuthMode authMode,
    @Default(AiProviderDeployment.cloud) AiProviderDeployment deployment,
    @Default(AiReasoningEffort.auto)
    AiReasoningEffort reasoningEffort, // AI reasoning effort
    @Default(0) int requestTimeoutSeconds, // 0 means no app-level timeout
    @Default(0) int keyIndex, // Current round-robin key index
    DateTime? createdAt, // Creation time
    DateTime? updatedAt, // Last update time
  }) = _AiProvider;

  factory AiProvider.fromJson(Map<String, dynamic> json) =>
      _$AiProviderFromJson(json);

  /// Get the current active API key (based on enabled keys and keyIndex)
  String? get currentApiKey {
    final enabledKeys = apiKeys
        .where((key) => key.enabled && key.key.trim().isNotEmpty)
        .toList();
    if (enabledKeys.isEmpty) return null;
    final index = keyIndex % enabledKeys.length;
    return enabledKeys[index].key.trim();
  }

  /// Check if this provider has any enabled API keys
  bool get hasValidKey {
    return apiKeys.any((k) => k.enabled && k.key.trim().isNotEmpty);
  }

  /// A provider is selectable only when every field needed to make a request
  /// is present. Keep this definition shared by settings and request routing.
  bool get isRunnable {
    return enabled &&
        url.trim().isNotEmpty &&
        model.trim().isNotEmpty &&
        ((authMode == AiProviderAuthMode.none &&
                !isBuiltin &&
                protocol == AiProtocol.openai) ||
            hasValidKey);
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
