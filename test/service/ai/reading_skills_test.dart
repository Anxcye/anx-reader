import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_skills.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const registry = ReadingSkillRegistry();
  const matcher = ReadingSkillMatcher();

  test('registry exposes ten unique reading methods with layered prompts', () {
    expect(ReadingSkillRegistry.definitions, hasLength(10));
    expect(
      ReadingSkillRegistry.definitions.map((item) => item.id).toSet(),
      hasLength(10),
    );
    for (final skill in ReadingSkillRegistry.definitions) {
      expect(skill.description, isNotEmpty);
      expect(skill.summaryInstruction, isNotEmpty);
      expect(skill.fullInstruction.length,
          greaterThan(skill.summaryInstruction.length));
      expect(registry.get(skill.id), same(skill));
    }
  });

  test('matches fiction, economics and psychology locally', () {
    expect(
      matcher
          .match(
            mode: ReadingAiMode.general,
            title: '长篇悬疑小说',
            description: '人物命运与未解伏笔',
          )
          .primary
          .id,
      ReadingSkillId.fictionCharacterTracking,
    );
    expect(
      matcher
          .match(
            mode: ReadingAiMode.general,
            title: '经济学原理',
            description: '市场与货币制度',
          )
          .primary
          .id,
      ReadingSkillId.argumentMapping,
    );
    expect(
      matcher
          .match(
            mode: ReadingAiMode.psychology,
            title: '认知心理学',
          )
          .primary
          .id,
      ReadingSkillId.socraticConcept,
    );
  });

  test('explicit intent and pinned method override automatic matching', () {
    final exam = matcher.match(
      mode: ReadingAiMode.general,
      title: '一部小说',
      query: '帮我按考试复习的方法整理考点',
    );
    expect(exam.primary.id, ReadingSkillId.examReview);
    expect(exam.loadLevel, ReadingSkillLoadLevel.full);

    final pinned = matcher.match(
      mode: ReadingAiMode.psychology,
      title: '心理学',
      query: '解释这个概念',
      pinnedSkill: ReadingSkillId.readingToAction,
    );
    expect(pinned.primary.id, ReadingSkillId.readingToAction);
    expect(pinned.pinned, isTrue);
  });

  test('ordinary context loads summary while deep and closure load full', () {
    final ordinary = matcher.match(
      mode: ReadingAiMode.general,
      title: '经济学原理',
    );
    expect(ordinary.loadLevel, ReadingSkillLoadLevel.summary);
    expect(ordinary.promptContext(), isNot(contains('按主张→证据')));

    final deep = matcher.match(
      mode: ReadingAiMode.general,
      title: '经济学原理',
      deepAnalysis: true,
    );
    expect(deep.loadLevel, ReadingSkillLoadLevel.full);
    expect(deep.promptContext(), contains('按主张→证据'));

    final closure = matcher.match(
      mode: ReadingAiMode.general,
      title: '一部小说',
      chapterClosure: true,
    );
    expect(closure.primary.id, ReadingSkillId.chapterClosure);
    expect(closure.supporting?.id, ReadingSkillId.fictionCharacterTracking);
    expect(closure.loadLevel, ReadingSkillLoadLevel.full);
  });
}
