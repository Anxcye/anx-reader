import 'package:anx_reader/service/ai/reading_agent_orchestrator.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const orchestrator = ReadingAgentOrchestrator();

  test('simple questions stay with the primary assistant', () {
    final plan = orchestrator.plan('这句话是什么意思？', ReadingAiMode.general);
    expect(plan.usesExperts, isFalse);
  });

  test(
    'long selection explanations do not dispatch experts by length alone',
    () {
      final selection = List.filled(80, '这是一段需要结合上下文解释的划线内容。').join();
      final plan = orchestrator.plan(
        '解释这段内容中的关键概念和论证。\n\n选中文本：\n$selection',
        ReadingAiMode.history,
      );
      expect(plan.usesExperts, isFalse);
    },
  );

  test('complex mode tasks dispatch no more than two specialists', () {
    final plan = orchestrator.plan(
      '请核查这段历史叙述的典籍出处、证据冲突、数字和事件时间线。',
      ReadingAiMode.history,
    );
    expect(plan.agentIds, contains('history-specialist'));
    expect(plan.agentIds, contains('source-researcher'));
    expect(plan.agentIds.length, lessThanOrEqualTo(2));
  });

  test('expert budget can lower the orchestration fan-out', () {
    const bounded = ReadingAgentOrchestrator(
      expertBudget: ReadingExpertBudget(maxExperts: 1),
    );
    final plan = bounded.plan(
      '请核查出处、证据和时间线。',
      ReadingAiMode.history,
    );

    expect(plan.agentIds, hasLength(1));
  });

  test('analysis depth controls experts and research source task', () {
    const quick = ReadingAnalysisRequest(
      depth: ReadingAnalysisDepth.quick,
      frameworks: <ReadingFramework>[
        ReadingFramework.scqa,
        ReadingFramework.fiveWTwoH,
      ],
      outputTemplate: ReadingOutputTemplate.learningNote,
    );
    const research = ReadingAnalysisRequest(
      depth: ReadingAnalysisDepth.research,
      frameworks: <ReadingFramework>[
        ReadingFramework.criticalThinking,
        ReadingFramework.systemsThinking,
      ],
      outputTemplate: ReadingOutputTemplate.argumentAnalysis,
      allowWebSearch: true,
    );

    expect(
      orchestrator
          .plan('分析划线', ReadingAiMode.general, analysisRequest: quick)
          .agentIds,
      isEmpty,
    );
    final plan = orchestrator.plan(
      '研究这段内容',
      ReadingAiMode.history,
      analysisRequest: research,
    );
    expect(plan.agentIds.first, 'source-researcher');
    expect(plan.agentIds.length, 2);
  });

  test('experts share one bounded immutable context snapshot', () {
    final messages = <ChatMessage>[
      ChatMessage.humanText(List.filled(3000, '前文背景').join()),
      ChatMessage.ai('此前回答'),
      ChatMessage.humanText('请核查这个结论的证据。'),
    ];
    final snapshot = ReadingExpertContextSnapshot.capture(
      messages: messages,
      mode: ReadingAiMode.history,
      budget: const ReadingExpertBudget(maxInputTokens: 500),
      capturedAt: 42,
    );

    expect(snapshot.query, '请核查这个结论的证据。');
    expect(snapshot.estimatedTokens, lessThanOrEqualTo(500));
    expect(snapshot.capturedAt, 42);
    expect(snapshot.context, contains('请核查这个结论的证据。'));
  });

  test('expert evidence is validated, source-bound and compressed', () {
    const bounded = ReadingAgentOrchestrator(
      expertBudget: ReadingExpertBudget(
        maxEvidence: 1,
        maxClaimCharacters: 12,
        maxSupportCharacters: 16,
      ),
    );
    final evidence = bounded.parseEvidence(
      'history-specialist',
      '''```json
{"evidence":[
  {"claim":"这是一个很长且需要被压缩的专家主张","support":"这是一段同样需要被严格压缩的支持材料","uncertainty":"史料有冲突","confidence":"high","sourceUrls":["https://trusted.example/a","https://invented.example/b"]},
  {"claim":"第二条不应进入结果","confidence":"medium"}
]}
```''',
      const ['https://trusted.example/a'],
    );

    expect(evidence, hasLength(1));
    expect(evidence.single.claim.length, lessThanOrEqualTo(13));
    expect(evidence.single.sourceUrls, ['https://trusted.example/a']);
    expect(bounded.compressEvidence(evidence), contains('[high]'));
  });

  test('malformed specialist output degrades to no evidence', () {
    expect(
      orchestrator.parseEvidence('expert', 'not-json', const []),
      isEmpty,
    );
  });
}
