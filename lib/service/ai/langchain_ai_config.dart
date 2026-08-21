import 'package:anx_reader/enums/ai_reasoning_effort.dart';
import 'package:anx_reader/enums/ai_reasoning_format.dart';
import 'dart:convert';

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
    this.reasoningEnabled = false,
    this.reasoningFormat = AiReasoningFormat.auto,
    this.reasoningBudgetTokens,
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
  final bool reasoningEnabled;
  final AiReasoningFormat reasoningFormat;
  final int? reasoningBudgetTokens;
  final Map<String, dynamic>? additional;

  ChatOpenAIOptions toOpenAIOptions() {
    return ChatOpenAIOptions(
      model: model.isEmpty ? null : model,
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
      reasoningEffort: _openAiReasoningEffort(),
    );
  }

  /// OpenAI `reasoning_effort` sent through options.
  ///
  /// - `openai` format: send the effort when reasoning is enabled; the
  ///   explicit "off" (`none`) is injected by the body interceptor instead.
  /// - `auto` format: legacy behavior — a non-auto effort is sent as-is.
  /// - Other formats: reasoning is expressed through other parameters
  ///   (`thinking` / `thinkingConfig`), so nothing is sent here.
  ChatOpenAIReasoningEffort? _openAiReasoningEffort() {
    switch (reasoningFormat) {
      case AiReasoningFormat.openai:
        if (!reasoningEnabled) return null;
        return _effectiveReasoningEffort().toOpenAiReasoningEffort();
      case AiReasoningFormat.auto:
        return reasoningEffort.toOpenAiReasoningEffort();
      case AiReasoningFormat.deepseek:
      case AiReasoningFormat.claude:
      case AiReasoningFormat.gemini:
        return null;
    }
  }

  /// Compute the extra body fields to inject for reasoning control.
  ///
  /// Returns an empty map when nothing needs to be injected. The `auto`
  /// format sends nothing; OpenAI's `low`/`medium`/`high` are sent through
  /// [toOpenAIOptions]; Claude's thinking through [toAnthropicOptions]. The
  /// fields produced here cover what those options cannot express: OpenAI's
  /// explicit `none`, DeepSeek's `thinking.type`, and Gemini's
  /// `generationConfig.thinkingConfig`.
  Map<String, dynamic> get reasoningBodyOverrides {
    switch (reasoningFormat) {
      case AiReasoningFormat.auto:
        return const {};
      case AiReasoningFormat.openai:
        // Explicitly disable reasoning by sending `reasoning_effort: none`.
        if (!reasoningEnabled) return {'reasoning_effort': 'none'};
        return const {};
      case AiReasoningFormat.deepseek:
        return {
          'thinking': {'type': reasoningEnabled ? 'enabled' : 'disabled'},
          if (reasoningEnabled) 'reasoning_effort': _effectiveReasoningEffort().code,
        };
      case AiReasoningFormat.claude:
        // Handled via ChatAnthropicThinking in toAnthropicOptions().
        return const {};
      case AiReasoningFormat.gemini:
        return {
          'generationConfig': {
            'thinkingConfig': {
              'thinkingBudget': reasoningEnabled
                  ? (reasoningBudgetTokens ?? _defaultGeminiBudget())
                  : 0,
            },
          },
        };
    }
  }

  /// Reasoning effort used when the user enabled reasoning but kept the
  /// legacy `auto` value (auto maps to medium).
  AiReasoningEffort _effectiveReasoningEffort() {
    if (reasoningEffort == AiReasoningEffort.auto) {
      return AiReasoningEffort.medium;
    }
    return reasoningEffort;
  }

  /// Default Gemini thinking budget by effort (when no custom budget set).
  int _defaultGeminiBudget() {
    return switch (_effectiveReasoningEffort()) {
      AiReasoningEffort.low => 1024,
      AiReasoningEffort.medium => 2048,
      AiReasoningEffort.high => 4096,
      AiReasoningEffort.auto => 2048,
    };
  }

  /// Default Claude thinking budget by effort (when no custom budget set).
  int _defaultClaudeBudget() {
    return switch (_effectiveReasoningEffort()) {
      AiReasoningEffort.low => 2048,
      AiReasoningEffort.medium => 4096,
      AiReasoningEffort.high => 8192,
      AiReasoningEffort.auto => 4096,
    };
  }

  ChatAnthropicOptions toAnthropicOptions() {
    return ChatAnthropicOptions(
      model: model.isEmpty ? null : model,
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
      thinking: _anthropicThinking(),
    );
  }

  /// Claude extended thinking configuration.
  ///
  /// Only applied when the reasoning format is `claude`. When reasoning is
  /// disabled, `thinking.type: "disabled"` is sent explicitly; otherwise a
  /// budget (custom or derived from the effort) is used.
  ChatAnthropicThinking? _anthropicThinking() {
    if (reasoningFormat != AiReasoningFormat.claude) return null;
    if (!reasoningEnabled) return ChatAnthropicThinking.disabled();
    return ChatAnthropicThinking.enabled(
      budgetTokens: reasoningBudgetTokens ?? _defaultClaudeBudget(),
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
    bool reasoningEnabled = false,
    AiReasoningFormat reasoningFormat = AiReasoningFormat.auto,
    int? reasoningBudgetTokens,
  }) {
    return LangchainAiConfig(
      identifier: providerId,
      apiKey: apiKey,
      model: model,
      baseUrl: _deriveBaseUrl(url),
      reasoningEffort: reasoningEffort,
      reasoningEnabled: reasoningEnabled,
      reasoningFormat: reasoningFormat,
      reasoningBudgetTokens: reasoningBudgetTokens,
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
    bool? reasoningEnabled,
    AiReasoningFormat? reasoningFormat,
    int? reasoningBudgetTokens,
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
      reasoningEnabled: reasoningEnabled ?? this.reasoningEnabled,
      reasoningFormat: reasoningFormat ?? this.reasoningFormat,
      reasoningBudgetTokens:
          reasoningBudgetTokens ?? this.reasoningBudgetTokens,
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
