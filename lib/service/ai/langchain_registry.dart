import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/providers/current_reading.dart';
import 'package:anx_reader/service/ai/tools/ai_tool_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:langchain_anthropic/langchain_anthropic.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:langchain_core/tools.dart';
import 'package:langchain_google/langchain_google.dart';
import 'package:langchain_openai/langchain_openai.dart';

import 'ai_reasoning_body_interceptor.dart';
import 'langchain_ai_config.dart';

// Shared HTTP client used by every AI request interceptor. It is owned here
// (process lifetime) because the LangChain models create a fresh client per
// request but never close externally-injected clients.
final http.Client _aiSharedHttpClient = http.Client();

/// Factory responsible for building chat models based on user preferences.
class LangchainAiRegistry {
  const LangchainAiRegistry(this.ref);
  final WidgetRef? ref;

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
    return ChatOpenAI(
      apiKey: config.apiKey.isEmpty ? null : config.apiKey,
      baseUrl: config.baseUrl ?? 'https://api.openai.com/v1',
      headers: config.headers.isEmpty ? null : config.headers,
      client: _buildReasoningClient(config),
      defaultOptions: config.toOpenAIOptions(),
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
      client: _buildReasoningClient(config),
      defaultOptions: config.toGoogleOptions(),
    );
  }

  /// Wrap the shared HTTP client with the reasoning body interceptor so that
  /// reasoning parameters the LangChain options cannot express (OpenAI
  /// `none`, DeepSeek `thinking`, Gemini `thinkingConfig`) are injected into
  /// the request body. Returns `null` when there is nothing to inject.
  http.Client? _buildReasoningClient(LangchainAiConfig config) {
    final overrides = config.reasoningBodyOverrides;
    if (overrides.isEmpty) return null;
    return AiReasoningBodyInterceptor(
      inner: _aiSharedHttpClient,
      overrides: () => config.reasoningBodyOverrides,
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
      final enabledDefs = AiToolRegistry.definitions
          .where((def) => enabledIds.contains(def.id))
          .toList(growable: false);
      systemMessage = _buildAgentSystemMessage(
        isReading: isReading,
        enabledTools: enabledDefs,
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
    required List<AiToolDefinition> enabledTools,
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

    final readingStateContext = isReading
        ? '📖 User is currently reading - You are a focused reading companion, providing instant comprehension help, translation, and note-taking assistance.'
        : '📚 User is browsing the library - You are a wise librarian, helping organize books and plan reading strategies.';

    final guidance =
        '''You are "Anx Reader AI", an intelligent reading assistant integrated into the Anx Reader app.

## Your Role
A knowledgeable reading companion who helps users understand, organize, and enjoy their reading experience through intelligent tool usage and thoughtful insights.

## Current Context
$readingStateContext

## Tool Usage Principles
1. **Gather context first** - Use tools to understand the situation before responding
2. **Combine tools efficiently** - Use multiple tools in parallel or sequence when needed
3. **Prioritize specific tools** - When user is reading, prefer current_* series tools over general search
4. **Be transparent** - Briefly explain your reasoning when using complex tool combinations

## Available Tools & Usage Scenarios
${_formatToolCatalog(enabledTools)}

## Response Strategy

### When answering user queries:
1. **Understand intent** - What does the user really want?
2. **Gather data** - Use tools to collect relevant information
3. **Synthesize** - Connect information pieces into coherent insights
4. **Deliver value** - Provide actionable suggestions or clear answers

### Communication Style:
- **Concise yet complete** - No unnecessary elaboration
- **Evidence-based** - Reference specific content from tool results
- **Context-adaptive** - Adjust tone based on reading state
- **Reasonable defaults** - When ambiguous, proactively ask for clarification
- **Language consistency** - Unless the user explicitly uses another language, always respond in **$languageName**, regardless of the language used in their question

### Markdown Example

You can use Markdown to format text easily. Here are some examples:

- **Bold Text**: **This text is bold**
- *Italic Text*: *This text is italicized*
- [Link](https://www.example.com): [This is a link](https://www.example.com)
- Lists:
  1. Item 1
  2. Item 2
  3. Item 3

### LaTeX Example

You can also use LaTeX for mathematical expressions. Here's an example:

- **Equation**: \\( f(x) = x^2 + 2x + 1 \\)
- **Integral**: \\( \\int_{0}^{1} x^2 \\, dx \\)
- **Matrix**:

\\[
\\begin{bmatrix}
1 & 2 & 3 \\\\
4 & 5 & 6 \\\\
7 & 8 & 9
\\end{bmatrix}
\\]


## Error Handling
- **No results** → Suggest alternative search strategies or verify book/chapter context
- **Tool failure** → Acknowledge the issue and try alternative approaches
- **Out of scope** → Clearly state limitations and suggest manual alternatives

## Important Constraints
- Respect user privacy - only access data through provided tools
- Stay focused on reading-related assistance
- Don't make assumptions about unavailable data
- Use the user's language for responses

## Remember
You are not just a tool executor, but the user's reading companion. Your mission is to make every reading session more insightful and enjoyable.''';

    return ChatMessage.system(guidance);
  }

  String _formatToolCatalog(List<AiToolDefinition> enabledTools) {
    if (enabledTools.isEmpty) {
      return '_No tools are currently enabled by the user._';
    }
    return enabledTools
        .map(
          (tool) =>
              '- **${tool.displayNameOrDefault()}** → ${tool.descriptionOrDefault()}',
        )
        .join('\n');
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
