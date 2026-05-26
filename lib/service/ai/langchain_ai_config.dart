import 'package:anx_reader/enums/ai_reasoning_effort.dart';
import 'dart:convert';

import 'package:anx_reader/enums/ai_thinking_mode.dart';
import 'package:anx_reader/service/ai/deepseek_compatibility.dart';
import 'package:anx_reader/service/ai/openai_url_utils.dart';
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
    this.thinkingMode = AiThinkingMode.auto,
    this.additional,
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
  final AiThinkingMode thinkingMode;
  final Map<String, dynamic>? additional;

  ChatOpenAIOptions toOpenAIOptions() {
    final isDeepSeek = isDeepSeekProvider(
      identifier: identifier,
      model: model,
      baseUrl: baseUrl,
    );
    final extraBody = isDeepSeek
        ? deepSeekThinkingExtraBody(thinkingMode) ?? const <String, dynamic>{}
        : null;

    return ChatOpenAIOptions(
      model: model.isEmpty ? null : model,
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
      reasoningEffort: reasoningEffort.toOpenAiReasoningEffort(),
      extraBody: extraBody,
    );
  }

  ChatAnthropicOptions toAnthropicOptions() {
    return ChatAnthropicOptions(
      model: model.isEmpty ? null : model,
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
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
      baseUrl: deriveOpenAiBaseUrl(url),
      headers: headers,
      temperature: parseDouble(raw['temperature']),
      topP: parseDouble(raw['top_p']),
      maxTokens: parseInt(raw['max_tokens']),
      maxOutputTokens: parseInt(raw['max_output_tokens']),
      reasoningEffort: AiReasoningEffort.fromCode(raw['reasoning_effort']),
      thinkingMode: AiThinkingMode.fromCode(raw['thinking_mode']),
      additional: additional,
    );
  }

  /// Create LangchainAiConfig from AiProvider model with a specific API key
  factory LangchainAiConfig.fromProvider({
    required String providerId,
    required String model,
    required String apiKey,
    required String url,
    AiReasoningEffort reasoningEffort = AiReasoningEffort.auto,
    AiThinkingMode thinkingMode = AiThinkingMode.auto,
  }) {
    return LangchainAiConfig(
      identifier: providerId,
      apiKey: apiKey,
      model: model,
      baseUrl: deriveOpenAiBaseUrl(url),
      reasoningEffort: reasoningEffort,
      thinkingMode: thinkingMode,
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
    AiThinkingMode? thinkingMode,
    Map<String, dynamic>? additional,
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
      thinkingMode: thinkingMode ?? this.thinkingMode,
      additional: additional ?? this.additional,
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
    thinkingMode: override.thinkingMode != AiThinkingMode.auto
        ? override.thinkingMode
        : base.thinkingMode,
    additional: mergeMaps(base.additional, override.additional),
  );
}

extension on AiReasoningEffort {
  ChatOpenAIReasoningEffort? toOpenAiReasoningEffort() {
    return switch (this) {
      AiReasoningEffort.auto => null,
      AiReasoningEffort.low => ChatOpenAIReasoningEffort.low,
      AiReasoningEffort.medium => ChatOpenAIReasoningEffort.medium,
      AiReasoningEffort.high => ChatOpenAIReasoningEffort.high,
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
