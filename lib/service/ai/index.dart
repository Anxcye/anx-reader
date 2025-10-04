import 'dart:async';
import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/service/ai/ai_cache.dart';
import 'package:anx_reader/service/ai/langchain_ai_config.dart';
import 'package:anx_reader/service/ai/langchain_registry.dart';
import 'package:anx_reader/service/ai/langchain_runner.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:langchain_core/prompts.dart';

final LangchainAiRegistry _registry = LangchainAiRegistry();
final CancelableLangchainRunner _runner = CancelableLangchainRunner();

Stream<String> aiGenerateStream(
  WidgetRef ref,
  List<ChatMessage> messages, {
  String? identifier,
  Map<String, String>? config,
  bool regenerate = false,
}) {
  return _generateStream(
    messages: messages,
    identifier: identifier,
    overrideConfig: config,
    regenerate: regenerate,
  );
}

Stream<String> aiGenerateStreamWithoutRef(
  List<ChatMessage> messages, {
  String? identifier,
  Map<String, String>? config,
  bool regenerate = false,
}) {
  return _generateStream(
    messages: messages,
    identifier: identifier,
    overrideConfig: config,
    regenerate: regenerate,
  );
}

void cancelActiveAiRequest() {
  _runner.cancel();
}

Stream<String> _generateStream({
  required List<ChatMessage> messages,
  String? identifier,
  Map<String, String>? overrideConfig,
  required bool regenerate,
}) async* {
  AnxLog.info('aiGenerateStream called identifier: $identifier');
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

  var config = LangchainAiConfig.fromPrefs(selectedIdentifier, savedConfig);
  if (overrideConfig != null && overrideConfig.isNotEmpty) {
    final override =
        LangchainAiConfig.fromPrefs(selectedIdentifier, overrideConfig);
    config = mergeConfigs(config, override);
  }

  final prompt = PromptValue.chat(messages);
  final hash = _hashMessages(messages);
  final cacheEntry = await AiCache.getAiCache(hash);

  if (cacheEntry != null && cacheEntry.data.isNotEmpty && !regenerate) {
    yield cacheEntry.decoratedText();
    return;
  }

  AnxLog.info('aiGenerateStream: $selectedIdentifier, model: ${config.model}');

  final model = _registry.resolve(config);
  final stream = _runner.stream(model: model, prompt: prompt);

  var buffer = cacheEntry?.data ?? '';

  try {
    await for (final chunk in stream) {
      buffer = chunk;
      yield buffer;
    }

    if (buffer.isNotEmpty) {
      final conversation = [...messages, ChatMessage.ai(buffer)];
      await AiCache.setAiCache(hash, buffer, selectedIdentifier, conversation);
    }
  } catch (error, stack) {
    final mapped = _mapError(error);
    AnxLog.severe('AI error: $mapped\n$stack');
    yield mapped;
  }
}

int _hashMessages(List<ChatMessage> messages) {
  final digest =
      messages.map((m) => '${_roleOf(m)}: ${m.contentAsString}').join('\n');
  return digest.hashCode;
}

String _roleOf(ChatMessage message) {
  return switch (message) {
    SystemChatMessage _ => 'system',
    HumanChatMessage _ => 'user',
    AIChatMessage _ => 'assistant',
    ToolChatMessage _ => 'tool',
    CustomChatMessage custom => custom.role,
  };
}

String _mapError(Object error) {
  final context = navigatorKey.currentContext;
  final l10n = context != null ? L10n.of(context) : null;
  final base = l10n?.translateError ?? 'Error: ';

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

  return '$base${error.toString()}';
}
