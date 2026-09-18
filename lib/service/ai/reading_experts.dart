import 'package:anx_reader/service/ai/reading_ai_models.dart';

/// Stable, auditable expert definitions. Experts describe a reading lens;
/// they do not own providers, persistence, or tools.
class ReadingExpertDefinition {
  const ReadingExpertDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.modes,
    required this.keywords,
    required this.instruction,
    required this.action,
    this.supportsWebSearch = false,
    this.tags = const <String>[],
  });

  final String id;
  final String title;
  final String description;
  final Set<ReadingAiMode> modes;
  final List<String> keywords;
  final String instruction;
  final SelectionAiAction action;
  final bool supportsWebSearch;
  final List<String> tags;
}

class ReadingExpertRegistry {
  const ReadingExpertRegistry();

  static const definitions = <ReadingExpertDefinition>[
    ReadingExpertDefinition(
      id: 'expert.text.general',
      title: '通用文本理解',
      description: '解释段落、结构与作者表达。',
      modes: {
        ReadingAiMode.general,
        ReadingAiMode.history,
        ReadingAiMode.psychology,
        ReadingAiMode.finance
      },
      keywords: ['解释', '理解', '文本', '结构'],
      instruction: '解释文本结构，区分原文事实、作者观点与读者推断。',
      action: SelectionAiAction.analyze,
      tags: ['基础', '文本'],
    ),
    ReadingExpertDefinition(
      id: 'expert.history.source',
      title: '历史与史料核查',
      description: '核对年代、人物、出处与争议。',
      modes: {ReadingAiMode.history},
      keywords: ['历史', '史料', '出处', '年代'],
      instruction: '区分原始史料、后世解释和不确定性；没有来源时不得声称已核查。',
      action: SelectionAiAction.factCheck,
      supportsWebSearch: true,
      tags: ['历史', '核查'],
    ),
    ReadingExpertDefinition(
      id: 'expert.psychology.concept',
      title: '心理学概念',
      description: '解释概念、边界、例子与反例。',
      modes: {ReadingAiMode.psychology, ReadingAiMode.general},
      keywords: ['心理', '认知', '情绪', '人格'],
      instruction: '提供教育性解释，不进行诊断；明确证据边界和适用条件。',
      action: SelectionAiAction.explain,
      tags: ['心理', '概念'],
    ),
    ReadingExpertDefinition(
      id: 'expert.finance.assumption',
      title: '财务与经济分析',
      description: '拆解数据口径、假设、计算与风险。',
      modes: {ReadingAiMode.finance, ReadingAiMode.general},
      keywords: ['财务', '经济', '投资', '估值'],
      instruction: '标注日期、单位、假设和下行风险，不给个性化投资建议。',
      action: SelectionAiAction.validateAssumption,
      supportsWebSearch: true,
      tags: ['经济', '风险'],
    ),
    ReadingExpertDefinition(
      id: 'expert.fiction.narrative',
      title: '小说叙事与人物',
      description: '追踪人物、关系、伏笔和叙事视角。',
      modes: {ReadingAiMode.general},
      keywords: ['小说', '人物', '角色', '伏笔', '情节'],
      instruction: '严格遵守当前阅读边界，区分文本事实与推测，不泄露后文。',
      action: SelectionAiAction.timeline,
      tags: ['小说', '人物'],
    ),
    ReadingExpertDefinition(
      id: 'expert.scifi.worldbuilding',
      title: '科幻世界观',
      description: '梳理文明、技术、规则和事件轨道。',
      modes: {ReadingAiMode.general},
      keywords: ['科幻', '文明', '技术', '世界观'],
      instruction: '只使用当前已读证据，区分设定事实、推断和未解释规则。',
      action: SelectionAiAction.contextualize,
      tags: ['科幻', '设定'],
    ),
    ReadingExpertDefinition(
      id: 'expert.academic.critical',
      title: '学术研究与论文批判',
      description: '审视问题、方法、证据、局限与可复现性。',
      modes: {
        ReadingAiMode.general,
        ReadingAiMode.psychology,
        ReadingAiMode.finance
      },
      keywords: ['论文', '研究', '样本', '实验'],
      instruction: '区分统计结果、因果解释和作者推论，指出证据缺口。',
      action: SelectionAiAction.deepAnalyze,
      supportsWebSearch: true,
      tags: ['学术', '方法'],
    ),
    ReadingExpertDefinition(
      id: 'expert.science.technical',
      title: '科学技术解释',
      description: '把技术概念讲清楚并标注适用边界。',
      modes: {ReadingAiMode.general},
      keywords: ['科学', '技术', '原理', '实验'],
      instruction: '先给直观解释，再说明机制、假设和未知，避免把类比当事实。',
      action: SelectionAiAction.explain,
      tags: ['科学', '技术'],
    ),
    ReadingExpertDefinition(
      id: 'expert.law.policy',
      title: '法律与政策阅读',
      description: '梳理条款、义务、例外和适用范围。',
      modes: {ReadingAiMode.general},
      keywords: ['法律', '政策', '法规', '条款'],
      instruction: '只作信息整理，不提供个案法律意见；注明法域、日期和不确定性。',
      action: SelectionAiAction.factCheck,
      supportsWebSearch: true,
      tags: ['法律', '政策'],
    ),
    ReadingExpertDefinition(
      id: 'expert.language.context',
      title: '外语语境学习',
      description: '结合上下文解释词义、语气和搭配。',
      modes: {ReadingAiMode.general},
      keywords: ['翻译', '外语', '单词', '语法'],
      instruction: '优先解释语境义、搭配和语气，不脱离原文堆砌词典释义。',
      action: SelectionAiAction.translate,
      tags: ['语言', '翻译'],
    ),
  ];

  ReadingExpertDefinition? get(String id) {
    for (final item in definitions) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<ReadingExpertDefinition> forMode(ReadingAiMode mode) => definitions
      .where((item) => item.modes.contains(mode))
      .toList(growable: false);

  List<ReadingExpertDefinition> search(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return definitions;
    return definitions
        .where((item) =>
            '${item.title} ${item.description} ${item.tags.join(' ')}'
                .toLowerCase()
                .contains(value))
        .toList(growable: false);
  }
}
