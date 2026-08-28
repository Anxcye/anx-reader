import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/page/reading_outcomes_page.dart';
import 'package:anx_reader/service/ai/reading_outcomes_service.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReadingOutcomesService extends ReadingOutcomesService {
  _FakeReadingOutcomesService(this.snapshot);

  final ReadingOutcomesSnapshot snapshot;

  @override
  Future<ReadingOutcomesSnapshot> load(int bookId) async => snapshot;
}

const _historyClosure = ReadingClosurePolicyDefinition(
  id: 'history.evidence',
  title: '历史证据闭环',
  description: '区分史料与解释',
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
    ReadingOutcomeSectionSpec(
      id: 'memories',
      source: ReadingOutcomeSource.memories,
      title: '史料与解释',
      emptyText: '暂无史料记录',
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

void main() {
  final now = DateTime(2026, 8, 19, 12).millisecondsSinceEpoch;
  final book = Book(
    id: 1,
    title: '测试书籍',
    coverPath: '',
    filePath: '',
    lastReadPosition: 'epubcfi(/6/2)',
    readingPercentage: 0.42,
    author: '作者',
    isDeleted: false,
    rating: 0,
    createTime: DateTime(2026),
    updateTime: DateTime(2026),
  );
  final snapshot = ReadingOutcomesSnapshot(
    goals: [
      ReadingGoal(
        id: 'goal',
        bookId: 1,
        title: '理解本章',
        progress: 0.42,
        createdAt: now,
        updatedAt: now,
      ),
    ],
    masteryStates: [
      MasteryState(
        id: 'mastery',
        bookId: 1,
        topic: '第一章',
        level: MasteryLevel.familiar,
        score: 0.5,
        updatedAt: now,
      ),
    ],
    difficulties: [
      ReadingDifficulty(
        id: 'difficulty',
        bookId: 1,
        cfi: 'epubcfi(/6/4)',
        text: '这个概念与上一章有什么关系？',
        createdAt: now,
        updatedAt: now,
      ),
    ],
    knowledgeCards: [
      KnowledgeCard(
        id: 'card',
        bookId: 1,
        front: '请回忆：第一章',
        back: '这是折叠的答案',
        dueAt: now - 1,
        createdAt: now,
        updatedAt: now,
      ),
    ],
    memories: [
      ReadingMemoryDocument(
        id: 'memory',
        bookId: 1,
        title: '核心概念',
        markdown: '**重要结论**',
        createdAt: now,
        updatedAt: now,
      ),
    ],
    loadedAt: DateTime.fromMillisecondsSinceEpoch(now),
  );

  Future<void> pumpPage(
    WidgetTester tester,
    Size size, {
    Book? pageBook,
    String? closureId,
    ReadingClosurePolicyRegistry registry =
        const ReadingClosurePolicyRegistry(),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ReadingOutcomesPage(
            book: pageBook ?? book,
            service: _FakeReadingOutcomesService(snapshot),
            closureIdOverride: closureId,
            closureRegistry: registry,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the unified outcome hierarchy on a phone', (tester) async {
    await pumpPage(tester, const Size(390, 844));

    expect(find.text('本书阅读成果'), findsOneWidget);
    expect(find.text('下一步 · 先复习 1 张到期卡片'), findsOneWidget);
    expect(find.text('阅读目标'), findsOneWidget);
    expect(find.text('论证掌握度'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('待核查问题'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('待核查问题'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('论证与证据记忆'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('论证与证据记忆'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wraps outcome metrics without overflow on a tablet',
      (tester) async {
    await pumpPage(tester, const Size(1024, 768));

    expect(find.text('阅读进度'), findsOneWidget);
    expect(find.text('平均掌握'), findsOneWidget);
    expect(find.text('未解决'), findsOneWidget);
    expect(find.text('到期复习'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fiction closure hides mastery and review-card sections',
      (tester) async {
    final fiction = book.copyWith(
      title: '测试小说',
      description: '一部人物关系复杂的悬疑小说',
    );
    await pumpPage(
      tester,
      const Size(390, 844),
      pageBook: fiction,
      closureId: ReadingClosureIds.fictionImmersion,
    );

    expect(find.text('小说沉浸闭环'), findsOneWidget);
    expect(find.text('小说故事档案'), findsOneWidget);
    expect(find.text('人物关系图'), findsOneWidget);
    expect(find.text('故事时间线'), findsOneWidget);
    expect(find.text('故事记忆'), findsOneWidget);
    expect(find.text('未解悬念'), findsWidgets);
    expect(find.text('章节掌握度'), findsNothing);
    expect(find.text('复习卡片'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('psychology closure uses concept and reflection vocabulary',
      (tester) async {
    await pumpPage(
      tester,
      const Size(430, 900),
      closureId: ReadingClosureIds.psychologyReflection,
    );

    expect(find.text('心理学概念与反思闭环'), findsOneWidget);
    expect(find.text('概念清晰度'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('待澄清概念与反思'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('待澄清概念与反思'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a registered fourth closure without page changes',
      (tester) async {
    await pumpPage(
      tester,
      const Size(430, 900),
      closureId: 'history.evidence',
      registry: const ReadingClosurePolicyRegistry(
        additionalDefinitions: [_historyClosure],
      ),
    );

    expect(find.text('历史证据闭环'), findsOneWidget);
    expect(find.text('史料目标'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('史料与解释'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('史料与解释'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
