import 'dart:convert';

import 'package:anx_reader/enums/ai_reasoning_effort.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:langchain_anthropic/langchain_anthropic.dart';
import 'package:langchain_google/langchain_google.dart';
import 'package:langchain_openai/langchain_openai.dart';

/// Normalized configuration for LangChain-backed chat providers.
class LangchainAiConfig {
  LangchainAiConfig({
    required this.identifier,
    required this.model,
    required this.apiKey,
    this.baseUrl,
    Map<String, String>? headers,
    this.temperature,
    this.topP,
    this.maxTokens,
    this.maxOutputTokens,
    this.reasoningEffort = AiReasoningEffort.auto,
    this.requestTimeoutSeconds = 0,
    this.additional,
    this.deployment = AiProviderDeployment.cloud,
    this.jsonOutput = false,
  }) : headers = Map.unmodifiable(headers ?? const {});

  final String identifier;
  final String model;
  final String apiKey;
  final String? baseUrl;
  final Map<String, String> headers;
  final double? temperature;
  final double? topP;
  final int? maxTokens;
  final int? maxOutputTokens;
  final AiReasoningEffort reasoningEffort;
  final int requestTimeoutSeconds;
  final Map<String, dynamic>? additional;
  final AiProviderDeployment deployment;
  final bool jsonOutput;

  /// Extensions understood by OpenAI-compatible local servers (for example
  /// llama.cpp/LM Studio). They are added by the shared HTTP transport so
  /// regular cloud providers keep receiving the standard request body.
  Map<String, dynamic> get openAiRequestBodyPatch {
    final configured = additional?['chat_template_kwargs'];
    final kwargs = <String, dynamic>{
      if (configured is Map) ...Map<String, dynamic>.from(configured),
      if (deployment == AiProviderDeployment.localPrivate &&
          reasoningEffort == AiReasoningEffort.off)
        'enable_thinking': false,
    };
    return kwargs.isEmpty ? const {} : {'chat_template_kwargs': kwargs};
  }

  ChatOpenAIOptions toOpenAIOptions() {
    return ChatOpenAIOptions(
      model: model.isEmpty ? null : model,
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
      reasoningEffort: reasoningEffort.toOpenAiReasoningEffort(),
      responseFormat: jsonOutput ? ChatOpenAIResponseFormat.jsonObject : null,
    );
  }

  ChatAnthropicOptions toAnthropicOptions() {
    final thinking = reasoningEffort.toAnthropicThinking();
    final thinkingBudget = thinking is ChatAnthropicThinkingEnabled
        ? thinking.budgetTokens
        : null;
    final configuredMaxTokens = maxTokens;
    final effectiveMaxTokens = thinkingBudget == null
        ? configuredMaxTokens
        : (configuredMaxTokens == null || configuredMaxTokens <= thinkingBudget
              ? thinkingBudget + 1024
              : configuredMaxTokens);

    return ChatAnthropicOptions(
      model: model.isEmpty ? null : model,
      temperature: thinkingBudget == null ? temperature : null,
      topP: thinkingBudget == null ? topP : (topP == null ? null : 0.95),
      maxTokens: effectiveMaxTokens,
      thinking: thinking,
    );
  }

  ChatGoogleGenerativeAIOptions toGoogleOptions() {
    return ChatGoogleGenerativeAIOptions(
      model: model.isEmpty ? null : model,
      temperature: temperature,
      topP: topP,
      maxOutputTokens: maxOutputTokens,
    );
  }

  factory LangchainAiConfig.fromPrefs(
    String identifier,
    Map<String, String> raw,
  ) {
    final apiKey = raw['api_key'] ?? '';
    final model = raw['model'] ?? '';
    final url = raw['url'] ?? '';
    final headers = _parseHeaders(raw['headers']);
    final additional = _parseJson(raw['extra'] ?? raw['additional']);

    double? parseDouble(String? value) =>
        value == null ? null : double.tryParse(value.trim());
    int? parseInt(String? value) =>
        value == null ? null : int.tryParse(value.trim());

    return LangchainAiConfig(
      identifier: identifier,
      apiKey: apiKey,
      model: model,
      baseUrl: _deriveBaseUrl(url),
      headers: headers,
      temperature: parseDouble(raw['temperature']),
      topP: parseDouble(raw['top_p']),
      maxTokens: parseInt(raw['max_tokens']),
      maxOutputTokens: parseInt(raw['max_output_tokens']),
      reasoningEffort: AiReasoningEffort.fromCode(raw['reasoning_effort']),
      requestTimeoutSeconds: parseInt(raw['request_timeout_seconds']) ?? 0,
      additional: additional,
      deployment: AiProviderDeployment.fromJson(raw['deployment']),
    );
  }

  /// Create LangchainAiConfig from AiProvider model with a specific API key
  factory LangchainAiConfig.fromProvider({
    required String providerId,
    required String model,
    required String apiKey,
    required String url,
    AiReasoningEffort reasoningEffort = AiReasoningEffort.auto,
    int requestTimeoutSeconds = 0,
    AiProviderDeployment deployment = AiProviderDeployment.cloud,
  }) {
    return LangchainAiConfig(
      identifier: providerId,
      apiKey: apiKey,
      model: model,
      baseUrl: _deriveBaseUrl(url),
      reasoningEffort: reasoningEffort,
      requestTimeoutSeconds: requestTimeoutSeconds,
      deployment: deployment,
    );
  }

  LangchainAiConfig copyWith({
    String? model,
    String? apiKey,
    String? baseUrl,
    Map<String, String>? headers,
    double? temperature,
    double? topP,
    int? maxTokens,
    int? maxOutputTokens,
    AiReasoningEffort? reasoningEffort,
    int? requestTimeoutSeconds,
    Map<String, dynamic>? additional,
    AiProviderDeployment? deployment,
    bool? jsonOutput,
  }) {
    return LangchainAiConfig(
      identifier: identifier,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      headers: headers ?? this.headers,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      requestTimeoutSeconds:
          requestTimeoutSeconds ?? this.requestTimeoutSeconds,
      additional: additional ?? this.additional,
      deployment: deployment ?? this.deployment,
      jsonOutput: jsonOutput ?? this.jsonOutput,
    );
  }
}

Map<String, String> _parseHeaders(String? headersRaw) {
  if (headersRaw == null || headersRaw.trim().isEmpty) {
    return const {};
  }

  try {
    final decoded = jsonDecode(headersRaw);
    if (decoded is Map<String, dynamic>) {
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    }
  } catch (_) {
    final entries = headersRaw.split(';');
    final map = <String, String>{};
    for (final entry in entries) {
      final parts = entry.split('=');
      if (parts.length == 2) {
        map[parts[0].trim()] = parts[1].trim();
      }
    }
    if (map.isNotEmpty) {
      return map;
    }
  }

  return const {};
}

Map<String, dynamic>? _parseJson(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  try {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } catch (_) {}

  return null;
}

String? _deriveBaseUrl(String? url) {
  if (url == null || url.trim().isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return url.trim();
  }

  final removableSegments = {
    'chat',
    'messages',
    'completions',
    'responses',
    'invoke',
    'openai',
  };

  final segments = uri.pathSegments.toList(growable: true);
  while (segments.isNotEmpty &&
      removableSegments.contains(segments.last.toLowerCase())) {
    segments.removeLast();
  }

  final cleaned = uri.replace(pathSegments: segments);
  final base = cleaned.toString();
  if (base.endsWith('/')) {
    return base.substring(0, base.length - 1);
  }
  return base;
}

LangchainAiConfig mergeConfigs(
  LangchainAiConfig base,
  LangchainAiConfig override,
) {
  final mergedHeaders = <String, String>{}
    ..addAll(base.headers)
    ..addAll(override.headers);

  return base.copyWith(
    model: override.model.isNotEmpty ? override.model : base.model,
    apiKey: override.apiKey.isNotEmpty ? override.apiKey : base.apiKey,
    baseUrl: override.baseUrl ?? base.baseUrl,
    headers: mergedHeaders,
    temperature: override.temperature ?? base.temperature,
    topP: override.topP ?? base.topP,
    maxTokens: override.maxTokens ?? base.maxTokens,
    maxOutputTokens: override.maxOutputTokens ?? base.maxOutputTokens,
    reasoningEffort: override.reasoningEffort != AiReasoningEffort.auto
        ? override.reasoningEffort
        : base.reasoningEffort,
    requestTimeoutSeconds: override.requestTimeoutSeconds != 0
        ? override.requestTimeoutSeconds
        : base.requestTimeoutSeconds,
    additional: mergeMaps(base.additional, override.additional),
    deployment: override.deployment != AiProviderDeployment.cloud
        ? override.deployment
        : base.deployment,
    jsonOutput: override.jsonOutput || base.jsonOutput,
  );
}

extension on AiReasoningEffort {
  ChatOpenAIReasoningEffort? toOpenAiReasoningEffort() {
    return switch (this) {
      AiReasoningEffort.auto => null,
      AiReasoningEffort.off => null,
      AiReasoningEffort.low => ChatOpenAIReasoningEffort.low,
      AiReasoningEffort.medium => ChatOpenAIReasoningEffort.medium,
      AiReasoningEffort.high => ChatOpenAIReasoningEffort.high,
    };
  }

  ChatAnthropicThinking? toAnthropicThinking() {
    return switch (this) {
      AiReasoningEffort.auto => null,
      AiReasoningEffort.off => const ChatAnthropicThinking.disabled(),
      AiReasoningEffort.low => const ChatAnthropicThinking.enabled(
        budgetTokens: 1024,
      ),
      AiReasoningEffort.medium => const ChatAnthropicThinking.enabled(
        budgetTokens: 4096,
      ),
      AiReasoningEffort.high => const ChatAnthropicThinking.enabled(
        budgetTokens: 8192,
      ),
    };
  }
}

Map<String, dynamic>? mergeMaps(
  Map<String, dynamic>? base,
  Map<String, dynamic>? override,
) {
  if (base == null && override == null) {
    return null;
  }

  final map = <String, dynamic>{};
  if (base != null) map.addAll(base);
  if (override != null) map.addAll(override);
  return map;
}
