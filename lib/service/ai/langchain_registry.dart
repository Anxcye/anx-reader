import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/providers/current_reading.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/timeout_http_client.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/service/ai/reading_experience_profile_service.dart';
import 'package:anx_reader/service/ai/reading_skills.dart';
import 'package:anx_reader/service/ai/tools/ai_tool_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:langchain_anthropic/langchain_anthropic.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:langchain_core/tools.dart';
import 'package:langchain_google/langchain_google.dart';
import 'package:langchain_openai/langchain_openai.dart';

import 'langchain_ai_config.dart';

/// Factory responsible for building chat models based on user preferences.
class LangchainAiRegistry {
  const LangchainAiRegistry(
    this.ref, {
    this.readingModeOverride,
    this.readingSkillOverride,
  });
  final WidgetRef? ref;
  final ReadingAiMode? readingModeOverride;
  final ReadingSkillSelection? readingSkillOverride;

  LangchainPipeline resolve(
    LangchainAiConfig config, {
    bool useAgent = false,
  }) {
    switch (config.identifier) {
      case 'claude':
        return _buildPipeline(
          config,
          _buildAnthropic(config),
          useAgent: useAgent,
        );
      case 'gemini':
        return _buildPipeline(
          config,
          _buildGoogle(config),
          useAgent: useAgent,
        );
      case 'deepseek':
      case 'openrouter':
      case 'openai':
      default:
        return _buildPipeline(
          config,
          _buildOpenAi(config),
          useAgent: useAgent,
        );
    }
  }

  /// Resolve pipeline based on AiProtocol enum (for new provider system)
  LangchainPipeline resolveByProtocol(
    AiProtocol protocol,
    LangchainAiConfig config, {
    bool useAgent = false,
  }) {
    switch (protocol) {
      case AiProtocol.claude:
        return _buildPipeline(
          config,
          _buildAnthropic(config),
          useAgent: useAgent,
        );
      case AiProtocol.gemini:
        return _buildPipeline(
          config,
          _buildGoogle(config),
          useAgent: useAgent,
        );
      case AiProtocol.openai:
        return _buildPipeline(
          config,
          _buildOpenAi(config),
          useAgent: useAgent,
        );
    }
  }

  BaseChatModel _buildOpenAi(LangchainAiConfig config) {
    final httpClient = config.requestTimeoutSeconds > 0
        ? TimeoutHttpClient(
            http.Client(),
            timeout: Duration(seconds: config.requestTimeoutSeconds),
          )
        : null;

    return ChatOpenAI(
      apiKey: config.apiKey.isEmpty ? null : config.apiKey,
      baseUrl: config.baseUrl ?? 'https://api.openai.com/v1',
      headers: config.headers.isEmpty ? null : config.headers,
      defaultOptions: config.toOpenAIOptions(),
      client: httpClient,
    );
  }

  BaseChatModel _buildAnthropic(LangchainAiConfig config) {
    return ChatAnthropic(
      apiKey: config.apiKey.isEmpty ? null : config.apiKey,
      baseUrl: config.baseUrl ?? 'https://api.anthropic.com/v1',
      headers: config.headers.isEmpty ? null : config.headers,
      defaultOptions: config.toAnthropicOptions(),
    );
  }

  BaseChatModel _buildGoogle(LangchainAiConfig config) {
    return ChatGoogleGenerativeAI(
      apiKey: config.apiKey.isEmpty ? null : config.apiKey,
      baseUrl: config.baseUrl,
      headers: config.headers.isEmpty ? null : config.headers,
      defaultOptions: config.toGoogleOptions(),
    );
  }

  LangchainPipeline _buildPipeline(
    LangchainAiConfig config,
    BaseChatModel model, {
    required bool useAgent,
  }) {
    if (useAgent) {
      assert(ref != null, 'ref must be provided when useAgent is true');
    }

    final isReading =
        useAgent && ref != null && ref!.read(currentReadingProvider).isReading;

    var tools = const <Tool>[];
    ChatMessage? systemMessage;

    if (useAgent) {
      final enabledIds = Prefs().enabledAiToolIds;
      final toolContext = AiToolContext(ref: ref!);
      tools = AiToolRegistry.buildTools(toolContext, enabledIds);
      final currentBook =
          isReading ? ref!.read(currentReadingProvider).book : null;
      final resolvedMode = readingModeOverride ??
          (currentBook == null
              ? ReadingAiMode.general
              : Prefs().readingAiModeForBook(currentBook.id));
      final closurePolicy = currentBook == null
          ? null
          : const ReadingClosurePolicyMatcher().match(
              mode: resolvedMode,
              title: currentBook.title,
              author: currentBook.author,
              description: currentBook.description ?? '',
              pinnedId: readingExperienceProfileService
                  .pinnedModuleId(currentBook.id),
            );
      systemMessage = _buildAgentSystemMessage(
        isReading: isReading,
        readingMode: resolvedMode,
        readingSkill: readingSkillOverride,
        closurePolicy: closurePolicy,
      );
    }

    return LangchainPipeline(
      model: model,
      tools: tools,
      systemMessage: systemMessage,
    );
  }

  ChatMessage _buildAgentSystemMessage({
    required bool isReading,
    required ReadingAiMode readingMode,
    ReadingSkillSelection? readingSkill,
    ReadingClosurePolicyDefinition? closurePolicy,
  }) {
    final currentLanguageCode =
        Prefs().locale?.languageCode ?? Platform.localeName;

    // Map language code to language name
    final languageMap = {
      'zh': '简体中文',
      'zh-CN': '简体中文',
      'zh-Hans': '简体中文',
      'zh-TW': '繁體中文',
      'zh-Hant': '繁體中文',
      'en': 'English',
      'ja': '日本語',
      'ko': '한국어',
      'fr': 'Français',
      'de': 'Deutsch',
      'es': 'Español',
      'ru': 'Русский',
      'ar': 'العربية',
      'tr': 'Türkçe',
    };

    final languageName = languageMap[currentLanguageCode] ??
        languageMap[currentLanguageCode.split('_').first] ??
        currentLanguageCode;

    final profile = readingMode.agentProfile;
    final readingAgentContext = Prefs().readingAgentBetaEnabled && isReading
        ? _cachedReadingAgentContext(readingAgentRuntime.state)
        : '';
    final readingSkillContext = readingSkill == null
        ? ''
        : '## Active Reading Method\n${readingSkill.promptContext()}';
    final closureContext = closurePolicy == null
        ? ''
        : '## Reading Closure Policy\n'
            'Closure: ${closurePolicy.title}\n'
            'Closure guidance: ${closurePolicy.systemGuidance}';
    final core = aiContextAssembler.cachedFragment(
      scope: 'agent-system-core',
      fingerprint:
          '$languageName:${readingMode.name}:$isReading:${profile.systemPrompt.hashCode}:${profile.safetyPrompt.hashCode}',
      create: () =>
          '''You are Anx Reader AI, a concise, evidence-based reading companion.

## Current role
${isReading ? 'The user is reading. Help with comprehension, translation, notes, and reading actions.' : 'The user is browsing the library. Help organize books and reading strategy.'}
Reading mode: ${readingMode.name}
Mode guidance: ${profile.systemPrompt}
Safety boundary: ${profile.safetyPrompt}
Respond in $languageName unless the user explicitly requests another language.

## Context and tools
Use layered context: selection and adjacent text first, then chapter/book metadata. Read chapter text, TOC, notes, or other chapters through tools only when needed. Tool schemas are already supplied separately; do not invent unavailable data or imply the whole book was uploaded. Prefer current-reading tools over broad search and briefly disclose material tool use.

## Authority
Page turns, dwell time, rereading, and chapter changes never authorize a model request or persistent write. Execute a write only after an explicit save/create/mark request; proactive ideas require confirmation. Never treat profile candidates or model inferences as confirmed user facts. On missing evidence or tool failure, state the limitation and use a safe fallback.''',
    );
    final guidance = aiContextAssembler.composeSections([
      core,
      readingAgentContext,
      readingSkillContext,
      closureContext,
    ]);

    return ChatMessage.system(guidance);
  }

  String _cachedReadingAgentContext(ReadingWorldState state) {
    final fingerprint = [
      state.bookId,
      state.chapterHref,
      state.cfi,
      state.totalProgress.toStringAsFixed(4),
      state.chapterProgress.toStringAsFixed(4),
      state.activeGoal?.id,
      state.activeGoal?.updatedAt,
      state.unresolvedDifficultyCount,
      state.pendingCheckpointCount,
      state.dueKnowledgeCardCount,
      state.masterySummary.hashCode,
      state.markdownMemorySummary.hashCode,
      state.confirmedProfileSummary.hashCode,
      state.selection?.cfi,
      state.selection?.text.hashCode,
    ].join(':');
    return aiContextAssembler.cachedFragment(
      scope: 'reading-world:${state.bookId ?? 'none'}',
      fingerprint: fingerprint,
      create: () => _formatReadingAgentContext(state),
    );
  }

  String _formatReadingAgentContext(ReadingWorldState state) {
    if (!state.isUsableForAgent) return '';
    final selection = state.selection;
    return '''

## Reading World State (local snapshot)
- Book: ${state.bookTitle ?? ''} (id: ${state.bookId})
- Chapter: ${state.chapterTitle ?? ''} (${state.chapterHref ?? ''})
- CFI: ${state.cfi ?? ''}
- Total progress: ${(state.totalProgress * 100).toStringAsFixed(1)}%
- Chapter progress: ${(state.chapterProgress * 100).toStringAsFixed(1)}%
- Active goal: ${state.activeGoal?.title ?? 'none'}
- Unresolved difficulties: ${state.unresolvedDifficultyCount}
- Pending chapter checks: ${state.pendingCheckpointCount}
- Due knowledge cards: ${state.dueKnowledgeCardCount}
- Mastery: ${state.masterySummary}
- Markdown memory documents: ${state.markdownMemorySummary}
- Confirmed reader profile: ${state.confirmedProfileSummary}
${selection == null ? '- Selection: none' : '- Selection: active at ${selection.cfi} (${selection.text.length} characters)'}
Only confirmed profile values above are user context. Pending profile candidates are intentionally excluded.
''';
  }
}

class LangchainPipeline {
  const LangchainPipeline({
    required this.model,
    required this.tools,
    this.systemMessage,
  });

  final BaseChatModel model;
  final List<Tool> tools;
  final ChatMessage? systemMessage;
}
