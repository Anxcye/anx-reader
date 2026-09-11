import 'dart:async';
import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/providers/ai_providers.dart';
import 'package:anx_reader/service/ai/ai_key_rotator.dart';
import 'package:anx_reader/service/ai/langchain_ai_config.dart';
import 'package:anx_reader/service/ai/langchain_registry.dart';
import 'package:anx_reader/service/ai/langchain_runner.dart';
import 'package:anx_reader/utils/ai_reasoning_parser.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:langchain_core/prompts.dart';

final CancelableLangchainRunner _runner = CancelableLangchainRunner();

// Global request timestamps list for RPM throttling
final List<DateTime> _aiRequestTimestamps = [];

/// Throttle AI requests if RPM limit is configured (sliding 1-minute window).
Future<void> _throttleIfNeeded() async {
  final rpm = Prefs().aiRpm;
  if (rpm <= 0) return;
  final now = DateTime.now();
  final windowStart = now.subtract(const Duration(minutes: 1));
  _aiRequestTimestamps.removeWhere((ts) => ts.isBefore(windowStart));
  if (_aiRequestTimestamps.length >= rpm) {
    final oldest = _aiRequestTimestamps.first;
    final waitUntil = oldest.add(const Duration(minutes: 1));
    final waitDuration = waitUntil.difference(DateTime.now());
    if (waitDuration > Duration.zero) {
      await Future.delayed(waitDuration);
    }
    final newNow = DateTime.now();
    _aiRequestTimestamps.removeWhere(
        (ts) => ts.isBefore(newNow.subtract(const Duration(minutes: 1))));
  }
  _aiRequestTimestamps.add(DateTime.now());
}

Stream<String> aiGenerateStream(
  List<ChatMessage> messages, {
  String? identifier,
  Map<String, String>? config,
  bool regenerate = false,
  bool useAgent = false,
  WidgetRef? ref,
}) {
  if (useAgent) {
    assert(ref != null, 'ref must be provided when useAgent is true');
  }
  LangchainAiRegistry registry = LangchainAiRegistry(ref);

  return _generateStream(
      messages: messages,
      identifier: identifier,
      overrideConfig: config,
      regenerate: regenerate,
      useAgent: useAgent,
      registry: registry);
}

void cancelActiveAiRequest() {
  _runner.cancel();
}

Stream<String> _generateStream({
  required List<ChatMessage> messages,
  String? identifier,
  Map<String, String>? overrideConfig,
  required bool regenerate,
  required bool useAgent,
  required LangchainAiRegistry registry,
}) async* {
  AnxLog.info('aiGenerateStream called identifier: $identifier');
  final sanitizedMessages = _sanitizeMessagesForPrompt(messages);

  LangchainAiConfig config;

  // Try to use new provider system first if ref is available
  if (registry.ref != null && overrideConfig == null) {
    try {
      final notifier = registry.ref!.read(aiProvidersProvider.notifier);
      // If a specific provider id was passed, use it; otherwise use the default
      final AiProvider? provider = identifier != null
          ? notifier.getProviderById(identifier)
          : notifier.getSelectedProvider();
      if (provider != null &&
          provider.enabled &&
          AiKeyRotator.hasValidKey(provider)) {
        final apiKey = AiKeyRotator.getNextKey(provider);
        if (apiKey != null) {
          config = LangchainAiConfig.fromProvider(
            providerId: provider.id,
            model: provider.model,
            apiKey: apiKey,
            url: provider.url,
            reasoningEffort: provider.reasoningEffort,
          );

          AnxLog.info(
              'aiGenerateStream (new): ${provider.id}, model: ${config.model}, baseUrl: ${config.baseUrl}');

          final pipeline = registry.resolveByProtocol(provider.protocol, config,
              useAgent: useAgent);
          final model = pipeline.model;

          await _throttleIfNeeded();
          yield* _executeStream(
            model: model,
            pipeline: pipeline,
            sanitizedMessages: sanitizedMessages,
            useAgent: useAgent,
          );

          // Advance key index for round-robin rotation after successful call
          registry.ref!
              .read(aiProvidersProvider.notifier)
              .advanceKeyIndex(provider.id);
          return;
        }
      }
    } catch (e) {
      AnxLog.warning(
          'Failed to use new provider system, falling back to legacy: $e');
    }
  }

  // Try new provider system without ref (reads directly from Prefs storage)
  if (overrideConfig == null) {
    try {
      final rawProviders = Prefs().getAiProviders();
      if (rawProviders.isNotEmpty) {
        final providers = rawProviders
            .map((json) => AiProvider.fromJson(json as Map<String, dynamic>))
            .toList();

        AiProvider? provider;
        if (identifier != null) {
          try {
            provider = providers.firstWhere((p) => p.id == identifier);
          } catch (_) {
            provider = null;
          }
        } else {
          final selectedId = Prefs().selectedAiService;
          try {
            provider = providers.firstWhere((p) => p.id == selectedId);
          } catch (_) {}
          provider ??= providers.where((p) => p.enabled).firstOrNull;
        }

        if (provider != null &&
            provider.enabled &&
            AiKeyRotator.hasValidKey(provider)) {
          final apiKey = AiKeyRotator.getNextKey(provider);
          if (apiKey != null) {
            config = LangchainAiConfig.fromProvider(
              providerId: provider.id,
              model: provider.model,
              apiKey: apiKey,
              url: provider.url,
              reasoningEffort: provider.reasoningEffort,
            );

            AnxLog.info(
                'aiGenerateStream (no-ref new): ${provider.id}, model: ${config.model}, baseUrl: ${config.baseUrl}');

            final pipeline = registry.resolveByProtocol(
                provider.protocol, config,
                useAgent: useAgent);
            final model = pipeline.model;

            await _throttleIfNeeded();
            yield* _executeStream(
              model: model,
              pipeline: pipeline,
              sanitizedMessages: sanitizedMessages,
              useAgent: useAgent,
            );

            // Advance key index in persistent storage for round-robin rotation
            final updatedProviders = providers.map((p) {
              if (p.id == provider!.id) {
                return p.copyWith(
                    keyIndex: p.keyIndex + 1, updatedAt: DateTime.now());
              }
              return p;
            }).toList();
            Prefs().saveAiProviders(updatedProviders);
            return;
          }
        }
      }
    } catch (e) {
      AnxLog.warning(
          'Failed to use no-ref new provider system, falling back to legacy: $e');
    }
  }

  // Fall back to legacy system
  final selectedIdentifier = identifier ?? Prefs().selectedAiService;
  final savedConfig = Prefs().getAiConfig(selectedIdentifier);
  if (savedConfig.isEmpty &&
      (overrideConfig == null || overrideConfig.isEmpty)) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      yield L10n.of(context).aiServiceNotConfigured;
    } else {
      yield 'AI service not configured';
    }
    return;
  }

  config = LangchainAiConfig.fromPrefs(selectedIdentifier, savedConfig);
  if (overrideConfig != null && overrideConfig.isNotEmpty) {
    final override =
        LangchainAiConfig.fromPrefs(selectedIdentifier, overrideConfig);
    config = mergeConfigs(config, override);
  }

  AnxLog.info(
      'aiGenerateStream (legacy): $selectedIdentifier, model: ${config.model}, baseUrl: ${config.baseUrl}');

  final pipeline = registry.resolve(config, useAgent: useAgent);
  final model = pipeline.model;

  await _throttleIfNeeded();
  yield* _executeStream(
    model: model,
    pipeline: pipeline,
    sanitizedMessages: sanitizedMessages,
    useAgent: useAgent,
  );
}

/// Execute the AI stream with the given model and pipeline
Stream<String> _executeStream({
  required BaseChatModel model,
  required LangchainPipeline pipeline,
  required List<ChatMessage> sanitizedMessages,
  required bool useAgent,
}) async* {
  Stream<String> stream;
  if (useAgent) {
    final inputMessage = _latestUserMessage(sanitizedMessages);
    if (inputMessage == null) {
      yield 'No user input provided';
      return;
    }

    final tools = pipeline.tools;
    if (tools.isEmpty) {
      yield 'Agent mode not supported for this provider.';
      return;
    }

    final historyMessages = sanitizedMessages
        .sublist(0, sanitizedMessages.length - 1)
        .toList(growable: false);

    stream = _runner.streamAgent(
      model: model,
      tools: tools,
      history: historyMessages,
      input: inputMessage,
      systemMessage: pipeline.systemMessage,
    );
  } else {
    final prompt = PromptValue.chat(sanitizedMessages);
    stream = _runner.stream(model: model, prompt: prompt);
  }

  var buffer = '';

  try {
    await for (final chunk in stream) {
      buffer = chunk;
      yield buffer;
    }
  } catch (error, stack) {
    final mapped = _mapError(error);
    AnxLog.severe('AI error: $mapped\n$stack');
    yield mapped;
  } finally {
    try {
      model.close();
    } catch (_) {}
  }
}

String _mapError(Object error) {
  final base = 'Error: ';

  if (error is TimeoutException) {
    return '${base}Request timed out';
  }

  if (error is SocketException) {
    return '${base}Network error: ${error.message}';
  }

  final message = error.toString().toLowerCase();

  if (message.contains('401') ||
      message.contains('unauthorized') ||
      message.contains('invalid api key')) {
    return '${base}Authentication failed. Please verify API key.';
  }

  if (message.contains('429') || message.contains('rate limit')) {
    return '${base}Rate limit reached. Try again later.';
  }

  if (message.contains('timeout')) {
    return '${base}Request timed out';
  }

  if (message.contains('network') ||
      message.contains('socket') ||
      message.contains('failed host lookup')) {
    return '${base}Network error: ${error.toString()}';
  }

  if (error is TypeError ||
      message.contains("is not a subtype of type 'string'") ||
      (message.contains('null') && message.contains('string'))) {
    return '${base}Provider returned an unexpected response. '
        'Check that the URL, protocol, and model match the API '
        '(Claude-compatible endpoints must return Anthropic-shaped messages).';
  }

  if (error is ArgumentError) {
    return '$base${error.message}';
  }

  return '$base${error.toString()}';
}

List<ChatMessage> _sanitizeMessagesForPrompt(List<ChatMessage> messages) {
  return messages.map((message) {
    if (message is AIChatMessage) {
      if (message.reasoningContent.isNotEmpty) {
        return AIChatMessage(
          content: message.content,
          toolCalls: message.toolCalls,
        );
      }
      final plainText = reasoningContentToPlainText(message.content);
      if (plainText == message.content) {
        return message;
      }
      return AIChatMessage(
        content: plainText,
        toolCalls: message.toolCalls,
      );
    }
    return message;
  }).toList(growable: false);
}

String? _latestUserMessage(List<ChatMessage> messages) {
  for (var i = messages.length - 1; i >= 0; i--) {
    final message = messages[i];
    if (message is HumanChatMessage) {
      return message.contentAsString;
    }
  }
  return null;
}
