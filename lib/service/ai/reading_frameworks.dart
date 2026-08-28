import 'package:anx_reader/service/ai/reading_ai_models.dart';

class ReadingFrameworkDefinition {
  const ReadingFrameworkDefinition({
    required this.framework,
    required this.label,
    required this.description,
    required this.instruction,
  });

  final ReadingFramework framework;
  final String label;
  final String description;
  final String instruction;
}

class ReadingFrameworkRegistry {
  const ReadingFrameworkRegistry();

  static const definitions = <ReadingFramework, ReadingFrameworkDefinition>{
    ReadingFramework.scqa: ReadingFrameworkDefinition(
      framework: ReadingFramework.scqa,
      label: 'SCQA',
      description: '梳理情境、冲突、问题与回答',
      instruction: '用“情境、冲突、问题、回答”四部分还原作者的表达结构。',
    ),
    ReadingFramework.fiveWTwoH: ReadingFrameworkDefinition(
      framework: ReadingFramework.fiveWTwoH,
      label: '5W2H',
      description: '快速补齐事实要素与行动条件',
      instruction: '检查人物、事件、时间、地点、原因、方式和成本，缺失项要明确标注。',
    ),
    ReadingFramework.criticalThinking: ReadingFrameworkDefinition(
      framework: ReadingFramework.criticalThinking,
      label: '批判性思维',
      description: '区分结论、证据、假设与反例',
      instruction: '拆分主张、证据、隐含假设、推理漏洞、反例和结论置信度。',
    ),
    ReadingFramework.inversion: ReadingFrameworkDefinition(
      framework: ReadingFramework.inversion,
      label: '反向思考',
      description: '从失败条件和反面命题检验观点',
      instruction: '反转作者的结论，寻找使其失效的条件、遗漏情景和边界。',
    ),
    ReadingFramework.firstPrinciples: ReadingFrameworkDefinition(
      framework: ReadingFramework.firstPrinciples,
      label: '第一性原理',
      description: '回到最基本事实重建推理',
      instruction: '剥离类比和惯例，列出不可再分的事实、约束，并从这些条件重新推导。',
    ),
    ReadingFramework.systemsThinking: ReadingFrameworkDefinition(
      framework: ReadingFramework.systemsThinking,
      label: '系统思维',
      description: '识别要素、关系、反馈与延迟',
      instruction: '分析系统边界、关键要素、因果关系、反馈回路、延迟和二阶影响。',
    ),
  };

  ReadingFrameworkDefinition get(ReadingFramework framework) =>
      definitions[framework]!;

  String promptFor(ReadingFramework framework) => get(framework).instruction;
}

class ReadingFrameworkRecommender {
  const ReadingFrameworkRecommender();

  List<ReadingFramework> recommend({
    required ReadingAnalysisDepth depth,
    required ReadingAiMode mode,
    String? readingGoal,
    String? text,
    int maxFrameworks = 2,
  }) {
    final candidates = switch (depth) {
      ReadingAnalysisDepth.quick => <ReadingFramework>[
          ReadingFramework.scqa,
          ReadingFramework.fiveWTwoH,
        ],
      ReadingAnalysisDepth.standard => <ReadingFramework>[
          ReadingFramework.criticalThinking,
          ReadingFramework.inversion,
        ],
      ReadingAnalysisDepth.deep => <ReadingFramework>[
          ReadingFramework.firstPrinciples,
          ReadingFramework.systemsThinking,
        ],
      ReadingAnalysisDepth.research => <ReadingFramework>[
          ReadingFramework.criticalThinking,
          ReadingFramework.systemsThinking,
        ],
    };

    final signal = '${readingGoal ?? ''} ${text ?? ''}'.toLowerCase();
    if (mode == ReadingAiMode.finance ||
        RegExp(r'风险|变量|循环|反馈|系统|risk|system').hasMatch(signal)) {
      _promote(candidates, ReadingFramework.systemsThinking);
    } else if (mode == ReadingAiMode.history ||
        RegExp(r'证据|史料|出处|真假|evidence|source').hasMatch(signal)) {
      _promote(candidates, ReadingFramework.criticalThinking);
    } else if (RegExp(r'行动|练习|怎么做|实践|action|practice').hasMatch(signal)) {
      _promote(candidates, ReadingFramework.firstPrinciples);
    }

    final limit = maxFrameworks.clamp(1, 2);
    return candidates.take(limit).toList(growable: false);
  }

  void _promote(
    List<ReadingFramework> frameworks,
    ReadingFramework framework,
  ) {
    frameworks.remove(framework);
    frameworks.insert(0, framework);
  }
}

String readingAnalysisPrompt(
  ReadingAnalysisRequest request, {
  ReadingFrameworkRegistry registry = const ReadingFrameworkRegistry(),
}) {
  final frameworkInstructions = request.frameworks
      .map((framework) => '- ${registry.get(framework).label}：'
          '${registry.promptFor(framework)}')
      .join('\n');
  final outputInstruction = switch (request.outputTemplate) {
    ReadingOutputTemplate.learningNote => '输出学习笔记：核心观点、框架分析、关键证据、疑问和可复习摘要。',
    ReadingOutputTemplate.argumentAnalysis => '输出论证分析：主张、证据、假设、反例、边界和结论置信度。',
    ReadingOutputTemplate.conceptMap =>
      '输出文本概念图：用缩进列表表达概念、关系、因果和反馈，不使用 Mermaid。',
    ReadingOutputTemplate.practicePlan => '输出实践计划：目标、步骤、触发条件、检查点、风险和复盘问题。',
  };
  final researchInstruction = request.depth == ReadingAnalysisDepth.research
      ? request.allowWebSearch
          ? '这是研究档分析。比较本书观点与可信外部来源，逐条给出引用；无法联网时明确降级。'
          : '这是研究档分析，但未授权联网。只使用本书上下文，并列出需要外部核查的问题。'
      : '不要发起联网检索；仅使用当前阅读上下文和按需读取的本书内容。';

  return '''执行深度阅读分析。
分析深度：${request.depth.name}
阅读目标：${request.readingGoal?.trim().isNotEmpty == true ? request.readingGoal!.trim() : '理解当前划线及其在本书中的作用'}
主要框架（只使用以下框架，不要擅自扩展）：
$frameworkInstructions

$outputInstruction
$researchInstruction
明确区分原文事实、作者观点、你的推断和未知信息。不要伪造引文或声称读过未读取的内容。''';
}
