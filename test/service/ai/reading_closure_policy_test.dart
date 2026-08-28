import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const matcher = ReadingClosurePolicyMatcher();

  test('matches fiction, knowledge and psychology closures locally', () {
    expect(
      matcher
          .match(
            mode: ReadingAiMode.general,
            title: '长篇悬疑小说',
            description: '人物关系与故事',
          )
          .id,
      ReadingClosureIds.fictionImmersion,
    );
    expect(
      matcher
          .match(
            mode: ReadingAiMode.general,
            title: '经济学原理',
          )
          .id,
      ReadingClosureIds.knowledgeArgument,
    );
    expect(
      matcher
          .match(
            mode: ReadingAiMode.psychology,
            title: '心理学',
          )
          .id,
      ReadingClosureIds.psychologyReflection,
    );
  });

  test(
      'detects suspense as a BookReadingProfile facet without replacing the fiction closure',
      () {
    final detected = matcher.detect(
      mode: ReadingAiMode.general,
      title: '法医秦明：悬疑案件',
      description: '刑侦推理小说',
    );
    expect(detected.moduleId, ReadingClosureIds.fictionImmersion);
    expect(
        detected.facets,
        containsAll([
          ReadingProfileFacetIds.suspense,
          ReadingProfileFacetIds.processingVolumeCaseScene,
          ReadingProfileFacetIds.entitiesSuspense,
          ReadingProfileFacetIds.timelineNarrativeOrder,
          ReadingProfileFacetIds.relationshipsDurableOnly,
        ]));
    final profile = BookReadingProfile(
      bookId: 1,
      primaryModuleId: detected.moduleId,
      facets: detected.facets,
      confidence: detected.confidence,
      createdAt: 1,
      updatedAt: 1,
    );
    expect(profile.isSuspense, isTrue);
    expect(ReadingClosureIds.fictionSuspense, ReadingProfileFacetIds.suspense);
    expect(profile.processingStrategy,
        ReadingProfileFacetIds.processingVolumeCaseScene);
    expect(profile.relationshipStrategy,
        ReadingProfileFacetIds.relationshipsDurableOnly);
    expect(profile.defaultStoryTrack, FictionEventTrackIds.caseInvestigation);
  });

  test('book profile selects a stable default story track by genre', () {
    BookReadingProfile profileFor(String title, String description) {
      final detected = matcher.detect(
        mode: ReadingAiMode.general,
        title: title,
        description: description,
      );
      return BookReadingProfile(
        bookId: 1,
        primaryModuleId: detected.moduleId,
        facets: detected.facets,
        createdAt: 1,
        updatedAt: 1,
      );
    }

    expect(profileFor('家族往事', '现实主义家庭小说').defaultStoryTrack,
        FictionEventTrackIds.family);
    expect(profileFor('王朝兴亡', '历史小说').defaultStoryTrack,
        FictionEventTrackIds.historical);
    expect(profileFor('普通小说', '一个人的成长').defaultStoryTrack,
        FictionEventTrackIds.character);
    final scienceFiction = profileFor('三体', '宇宙文明科幻小说');
    expect(
        scienceFiction.facets, contains(ReadingProfileFacetIds.scienceFiction));
    expect(scienceFiction.facets,
        contains(ReadingProfileFacetIds.entitiesWorldbuilding));
    expect(
        scienceFiction.defaultStoryTrack, FictionEventTrackIds.worldbuilding);
  });

  test('pinned closure overrides metadata and exposes distinct behavior', () {
    final closure = matcher.match(
      mode: ReadingAiMode.general,
      title: '一部小说',
      pinnedId: ReadingClosureIds.knowledgeArgument,
    );
    expect(closure.id, ReadingClosureIds.knowledgeArgument);
    expect(closure.showMastery, isTrue);
    expect(closure.showKnowledgeCards, isTrue);
    expect(closure.defaultCreateKnowledgeCard, isFalse);

    expect(
      ReadingClosurePolicyRegistry.fictionImmersion.checkpointTriggersCapsule,
      isFalse,
    );
    expect(
      ReadingClosurePolicyRegistry.fictionImmersion.showMastery,
      isFalse,
    );
  });

  test('legacy enum and preference names map to stable ids', () {
    // ignore: deprecated_member_use_from_same_package
    expect(ReadingClosureType.fictionImmersion.stableId,
        ReadingClosureIds.fictionImmersion);
    expect(ReadingClosureIds.normalize('psychologyReflection'),
        ReadingClosureIds.psychologyReflection);
  });

  test('registry accepts a fourth module without changing matcher code', () {
    const fourth = ReadingClosurePolicyDefinition(
      id: 'history.evidence',
      title: '历史证据闭环',
      description: '测试扩展模块',
      goalLabel: '史料目标',
      goalTemplateSpecs: [
        ReadingGoalTemplateSpec(id: 'source', title: '核查一条史料'),
      ],
      checkpoint: ReadingCheckpointSpec(
        title: '史料检查',
        actionLabel: '核查',
        emptyText: '暂无',
        reflectionLabel: '争议',
        reflectionHelperText: '区分事实与解释',
        memoryTitleSuffix: '史料',
      ),
      outcomeSections: [
        ReadingOutcomeSectionSpec(
          id: 'goals',
          source: ReadingOutcomeSource.goals,
          title: '史料目标',
          emptyText: '暂无史料目标',
        ),
      ],
      quickPrompts: [
        ReadingQuickPromptSpec(
          id: 'source-check',
          label: '核查史料',
          prompt: '区分原始史料与解释。',
        ),
      ],
      systemGuidance: 'Separate sources from interpretations.',
    );
    const registry =
        ReadingClosurePolicyRegistry(additionalDefinitions: [fourth]);
    final matched = ReadingClosurePolicyMatcher(registry: registry).match(
      mode: ReadingAiMode.history,
      pinnedId: 'history.evidence',
    );
    expect(matched.id, 'history.evidence');
    expect(matched.goalTemplateSpecs.single.title, '核查一条史料');
    expect(matched.quickPrompts.single.label, '核查史料');

    // The outcomes surface consumes declaration fields generically. A fourth
    // registered type therefore needs no page/type switch to expose its
    // sections, goals, checkpoint and prompts.
    expect(registry.definitions, contains(fourth));
    expect(fourth.outcomeSections.map((item) => item.id), ['goals']);
    expect(fourth.checkpoint.title, '史料检查');
  });
}
