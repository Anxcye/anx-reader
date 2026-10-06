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

  @JsonSerializable(explicitToJson: true)
  const factory AiProvider({
    // UUID for custom providers, fixed id for built-in ones
    @JsonKey(required: true, disallowNullValue: true, fromJson: _requiredString)
    required String id,
    // Display name
    @JsonKey(required: true, disallowNullValue: true, fromJson: _requiredString)
    required String title,
    // Asset path for built-in providers
    @JsonKey(fromJson: _nullableString) String? logoAsset,
    // API endpoint URL
    @JsonKey(required: true, disallowNullValue: true, fromJson: _requiredString)
    required String url,
    // Protocol type
    @_AiProtocolConverter() required AiProtocol protocol,
    // Whether this provider is enabled
    @Default(true) bool enabled,
    // Whether this is a built-in provider (cannot be deleted)
    @Default(false) bool isBuiltin,
    // List of API keys
    @Default([]) List<AiApiKey> apiKeys,
    // Current selected model
    @JsonKey(fromJson: _stringOrEmpty) @Default('') String model,
    // OpenAI reasoning effort
    @_AiReasoningEffortConverter()
    @Default(AiReasoningEffort.auto)
    AiReasoningEffort reasoningEffort,
    // Current round-robin key index
    @Default(0) int keyIndex,
    // Creation time
    @_LenientDateTimeConverter() DateTime? createdAt,
    // Last update time
    @_LenientDateTimeConverter() DateTime? updatedAt,
  }) = _AiProvider;

  factory AiProvider.fromJson(Map<String, dynamic> json) =>
      _$AiProviderFromJson(json);

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
    // UUID; generated from the current time when missing or empty
    @JsonKey(fromJson: _apiKeyId) required String id,
    // API key value
    @JsonKey(required: true, disallowNullValue: true, fromJson: _requiredString)
    required String key,
    // Whether this key is enabled
    @Default(true) bool enabled,
    // Optional label/note for this key
    @JsonKey(fromJson: _nullableString) String? label,
    // Creation time
    @_LenientDateTimeConverter() DateTime? createdAt,
  }) = _AiApiKey;

  factory AiApiKey.fromJson(Map<String, dynamic> json) =>
      _$AiApiKeyFromJson(json);
}

// Lenient JSON helpers: stored configs may come from older versions or be
// hand-edited, so coerce scalars to strings instead of failing on type casts.
// Required keys are enforced by `required`/`disallowNullValue` above, which
// throw a BadKeyException that AiProviders.build() catches to reinitialize.

String _requiredString(Object? value) {
  if (value == null) {
    throw const FormatException('Required string value was null');
  }
  return value.toString();
}

String? _nullableString(Object? value) => value?.toString();

String _stringOrEmpty(Object? value) => value?.toString() ?? '';

String _apiKeyId(Object? value) {
  final id = value?.toString() ?? '';
  return id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id;
}

class _AiProtocolConverter implements JsonConverter<AiProtocol, Object?> {
  const _AiProtocolConverter();

  @override
  AiProtocol fromJson(Object? json) =>
      AiProtocol.fromCode(json?.toString() ?? AiProtocol.openai.code);

  @override
  Object? toJson(AiProtocol object) => object.code;
}

class _AiReasoningEffortConverter
    implements JsonConverter<AiReasoningEffort, Object?> {
  const _AiReasoningEffortConverter();

  @override
  AiReasoningEffort fromJson(Object? json) =>
      AiReasoningEffort.fromCode(json?.toString());

  @override
  Object? toJson(AiReasoningEffort object) => object.code;
}

class _LenientDateTimeConverter implements JsonConverter<DateTime?, Object?> {
  const _LenientDateTimeConverter();

  @override
  DateTime? fromJson(Object? json) =>
      json == null ? null : DateTime.tryParse(json.toString());

  @override
  Object? toJson(DateTime? object) => object?.toIso8601String();
}
