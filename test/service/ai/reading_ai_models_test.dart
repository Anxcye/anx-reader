import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_frameworks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reading AI domain models', () {
    test('uses domain-specific action order, safety, and trusted sources', () {
      final history = ReadingAiMode.history.agentProfile;
      final psychology = ReadingAiMode.psychology.agentProfile;
      final finance = ReadingAiMode.finance.agentProfile;

      expect(history.actionOrder.first, SelectionAiAction.sourceLookup);
      expect(psychology.actionOrder.first, SelectionAiAction.explain);
      expect(psychology.safetyPrompt, contains('not diagnosis'));
      expect(finance.actionOrder.first, SelectionAiAction.explain);
      expect(finance.safetyPrompt, contains('not personalized investment'));
      expect(
        finance.trustedSources.trusts(
          Uri.parse('https://www.sec.gov/Archives/example'),
        ),
        isTrue,
      );
      expect(
        finance.trustedSources.trusts(
          Uri.parse('https://sec.gov.evil.example/report'),
        ),
        isFalse,
      );
      expect(
        finance.trustedSources.trusts(Uri.parse('http://sec.gov/report')),
        isFalse,
      );
    });

    test('round-trips context, trace, and loosely coupled messages', () {
      final session = AiReadingSession(
        id: 'session-1',
        serviceId: 'openai',
        model: 'example-model',
        createdAt: 100,
        updatedAt: 200,
        completed: true,
        mode: ReadingAiMode.history,
        messages: const <Object>[
          <String, dynamic>{'role': 'human', 'content': 'What happened?'},
          'A plain legacy message',
        ],
        context: const ReadingContextSnapshot(
          bookId: 'book-1',
          bookTitle: 'A History',
          selectedText: 'Selected passage',
          progress: 0.25,
        ),
        traces: const <AgentRunTrace>[
          AgentRunTrace(
            id: 'trace-1',
            agentId: 'reading-history',
            mode: ReadingAiMode.history,
            action: SelectionAiAction.contextualize,
            startedAt: 101,
            completedAt: 150,
            status: AgentRunStatus.completed,
            sourceUrls: <String>['https://loc.gov/item/1'],
            evidence: <EvidenceObject>[
              EvidenceObject(
                id: 'evidence-1',
                expertId: 'reading-history',
                claim: 'The dated source supports the chronology.',
                support: 'Archive record',
                confidence: EvidenceConfidence.high,
                sourceUrls: <String>['https://loc.gov/item/1'],
              ),
            ],
          ),
        ],
      );

      final json = session.toJson();
      final restored = AiReadingSession.fromJson(json);

      expect(json, containsPair('serviceId', 'openai'));
      expect(json, containsPair('completed', true));
      expect(restored.mode, ReadingAiMode.history);
      expect(restored.messages, hasLength(2));
      expect(restored.messages.last, 'A plain legacy message');
      expect(restored.context?.bookTitle, 'A History');
      expect(restored.traces.single.status, AgentRunStatus.completed);
      expect(restored.traces.single.evidence.single.confidence,
          EvidenceConfidence.high);
    });

    test('reads an AiChatHistoryEntry-shaped JSON payload', () {
      final session = AiReadingSession.fromJson(<String, dynamic>{
        'id': 'legacy',
        'serviceId': 'anthropic',
        'model': 'legacy-model',
        'createdAt': 1,
        'updatedAt': 2,
        'completed': false,
        'messages': <Object>[
          <String, dynamic>{'role': 'human', 'content': 'Hello'},
        ],
      });

      expect(session.id, 'legacy');
      expect(session.mode, ReadingAiMode.general);
      expect(session.messages.single, isA<Map<String, dynamic>>());
    });

    test('round-trips deep-reading request and result', () {
      const request = ReadingAnalysisRequest(
        depth: ReadingAnalysisDepth.research,
        frameworks: <ReadingFramework>[
          ReadingFramework.criticalThinking,
          ReadingFramework.systemsThinking,
        ],
        outputTemplate: ReadingOutputTemplate.argumentAnalysis,
        readingGoal: '核查核心主张',
        allowWebSearch: true,
      );
      const result = ReadingAnalysisResult(
        request: request,
        generatedAt: 200,
        summary: 'result',
        sections: <FrameworkAnalysisSection>[
          FrameworkAnalysisSection(
            framework: ReadingFramework.criticalThinking,
            title: '证据',
            content: 'content',
            keyPoints: <String>['point'],
          ),
        ],
      );

      final restored = ReadingAnalysisResult.fromJson(result.toJson());

      expect(restored.request.depth, ReadingAnalysisDepth.research);
      expect(restored.request.frameworks, request.frameworks);
      expect(restored.request.allowWebSearch, isTrue);
      expect(restored.sections.single.keyPoints, ['point']);
    });

    test('recommends frameworks locally by depth and mode', () {
      const recommender = ReadingFrameworkRecommender();

      expect(
        recommender.recommend(
          depth: ReadingAnalysisDepth.quick,
          mode: ReadingAiMode.general,
        ),
        [ReadingFramework.scqa, ReadingFramework.fiveWTwoH],
      );
      expect(
        recommender.recommend(
          depth: ReadingAnalysisDepth.research,
          mode: ReadingAiMode.history,
          text: '核查史料证据',
          maxFrameworks: 1,
        ),
        [ReadingFramework.criticalThinking],
      );
    });

    test('analysis prompt restricts networking to research permission', () {
      const request = ReadingAnalysisRequest(
        depth: ReadingAnalysisDepth.deep,
        frameworks: <ReadingFramework>[ReadingFramework.firstPrinciples],
        outputTemplate: ReadingOutputTemplate.learningNote,
      );

      final prompt = readingAnalysisPrompt(request);

      expect(prompt, contains('不要发起联网检索'));
      expect(prompt, contains('第一性原理'));
    });
  });
}
