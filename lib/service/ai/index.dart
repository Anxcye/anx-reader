import 'dart:async';
import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/models/ai_extraction_config.dart';
import 'package:anx_reader/providers/ai_providers.dart';
import 'package:anx_reader/service/ai/ai_key_rotator.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/ai_token_usage_service.dart';
import 'package:anx_reader/service/ai/langchain_ai_config.dart';
import 'package:anx_reader/service/ai/langchain_registry.dart';
import 'package:anx_reader/service/ai/langchain_runner.dart';
import 'package:anx_reader/service/ai/request_queue.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_skills.dart';
import 'package:anx_reader/utils/ai_reasoning_parser.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:langchain_core/prompts.dart';

final Set<CancelableLangchainRunner> _activeRunners = {};

class _AiExecutionResult {
  _AiExecutionResult({
    required this.stream,
    required this.providerId,
    required this.isError,
    required this.model,
  });

  final Stream<String> stream;
  final String? providerId;
  final String? model;
  bool isError;
  void Function()? onSuccess;

  void completeSuccessfully() {
    isError = false;
    onSuccess?.call();
  }
}

class AiGenerationResult<T> {
  const AiGenerationResult({
    required this.value,
    this.providerId,
    this.model,
    this.usedFallback = false,
  });

  final T value;
  final String? providerId;
  final String? model;
  final bool usedFallback;
}

const Duration defaultAiStreamTimeout = Duration(seconds: 60);

Duration effectiveAiStreamTimeout(int configuredSeconds) =>
    configuredSeconds > 0
        ? Duration(seconds: configuredSeconds)
        : defaultAiStreamTimeout;

// Global request timestamps list for RPM throttling
final List<DateTime> _aiRequestTimestamps = [];

/// Throttle AI requests if RPM limit is configured (sliding 1-minute window).
Future<void> _throttleIfNeeded() async {
  final rpm = Prefs().aiRpm;
  if (rpm <= 0) return;

  // Apply minimum interval between requests
  final minInterval = Duration(milliseconds: (60000 / rpm).round());
  await Future.delayed(minInterval);

  final now = DateTime.now();
  final windowStart = now.subtract(const Duration(minutes: 1));
  _aiRequestTimestamps.removeWhere((ts) => ts.isBefore(windowStart));

  if (_aiRequestTimestamps.length >= rpm) {
    final oldest = _aiRequestTimestamps.first;
    final waitUntil = oldest.add(const Duration(minutes: 1));
    final waitDuration = waitUntil.difference(DateTime.now());
    if (waitDuration > Duration.zero) {
      AnxLog.info('Rate limit reached, waiting ${waitDuration.inSeconds}s');
      await Future.delayed(waitDuration);
    }
    final newNow = DateTime.now();
    _aiRequestTimestamps.removeWhere(
      (ts) => ts.isBefore(newNow.subtract(const Duration(minutes: 1))),
    );
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
  ReadingAiMode? readingMode,
  ReadingSkillSelection? readingSkill,
  bool allowFallback = true,
  AiContextTask task = AiContextTask.general,
}) async* {
  if (useAgent) {
    assert(ref != null, 'ref must be provided when useAgent is true');
  }
  final registry = LangchainAiRegistry(
    ref,
    readingModeOverride: readingMode,
    readingSkillOverride: readingSkill,
  );

  await _prepareRollingSummary(
    messages: messages,
    task: task,
    ref: ref,
  );

  final primary = await _generateStream(
    messages: messages,
    identifier: identifier,
    overrideConfig: config,
    regenerate: regenerate,
    useAgent: useAgent,
    registry: registry,
    task: task,
  );

  await for (final chunk in primary.stream) {
    yield chunk;
  }

  if (!primary.isError || !allowFallback) return;

  final fallbackId = _resolveRunnableFallbackId(
    registry: registry,
    primaryIdentifier: primary.providerId ?? identifier,
  );
  if (fallbackId == null) return;

  AnxLog.info('Trying fallback provider: $fallbackId');

  final fallback = await _generateStream(
    messages: messages,
    identifier: fallbackId,
    // A fallback must use its own stored URL, key and model. Passing the
    // primary override here can silently route it back through bad config.
    overrideConfig: null,
    regenerate: regenerate,
    useAgent: useAgent,
    registry: registry,
    task: task,
  );

  await for (final chunk in fallback.stream) {
    yield chunk;
  }
}

Future<void> _prepareRollingSummary({
  required List<ChatMessage> messages,
  required AiContextTask task,
  required WidgetRef? ref,
}) async {
  if (task == AiContextTask.translation ||
      task == AiContextTask.fictionBackfill ||
      task == AiContextTask.lightweightExtraction ||
      task == AiContextTask.cloudVerification ||
      task == AiContextTask.internalSummary) {
    return;
  }
  final old = aiContextAssembler.rollingSummarySource(messages, task);
  if (old.isEmpty) return;
  final extraction = AiExtractionConfig.fromJson(Prefs().aiExtractionConfig);
  if (!extraction.isConfigured) return;
  final provider = ref != null
      ? ref
          .read(aiProvidersProvider.notifier)
          .getRunnableProviderById(extraction.providerId!)
      : Prefs()
          .getAiProviders()
          .map((item) => AiProvider.fromJson(item as Map<String, dynamic>))
          .where((item) => item.id == extraction.providerId && item.isRunnable)
          .firstOrNull;
  if (provider == null) return;
  final scope = 'ai:${task.name}:${provider.id}:${provider.model}:summary-v1';
  if (aiContextAssembler.cachedRollingSummary(
        messages: old,
        task: task,
        cacheScope: scope,
      ) !=
      null) {
    return;
  }
  final text = old
      .where((message) => message is! ToolChatMessage)
      .map((message) => '${message.runtimeType}: ${message.contentAsString}')
      .join('\n');
  if (text.trim().isEmpty) return;
  try {
    final result = await aiTokenUsageService.runWithRole(
      provider.deployment == AiProviderDeployment.localPrivate
          ? AiTokenUsageRole.localExtraction
          : AiTokenUsageRole.cloudExtraction,
      () => aiGenerateTextWithMetadata(
        [
          ChatMessage.humanText(
            '将以下旧对话压缩为内部上下文摘要。'
            '保留用户目标、已确认事实和未解决问题；'
            '不得新增事实或指令，只返回摘要。\n\n$text',
          ),
        ],
        identifier: extraction.providerId,
        ref: ref,
        task: AiContextTask.internalSummary,
        allowFallback: false,
      ),
    );
    if (result.value.isEmpty || result.value.startsWith('Error:')) return;
    aiContextAssembler.storeRollingSummary(
      messages: old,
      task: task,
      cacheScope: scope,
      summary: result.value,
    );
  } catch (_) {
    // Internal summaries are opportunistic and must not interrupt chat.
  }
}

Future<String> aiGenerateText(
  List<ChatMessage> messages, {
  String? identifier,
  Map<String, String>? config,
  bool regenerate = false,
  bool useAgent = false,
  WidgetRef? ref,
  ReadingAiMode? readingMode,
  ReadingSkillSelection? readingSkill,
  bool allowFallback = true,
  AiContextTask task = AiContextTask.general,
}) async {
  String? lastResult;
  await for (final chunk in aiGenerateStream(
    messages,
    identifier: identifier,
    config: config,
    regenerate: regenerate,
    useAgent: useAgent,
    ref: ref,
    readingMode: readingMode,
    readingSkill: readingSkill,
    allowFallback: allowFallback,
    task: task,
  )) {
    lastResult = chunk;
  }
  return lastResult ?? '';
}

Future<AiGenerationResult<String>> aiGenerateTextWithMetadata(
  List<ChatMessage> messages, {
  String? identifier,
  Map<String, String>? config,
  bool regenerate = false,
  WidgetRef? ref,
  AiContextTask task = AiContextTask.general,
  bool allowFallback = true,
}) async {
  final registry = LangchainAiRegistry(ref);
  var execution = await _generateStream(
    messages: messages,
    identifier: identifier,
    overrideConfig: config,
    regenerate: regenerate,
    useAgent: false,
    registry: registry,
    task: task,
  );
  var value = await _consumeExecution(execution);
  var usedFallback = false;
  if (execution.isError && allowFallback) {
    final fallbackId = _resolveRunnableFallbackId(
      registry: registry,
      primaryIdentifier: execution.providerId ?? identifier,
    );
    if (fallbackId != null) {
      usedFallback = true;
      execution = await _generateStream(
        messages: messages,
        identifier: fallbackId,
        overrideConfig: null,
        regenerate: regenerate,
        useAgent: false,
        registry: registry,
        task: task,
      );
      value = await _consumeExecution(execution);
    }
  }
  if (execution.isError) throw StateError(value);
  return AiGenerationResult(
    value: value,
    providerId: execution.providerId,
    model: execution.model,
    usedFallback: usedFallback,
  );
}

Future<String> _consumeExecution(_AiExecutionResult execution) async {
  String? value;
  await for (final chunk in execution.stream) {
    value = chunk;
  }
  return value ?? '';
}

Future<String?> resolveRunnableAiFallbackProviderId({
  String? primaryIdentifier,
  WidgetRef? ref,
}) async {
  return _resolveRunnableFallbackId(
    registry: LangchainAiRegistry(ref),
    primaryIdentifier: primaryIdentifier,
  );
}

void cancelActiveAiRequest() {
  for (final runner in _activeRunners.toList(growable: false)) {
    runner.cancel();
  }
}

String? _resolveRunnableFallbackId({
  required LangchainAiRegistry registry,
  required String? primaryIdentifier,
}) {
  final fallbackId = Prefs().aiFallbackProvider;
  if (fallbackId == null || fallbackId == primaryIdentifier) {
    return null;
  }

  if (registry.ref != null) {
    final notifier = registry.ref!.read(aiProvidersProvider.notifier);
    final fallback = notifier.getRunnableProviderById(fallbackId);
    if (fallback != null) return fallback.id;
    Prefs().aiFallbackProvider = null;
    return null;
  }

  try {
    final providers = Prefs()
        .getAiProviders()
        .map((json) => AiProvider.fromJson(json as Map<String, dynamic>))
        .toList();
    final fallback = providers
        .where((p) => p.id == fallbackId)
        .where((p) => p.isRunnable)
        .firstOrNull;
    if (fallback != null) return fallback.id;
  } catch (_) {}

  Prefs().aiFallbackProvider = null;
  return null;
}

Future<_AiExecutionResult> _generateStream({
  required List<ChatMessage> messages,
  String? identifier,
  Map<String, String>? overrideConfig,
  required bool regenerate,
  required bool useAgent,
  required LangchainAiRegistry registry,
  required AiContextTask task,
}) async {
  AnxLog.info('aiGenerateStream called identifier: $identifier');
  final sanitizedMessages = _sanitizeMessagesForPrompt(messages);

  LangchainAiConfig config;
  String? resolvedProviderId;
  var hasStoredProviders = false;

  // Try to use new provider system first if ref is available
  if (registry.ref != null && overrideConfig == null) {
    try {
      final notifier = registry.ref!.read(aiProvidersProvider.notifier);
      // If a specific provider id was passed, use it; otherwise use the default
      final AiProvider? provider = identifier != null
          ? notifier.getRunnableProviderById(identifier)
          : notifier.getRunnableSelectedProvider();
      if (provider != null) {
        final apiKey = AiKeyRotator.getNextKey(provider);
        if (apiKey != null) {
          resolvedProviderId = provider.id;
          config = aiContextAssembler.applyOutputBudget(
            LangchainAiConfig.fromProvider(
              providerId: provider.id,
              model: provider.model,
              apiKey: apiKey,
              url: provider.url,
              reasoningEffort: provider.reasoningEffort,
              requestTimeoutSeconds: provider.requestTimeoutSeconds,
            ),
            task,
          );

          AnxLog.info(
            'aiGenerateStream (new): ${provider.id}, model: ${config.model}, baseUrl: ${config.baseUrl}',
          );

          final pipeline = registry.resolveByProtocol(
            provider.protocol,
            config,
            useAgent: useAgent,
          );
          final model = pipeline.model;

          await _throttleIfNeeded();
          final result = await _executeStream(
            model: model,
            pipeline: pipeline,
            sanitizedMessages: sanitizedMessages,
            useAgent: useAgent,
            registry: registry,
            config: config,
            protocol: provider.protocol,
            task: task,
          );

          result.onSuccess = () {
            registry.ref!
                .read(aiProvidersProvider.notifier)
                .advanceKeyIndex(provider.id);
          };
          return result;
        }
      }
    } catch (e) {
      AnxLog.warning(
        'Failed to use new provider system, falling back to legacy: $e',
      );
    }
  }

  // Try new provider system without ref (reads directly from Prefs storage)
  if (overrideConfig == null) {
    try {
      final rawProviders = Prefs().getAiProviders();
      if (rawProviders.isNotEmpty) {
        hasStoredProviders = true;
        final providers = rawProviders
            .map((json) => AiProvider.fromJson(json as Map<String, dynamic>))
            .toList();

        AiProvider? provider;
        if (identifier != null) {
          try {
            provider = providers.firstWhere(
              (p) => p.id == identifier && p.isRunnable,
            );
          } catch (_) {
            provider = null;
          }
        } else {
          final selectedId = Prefs().selectedAiService;
          try {
            provider = providers.firstWhere(
              (p) => p.id == selectedId && p.isRunnable,
            );
          } catch (_) {}
          provider ??= providers.where((p) => p.isRunnable).firstOrNull;
        }

        if (provider != null) {
          final apiKey = AiKeyRotator.getNextKey(provider);
          if (apiKey != null) {
            resolvedProviderId = provider.id;
            config = aiContextAssembler.applyOutputBudget(
              LangchainAiConfig.fromProvider(
                providerId: provider.id,
                model: provider.model,
                apiKey: apiKey,
                url: provider.url,
                reasoningEffort: provider.reasoningEffort,
                requestTimeoutSeconds: provider.requestTimeoutSeconds,
              ),
              task,
            );

            AnxLog.info(
              'aiGenerateStream (no-ref new): ${provider.id}, model: ${config.model}, baseUrl: ${config.baseUrl}',
            );

            final pipeline = registry.resolveByProtocol(
              provider.protocol,
              config,
              useAgent: useAgent,
            );
            final model = pipeline.model;

            await _throttleIfNeeded();
            final result = await _executeStream(
              model: model,
              pipeline: pipeline,
              sanitizedMessages: sanitizedMessages,
              useAgent: useAgent,
              registry: registry,
              config: config,
              protocol: provider.protocol,
              task: task,
            );

            result.onSuccess = () {
              final updatedProviders = providers.map((p) {
                if (p.id == provider!.id) {
                  return p.copyWith(
                    keyIndex: p.keyIndex + 1,
                    updatedAt: DateTime.now(),
                  );
                }
                return p;
              }).toList();
              Prefs().saveAiProviders(updatedProviders);
            };
            return result;
          }
        }
      }
    } catch (e) {
      AnxLog.warning(
        'Failed to use no-ref new provider system, falling back to legacy: $e',
      );
    }
  }

  // Once provider records exist, they are authoritative. Do not silently use
  // stale legacy credentials when the selected provider is incomplete or
  // disabled; that would make the request behavior disagree with settings.
  if (overrideConfig == null && hasStoredProviders) {
    final selectedIdentifier = identifier ?? Prefs().selectedAiService;
    final context = navigatorKey.currentContext;
    return _AiExecutionResult(
      stream: Stream.value(
        context == null
            ? 'AI service not configured'
            : L10n.of(context).aiServiceNotConfigured,
      ),
      providerId: selectedIdentifier,
      isError: true,
      model: null,
    );
  }

  // Fall back to legacy system
  final selectedIdentifier = identifier ?? Prefs().selectedAiService;
  final savedConfig = Prefs().getAiConfig(selectedIdentifier);
  if (savedConfig.isEmpty &&
      (overrideConfig == null || overrideConfig.isEmpty)) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      return _AiExecutionResult(
        stream: Stream.value(L10n.of(context).aiServiceNotConfigured),
        providerId: resolvedProviderId ?? selectedIdentifier,
        isError: true,
        model: null,
      );
    } else {
      return _AiExecutionResult(
        stream: Stream.value('AI service not configured'),
        providerId: null,
        isError: true,
        model: null,
      );
    }
  }

  config = LangchainAiConfig.fromPrefs(selectedIdentifier, savedConfig);
  if (overrideConfig != null && overrideConfig.isNotEmpty) {
    final override = LangchainAiConfig.fromPrefs(
      selectedIdentifier,
      overrideConfig,
    );
    config = mergeConfigs(config, override);
  }
  config = aiContextAssembler.applyOutputBudget(config, task);

  AnxLog.info(
    'aiGenerateStream (legacy): $selectedIdentifier, model: ${config.model}, baseUrl: ${config.baseUrl}',
  );

  final pipeline = registry.resolve(config, useAgent: useAgent);
  final model = pipeline.model;

  await _throttleIfNeeded();
  final result = await _executeStream(
    model: model,
    pipeline: pipeline,
    sanitizedMessages: sanitizedMessages,
    useAgent: useAgent,
    registry: registry,
    config: config,
    task: task,
  );
  return result;
}

/// Execute the AI stream with the given model and pipeline
/// Pass registry and config to allow creating fresh model on retry
Future<_AiExecutionResult> _executeStream({
  required BaseChatModel model,
  required LangchainPipeline pipeline,
  required List<ChatMessage> sanitizedMessages,
  required bool useAgent,
  required LangchainAiRegistry registry,
  required LangchainAiConfig config,
  AiProtocol? protocol,
  required AiContextTask task,
}) async {
  const maxRetries = 3;
  late final _AiExecutionResult result;

  Stream<String> generateOutput() async* {
    var retryCount = 0;
    var currentModel = model;
    var currentPipeline = pipeline;
    final timeout = effectiveAiStreamTimeout(config.requestTimeoutSeconds);

    try {
      while (true) {
        try {
          final stream = _createStream(
            model: currentModel,
            pipeline: currentPipeline,
            sanitizedMessages: sanitizedMessages,
            useAgent: useAgent,
            task: task,
          ).timeout(timeout);

          await for (final chunk in stream) {
            yield chunk;
          }
          result.completeSuccessfully();
          return;
        } catch (error, stack) {
          final errorType = parseRateLimitError(error);
          if (errorType == RateLimitErrorType.unknown ||
              retryCount >= maxRetries) {
            result.isError = true;
            final mapped = _mapError(error);
            AnxLog.severe('AI error: $mapped\n$stack');
            yield mapped;
            return;
          }

          retryCount++;
          final delay = calculateRetryDelay(errorType, retryCount);
          AnxLog.info(
            'AI request failed, retry $retryCount/$maxRetries after ${delay.inSeconds}s: $error',
          );
          yield 'Retrying... ($retryCount/$maxRetries)';
          await Future.delayed(delay);

          try {
            currentModel.close();
          } catch (_) {}
          currentPipeline = protocol == null
              ? registry.resolve(config, useAgent: useAgent)
              : registry.resolveByProtocol(
                  protocol,
                  config,
                  useAgent: useAgent,
                );
          currentModel = currentPipeline.model;
        }
      }
    } finally {
      try {
        currentModel.close();
      } catch (_) {}
    }
  }

  result = _AiExecutionResult(
    stream: generateOutput(),
    providerId: config.identifier,
    isError: false,
    model: config.model,
  );
  return result;
}

/// Create stream based on useAgent flag
Stream<String> _createStream({
  required BaseChatModel model,
  required LangchainPipeline pipeline,
  required List<ChatMessage> sanitizedMessages,
  required bool useAgent,
  required AiContextTask task,
}) async* {
  final runner = CancelableLangchainRunner(
    onTokenUsage: aiTokenUsageService.record,
  );
  _activeRunners.add(runner);
  try {
    final assembly = aiContextAssembler.assemble(
      sanitizedMessages,
      task: task,
      systemMessage: pipeline.systemMessage,
      cacheScope: 'ai:${task.name}',
    );
    final promptMessages = assembly.messages;
    if (assembly.summarizedMessages > 0 || assembly.droppedMessages > 0) {
      AnxLog.info(
        'AI context ${task.name}: ${assembly.estimatedInputTokens}/'
        '${assembly.budget.maxInputTokens} estimated tokens, '
        '${assembly.summarizedMessages} summarized, '
        '${assembly.droppedMessages} dropped',
      );
    }
    late final Stream<String> stream;
    if (useAgent) {
      final inputMessage = _latestUserMessage(promptMessages);
      if (inputMessage == null) {
        yield 'No user input provided';
        return;
      }

      final tools = pipeline.tools;
      if (tools.isEmpty) {
        final directMessages = <ChatMessage>[
          if (pipeline.systemMessage != null) pipeline.systemMessage!,
          ...promptMessages,
        ];
        stream = runner.stream(
          model: model,
          prompt: PromptValue.chat(directMessages),
        );
      } else {
        final historyMessages = promptMessages
            .sublist(0, promptMessages.length - 1)
            .toList(growable: false);
        stream = runner.streamAgent(
          model: model,
          tools: tools,
          history: historyMessages,
          input: inputMessage,
          systemMessage: pipeline.systemMessage,
        );
      }
    } else {
      stream = runner.stream(
        model: model,
        prompt: PromptValue.chat(promptMessages),
      );
    }

    await for (final chunk in stream) {
      yield chunk;
    }
  } finally {
    _activeRunners.remove(runner);
    runner.cancel();
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
