import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/ai_request.dart';
import 'package:anx_reader/service/ai/ai_request_gateway.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_experience_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain_core/chat_models.dart';

class RecordingGateway extends AiRequestGateway {
  final List<AiRequest> requests = [];
  String response = 'general';

  @override
  Future<String> executeText(AiRequest request) async {
    requests.add(request);
    return response;
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

void main() {
  test('explicit metadata hint uses registered gateway, assembler and trace',
      () async {
    final gateway = RecordingGateway()..response = ' FINANCE\n';
    final assembler = RecordingAssembler();
    final service = ReadingExperienceProfileService(
        gateway: gateway,
        assembler: assembler,
        runtimeState: () =>
            const ReadingWorldState(bookId: 7, sessionId: 'current-session'));
    expect(gateway.requests, isEmpty);
    expect(assembler.calls, 0);
    final result = await service.suggestAnswerMode(
        bookId: 7,
        title: 'A book',
        author: 'An author',
        description: 'A description',
        selection: const ReadingContextSnapshot(
            bookId: '7',
            bookTitle: 'A book',
            chapterTitle: 'Visible chapter',
            chapterHref: 'chapter.xhtml',
            selectedText: 'PRIVATE EXACT QUOTATION',
            surroundingText: 'PRIVATE CHAPTER CONTEXT',
            progress: .3,
            capturedAt: 1));
    expect(result, ReadingAiMode.finance);
    expect(assembler.calls, 1);
    final request = gateway.requests.single;
    final descriptor =
        AiWorkloadDescriptorRegistry.find('reading.mode_suggestion')!;
    expect(request.workloadId, descriptor.id);
    expect(request.contextTask, descriptor.contextTask);
    expect(request.providerRole, AiProviderRole.general);
    expect(request.outputContract.kind, AiOutputKind.text);
    expect(request.fallbackPolicy, AiFallbackPolicy.none);
    expect(request.failureDelivery, AiFailureDelivery.streamError);
    expect(request.useAgent, isFalse);
    expect(descriptor.allowsTools, isFalse);
    expect(descriptor.allowsWebSearch, isFalse);
    expect(request.trace.requestId, isNotEmpty);
    expect(request.trace.bookId, 7);
    expect(request.trace.sessionId, 'current-session');
    expect(request.sourceScope?.bookId, 7);
    expect(request.sourceScope?.chapterHref, 'chapter.xhtml');
    expect(request.sourceScope?.safeBoundary, .3);
    final prompt = request.messages.map((m) => m.contentAsString).join('\n');
    expect(prompt, contains('Visible chapter'));
    expect(prompt, isNot(contains('PRIVATE EXACT QUOTATION')));
    expect(prompt, isNot(contains('PRIVATE CHAPTER CONTEXT')));
    expect(service.cached(7), isNull);
  });

  test('unknown output cannot silently select a substring or persist a mode',
      () async {
    final gateway = RecordingGateway();
    final service = ReadingExperienceProfileService(
        gateway: gateway, runtimeState: () => const ReadingWorldState());
    for (final response in [
      'not finance',
      'history or psychology',
      'future.new-perspective',
      '',
    ]) {
      gateway.response = response;
      expect(
          await service.suggestAnswerMode(
              bookId: 7, title: 'Book', author: 'Author'),
          isNull);
    }
    expect(service.cached(7), isNull);
  });

  test('foreign selection and session are excluded from the scoped request',
      () async {
    final gateway = RecordingGateway();
    final service = ReadingExperienceProfileService(
        gateway: gateway,
        runtimeState: () =>
            const ReadingWorldState(bookId: 9, sessionId: 'foreign-session'));
    await service.suggestAnswerMode(
        bookId: 7,
        title: 'Book',
        author: 'Author',
        selection: const ReadingContextSnapshot(
            bookId: '9',
            bookTitle: 'Foreign book',
            chapterTitle: 'FOREIGN CHAPTER',
            chapterHref: 'foreign.xhtml',
            progress: .9,
            capturedAt: 1));
    final request = gateway.requests.single;
    expect(request.trace.sessionId, isNull);
    expect(request.sourceScope?.chapterHref, isNull);
    expect(request.sourceScope?.safeBoundary, isNull);
    expect(request.messages.map((m) => m.contentAsString).join('\n'),
        isNot(contains('FOREIGN CHAPTER')));
  });
}
