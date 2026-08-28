import 'dart:async';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/providers/ai_history.dart';
import 'package:anx_reader/providers/ai_providers.dart';
import 'package:anx_reader/providers/current_reading.dart';
import 'package:anx_reader/service/ai/ai_history.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/service/ai/reading_agent_orchestrator.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_skills.dart';
import 'package:anx_reader/utils/ai_reasoning_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:langchain_core/chat_models.dart';

part 'ai_chat.g.dart';

@Riverpod(keepAlive: true)
class AiChat extends _$AiChat {
  String? _currentSessionId;
  ReadingAiMode? _readingModeOverride;
  ReadingAnalysisRequest? _analysisRequestOverride;

  @override
  FutureOr<List<ChatMessage>> build() async {
    _currentSessionId = null;
    _readingModeOverride = null;
    _analysisRequestOverride = null;
    return List<ChatMessage>.empty();
  }

  Future<void> sendMessage(String message) async {
    state = AsyncData([
      ...state.whenOrNull(data: (data) => data) ?? [],
      ChatMessage.humanText(message),
    ]);
  }

  void restore(List<ChatMessage> history, {String? sessionId}) {
    if (sessionId != null) {
      _currentSessionId = sessionId;
    }
    state = AsyncData(history);
  }

  Stream<List<ChatMessage>> sendMessageStream(
    String message,
    WidgetRef widgetRef,
    bool isRegenerate,
  ) async* {
    final sessionId = _ensureSessionId();
    final selectedProvider = widgetRef
        .read(aiProvidersProvider.notifier)
        .getRunnableSelectedProvider();
    final serviceId = selectedProvider?.id ?? Prefs().selectedAiService;
    final model = selectedProvider?.model.trim() ??
        (Prefs().getAiConfig(serviceId)['model'])?.trim() ??
        '';
    final historyNotifier = widgetRef.read(aiHistoryProvider.notifier);
    final initialHistoryState = widgetRef
        .read(aiHistoryProvider)
        .maybeWhen(data: (value) => value, orElse: () => const []);
    AiChatHistoryEntry? entry;
    for (final item in initialHistoryState) {
      if (item.id == sessionId) {
        entry = item;
        break;
      }
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final reading = widgetRef.read(currentReadingProvider);
    final book = reading.book;
    final readingMode = _readingModeOverride ??
        (book == null
            ? ReadingAiMode.general
            : Prefs().readingAiModeForBook(book.id));
    final analysisRequest = _analysisRequestOverride;
    _analysisRequestOverride = null;
    final readingSkill = book == null
        ? null
        : const ReadingSkillMatcher().match(
            mode: readingMode,
            title: book.title,
            author: book.author,
            description: book.description ?? '',
            chapterTitle: reading.chapterTitle ?? '',
            query: message,
            pinnedSkill: Prefs().readingSkillForBook(book.id),
            deepAnalysis: analysisRequest != null,
            chapterClosure: RegExp(r'章节结束|章节检查|本章回顾|总结本章|chapter review',
                    caseSensitive: false)
                .hasMatch(message),
          );

    List<ChatMessage> messages = [
      ...state.whenOrNull(data: (data) => data) ?? [],
      ChatMessage.humanText(message),
    ];

    state = AsyncData(messages);

    List<ChatMessage> updatedMessages = [
      ...messages,
      ChatMessage.ai(''),
    ];

    final draftEntry = (entry ??
            AiChatHistoryEntry(
              id: sessionId,
              serviceId: serviceId,
              model: model,
              createdAt: entry?.createdAt ?? now,
              updatedAt: now,
              messages: List<ChatMessage>.from(updatedMessages),
              completed: false,
              title: message.split('\n').first.trim(),
              bookId: book?.id,
              bookTitle: book?.title,
              chapterTitle: reading.chapterTitle,
              chapterHref: reading.chapterHref,
              readingMode: readingMode.name,
              analysisDepth: analysisRequest?.depth.name,
              frameworks: analysisRequest?.frameworks
                      .map((framework) => framework.name)
                      .toList(growable: false) ??
                  const <String>[],
              outputTemplate: analysisRequest?.outputTemplate.name,
              readingGoal: analysisRequest?.readingGoal,
              contextSnapshot: book == null
                  ? null
                  : ReadingContextSnapshot(
                      bookId: book.id.toString(),
                      bookTitle: book.title,
                      author: book.author,
                      chapterTitle: reading.chapterTitle,
                      chapterHref: reading.chapterHref,
                      progress: reading.percentage,
                      capturedAt: now,
                      metadata: {'cfi': reading.cfi},
                    ).toJson(),
            ))
        .copyWith(
      messages: List<ChatMessage>.from(updatedMessages),
      updatedAt: now,
      completed: false,
      serviceId: serviceId,
      model: model,
      analysisDepth: analysisRequest?.depth.name,
      frameworks: analysisRequest?.frameworks
          .map((framework) => framework.name)
          .toList(growable: false),
      outputTemplate: analysisRequest?.outputTemplate.name,
      readingGoal: analysisRequest?.readingGoal,
      clearAnalysisResult: analysisRequest != null,
    );

    await historyNotifier.upsert(draftEntry);

    yield updatedMessages;

    String assistantResponse = "";
    var agentTraces = const <AgentRunTrace>[];
    var citations = const <Map<String, dynamic>>[];
    try {
      final turn = reading.isReading
          ? await const ReadingAgentOrchestrator().prepare(
              messages: messages,
              mode: readingMode,
              ref: widgetRef,
              analysisRequest: analysisRequest,
            )
          : ReadingAgentTurn(messages: messages);
      agentTraces = turn.traces;
      citations = turn.citations;
      await for (final chunk in aiGenerateStream(
        turn.messages,
        regenerate: isRegenerate,
        useAgent: true,
        ref: widgetRef,
        readingMode: readingMode,
        readingSkill: readingSkill,
        task: analysisRequest == null
            ? AiContextTask.readingChat
            : AiContextTask.chapterReview,
      )) {
        assistantResponse = chunk;

        final updatedMessagesWithResponse =
            List<ChatMessage>.from(updatedMessages);
        updatedMessagesWithResponse[updatedMessagesWithResponse.length - 1] =
            assistantMessageFromDisplayContent(assistantResponse);

        yield updatedMessagesWithResponse;

        state = AsyncData(updatedMessagesWithResponse);
      }
      final completedEntry = draftEntry.copyWith(
        messages: List<ChatMessage>.from(state.value ?? updatedMessages),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        completed: true,
        model: model,
        readingMode: readingMode.name,
        agentTraces: agentTraces.map((trace) => trace.toJson()).toList(),
        citations: citations,
        analysisResult: analysisRequest == null
            ? null
            : ReadingAnalysisResult(
                request: analysisRequest,
                generatedAt: DateTime.now().millisecondsSinceEpoch,
                summary: assistantResponse,
                citations: citations,
              ).toJson(),
      );
      final assistantIndex =
          (state.value?.length ?? updatedMessages.length) - 1;
      await historyNotifier.upsert(completedEntry);
      unawaited(
        _generateAndSaveTurnTitle(
          entryId: completedEntry.id,
          assistantIndex: assistantIndex,
          question: message,
          answer: assistantResponse,
          widgetRef: widgetRef,
          historyNotifier: historyNotifier,
        ),
      );
    } catch (_) {
      final failedEntry = draftEntry.copyWith(
        messages: List<ChatMessage>.from(state.value ?? updatedMessages),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        completed: false,
        model: model,
        readingMode: readingMode.name,
        agentTraces: agentTraces.map((trace) => trace.toJson()).toList(),
        citations: citations,
      );
      await historyNotifier.upsert(failedEntry);
      rethrow;
    }
  }

  void clear() {
    state = AsyncData(List<ChatMessage>.empty());
    _currentSessionId = null;
    _readingModeOverride = null;
    _analysisRequestOverride = null;
  }

  void loadHistoryEntry(AiChatHistoryEntry entry) {
    _currentSessionId = entry.id;
    _readingModeOverride = ReadingAiMode.fromJson(entry.readingMode);
    _analysisRequestOverride = null;
    state = AsyncData(List<ChatMessage>.from(entry.messages));
  }

  void setReadingModeOverride(ReadingAiMode mode) {
    _readingModeOverride = mode;
  }

  void setReadingAnalysisRequest(ReadingAnalysisRequest request) {
    _analysisRequestOverride = request;
  }

  String? get currentSessionId => _currentSessionId;

  String _ensureSessionId() {
    return _currentSessionId ??= _generateSessionId();
  }

  String _generateSessionId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  Future<String> _generateTurnTitle({
    required String question,
    required String answer,
    required WidgetRef widgetRef,
  }) async {
    final cleanAnswer = cleanAiDisplayText(answer, answerOnly: true);
    try {
      final generated = await aiGenerateText(
        [
          ChatMessage.humanText('''为下面这轮读书对话生成一个简短标题。
要求：只输出标题，不要引号、标签、解释或标点；中文不超过16个字，英文不超过8个词。
问题：${cleanAiDisplayText(question)}
回答：${cleanAnswer.length > 800 ? cleanAnswer.substring(0, 800) : cleanAnswer}'''),
        ],
        useAgent: false,
        ref: widgetRef,
      );
      final title = cleanAiDisplayText(generated, answerOnly: true);
      if (title.isNotEmpty) return title;
    } catch (_) {}
    if (cleanAnswer.isEmpty) return '本轮对话';
    return cleanAnswer.length <= 32
        ? cleanAnswer
        : '${cleanAnswer.substring(0, 32)}…';
  }

  Future<void> _generateAndSaveTurnTitle({
    required String entryId,
    required int assistantIndex,
    required String question,
    required String answer,
    required WidgetRef widgetRef,
    required AiHistoryNotifier historyNotifier,
  }) async {
    final title = await _generateTurnTitle(
      question: question,
      answer: answer,
      widgetRef: widgetRef,
    );
    // Another turn may finish while the title request is running. Merge into
    // the latest entry so the background update never restores stale messages.
    final latest = historyNotifier.findById(entryId);
    if (latest == null) return;
    await historyNotifier.upsert(
      latest.copyWith(
        contextSnapshot: _withTurnTitle(
          latest.contextSnapshot,
          assistantIndex,
          title,
        ),
      ),
    );
  }

  Map<String, dynamic>? _withTurnTitle(
    Map<String, dynamic>? snapshot,
    int assistantIndex,
    String title,
  ) {
    final updated = Map<String, dynamic>.from(snapshot ?? const {});
    final rawTitles = updated['turnTitles'];
    final titles = rawTitles is Map
        ? rawTitles.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};
    titles['$assistantIndex'] = title;
    updated['turnTitles'] = titles;
    return updated;
  }
}
