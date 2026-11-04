import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/ai_request.dart';
import 'package:anx_reader/service/ai/ai_request_gateway.dart';
import 'package:anx_reader/service/ai/book_wiki_generation_service.dart';
import 'package:anx_reader/service/ai/fiction_backfill_service.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain_core/chat_models.dart';

class RecordingGateway extends AiRequestGateway {
  final List<AiRequest> requests = [];
  final List<Object> responses = [];

  @override
  Future<String> executeText(AiRequest request) async {
    requests.add(request);
    final response = responses.removeAt(0);
    if (response is String) return response;
    throw response;
  }
}

class RecordingAssembler extends AiContextAssembler {
  var calls = 0;

  @override
  AiContextAssembly assemble(List<ChatMessage> source,
      {required AiContextTask task,
      ChatMessage? systemMessage,
      String cacheScope = 'conversation',
      int? maxInputTokens}) {
    calls++;
    return super.assemble(source,
        task: task,
        systemMessage: systemMessage,
        cacheScope: cacheScope,
        maxInputTokens: maxInputTokens);
  }
}

class EmptyRepository extends ReadingAgentRepository {
  @override
  Future<List<BookWikiEntry>> bookWikiEntries(int bookId,
          {double? visibleAtProgress}) async =>
      [];
}

void expectRegisteredRequest(AiRequest request, String workload) {
  final descriptor = AiWorkloadDescriptorRegistry.find(workload)!;
  expect(request.workloadId, workload);
  expect(request.trace.workloadId, workload);
  expect(request.trace.requestId, isNotEmpty);
  expect(request.trace.taskId, 'task');
  expect(request.trace.sessionId, 'session');
  expect(request.trace.bookId, 7);
  expect(request.contextTask, descriptor.contextTask);
  expect(request.providerRole, descriptor.providerRole);
  expect(request.outputContract.kind, AiOutputKind.json);
  expect(request.useAgent, isFalse);
  expect(request.fallbackPolicy, AiFallbackPolicy.none);
  expect(request.allowAutomaticFallback, isFalse);
  expect(request.failureDelivery, AiFailureDelivery.streamError);
  expect(request.sourceScope?.bookId, 7);
  expect(request.sourceScope?.safeBoundary, .4);
  expect(request.sourceScope?.chapterRefs, ['early.xhtml']);
  expect(request.sourceScope?.chapterHref, 'early.xhtml');
}

void main() {
  const fictionChapters = [
    FictionBackfillChapter(
        href: 'early.xhtml',
        title: 'Early chapter',
        startProgress: .1,
        endProgress: .2),
    FictionBackfillChapter(
        href: 'future.xhtml',
        title: 'Future chapter',
        startProgress: .8,
        endProgress: .9),
  ];
  const wikiChapters = [
    BookWikiChapter(
        href: 'early.xhtml',
        title: 'Early chapter',
        progress: .2,
        content: 'Visible original text.'),
    BookWikiChapter(
        href: 'future.xhtml',
        title: 'Future chapter',
        progress: .8,
        content: 'FUTURE PRIVATE CONTENT'),
  ];

  test('default fiction request carries task and safe source scope', () async {
    final gateway = RecordingGateway()..responses.add('[]');
    final assembler = RecordingAssembler();
    final service =
        FictionBackfillService(gateway: gateway, assembler: assembler);
    expect(gateway.requests, isEmpty);
    final loaded = <String>[];
    final result = await service.build(
        bookId: 7,
        moduleId: 'fiction.immersion',
        safeBoundary: .4,
        chapters: fictionChapters,
        loadChapter: (href) async {
          loaded.add(href);
          return 'Visible original text.';
        },
        sessionId: 'session',
        taskId: 'task',
        providerId: 'confirmed-provider',
        ingestedAt: 1);
    expect(result, isEmpty);
    expect(loaded, ['early.xhtml']);
    expect(assembler.calls, 1);
    expectRegisteredRequest(gateway.requests.single, 'fiction.story_atlas');
    expect(gateway.requests.single.providerId, 'confirmed-provider');
  });

  test('fiction retry retains explicit provider policy and task identity',
      () async {
    final gateway = RecordingGateway()
      ..responses.addAll([const AiGenerationFailure(), '[]']);
    await FictionBackfillService(gateway: gateway).build(
        bookId: 7,
        moduleId: 'fiction.immersion',
        safeBoundary: .4,
        chapters: fictionChapters,
        loadChapter: (_) async => 'Visible original text.',
        sessionId: 'session',
        taskId: 'task',
        ingestedAt: 1);
    expect(gateway.requests, hasLength(2));
    for (final request in gateway.requests) {
      expectRegisteredRequest(request, 'fiction.story_atlas');
    }
    expect(
        gateway.requests.map((r) => r.trace.requestId).toSet(), hasLength(2));
  });

  test('default Wiki request uses registered execution and bounded sources',
      () async {
    final gateway = RecordingGateway()..responses.add('[]');
    final assembler = RecordingAssembler();
    final service = BookWikiGenerationService(
        gateway: gateway, assembler: assembler, repository: EmptyRepository());
    expect(gateway.requests, isEmpty);
    expect(
        await service.generate(
            bookId: 7,
            chapters: wikiChapters,
            safeBoundary: .4,
            sessionId: 'session',
            taskId: 'task',
            providerId: 'confirmed-provider'),
        0);
    expect(assembler.calls, 1);
    final request = gateway.requests.single;
    expectRegisteredRequest(request, 'wiki.book_generate');
    expect(request.providerId, 'confirmed-provider');
    expect(request.messages.map((m) => m.contentAsString).join('\n'),
        isNot(contains('FUTURE PRIVATE CONTENT')));
  });

  test('Wiki provider failure is surfaced without a provider fallback',
      () async {
    final gateway = RecordingGateway()
      ..responses.add(const AiGenerationFailure());
    final service = BookWikiGenerationService(
        gateway: gateway, repository: EmptyRepository());
    await expectLater(
        service.generate(
            bookId: 7,
            chapters: wikiChapters,
            safeBoundary: .4,
            sessionId: 'session',
            taskId: 'task'),
        throwsA(isA<AiGenerationFailure>()));
    expectRegisteredRequest(gateway.requests.single, 'wiki.book_generate');
  });

  test('injected Wiki and hybrid generators retain compatibility', () async {
    final gateway = RecordingGateway();
    var calls = 0;
    Future<String> generate(String _) async {
      calls++;
      return '[]';
    }

    await BookWikiGenerationService(
            gateway: gateway, repository: EmptyRepository())
        .generate(
            bookId: 7,
            chapters: wikiChapters,
            safeBoundary: .4,
            sessionId: 'session',
            generate: generate);
    await FictionBackfillService(gateway: gateway).build(
        bookId: 7,
        moduleId: 'fiction.immersion',
        safeBoundary: .4,
        chapters: fictionChapters,
        loadChapter: (_) async => 'Visible original text.',
        sessionId: 'session',
        ingestedAt: 1,
        generate: generate);
    expect(calls, 2);
    expect(gateway.requests, isEmpty);
  });
}
