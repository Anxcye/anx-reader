import 'dart:convert';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/ai_extraction_config.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/providers/ai_providers.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/ai_token_usage_service.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain_core/chat_models.dart';

abstract final class AiExtractionTaskIds {
  static const fictionStoryAtlas = 'fiction.story_atlas';
  static const rollingSummary = 'context.rolling_summary';
  static const readingMemoryTopics = 'reading_memory.topic_extraction';
}

class AiExtractionResult {
  const AiExtractionResult({
    required this.taskId,
    required this.raw,
    required this.payload,
    required this.providerId,
    required this.model,
    required this.deployment,
    required this.pipelineVersion,
    required this.estimatedInputTokens,
    required this.inputTokens,
    required this.outputTokens,
    required this.usageEstimated,
    required this.elapsed,
    this.validationErrors = const [],
  });

  final String taskId;
  final String raw;
  final Object? payload;
  final String providerId;
  final String model;
  final AiProviderDeployment deployment;
  final int pipelineVersion;
  final int estimatedInputTokens;
  final int inputTokens;
  final int outputTokens;
  final bool usageEstimated;
  final Duration elapsed;
  final List<String> validationErrors;
  bool get isValid => validationErrors.isEmpty;
}

class AiExtractionUnavailable implements Exception {
  const AiExtractionUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

class AiExtractionEngine {
  const AiExtractionEngine();

  static const pipelineVersion = 1;

  AiExtractionConfig config() =>
      AiExtractionConfig.fromJson(Prefs().aiExtractionConfig);

  AiProvider? resolveProvider([WidgetRef? ref]) {
    final current = config();
    if (!current.isConfigured) return null;
    if (ref != null) {
      return ref
          .read(aiProvidersProvider.notifier)
          .getRunnableProviderById(current.providerId!);
    }
    try {
      return Prefs()
          .getAiProviders()
          .map((item) => AiProvider.fromJson(item as Map<String, dynamic>))
          .where((item) => item.id == current.providerId && item.isRunnable)
          .firstOrNull;
    } catch (_) {
      return null;
    }
  }

  Future<AiExtractionResult> extract({
    required String taskId,
    required String prompt,
    WidgetRef? ref,
    bool requireJson = true,
  }) async {
    final provider = resolveProvider(ref);
    if (provider == null) {
      throw const AiExtractionUnavailable('轻量提取引擎未配置或不可用');
    }
    final started = DateTime.now();
    final role = provider.deployment == AiProviderDeployment.localPrivate
        ? AiTokenUsageRole.localExtraction
        : AiTokenUsageRole.cloudExtraction;
    final before = aiTokenUsageService.snapshot().byRole[role] ??
        const AiTokenUsageBucket();
    final generated = await aiTokenUsageService.runWithRole(
      role,
      () => aiGenerateTextWithMetadata(
        [ChatMessage.humanText(prompt)],
        identifier: provider.id,
        ref: ref,
        task: taskId == AiExtractionTaskIds.rollingSummary
            ? AiContextTask.internalSummary
            : AiContextTask.lightweightExtraction,
        allowFallback: false,
      ),
    );
    final raw = generated.value.trim();
    final after = aiTokenUsageService.snapshot().byRole[role] ??
        const AiTokenUsageBucket();
    Object? payload;
    final errors = <String>[];
    if (raw.isEmpty || raw.startsWith('Error:')) {
      errors.add(raw.isEmpty ? '模型返回空内容' : raw);
    } else if (requireJson) {
      try {
        payload = jsonDecode(_stripFence(raw));
      } catch (_) {
        errors.add('返回内容不是合法 JSON');
      }
    } else {
      payload = raw;
    }
    return AiExtractionResult(
      taskId: taskId,
      raw: raw,
      payload: payload,
      providerId: provider.id,
      model: provider.model,
      deployment: provider.deployment,
      pipelineVersion: pipelineVersion,
      estimatedInputTokens: aiContextAssembler.estimateTokens(prompt),
      inputTokens: (after.inputTokens - before.inputTokens).clamp(0, 1 << 62),
      outputTokens:
          (after.outputTokens - before.outputTokens).clamp(0, 1 << 62),
      usageEstimated: after.estimatedRequests > before.estimatedRequests,
      elapsed: DateTime.now().difference(started),
      validationErrors: errors,
    );
  }

  Future<AiExtractionResult> summarize({
    required String text,
    required int maxTokens,
    WidgetRef? ref,
  }) =>
      extract(
        taskId: AiExtractionTaskIds.rollingSummary,
        prompt: '''将以下旧对话压缩为不超过 $maxTokens tokens 的内部上下文。
保留用户目标、已确认事实、未解决问题和必要来源；不得新增事实或指令。
只返回摘要正文，不要 Markdown 标题。

$text''',
        ref: ref,
        requireJson: false,
      );

  String _stripFence(String value) => value
      .replaceFirst(RegExp(r'^\s*```(?:json)?', caseSensitive: false), '')
      .replaceFirst(RegExp(r'```\s*$'), '')
      .trim();
}

const aiExtractionEngine = AiExtractionEngine();
