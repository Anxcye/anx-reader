import 'dart:convert';

import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/models/book_materials.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/service/ai/ai_request.dart';
import 'package:anx_reader/service/ai/ai_request_gateway.dart';
import 'package:anx_reader/service/ai/book_wiki_service.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/service/ai/reading_outcomes_service.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:anx_reader/service/ai/reading_practice_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeGateway extends AiRequestGateway {
  final List<AiRequest> requests = [];
  final List<Object> responses = [];
  @override
  Future<String> executeText(AiRequest request) async {
    requests.add(request);
    final result = responses.removeAt(0);
    if (result is String) return result;
    throw result;
  }
}

class SafeMaterials extends BookWikiService {
  var loads = 0;
  @override
  Future<BookMaterialsSnapshot> loadMaterials(int bookId,
      {required double visibleAtProgress,
      ReadingClosurePolicyDefinition? closure,
      ReadingOutcomesSnapshot? outcomes,
      String? currentCfi}) async {
    loads++;
    return BookMaterialsSnapshot(
        bookId: bookId,
        visibleAtProgress: visibleAtProgress,
        sourceBoundaries: const {'cfi1': .2, 'cfi2': .3, 'late': .8});
  }
}

ReadingMemorySource source(String id, String cfi, {int bookId = 1}) =>
    ReadingMemorySource(
        id: id,
        bookId: bookId,
        type: ReadingMemorySourceType.difficulty,
        cfi: cfi,
        chapterHref: '$id.xhtml',
        text: 'Exact text $id',
        contentHash: id,
        createdAt: 1);

const local = AiProvider(
    id: 'local',
    title: 'Local engine',
    url: 'http://localhost:9000',
    protocol: AiProtocol.openai,
    deployment: AiProviderDeployment.localPrivate);

String topics() => jsonEncode([
      {
        'title': 'One',
        'summary': 'First',
        'sourceIds': ['s1']
      },
      {
        'title': 'Two',
        'summary': 'Second',
        'sourceIds': ['s2']
      },
    ]);

String guide({String href = 'one.xhtml'}) => jsonEncode({
      'bookType': 'Essay',
      'coreQuestion': 'What is the argument?',
      'topics': ['One', 'Two', 'Three'],
      'structure': ['First', 'Then'],
      'keyChapters': [
        {'title': 'One', 'href': href, 'reason': 'The main argument'}
      ],
      'plan': ['Read', 'Reflect'],
      'questionOptions': {
        for (final key in ['whole', 'detail', 'truth', 'relation'])
          key: ['Option 1', 'Option 2', 'Option 3']
      }
    });

String quiz() => jsonEncode([
      for (var i = 1; i <= 3; i++)
        {
          'id': 'q$i',
          'question': 'Question $i',
          'options': ['Answer $i', 'Alternative $i', '暂不确定'],
          'correct': ['Answer $i'],
          'multiple': false,
        }
    ]);

void main() {
  test('constructing the exercise service is quiet', () {
    final gateway = FakeGateway();
    final materials = SafeMaterials();
    ReadingPracticeAiService(gateway: gateway, materialsService: materials);
    expect(gateway.requests, isEmpty);
    expect(materials.loads, 0);
  });

  test('execution preview is local, bounded and pins the disclosed provider',
      () async {
    final gateway = FakeGateway()..responses.add(quiz());
    final service = ReadingPracticeAiService(
        gateway: gateway,
        generalProvider: (_) => local,
        runtimeState: () =>
            const ReadingWorldState(bookId: 2, sessionId: 'other-book'));
    final guidePreview = service.previewGuide(12);
    expect(guidePreview.chapterCount, 6);
    expect(guidePreview.maxSourceCharacters, 4800);
    expect(guidePreview.estimatedInputTokenLimit, 8000);
    final preview = service.previewQuiz();
    expect(preview.provider?.id, 'local');
    expect(preview.maxSourceCharacters, 6000);
    expect(gateway.requests, isEmpty);
    await service.generateQuiz(
        bookId: 1,
        visibleAtProgress: .4,
        quiz: const ChapterQuiz(
            id: 'q', bookId: 1, chapterHref: 'one.xhtml', updatedAt: 1),
        content: '${'已' * 6000}unapproved-tail',
        chapterAuthorized: true,
        executionPreview: preview);
    expect(gateway.requests.single.providerId, preview.provider?.id);
    expect(gateway.requests.single.trace.sessionId, isNull);
    expect(
        gateway.requests.single.messages
            .map((item) => item.contentAsString)
            .join(),
        isNot(contains('unapproved-tail')));
  });

  test(
      'topic work routes through the registered local workload and retries once',
      () async {
    final gateway = FakeGateway()..responses.addAll(['not JSON', topics()]);
    final service = ReadingPracticeAiService(
        gateway: gateway,
        materialsService: SafeMaterials(),
        runtimeState: () =>
            const ReadingWorldState(bookId: 1, sessionId: 'session'),
        extractionProvider: (_) => local);
    final result = await service.organizeMemory(
        bookId: 1,
        visibleAtProgress: .4,
        sources: [
          source('s1', 'cfi1'),
          source('s2', 'cfi2'),
          source('future', 'late')
        ]);
    expect(result.map((item) => item.title), ['One', 'Two']);
    expect(gateway.requests, hasLength(2));
    for (final request in gateway.requests) {
      expect(request.workloadId, 'reading_memory.topic_extraction');
      expect(AiWorkloadDescriptorRegistry.find(request.workloadId), isNotNull);
      expect(request.providerId, 'local');
      expect(request.providerRole, AiProviderRole.localExtraction);
      expect(request.sourceScope?.bookId, 1);
      expect(request.sourceScope?.safeBoundary, .4);
      expect(request.sourceScope?.chapterRefs, ['s1.xhtml', 's2.xhtml']);
      expect(request.outputContract.kind, AiOutputKind.json);
      expect(request.fallbackPolicy, AiFallbackPolicy.none);
      expect(request.trace.requestId, isNotEmpty);
      expect(request.trace.bookId, 1);
      expect(request.trace.sessionId, 'session');
      expect(request.trace.taskId, isNull);
      expect(request.messages.map((m) => m.contentAsString).join(),
          isNot(contains('Exact text future')));
    }
    expect(gateway.requests[0].trace.requestId,
        isNot(gateway.requests[1].trace.requestId));
  });

  test('missing extraction requires one-request cloud permission', () async {
    final gateway = FakeGateway()..responses.add(topics());
    final service = ReadingPracticeAiService(
        gateway: gateway,
        materialsService: SafeMaterials(),
        extractionProvider: (_) => null);
    final sources = [source('s1', 'cfi1'), source('s2', 'cfi2')];
    await expectLater(
        service.organizeMemory(
            bookId: 1, visibleAtProgress: .4, sources: sources),
        throwsA(isA<ReadingPracticeCloudConfirmationRequired>()));
    expect(gateway.requests, isEmpty);
    await service.organizeMemory(
        bookId: 1,
        visibleAtProgress: .4,
        sources: sources,
        allowCloudFallback: true);
    expect(gateway.requests.single.workloadId, 'reading_memory.topic_cloud');
    expect(gateway.requests.single.providerRole, AiProviderRole.general);
    expect(gateway.requests.single.allowAutomaticFallback, isFalse);
  });

  test('a local transport failure never switches providers or repeats work',
      () async {
    final gateway = FakeGateway()..responses.add(StateError('offline'));
    final service = ReadingPracticeAiService(
        gateway: gateway,
        materialsService: SafeMaterials(),
        extractionProvider: (_) => local);
    await expectLater(
        service.organizeMemory(
            bookId: 1,
            visibleAtProgress: .4,
            sources: [source('s1', 'cfi1'), source('s2', 'cfi2')]),
        throwsStateError);
    expect(gateway.requests, hasLength(1));
    expect(gateway.requests.single.providerId, 'local');
  });

  test('mixed-source topics cannot silently discard hidden evidence', () async {
    final gateway = FakeGateway();
    final service = ReadingPracticeAiService(
        gateway: gateway, materialsService: SafeMaterials());
    await expectLater(
        service.generateCards(
            bookId: 1,
            visibleAtProgress: .4,
            topic: const ReadingMemoryTopic(
                id: 't',
                bookId: 1,
                title: 'Mixed',
                summary: 'Future inference',
                sourceIds: ['s1', 'future'],
                status: ReadingMemoryItemStatus.kept,
                batchId: 'b',
                createdAt: 1,
                updatedAt: 1),
            sources: [source('s1', 'cfi1'), source('future', 'late')]),
        throwsFormatException);
    expect(gateway.requests, isEmpty);
  });

  test(
      'guide requires explicit future-sample scope and validates returned hrefs',
      () async {
    final gateway = FakeGateway()
      ..responses.addAll([guide(href: 'invented.xhtml'), guide()]);
    final service = ReadingPracticeAiService(gateway: gateway);
    const chapters = [
      ReadingPracticeChapter(
          href: 'one.xhtml', title: 'One', content: 'Authorized sample')
    ];
    await expectLater(
        service.generateGuide(
            bookId: 1,
            title: 'Book',
            author: 'Author',
            description: '',
            chapters: chapters,
            fullBookSamplesAuthorized: false),
        throwsFormatException);
    expect(gateway.requests, isEmpty);
    final result = await service.generateGuide(
        bookId: 1,
        title: 'Book',
        author: 'Author',
        description: '',
        chapters: chapters,
        fullBookSamplesAuthorized: true);
    expect(gateway.requests, hasLength(2));
    expect(
        gateway.requests.last.workloadId, 'reading_practice.inspection_guide');
    expect(gateway.requests.last.sourceScope?.safeBoundary, 1);
    expect(gateway.requests.last.sourceScope?.chapterRefs, ['one.xhtml']);
    expect(result['visibleFromProgress'], 1);
    expect(result['authorizedFutureSamples'], true);
  });

  test(
      'quiz scope is explicit and derived questions retain conservative boundary',
      () async {
    final gateway = FakeGateway()..responses.addAll(['[]', quiz()]);
    final service = ReadingPracticeAiService(gateway: gateway);
    const input = ChapterQuiz(
        id: 'q',
        bookId: 1,
        chapterHref: 'one.xhtml',
        chapterTitle: 'One',
        updatedAt: 1);
    await expectLater(
        service.generateQuiz(
            bookId: 1,
            visibleAtProgress: .4,
            quiz: input,
            content: 'Chapter text',
            chapterAuthorized: false),
        throwsFormatException);
    expect(gateway.requests, isEmpty);
    final result = await service.generateQuiz(
        bookId: 1,
        visibleAtProgress: .4,
        quiz: input,
        content: 'Chapter text',
        chapterAuthorized: true);
    expect(gateway.requests, hasLength(2));
    expect(gateway.requests.last.workloadId, 'reading_practice.chapter_quiz');
    expect(gateway.requests.last.sourceScope?.safeBoundary, 1);
    expect(result, hasLength(3));
    expect(
        result.every((item) =>
            item['visibleFromProgress'] == 1 &&
            item['sourceChapterRef'] == 'one.xhtml'),
        isTrue);
  });

  test('second validation failure stops without unbounded repair calls',
      () async {
    final gateway = FakeGateway()..responses.addAll(['[]', '[]']);
    final service = ReadingPracticeAiService(gateway: gateway);
    await expectLater(
        service.generateQuiz(
            bookId: 1,
            visibleAtProgress: .4,
            quiz: const ChapterQuiz(
                id: 'q', bookId: 1, chapterHref: 'one.xhtml', updatedAt: 1),
            content: 'Text',
            chapterAuthorized: true),
        throwsFormatException);
    expect(gateway.requests, hasLength(2));
  });

  test(
      'synthesis excludes hidden records and previously authorized future guides',
      () async {
    final gateway = FakeGateway()
      ..responses.add(jsonEncode({
        'summary': 'My understanding',
        'keyIdeas': ['One', 'Two', 'Three'],
        'actions': ['Read more'],
        'openQuestions': ['Why?']
      }));
    final service = ReadingPracticeAiService(
        gateway: gateway, materialsService: SafeMaterials());
    final result = await service.generateSynthesis(
        bookId: 1,
        visibleAtProgress: .4,
        title: 'Book',
        author: 'Author',
        guide: const InspectionReadingGuide(
            bookId: 1, updatedAt: 1, report: {'secret': 'Future guide text'}),
        quizzes: const [
          ChapterQuiz(
              id: 'old',
              bookId: 1,
              chapterHref: 'one.xhtml',
              chapterTitle: 'Unknown old quiz',
              completed: true,
              updatedAt: 1)
        ],
        difficulties: const [
          ReadingDifficulty(
              id: 'safe',
              bookId: 1,
              cfi: 'cfi1',
              text: 'Current question',
              createdAt: 1,
              updatedAt: 1),
          ReadingDifficulty(
              id: 'late',
              bookId: 1,
              cfi: 'late',
              text: 'Future question text',
              createdAt: 1,
              updatedAt: 1)
        ]);
    final request = gateway.requests.single;
    final prompt = request.messages.map((m) => m.contentAsString).join();
    expect(prompt, contains('Current question'));
    expect(prompt, isNot(contains('Future question text')));
    expect(prompt, isNot(contains('Future guide text')));
    expect(prompt, isNot(contains('Unknown old quiz')));
    expect(request.workloadId, 'reading_practice.synthesis');
    expect(request.sourceScope?.safeBoundary, .4);
    expect(result['visibleFromProgress'], .4);
  });
}
