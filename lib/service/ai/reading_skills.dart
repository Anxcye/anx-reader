import 'package:anx_reader/service/ai/reading_ai_models.dart';

enum ReadingSkillId {
  socraticConcept,
  argumentMapping,
  historicalSourceCheck,
  fictionCharacterTracking,
  academicCriticalReading,
  contextualLanguageLearning,
  financialAssumptionValidation,
  chapterClosure,
  examReview,
  readingToAction;

  static ReadingSkillId? fromJson(Object? value) {
    for (final item in values) {
      if (item.name == value) return item;
    }
    return null;
  }
}

enum ReadingSkillLoadLevel { catalog, summary, full }

class ReadingSkillDefinition {
  const ReadingSkillDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.summaryInstruction,
    required this.fullInstruction,
    required this.supportedModes,
    required this.triggerKeywords,
    required this.closureContributions,
  });

  final ReadingSkillId id;
  final String title;
  final String description;
  final String summaryInstruction;
  final String fullInstruction;
  final Set<ReadingAiMode> supportedModes;
  final List<String> triggerKeywords;
  final List<String> closureContributions;
}

class ReadingSkillSelection {
  const ReadingSkillSelection({
    required this.primary,
    required this.loadLevel,
    required this.reason,
    this.supporting,
    this.pinned = false,
  });

  final ReadingSkillDefinition primary;
  final ReadingSkillDefinition? supporting;
  final ReadingSkillLoadLevel loadLevel;
  final String reason;
  final bool pinned;

  String promptContext() {
    final primaryInstruction = loadLevel == ReadingSkillLoadLevel.full
        ? primary.fullInstruction
        : primary.summaryInstruction;
    final support = supporting == null
        ? ''
        : '\nSupporting method (summary only): ${supporting!.title}: '
            '${supporting!.summaryInstruction}';
    return '''Reading method: ${primary.title}
Load level: ${loadLevel.name}
Method guidance: $primaryInstruction$support
Method outputs are proposals, not proof of mastery or user facts. Any note, memory, goal, difficulty, card, or action-plan write must follow the existing confirmation and undo rules.''';
  }
}

class ReadingSkillRegistry {
  const ReadingSkillRegistry();

  static const definitions = <ReadingSkillDefinition>[
    ReadingSkillDefinition(
      id: ReadingSkillId.socraticConcept,
      title: '苏格拉底式概念教学',
      description: '用递进问题澄清概念、边界、例子与反例。',
      summaryInstruction: '先确认读者的当前理解，再用一个问题或一个最小例子推进，不连续追问。',
      fullInstruction:
          '识别核心概念；请读者先用自己的话解释；逐步检查定义、边界、例子、反例和迁移应用。每轮最多提出一个关键问题，也允许用户选择直接解释。将理解判断交给读者确认。',
      supportedModes: {ReadingAiMode.general, ReadingAiMode.psychology},
      triggerKeywords: ['概念', '为什么', '理解', '心理', '认知', 'socratic'],
      closureContributions: ['mastery', 'knowledgeCard'],
    ),
    ReadingSkillDefinition(
      id: ReadingSkillId.argumentMapping,
      title: '论证结构拆解',
      description: '拆出主张、证据、假设、反例和结论。',
      summaryInstruction: '区分作者的主张、证据和隐含假设，不把观点写成事实。',
      fullInstruction:
          '按主张→证据→推理桥梁→隐含假设→可能反例→适用边界拆解文本；标记证据缺口和相关性，不因表达有说服力就判定论证成立。可建议保存“主张-证据-假设”Markdown 记忆。',
      supportedModes: {
        ReadingAiMode.general,
        ReadingAiMode.psychology,
        ReadingAiMode.finance
      },
      triggerKeywords: ['论证', '主张', '证据', '假设', '逻辑', 'argument'],
      closureContributions: ['markdownMemory', 'difficulty'],
    ),
    ReadingSkillDefinition(
      id: ReadingSkillId.historicalSourceCheck,
      title: '历史事件与史料核查',
      description: '区分史实、史料出处、后世解释与争议。',
      summaryInstruction: '区分原始史料、二手研究和作者解释，并明确证据不足。',
      fullInstruction:
          '建立事件时间、人物和来源对应关系；优先核对原始史料与可信研究，记录版本、日期、冲突说法和不确定性。未实际联网或读取来源时不得声称已核查。',
      supportedModes: {ReadingAiMode.history},
      triggerKeywords: ['历史', '史料', '出处', '年代', '事件', 'source'],
      closureContributions: ['markdownMemory', 'difficulty'],
    ),
    ReadingSkillDefinition(
      id: ReadingSkillId.fictionCharacterTracking,
      title: '小说人物关系追踪',
      description: '跟踪人物、关系变化、动机、伏笔与叙事视角。',
      summaryInstruction: '围绕当前阅读进度解释人物和关系，严格避免后文剧透。',
      fullInstruction:
          '只使用当前进度以前的信息，整理人物身份、关系变化、公开动机、叙事视角、已出现伏笔和未解悬念；区分文本事实与推测，默认不剧透。可建议保存“人物关系/伏笔”Markdown 记忆。',
      supportedModes: {ReadingAiMode.general},
      triggerKeywords: ['小说', '人物', '角色', '关系', '伏笔', '情节', 'novel'],
      closureContributions: ['markdownMemory', 'difficulty'],
    ),
    ReadingSkillDefinition(
      id: ReadingSkillId.academicCriticalReading,
      title: '学术论文批判阅读',
      description: '检查研究问题、方法、证据、局限与可复现性。',
      summaryInstruction: '区分研究问题、方法、结果和作者推论，优先指出证据边界。',
      fullInstruction:
          '按研究问题、相关工作、样本与方法、指标、结果、因果解释、局限、利益冲突和可复现性审读；区分统计显著、效应大小与现实意义。',
      supportedModes: {
        ReadingAiMode.general,
        ReadingAiMode.psychology,
        ReadingAiMode.finance
      },
      triggerKeywords: ['论文', '研究', '样本', '实验设计', '学术', 'paper'],
      closureContributions: ['mastery', 'markdownMemory'],
    ),
    ReadingSkillDefinition(
      id: ReadingSkillId.contextualLanguageLearning,
      title: '外语语境学习',
      description: '在原句语境中学习词义、语法、语气与搭配。',
      summaryInstruction: '优先解释语境义、搭配和语气，避免脱离原文堆砌词典释义。',
      fullInstruction:
          '先给自然语境义，再解释关键词搭配、句法、语气和文化含义；给一个近义改写和可迁移例句。只把值得复习的内容建议为知识卡。',
      supportedModes: {ReadingAiMode.general},
      triggerKeywords: ['翻译', '外语', '单词', '语法', '语境', 'language'],
      closureContributions: ['knowledgeCard'],
    ),
    ReadingSkillDefinition(
      id: ReadingSkillId.financialAssumptionValidation,
      title: '财务假设验证',
      description: '核对口径、假设、计算、情景与下行风险。',
      summaryInstruction: '拆出财务假设、数据口径与风险，不给个性化投资指令。',
      fullInstruction:
          '列出变量、单位、数据日期和公式；分别检查增长、利润率、资本成本、估值倍数与下行情景；区分事实数据、作者假设和推导结果，并给出可证伪条件。',
      supportedModes: {ReadingAiMode.finance},
      triggerKeywords: ['财务', '估值', '投资', '利润', '现金流', '假设', 'finance'],
      closureContributions: ['markdownMemory', 'difficulty'],
    ),
    ReadingSkillDefinition(
      id: ReadingSkillId.chapterClosure,
      title: '章节结束回顾',
      description: '把章节检查、掌握度、难点和复习卡连接起来。',
      summaryInstruction: '章节结束时只生成待处理入口，用户打开后再回顾。',
      fullInstruction:
          '用核心内容、仍不确定之处和下一步三段完成回顾；让用户确认掌握度；未解决问题继续跨章节追踪；仅将用户确认的重要知识生成复习卡。',
      supportedModes: {
        ReadingAiMode.general,
        ReadingAiMode.history,
        ReadingAiMode.psychology,
        ReadingAiMode.finance
      },
      triggerKeywords: ['章节结束', '本章回顾', '章节检查', '总结本章', 'chapter review'],
      closureContributions: [
        'checkpoint',
        'mastery',
        'difficulty',
        'knowledgeCard'
      ],
    ),
    ReadingSkillDefinition(
      id: ReadingSkillId.examReview,
      title: '考试复习',
      description: '围绕考试范围做主动回忆、错题与间隔复习。',
      summaryInstruction: '优先主动回忆和错因，不直接把答案当作掌握。',
      fullInstruction:
          '根据考试范围建立最小复习单元；先提问后揭示答案；记录错误类型和薄弱点；把已确认的重要内容安排为到期知识卡，并用再次回忆更新掌握度。',
      supportedModes: {
        ReadingAiMode.general,
        ReadingAiMode.history,
        ReadingAiMode.psychology,
        ReadingAiMode.finance
      },
      triggerKeywords: ['考试', '复习', '背诵', '测验', '考点', 'exam'],
      closureContributions: ['mastery', 'knowledgeCard'],
    ),
    ReadingSkillDefinition(
      id: ReadingSkillId.readingToAction,
      title: '从阅读到行动计划',
      description: '把可迁移洞见转成具体、可检查的小行动。',
      summaryInstruction: '只把用户认可的洞见转成一个具体、可撤销的下一步。',
      fullInstruction:
          '从文本洞见提取适用情境、最小行动、触发条件、完成标准和复盘日期；检查行动是否超出证据边界。保存为目标或 Markdown 行动计划前必须遵循现有确认与撤销规则。',
      supportedModes: {
        ReadingAiMode.general,
        ReadingAiMode.psychology,
        ReadingAiMode.finance
      },
      triggerKeywords: ['行动', '实践', '应用', '计划', '下一步', 'action'],
      closureContributions: ['goal', 'markdownMemory'],
    ),
  ];

  ReadingSkillDefinition get(ReadingSkillId id) =>
      definitions.firstWhere((item) => item.id == id);
}

class ReadingSkillMatcher {
  const ReadingSkillMatcher({this.registry = const ReadingSkillRegistry()});

  final ReadingSkillRegistry registry;

  ReadingSkillSelection match({
    required ReadingAiMode mode,
    String title = '',
    String author = '',
    String description = '',
    String chapterTitle = '',
    String query = '',
    ReadingSkillId? pinnedSkill,
    bool deepAnalysis = false,
    bool chapterClosure = false,
  }) {
    final queryText = query.toLowerCase();
    final metadata = '$title $author $description $chapterTitle'.toLowerCase();
    ReadingSkillDefinition primary;
    var reason = '根据当前阅读模式匹配';
    var pinned = false;

    if (pinnedSkill != null) {
      primary = registry.get(pinnedSkill);
      reason = '本书已固定该阅读方法';
      pinned = true;
    } else if (chapterClosure ||
        _containsAny(queryText,
            registry.get(ReadingSkillId.chapterClosure).triggerKeywords)) {
      primary = registry.get(ReadingSkillId.chapterClosure);
      reason = '正在进行章节结束回顾';
    } else {
      final explicit = ReadingSkillRegistry.definitions.where(
        (skill) => _containsAny(queryText, skill.triggerKeywords),
      );
      if (explicit.isNotEmpty) {
        primary = explicit.first;
        reason = '匹配本次阅读意图';
      } else if (_looksLikeFiction(metadata)) {
        primary = registry.get(ReadingSkillId.fictionCharacterTracking);
        reason = '根据书籍信息识别为小说阅读';
      } else if (mode == ReadingAiMode.finance ||
          _looksLikeEconomics(metadata)) {
        primary = registry.get(
          _looksFinancial(metadata)
              ? ReadingSkillId.financialAssumptionValidation
              : ReadingSkillId.argumentMapping,
        );
        reason = '根据经济/财务主题匹配';
      } else if (mode == ReadingAiMode.psychology ||
          _looksLikePsychology(metadata)) {
        primary = registry.get(ReadingSkillId.socraticConcept);
        reason = '根据心理学主题匹配';
      } else if (mode == ReadingAiMode.history) {
        primary = registry.get(ReadingSkillId.historicalSourceCheck);
      } else {
        primary = registry.get(ReadingSkillId.argumentMapping);
      }
    }

    final explicitInvocation = queryText.isNotEmpty &&
        (_containsAny(queryText, primary.triggerKeywords) ||
            RegExp(r'使用|用.+方法|深入|拆解|核查|复习|回顾|计划').hasMatch(queryText));
    final loadLevel = deepAnalysis || chapterClosure || explicitInvocation
        ? ReadingSkillLoadLevel.full
        : ReadingSkillLoadLevel.summary;
    final supporting = primary.id == ReadingSkillId.chapterClosure
        ? _domainDefault(mode, metadata, exclude: primary.id)
        : null;
    return ReadingSkillSelection(
      primary: primary,
      supporting: supporting,
      loadLevel: loadLevel,
      reason: reason,
      pinned: pinned,
    );
  }

  ReadingSkillDefinition? _domainDefault(
    ReadingAiMode mode,
    String metadata, {
    required ReadingSkillId exclude,
  }) {
    final id = _looksLikeFiction(metadata)
        ? ReadingSkillId.fictionCharacterTracking
        : mode == ReadingAiMode.finance
            ? ReadingSkillId.financialAssumptionValidation
            : mode == ReadingAiMode.psychology
                ? ReadingSkillId.socraticConcept
                : mode == ReadingAiMode.history
                    ? ReadingSkillId.historicalSourceCheck
                    : ReadingSkillId.argumentMapping;
    return id == exclude ? null : registry.get(id);
  }

  bool _containsAny(String text, Iterable<String> values) =>
      text.isNotEmpty &&
      values.any((value) => text.contains(value.toLowerCase()));

  bool _looksLikeFiction(String text) => RegExp(
        r'小说|文学|故事|人物|侦探|悬疑|科幻|奇幻|言情|novel|fiction',
      ).hasMatch(text);

  bool _looksLikeEconomics(String text) => RegExp(
        r'经济|商业|市场|货币|资本|金融|投资|economics|economy|business',
      ).hasMatch(text);

  bool _looksFinancial(String text) => RegExp(
        r'财务|估值|投资|股票|现金流|利润|资产负债|finance|valuation|invest',
      ).hasMatch(text);

  bool _looksLikePsychology(String text) => RegExp(
        r'心理|认知|情绪|人格|行为|精神分析|psychology|cognitive|emotion',
      ).hasMatch(text);
}
