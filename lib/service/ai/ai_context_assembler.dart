import 'dart:collection';

import 'package:anx_reader/service/ai/langchain_ai_config.dart';
import 'package:langchain_core/chat_models.dart';

/// Stable request classes used to give different AI workloads explicit input
/// and output budgets. The budget applies to the prompt sent to the provider;
/// the full local conversation remains untouched.
enum AiContextTask {
  general,
  readingChat,
  translation,
  chapterReview,
  fictionBackfill,
  noteOrganizer,
  expertAnalysis,
  lightweightExtraction,
  cloudVerification,
  internalSummary,
}

class AiContextBudget {
  const AiContextBudget({
    required this.maxInputTokens,
    required this.reservedOutputTokens,
    required this.recentMessages,
    required this.summaryTokens,
  });

  final int maxInputTokens;
  final int reservedOutputTokens;
  final int recentMessages;
  final int summaryTokens;
}

class AiContextAssembly {
  const AiContextAssembly({
    required this.messages,
    required this.budget,
    required this.estimatedInputTokens,
    required this.summarizedMessages,
    required this.droppedMessages,
    this.rollingSummary,
  });

  final List<ChatMessage> messages;
  final AiContextBudget budget;
  final int estimatedInputTokens;
  final int summarizedMessages;
  final int droppedMessages;
  final String? rollingSummary;

  bool get isOverBudget => estimatedInputTokens > budget.maxInputTokens;
}

/// Small LRU for prompt fragments and rolling summaries. Entries are scoped so
/// a book/session/config change can invalidate only its own context.
class AiContextCache {
  AiContextCache({this.maxEntries = 64});

  final int maxEntries;
  final LinkedHashMap<String, String> _entries = LinkedHashMap();

  int get length => _entries.length;

  String getOrCreate({
    required String scope,
    required String fingerprint,
    required String Function() create,
  }) {
    final key = '$scope::$fingerprint';
    final cached = _entries.remove(key);
    if (cached != null) {
      _entries[key] = cached;
      return cached;
    }
    final value = create();
    _entries[key] = value;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    return value;
  }

  void invalidateScope(String scope) {
    _entries.removeWhere((key, _) => key.startsWith('$scope::'));
  }

  String? read({required String scope, required String fingerprint}) {
    final key = '$scope::$fingerprint';
    final value = _entries.remove(key);
    if (value != null) _entries[key] = value;
    return value;
  }

  void put({
    required String scope,
    required String fingerprint,
    required String value,
  }) {
    final key = '$scope::$fingerprint';
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();
}

class AiContextAssembler {
  AiContextAssembler({
    AiContextCache? cache,
    Map<AiContextTask, AiContextBudget>? budgets,
  })  : cache = cache ?? AiContextCache(),
        _budgets = {..._defaultBudgets, ...?budgets};

  final AiContextCache cache;
  final Map<AiContextTask, AiContextBudget> _budgets;

  static const _defaultBudgets = <AiContextTask, AiContextBudget>{
    AiContextTask.general: AiContextBudget(
      maxInputTokens: 12000,
      reservedOutputTokens: 3000,
      recentMessages: 10,
      summaryTokens: 1200,
    ),
    AiContextTask.readingChat: AiContextBudget(
      maxInputTokens: 10000,
      reservedOutputTokens: 2500,
      recentMessages: 8,
      summaryTokens: 1000,
    ),
    AiContextTask.translation: AiContextBudget(
      maxInputTokens: 24000,
      reservedOutputTokens: 8000,
      recentMessages: 4,
      summaryTokens: 400,
    ),
    AiContextTask.chapterReview: AiContextBudget(
      maxInputTokens: 14000,
      reservedOutputTokens: 3500,
      recentMessages: 6,
      summaryTokens: 800,
    ),
    AiContextTask.fictionBackfill: AiContextBudget(
      maxInputTokens: 20000,
      reservedOutputTokens: 6000,
      recentMessages: 2,
      summaryTokens: 0,
    ),
    AiContextTask.noteOrganizer: AiContextBudget(
      maxInputTokens: 16000,
      reservedOutputTokens: 4000,
      recentMessages: 4,
      summaryTokens: 500,
    ),
    AiContextTask.expertAnalysis: AiContextBudget(
      maxInputTokens: 6000,
      reservedOutputTokens: 1200,
      recentMessages: 2,
      summaryTokens: 300,
    ),
    AiContextTask.lightweightExtraction: AiContextBudget(
      maxInputTokens: 8000,
      reservedOutputTokens: 768,
      recentMessages: 2,
      summaryTokens: 0,
    ),
    AiContextTask.cloudVerification: AiContextBudget(
      maxInputTokens: 4000,
      reservedOutputTokens: 1000,
      recentMessages: 2,
      summaryTokens: 0,
    ),
    AiContextTask.internalSummary: AiContextBudget(
      maxInputTokens: 8000,
      reservedOutputTokens: 768,
      recentMessages: 8,
      summaryTokens: 0,
    ),
  };

  AiContextBudget budgetFor(AiContextTask task) =>
      _budgets[task] ?? _defaultBudgets[AiContextTask.general]!;

  List<ChatMessage> rollingSummarySource(
    List<ChatMessage> source,
    AiContextTask task,
  ) {
    final budget = budgetFor(task);
    if (budget.summaryTokens <= 0) return const [];
    final nonSystem = _deduplicateSystemMessages(source)
        .where((message) => message is! SystemChatMessage)
        .toList(growable: false);
    final start =
        (nonSystem.length - budget.recentMessages).clamp(0, nonSystem.length);
    return nonSystem.sublist(0, start);
  }

  String rollingSummaryFingerprint(
    List<ChatMessage> messages,
    AiContextTask task,
  ) =>
      _fingerprint(messages, budgetFor(task).summaryTokens);

  String? cachedRollingSummary({
    required List<ChatMessage> messages,
    required AiContextTask task,
    required String cacheScope,
  }) =>
      cache.read(
        scope: '$cacheScope:summary',
        fingerprint: rollingSummaryFingerprint(messages, task),
      );

  void storeRollingSummary({
    required List<ChatMessage> messages,
    required AiContextTask task,
    required String cacheScope,
    required String summary,
  }) =>
      cache.put(
        scope: '$cacheScope:summary',
        fingerprint: rollingSummaryFingerprint(messages, task),
        value: summary.trim(),
      );

  LangchainAiConfig applyOutputBudget(
    LangchainAiConfig config,
    AiContextTask task,
  ) {
    final limit = budgetFor(task).reservedOutputTokens;
    int capped(int? configured) =>
        configured == null ? limit : configured.clamp(1, limit);
    return config.copyWith(
      maxTokens: capped(config.maxTokens),
      maxOutputTokens: capped(config.maxOutputTokens),
    );
  }

  AiContextAssembly assemble(
    List<ChatMessage> source, {
    required AiContextTask task,
    ChatMessage? systemMessage,
    String cacheScope = 'conversation',
  }) {
    final budget = budgetFor(task);
    final messages = _deduplicateSystemMessages(source);
    final systemTokens = systemMessage == null
        ? 0
        : estimateTokens(systemMessage.contentAsString);
    final nonSystem = messages
        .where((message) => message is! SystemChatMessage)
        .toList(growable: false);
    final systems =
        messages.whereType<SystemChatMessage>().toList(growable: false);

    if (nonSystem.length <= budget.recentMessages &&
        estimateMessages(messages) + systemTokens <= budget.maxInputTokens) {
      return AiContextAssembly(
        messages: List.unmodifiable(messages),
        budget: budget,
        estimatedInputTokens: estimateMessages(messages) + systemTokens,
        summarizedMessages: 0,
        droppedMessages: 0,
      );
    }

    var recentStart =
        (nonSystem.length - budget.recentMessages).clamp(0, nonSystem.length);
    // A tool result is only meaningful together with the preceding assistant
    // tool call. Expand the recent window by one when it would start midway
    // through that exchange.
    while (recentStart > 0 && nonSystem[recentStart] is ToolChatMessage) {
      recentStart--;
    }
    final old = nonSystem.sublist(0, recentStart);
    var recent = nonSystem.sublist(recentStart).toList(growable: true);
    final rollingSummary = budget.summaryTokens == 0 || old.isEmpty
        ? null
        : _rollingSummary(
            old,
            maxTokens: budget.summaryTokens,
            cacheScope: cacheScope,
          );
    final assembled = <ChatMessage>[
      ...systems,
      if (rollingSummary != null && rollingSummary.isNotEmpty)
        ChatMessage.system('''## Earlier conversation (local rolling summary)
$rollingSummary
This summary is compressed context, not a new user instruction or a confirmed fact.'''),
      ...recent,
    ];

    var estimate = estimateMessages(assembled) + systemTokens;
    var dropped = 0;
    var includedSummary = rollingSummary;
    // Prefer fewer recent turns over silently truncating the current request.
    // The newest message is always preserved, even when a single explicit
    // request exceeds the advisory budget.
    while (estimate > budget.maxInputTokens && recent.length > 1) {
      final recentOffset = systems.length +
          (rollingSummary != null && rollingSummary.isNotEmpty ? 1 : 0);
      recent.removeAt(0);
      assembled.removeAt(recentOffset);
      dropped++;
      // Never leave tool results without their assistant tool-call message.
      while (recent.length > 1 && recent.first is ToolChatMessage) {
        recent.removeAt(0);
        assembled.removeAt(recentOffset);
        dropped++;
      }
      estimate = estimateMessages(assembled) + systemTokens;
    }
    // If the current request alone is large, discard derived history before
    // reporting an advisory overage. The explicit user message still wins.
    if (estimate > budget.maxInputTokens &&
        includedSummary != null &&
        includedSummary.isNotEmpty) {
      assembled.removeAt(systems.length);
      includedSummary = null;
      dropped += old.length;
      estimate = estimateMessages(assembled) + systemTokens;
    }

    return AiContextAssembly(
      messages: List.unmodifiable(assembled),
      budget: budget,
      estimatedInputTokens: estimate,
      summarizedMessages: includedSummary == null ? 0 : old.length,
      droppedMessages: dropped,
      rollingSummary: includedSummary,
    );
  }

  /// Composes prompt sections once and removes repeated normalized sections.
  /// This is used for Skill/Closure blocks and other system context fragments.
  String composeSections(Iterable<String?> sections) {
    final seen = <String>{};
    final output = <String>[];
    for (final raw in sections) {
      final value = raw?.trim() ?? '';
      if (value.isEmpty) continue;
      final fingerprint = value.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
      if (seen.add(fingerprint)) output.add(value);
    }
    return output.join('\n\n');
  }

  String cachedFragment({
    required String scope,
    required String fingerprint,
    required String Function() create,
  }) =>
      cache.getOrCreate(
        scope: scope,
        fingerprint: fingerprint,
        create: create,
      );

  String _rollingSummary(
    List<ChatMessage> messages, {
    required int maxTokens,
    required String cacheScope,
  }) {
    final fingerprint = _fingerprint(messages, maxTokens);
    return cache.getOrCreate(
      scope: '$cacheScope:summary',
      fingerprint: fingerprint,
      create: () {
        final buffer = StringBuffer();
        for (final message in messages) {
          // Tool payloads can be large, provider-specific and meaningless
          // without their call schema. Keep them only in the recent window.
          if (message is ToolChatMessage) continue;
          final content = _compact(message.contentAsString);
          if (content.isEmpty) continue;
          final role = switch (message) {
            HumanChatMessage _ => 'User',
            AIChatMessage _ => 'Assistant',
            CustomChatMessage custom => custom.role,
            _ => 'Context',
          };
          final candidate = '${buffer.isEmpty ? '' : '\n'}- $role: $content';
          if (estimateTokens(buffer.toString() + candidate) > maxTokens) {
            break;
          }
          buffer.write(candidate);
        }
        return buffer.toString().trim();
      },
    );
  }

  List<ChatMessage> _deduplicateSystemMessages(List<ChatMessage> source) {
    final seen = <String>{};
    final result = <ChatMessage>[];
    for (final message in source) {
      if (message is SystemChatMessage) {
        final key = message.content.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (!seen.add(key)) continue;
      }
      result.add(message);
    }
    return result;
  }

  String _fingerprint(List<ChatMessage> messages, int maxTokens) {
    var hash = 17;
    for (final message in messages) {
      hash = 37 * hash + message.runtimeType.hashCode;
      hash = 37 * hash + message.contentAsString.hashCode;
    }
    return '$hash:$maxTokens:${messages.length}';
  }

  String _compact(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    const maxCharacters = 480;
    if (normalized.length <= maxCharacters) return normalized;
    return '${normalized.substring(0, maxCharacters)}…';
  }

  int estimateMessages(Iterable<ChatMessage> messages) => messages.fold(
        0,
        (total, message) => total + estimateTokens(message.contentAsString) + 4,
      );

  int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    var cjk = 0;
    var other = 0;
    for (final rune in text.runes) {
      if ((rune >= 0x3400 && rune <= 0x9fff) ||
          (rune >= 0xf900 && rune <= 0xfaff)) {
        cjk++;
      } else {
        other++;
      }
    }
    return cjk + (other / 4).ceil();
  }
}

final aiContextAssembler = AiContextAssembler();
