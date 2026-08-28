import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';

/// Stable identifiers persisted in reading profiles and artifacts.
abstract final class ReadingClosureIds {
  static const fictionImmersion = 'fiction.immersion';

  /// Profile facet for suspense/case-oriented fiction. It is intentionally
  /// not a fourth closure: suspense books still use the immersive outcome
  /// declarations and only specialize processing/projection behavior.
  static const fictionSuspense = 'fiction.suspense';
  static const knowledgeArgument = 'knowledge.argument';
  static const psychologyReflection = 'psychology.reflection';

  static const legacyAliases = <String, String>{
    'fictionImmersion': fictionImmersion,
    'knowledgeArgument': knowledgeArgument,
    'psychologyReflection': psychologyReflection,
  };

  static String? normalize(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return legacyAliases[raw] ?? raw;
  }
}

/// Compatibility surface for v17 preferences and older callers.
@Deprecated('Use ReadingClosureIds and ReadingClosurePolicyDefinition.id')
enum ReadingClosureType {
  fictionImmersion,
  knowledgeArgument,
  psychologyReflection;

  String get stableId => switch (this) {
        fictionImmersion => ReadingClosureIds.fictionImmersion,
        knowledgeArgument => ReadingClosureIds.knowledgeArgument,
        psychologyReflection => ReadingClosureIds.psychologyReflection,
      };

  static ReadingClosureType? fromJson(Object? value) {
    final id = ReadingClosureIds.normalize(value);
    return switch (id) {
      ReadingClosureIds.fictionImmersion => fictionImmersion,
      ReadingClosureIds.knowledgeArgument => knowledgeArgument,
      ReadingClosureIds.psychologyReflection => psychologyReflection,
      _ => null,
    };
  }
}

enum ReadingClosureCapability {
  mastery,
  knowledgeCards,
  markdownMemory,
  readingArtifacts,
  spoilerBoundary,
  resumeContext,
  storyAtlas,
}

enum ReadingOutcomeSource {
  goals,
  checkpoints,
  mastery,
  difficulties,
  knowledgeCards,
  memories,
  artifacts,
}

class ReadingGoalTemplateSpec {
  const ReadingGoalTemplateSpec({
    required this.id,
    required this.title,
    this.criteria = const [],
  });

  final String id;
  final String title;
  final List<String> criteria;
}

class ReadingMasteryOptionSpec {
  const ReadingMasteryOptionSpec({required this.level, required this.label});

  final MasteryLevel level;
  final String label;
}

class ReadingCheckpointSpec {
  const ReadingCheckpointSpec({
    required this.title,
    required this.actionLabel,
    required this.emptyText,
    required this.reflectionLabel,
    required this.reflectionHelperText,
    required this.memoryTitleSuffix,
    this.masteryLabel,
    this.masteryOptions = const [],
    this.showKnowledgeCardOption = false,
    this.defaultCreateKnowledgeCard = false,
    this.triggersCapsule = true,
    this.saveReflectionAsMemory = false,
  });

  final String title;
  final String actionLabel;
  final String emptyText;
  final String reflectionLabel;
  final String reflectionHelperText;
  final String memoryTitleSuffix;
  final String? masteryLabel;
  final List<ReadingMasteryOptionSpec> masteryOptions;
  final bool showKnowledgeCardOption;
  final bool defaultCreateKnowledgeCard;
  final bool triggersCapsule;
  final bool saveReflectionAsMemory;

  bool get showsMastery => masteryOptions.isNotEmpty;
}

class ReadingOutcomeSectionSpec {
  const ReadingOutcomeSectionSpec({
    required this.id,
    required this.source,
    required this.title,
    required this.emptyText,
    this.visibleWhenEmpty = true,
  });

  final String id;
  final ReadingOutcomeSource source;
  final String title;
  final String emptyText;
  final bool visibleWhenEmpty;
}

class ReadingQuickPromptSpec {
  const ReadingQuickPromptSpec({
    required this.id,
    required this.label,
    required this.prompt,
  });

  final String id;
  final String label;
  final String prompt;
}

class ReadingClosurePolicyDefinition {
  const ReadingClosurePolicyDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.goalLabel,
    required this.goalTemplateSpecs,
    required this.checkpoint,
    required this.outcomeSections,
    required this.quickPrompts,
    required this.systemGuidance,
    this.capabilities = const {},
    this.heroMasteryLabel = '平均掌握',
    this.heroUnresolvedLabel = '未解决',
    this.immersive = false,
  });

  final String id;
  final String title;
  final String description;
  final String goalLabel;
  final List<ReadingGoalTemplateSpec> goalTemplateSpecs;
  final ReadingCheckpointSpec checkpoint;
  final List<ReadingOutcomeSectionSpec> outcomeSections;
  final List<ReadingQuickPromptSpec> quickPrompts;
  final String systemGuidance;
  final Set<ReadingClosureCapability> capabilities;
  final String heroMasteryLabel;
  final String heroUnresolvedLabel;
  final bool immersive;

  bool supports(ReadingClosureCapability capability) =>
      capabilities.contains(capability);

  List<String> get goalTemplates =>
      goalTemplateSpecs.map((item) => item.title).toList(growable: false);
  String get checkpointTitle => checkpoint.title;
  String get checkpointAction => checkpoint.actionLabel;
  String get checkpointEmptyText => checkpoint.emptyText;
  String get masteryTitle => _sectionTitle(ReadingOutcomeSource.mastery);
  String get difficultyTitle =>
      _sectionTitle(ReadingOutcomeSource.difficulties);
  String get memoryTitle => _sectionTitle(ReadingOutcomeSource.memories);
  String get memoryHint => _sectionEmptyText(ReadingOutcomeSource.memories);
  bool get showMastery => checkpoint.showsMastery;
  bool get showKnowledgeCards => checkpoint.showKnowledgeCardOption;
  bool get checkpointTriggersCapsule => checkpoint.triggersCapsule;
  bool get defaultCreateKnowledgeCard => checkpoint.defaultCreateKnowledgeCard;

  String _sectionTitle(ReadingOutcomeSource source) {
    for (final item in outcomeSections) {
      if (item.source == source) return item.title;
    }
    return '';
  }

  String _sectionEmptyText(ReadingOutcomeSource source) {
    for (final item in outcomeSections) {
      if (item.source == source) return item.emptyText;
    }
    return '';
  }

  @Deprecated('Use id')
  ReadingClosureType? get type => ReadingClosureType.fromJson(id);
}

class ReadingClosurePolicyRegistry {
  const ReadingClosurePolicyRegistry({this.additionalDefinitions = const []});

  final List<ReadingClosurePolicyDefinition> additionalDefinitions;

  static const fictionImmersion = ReadingClosurePolicyDefinition(
    id: ReadingClosureIds.fictionImmersion,
    title: '小说沉浸闭环',
    description: '优先保持叙事节奏，按需记录人物、关系、伏笔、悬念和感受。',
    goalLabel: '阅读意图',
    goalTemplateSpecs: [
      ReadingGoalTemplateSpec(id: 'enjoy', title: '享受故事，不被打断'),
      ReadingGoalTemplateSpec(id: 'finish-range', title: '读完当前部分'),
      ReadingGoalTemplateSpec(id: 'track-story', title: '跟踪人物与伏笔'),
    ],
    checkpoint: ReadingCheckpointSpec(
      title: '可回顾章节',
      actionLabel: '回顾',
      emptyText: '章节切换会静默积累可回顾内容，不会主动提醒。',
      reflectionLabel: '这一章的感受或未解悬念（可选）',
      reflectionHelperText: '只记录当前进度以前的信息，不做掌握度测试',
      memoryTitleSuffix: '阅读感受',
      triggersCapsule: false,
      saveReflectionAsMemory: true,
    ),
    outcomeSections: [
      ReadingOutcomeSectionSpec(
        id: 'goals',
        source: ReadingOutcomeSource.goals,
        title: '阅读意图',
        emptyText: '还没有阅读意图，可在阅读 Agent 面板中创建。',
      ),
      ReadingOutcomeSectionSpec(
        id: 'checkpoints',
        source: ReadingOutcomeSource.checkpoints,
        title: '可回顾章节',
        emptyText: '章节切换后会在这里静默积累。',
        visibleWhenEmpty: false,
      ),
      ReadingOutcomeSectionSpec(
        id: 'difficulties',
        source: ReadingOutcomeSource.difficulties,
        title: '未解悬念',
        emptyText: '当前没有未解悬念。',
      ),
      ReadingOutcomeSectionSpec(
        id: 'artifacts',
        source: ReadingOutcomeSource.artifacts,
        title: '人物与悬念档案',
        emptyText: '保存人物、关系或悬念后，会在这里形成当前位置安全的故事档案。',
      ),
      ReadingOutcomeSectionSpec(
        id: 'memories',
        source: ReadingOutcomeSource.memories,
        title: '人物、伏笔与感受',
        emptyText: '可保存人物关系变化、已出现伏笔、喜欢的摘录或自己的阅读感受。',
      ),
    ],
    quickPrompts: [
      ReadingQuickPromptSpec(
        id: 'fiction-character-recall',
        label: '这个人物是谁',
        prompt: '只根据当前阅读进度以前的内容，说明我询问的人物是谁、与主要人物的关系和最近一次出现。区分文本事实与推测，禁止剧透后文。',
      ),
      ReadingQuickPromptSpec(
        id: 'fiction-story-state',
        label: '人物与悬念',
        prompt: '只根据当前阅读进度以前的内容，整理已登场人物、关系变化和未解悬念。区分文本事实与推测，禁止剧透后文。',
      ),
    ],
    systemGuidance:
        'Prioritize immersion and spoiler safety. Do not quiz, score mastery, or schedule review cards by default. Track only facts available before the current reading position, and clearly separate textual facts from guesses.',
    capabilities: {
      ReadingClosureCapability.markdownMemory,
      ReadingClosureCapability.readingArtifacts,
      ReadingClosureCapability.spoilerBoundary,
      ReadingClosureCapability.resumeContext,
      ReadingClosureCapability.storyAtlas,
    },
    heroUnresolvedLabel: '未解悬念',
    immersive: true,
  );

  static const knowledgeArgument = ReadingClosurePolicyDefinition(
    id: ReadingClosureIds.knowledgeArgument,
    title: '经济／知识论证闭环',
    description: '围绕主张、证据、隐含假设、反例和适用边界形成理解。',
    goalLabel: '阅读目标',
    goalTemplateSpecs: [
      ReadingGoalTemplateSpec(id: 'understand-argument', title: '理解本章核心论证'),
      ReadingGoalTemplateSpec(id: 'finish-range', title: '完成指定范围'),
      ReadingGoalTemplateSpec(id: 'argument-note', title: '形成主张—证据—假设笔记'),
    ],
    checkpoint: ReadingCheckpointSpec(
      title: '待完成论证检查',
      actionLabel: '检查',
      emptyText: '读完章节后可检查核心主张、证据和假设。',
      reflectionLabel: '一句话概括核心论证（可选）',
      reflectionHelperText: '反思是你的记录，不会被当作已掌握的事实',
      memoryTitleSuffix: '论证回顾',
      masteryLabel: '当前掌握度',
      masteryOptions: [
        ReadingMasteryOptionSpec(
            level: MasteryLevel.emerging, label: '识别了核心主张'),
        ReadingMasteryOptionSpec(
            level: MasteryLevel.familiar, label: '能说明证据和假设'),
        ReadingMasteryOptionSpec(
            level: MasteryLevel.mastered, label: '能提出反例或应用边界'),
      ],
      showKnowledgeCardOption: true,
    ),
    outcomeSections: [
      ReadingOutcomeSectionSpec(
          id: 'goals',
          source: ReadingOutcomeSource.goals,
          title: '阅读目标',
          emptyText: '还没有阅读目标，可在阅读 Agent 面板中创建。'),
      ReadingOutcomeSectionSpec(
          id: 'checkpoints',
          source: ReadingOutcomeSource.checkpoints,
          title: '待完成论证检查',
          emptyText: '读完章节后可检查核心论证。',
          visibleWhenEmpty: false),
      ReadingOutcomeSectionSpec(
          id: 'mastery',
          source: ReadingOutcomeSource.mastery,
          title: '论证掌握度',
          emptyText: '检查章节后，这里会形成用户确认的记录。'),
      ReadingOutcomeSectionSpec(
          id: 'difficulties',
          source: ReadingOutcomeSource.difficulties,
          title: '待核查问题',
          emptyText: '当前没有待核查问题。'),
      ReadingOutcomeSectionSpec(
          id: 'cards',
          source: ReadingOutcomeSource.knowledgeCards,
          title: '复习卡片',
          emptyText: '章节检查时可选择生成复习卡片，默认不会创建。'),
      ReadingOutcomeSectionSpec(
          id: 'memories',
          source: ReadingOutcomeSource.memories,
          title: '论证与证据记忆',
          emptyText: '适合保存主张—证据—假设、反例、数据口径和待验证条件。'),
    ],
    quickPrompts: [
      ReadingQuickPromptSpec(
          id: 'argument-map',
          label: '拆解本章论证',
          prompt: '拆解本章的核心主张、证据、隐含假设、可能反例和适用边界。'),
    ],
    systemGuidance:
        'Build the closure around claims, evidence, assumptions, counterexamples, and applicability. Do not treat persuasive wording as evidence. Mastery and review-card writes require user confirmation.',
    capabilities: {
      ReadingClosureCapability.mastery,
      ReadingClosureCapability.knowledgeCards,
      ReadingClosureCapability.markdownMemory,
    },
  );

  static const psychologyReflection = ReadingClosurePolicyDefinition(
    id: ReadingClosureIds.psychologyReflection,
    title: '心理学概念与反思闭环',
    description: '澄清概念边界，用可选反思联系情境，但不诊断、不评判。',
    goalLabel: '理解与反思意图',
    goalTemplateSpecs: [
      ReadingGoalTemplateSpec(id: 'understand-concept', title: '理解一个核心概念'),
      ReadingGoalTemplateSpec(id: 'concept-boundary', title: '区分概念、例子与反例'),
      ReadingGoalTemplateSpec(id: 'optional-reflection', title: '完成一次可选反思'),
    ],
    checkpoint: ReadingCheckpointSpec(
      title: '待完成概念检查',
      actionLabel: '检查',
      emptyText: '可检查概念边界，并选择是否写下一句个人反思。',
      reflectionLabel: '概念理解或个人反思（可选）',
      reflectionHelperText: '反思是你的记录，不会被当作心理事实',
      memoryTitleSuffix: '概念与反思',
      masteryLabel: '概念清晰度',
      masteryOptions: [
        ReadingMasteryOptionSpec(level: MasteryLevel.emerging, label: '概念仍模糊'),
        ReadingMasteryOptionSpec(
            level: MasteryLevel.familiar, label: '能区分例子与反例'),
        ReadingMasteryOptionSpec(
            level: MasteryLevel.mastered, label: '能解释边界与应用'),
      ],
      showKnowledgeCardOption: true,
      saveReflectionAsMemory: true,
    ),
    outcomeSections: [
      ReadingOutcomeSectionSpec(
          id: 'goals',
          source: ReadingOutcomeSource.goals,
          title: '理解与反思意图',
          emptyText: '还没有理解与反思意图，可在阅读 Agent 面板中创建。'),
      ReadingOutcomeSectionSpec(
          id: 'checkpoints',
          source: ReadingOutcomeSource.checkpoints,
          title: '待完成概念检查',
          emptyText: '读完章节后可检查概念边界。',
          visibleWhenEmpty: false),
      ReadingOutcomeSectionSpec(
          id: 'mastery',
          source: ReadingOutcomeSource.mastery,
          title: '概念清晰度',
          emptyText: '检查章节后，这里会形成用户确认的记录。'),
      ReadingOutcomeSectionSpec(
          id: 'difficulties',
          source: ReadingOutcomeSource.difficulties,
          title: '待澄清概念与反思',
          emptyText: '当前没有待澄清内容。'),
      ReadingOutcomeSectionSpec(
          id: 'cards',
          source: ReadingOutcomeSource.knowledgeCards,
          title: '复习卡片',
          emptyText: '章节检查时可选择生成复习卡片，默认不会创建。'),
      ReadingOutcomeSectionSpec(
          id: 'memories',
          source: ReadingOutcomeSource.memories,
          title: '概念与反思记忆',
          emptyText: '适合保存概念边界、例子、反例和用户主动写下的反思。'),
    ],
    quickPrompts: [
      ReadingQuickPromptSpec(
          id: 'clarify-concept',
          label: '澄清核心概念',
          prompt: '解释本章核心概念、边界、例子与反例；最后最多给一个可选的反思问题，不诊断、不评判。'),
    ],
    systemGuidance:
        'Clarify concepts, boundaries, examples, and counterexamples. Offer at most one optional reflection question at a time. Never diagnose, judge, or present reflection as a psychological fact about the user.',
    capabilities: {
      ReadingClosureCapability.mastery,
      ReadingClosureCapability.knowledgeCards,
      ReadingClosureCapability.markdownMemory,
    },
    heroMasteryLabel: '概念清晰度',
  );

  static const builtIns = [
    fictionImmersion,
    knowledgeArgument,
    psychologyReflection,
  ];

  List<ReadingClosurePolicyDefinition> get definitions =>
      List.unmodifiable([...builtIns, ...additionalDefinitions]);

  ReadingClosurePolicyDefinition getById(String id) {
    final normalized = ReadingClosureIds.normalize(id);
    return definitions.firstWhere(
      (item) => item.id == normalized,
      orElse: () => knowledgeArgument,
    );
  }

  bool contains(String id) {
    final normalized = ReadingClosureIds.normalize(id);
    return definitions.any((item) => item.id == normalized);
  }

  @Deprecated('Use getById')
  ReadingClosurePolicyDefinition get(ReadingClosureType type) =>
      getById(type.stableId);
}

class ReadingClosurePolicyMatcher {
  const ReadingClosurePolicyMatcher({
    this.registry = const ReadingClosurePolicyRegistry(),
  });

  final ReadingClosurePolicyRegistry registry;

  DetectedReadingProfile detect({
    required ReadingAiMode mode,
    String title = '',
    String author = '',
    String description = '',
  }) {
    final text = '$title $author $description'.toLowerCase();
    final facets = <String>{
      if (RegExp(r'悬疑|推理|侦探|刑侦|法医|案件|谋杀|suspense|mystery|detective')
          .hasMatch(text)) ...{
        ReadingProfileFacetIds.suspense,
        ReadingProfileFacetIds.processingVolumeCaseScene,
        ReadingProfileFacetIds.entitiesSuspense,
        ReadingProfileFacetIds.timelineNarrativeOrder,
        ReadingProfileFacetIds.relationshipsDurableOnly,
      },
      if (RegExp(r'历史|王朝|战争|history|historical').hasMatch(text)) ...{
        'historical',
        ReadingProfileFacetIds.timelineHistoricalDefault,
      },
      if (RegExp(r'家族|家庭|亲情|现实主义|family|realist').hasMatch(text)) ...{
        ReadingProfileFacetIds.timelineFamilyDefault,
      },
      if (RegExp(r'科幻|宇宙|星际|外星|未来|机器人|人工智能|science fiction|sci-fi|space opera')
          .hasMatch(text)) ...{
        ReadingProfileFacetIds.scienceFiction,
        ReadingProfileFacetIds.entitiesWorldbuilding,
        ReadingProfileFacetIds.timelineWorldbuildingDefault,
      },
      if (RegExp(r'外语|英语|日语|法语|english|japanese|french').hasMatch(text))
        'foreign_language',
      if (RegExp(r'投资|金融|财务|估值|finance|invest').hasMatch(text)) 'finance',
      if (RegExp(r'论文|研究|实验|paper|research').hasMatch(text)) 'academic',
    };
    final policy = match(
      mode: mode,
      title: title,
      author: author,
      description: description,
    );
    final hasDefaultTimeline =
        facets.any((facet) => facet.startsWith('timeline.default.'));
    if (policy.id == ReadingClosureIds.fictionImmersion &&
        !hasDefaultTimeline &&
        !facets.contains(ReadingProfileFacetIds.suspense)) {
      facets.add(ReadingProfileFacetIds.timelineCharacterDefault);
    }
    if (facets.contains(ReadingProfileFacetIds.suspense)) {
      facets.add(ReadingProfileFacetIds.timelineCaseDefault);
    }
    final explicitSignal =
        policy.id != ReadingClosureIds.knowledgeArgument || facets.isNotEmpty;
    return DetectedReadingProfile(
      moduleId: policy.id,
      facets: facets.toList(growable: false)..sort(),
      confidence: explicitSignal ? 0.82 : 0.55,
    );
  }

  ReadingClosurePolicyDefinition match({
    required ReadingAiMode mode,
    String title = '',
    String author = '',
    String description = '',
    String? pinnedId,
    @Deprecated('Use pinnedId') ReadingClosureType? pinnedType,
  }) {
    final requestedId =
        ReadingClosureIds.normalize(pinnedId) ?? pinnedType?.stableId;
    if (requestedId != null && registry.contains(requestedId)) {
      return registry.getById(requestedId);
    }
    final metadata = '$title $author $description'.toLowerCase();
    if (RegExp(r'小说|文学|故事|侦探|悬疑|科幻|奇幻|言情|推理|novel|fiction')
        .hasMatch(metadata)) {
      return registry.getById(ReadingClosureIds.fictionImmersion);
    }
    if (mode == ReadingAiMode.psychology ||
        RegExp(r'心理|认知|情绪|人格|行为科学|精神分析|psychology|cognitive|emotion')
            .hasMatch(metadata)) {
      return registry.getById(ReadingClosureIds.psychologyReflection);
    }
    return registry.getById(ReadingClosureIds.knowledgeArgument);
  }
}

class DetectedReadingProfile {
  const DetectedReadingProfile({
    required this.moduleId,
    this.facets = const [],
    required this.confidence,
  });

  final String moduleId;
  final List<String> facets;
  final double confidence;
}
