import 'dart:convert';

import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/ai_extraction_engine.dart';
import 'package:anx_reader/service/ai/ai_request.dart';
import 'package:anx_reader/service/ai/ai_request_gateway.dart';
import 'package:anx_reader/service/ai/book_wiki_service.dart';
import 'package:anx_reader/service/ai/reading_coach_phase2.dart';
import 'package:anx_reader/service/ai/reading_coach_policy.dart';
import 'package:anx_reader/service/ai/reading_memory_ai_service.dart';
import 'package:anx_reader/service/ai/reading_memory_projection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain_core/chat_models.dart';

class ReadingPracticeCloudConfirmationRequired implements Exception {
  const ReadingPracticeCloudConfirmationRequired();
}

class ReadingPracticeChapter {
  const ReadingPracticeChapter(
      {required this.href, required this.title, required this.content});
  final String href;
  final String title;
  final String content;
}

class ReadingPracticeExecutionPreview {
  const ReadingPracticeExecutionPreview(
      {required this.provider,
      required this.chapterCount,
      required this.estimatedInputTokenLimit,
      required this.maxSourceCharacters});
  final AiProvider? provider;
  final int chapterCount;
  final int estimatedInputTokenLimit;
  final int maxSourceCharacters;
}

/// Execution boundary for explicit reading exercises. Existing memory/coach
/// parsers own domain validation; the shared gateway owns provider execution.
/// No persistence or model work occurs when constructing this service.
class ReadingPracticeAiService {
  ReadingPracticeAiService({
    AiRequestGateway gateway = aiRequestGateway,
    BookWikiService? materialsService,
    AiContextAssembler? assembler,
    ReadingMemoryAiService? memoryParser,
    AiProvider? Function(WidgetRef? ref)? extractionProvider,
    AiProvider? Function(WidgetRef? ref)? generalProvider,
    ReadingWorldState Function()? runtimeState,
  })  : _gateway = gateway,
        _materials = materialsService ?? bookWikiService,
        _assembler = assembler ?? AiContextAssembler(),
        _memory = memoryParser ?? ReadingMemoryAiService(),
        _extractionProvider =
            extractionProvider ?? aiExtractionEngine.resolveProvider,
        _generalProvider = generalProvider ?? gateway.generalProvider,
        _runtimeState = runtimeState ?? (() => readingAgentRuntime.state);

  final AiRequestGateway _gateway;
  final BookWikiService _materials;
  final AiContextAssembler _assembler;
  final ReadingMemoryAiService _memory;
  final AiProvider? Function(WidgetRef? ref) _extractionProvider;
  final AiProvider? Function(WidgetRef? ref) _generalProvider;
  final ReadingWorldState Function() _runtimeState;

  ReadingPracticeExecutionPreview previewGuide(int chapterCount,
          [WidgetRef? ref]) =>
      ReadingPracticeExecutionPreview(
        provider: _generalProvider(ref),
        chapterCount: chapterCount.clamp(1, 6),
        estimatedInputTokenLimit:
            _assembler.budgetFor(AiContextTask.bookContext).maxInputTokens,
        maxSourceCharacters: chapterCount.clamp(1, 6) * 800,
      );

  ReadingPracticeExecutionPreview previewQuiz([WidgetRef? ref]) =>
      ReadingPracticeExecutionPreview(
          provider: _generalProvider(ref),
          chapterCount: 1,
          estimatedInputTokenLimit:
              _assembler.budgetFor(AiContextTask.chapterReview).maxInputTokens,
          maxSourceCharacters: 6000);

  bool topicCloudConfirmationRequired([WidgetRef? ref]) =>
      _extractionProvider(ref) == null;

  Future<List<ReadingMemorySource>> _safeSources(
      int bookId, double boundary, List<ReadingMemorySource> sources) async {
    _checkBoundary(boundary);
    final materials =
        await _materials.loadMaterials(bookId, visibleAtProgress: boundary);
    return sources
        .where((source) =>
            source.bookId == bookId &&
            source.text.trim().isNotEmpty &&
            ReadingMemoryProjection.sourceBoundary(source, materials) != null)
        .toList(growable: false);
  }

  Future<List<ReadingMemoryTopic>> organizeMemory({
    required int bookId,
    required double visibleAtProgress,
    required List<ReadingMemorySource> sources,
    bool allowCloudFallback = false,
    WidgetRef? ref,
  }) async {
    final safe = await _safeSources(bookId, visibleAtProgress, sources);
    if (safe.length < 2) {
      throw const FormatException('At least two visible sources are required');
    }
    final provider = _extractionProvider(ref);
    if (provider == null && !allowCloudFallback) {
      throw const ReadingPracticeCloudConfirmationRequired();
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return _generate(
      workload: provider == null
          ? 'reading_memory.topic_cloud'
          : 'reading_memory.topic_extraction',
      bookId: bookId,
      boundary: visibleAtProgress,
      chapterRefs:
          safe.map((item) => item.chapterHref).nonNulls.toSet().toList(),
      prompt: _memory.topicPrompt(safe),
      correction: '输出 2-8 个主题，每项包含 title、summary 和输入中的 sourceIds。',
      parser: (response) => _memory.parseTopics(response,
          bookId: bookId,
          batchId: '$now',
          allowedSourceIds: safe.map((item) => item.id).toSet(),
          now: now),
      ref: ref,
      providerId: provider?.id,
      providerRole: provider == null
          ? AiProviderRole.general
          : provider.deployment == AiProviderDeployment.localPrivate
              ? AiProviderRole.localExtraction
              : AiProviderRole.cloudExtraction,
    );
  }

  Future<List<ReadingKnowledgeCard>> generateCards({
    required int bookId,
    required double visibleAtProgress,
    required ReadingMemoryTopic topic,
    required List<ReadingMemorySource> sources,
    WidgetRef? ref,
  }) async {
    if (topic.bookId != bookId) throw const FormatException('Foreign topic');
    final safe = await _safeSources(bookId, visibleAtProgress,
        sources.where((item) => topic.sourceIds.contains(item.id)).toList());
    // A mixed/future topic cannot be made safe by silently dropping its sources.
    if (topic.sourceIds.isEmpty ||
        !safe.map((item) => item.id).toSet().containsAll(topic.sourceIds)) {
      throw const FormatException('Topic has unavailable or hidden sources');
    }
    return _generate(
      workload: 'reading_memory.card_generation',
      bookId: bookId,
      boundary: visibleAtProgress,
      chapterRefs:
          safe.map((item) => item.chapterHref).nonNulls.toSet().toList(),
      prompt: _memory.cardPrompt(topic, safe),
      correction: '输出 3-8 张卡片，每项包含 question、answer 和输入中的 sourceIds。',
      parser: (response) => _memory.parseCards(response,
          bookId: bookId,
          topic: topic,
          allowedSourceIds: safe.map((item) => item.id).toSet(),
          now: DateTime.now().millisecondsSinceEpoch),
      ref: ref,
    );
  }

  Future<Map<String, dynamic>> generateGuide({
    required int bookId,
    required String title,
    required String author,
    required String description,
    required List<ReadingPracticeChapter> chapters,
    required bool fullBookSamplesAuthorized,
    ReadingPracticeExecutionPreview? executionPreview,
    WidgetRef? ref,
  }) async {
    if (!fullBookSamplesAuthorized) {
      throw const FormatException(
          'Future chapter samples require authorization');
    }
    if (chapters.isEmpty ||
        chapters.length > 6 ||
        chapters
            .any((item) => item.href.isEmpty || item.content.trim().isEmpty)) {
      throw const FormatException(
          'Expected one to six explicit chapter samples');
    }
    final hrefs = chapters.map((item) => item.href).toSet();
    return _generate(
      workload: 'reading_practice.inspection_guide',
      bookId: bookId,
      boundary: 1,
      chapterRefs: hrefs.toList(),
      prompt: '''根据书籍元数据和明确授权的有限章节样本生成检视阅读向导。
只输出 JSON 对象，不要 Markdown。格式：
{"bookType":"类型","coreQuestion":"核心问题","topics":["主题1","主题2","主题3"],"structure":["结构1","结构2"],"keyChapters":[{"title":"章节名","href":"样本原始href","reason":"原因"}],"plan":["步骤1","步骤2"],"questionOptions":{"whole":["选项1","选项2","选项3"],"detail":["选项1","选项2","选项3"],"truth":["选项1","选项2","选项3"],"relation":["选项1","选项2","选项3"]}}
每组问题 3-5 个具体、短且不重复的选项。不得编造未提供的目录 href，不得把样本推断当成全书事实。
书名：$title
作者：$author
简介：${description.length > 1000 ? description.substring(0, 1000) : description}
授权样本：${jsonEncode(chapters.map((item) => {
                'title': item.title,
                'href': item.href,
                'sample': boundedChapterSample(item.content,
                    headCharacters: 500, tailCharacters: 297)
              }).toList())}''',
      correction: '输出检视向导 JSON，keyChapters 只能引用输入样本的 href。',
      parser: (response) {
        final report = parsePersonalizedGuideResponse(response);
        if ((report['keyChapters'] as List).any(
            (chapter) => chapter is! Map || !hrefs.contains(chapter['href']))) {
          throw const FormatException('Unknown chapter reference');
        }
        return {
          ...report,
          'sourceProgress': 1.0,
          'visibleFromProgress': 1.0,
          'authorizedFutureSamples': true,
          'sourceChapterRefs': hrefs.toList(),
        };
      },
      ref: ref,
      providerId: executionPreview?.provider?.id,
    );
  }

  Future<Map<String, dynamic>> generateSynthesis({
    required int bookId,
    required double visibleAtProgress,
    required String title,
    required String author,
    required InspectionReadingGuide guide,
    required List<ChapterQuiz> quizzes,
    required List<ReadingDifficulty> difficulties,
    WidgetRef? ref,
  }) async {
    _checkBoundary(visibleAtProgress);
    if (guide.bookId != bookId) throw const FormatException('Foreign guide');
    final materials = await _materials.loadMaterials(bookId,
        visibleAtProgress: visibleAtProgress);
    bool visible(String? ref) {
      final progress = materials.sourceBoundaries[ref];
      return progress != null &&
          progress.isFinite &&
          progress <= visibleAtProgress + .000001;
    }

    final evidence = {
      'book': {'title': title, 'author': author, 'goal': guide.goalChoice},
      'activeAnswers':
          guide.answers.map((id, answer) => MapEntry(id, answer.selected)),
      'quizzes': quizzes
          .where((quiz) =>
              quiz.bookId == bookId &&
              quiz.completed &&
              quiz.questions.isNotEmpty &&
              quiz.questions.every((question) {
                final source = question['sourceProgress'];
                final display = question['visibleFromProgress'];
                return source is num &&
                    source.isFinite &&
                    source >= 0 &&
                    display is num &&
                    display.isFinite &&
                    display >= 0 &&
                    question['sourceChapterRef'] == quiz.chapterHref &&
                    source <= visibleAtProgress &&
                    display <= visibleAtProgress;
              }))
          .take(30)
          .map((quiz) =>
              {'chapter': quiz.chapterTitle, 'mastery': quiz.mastery?.name})
          .toList(),
      'difficulties': difficulties
          .where((item) => item.bookId == bookId && visible(item.cfi))
          .take(30)
          .map((item) => {
                'text': item.text,
                'type': item.type.name,
                'status': item.status.name
              })
          .toList(),
    };
    return _generate(
      workload: 'reading_practice.synthesis',
      bookId: bookId,
      boundary: visibleAtProgress,
      prompt: '''根据用户已有的安全阅读记录总结理解变化，不补写用户没有表达的个人观点，不使用已读边界之外的知识。
只输出 JSON 对象：{"summary":"理解变化总结","keyIdeas":["观点1","观点2","观点3"],"actions":["行动1"],"openQuestions":["待核查问题1"]}。
关键观点 3-6 项，行动和待核查问题各 1-4 项。明确区分用户选择和模型归纳。
阅读记录：${jsonEncode(evidence)}''',
      correction: '输出包含 summary、keyIdeas、actions、openQuestions 的 JSON 对象。',
      parser: (response) => {
        ...parseReadingSynthesisResponse(response),
        'sourceProgress': visibleAtProgress,
        'visibleFromProgress': visibleAtProgress,
      },
      ref: ref,
    );
  }

  Future<List<Map<String, dynamic>>> generateQuiz({
    required int bookId,
    required double visibleAtProgress,
    required ChapterQuiz quiz,
    required String content,
    required bool chapterAuthorized,
    ReadingPracticeExecutionPreview? executionPreview,
    WidgetRef? ref,
  }) async {
    _checkBoundary(visibleAtProgress);
    if (quiz.bookId != bookId || !chapterAuthorized || content.trim().isEmpty) {
      throw const FormatException('Chapter authorization required');
    }
    return _generate(
      workload: 'reading_practice.chapter_quiz',
      bookId: bookId,
      // An entire chapter can extend beyond the current exact text position.
      // Independent explicit authorization permits the request, while a
      // conservative bound prevents its derived quiz entering early summaries.
      boundary: 1,
      chapterRefs: [quiz.chapterHref],
      prompt: '''根据明确授权的章节生成 3 道阅读自测题。
只输出 JSON 数组，每项：{"id":"q1","question":"问题","options":["选项1","选项2","选项3","暂不确定"],"correct":["选项1"],"multiple":false}。
问题依次覆盖主旨、论证路径、联系或批评；每题 3-5 个短选项，必须包含“暂不确定”，correct 必须来自 options，不得使用章节外知识。
章节：${quiz.chapterTitle ?? ''}
正文：${content.length > 6000 ? content.substring(0, 6000) : content}''',
      correction:
          '恰好 3 题，id 唯一，包含 question、3-5 个 options、correct、multiple；options 包含“暂不确定”，correct 来自 options。',
      parser: (response) => parseChapterQuizResponse(response)
          .map((question) => {
                ...question,
                'sourceProgress': 1.0,
                'visibleFromProgress': 1.0,
                'sourceChapterRef': quiz.chapterHref,
                'authorizedChapterProcessing': true,
              })
          .toList(growable: false),
      ref: ref,
      providerId: executionPreview?.provider?.id,
    );
  }

  Future<T> _generate<T>({
    required String workload,
    required int bookId,
    required double boundary,
    required String prompt,
    required String correction,
    required T Function(String response) parser,
    List<String> chapterRefs = const [],
    String? providerId,
    AiProviderRole providerRole = AiProviderRole.general,
    WidgetRef? ref,
  }) async {
    final descriptor = AiWorkloadDescriptorRegistry.find(workload)!;
    Future<String> run(String input) {
      if (_assembler.estimateTokens(input) >
          _assembler.budgetFor(descriptor.contextTask).maxInputTokens) {
        throw const FormatException(
            'Practice request exceeds its context budget');
      }
      final world = _runtimeState();
      final messages = _assembler.assemble([ChatMessage.humanText(input)],
          task: descriptor.contextTask,
          cacheScope: 'practice:$bookId:$workload').messages;
      return _gateway.executeText(AiRequest(
        workloadId: workload,
        trace: AiTraceContext(
            workloadId: workload,
            bookId: bookId,
            sessionId: world.bookId == bookId ? world.sessionId : null),
        messages: messages,
        contextTask: descriptor.contextTask,
        providerId: providerId,
        providerRole: providerRole,
        outputContract: descriptor.outputContract,
        fallbackPolicy: AiFallbackPolicy.none,
        failureDelivery: AiFailureDelivery.streamError,
        sourceScope: AiSourceScope(
            bookId: bookId, chapterRefs: chapterRefs, safeBoundary: boundary),
        ref: ref,
      ));
    }

    var response = await run(prompt);
    try {
      return parser(response);
    } on FormatException {
      response = await run('''返回未通过确定性校验。请只输出合法 JSON，不要解释。
$correction
原始任务：$prompt
待纠正返回：$response''');
      return parser(response);
    }
  }

  void _checkBoundary(double value) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw const FormatException('Invalid visible reading boundary');
    }
  }
}
