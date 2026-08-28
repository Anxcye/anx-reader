import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/providers/ai_workspace.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/widgets/ai/ai_chat_stream.dart';
import 'package:anx_reader/widgets/ai/ai_reading_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fourthClosure = ReadingClosurePolicyDefinition(
  id: 'history.evidence',
  title: '历史证据闭环',
  description: '区分史料、解释与争议',
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

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs().initPrefs();
  });

  testWidgets('reading workspace renders a registered fourth closure',
      (tester) async {
    final controller = AiWorkspaceController(bookId: 4);
    controller.setReadingProfile(const BookReadingProfile(
      bookId: 4,
      primaryModuleId: 'history.evidence',
      pinned: true,
      createdAt: 1,
      updatedAt: 1,
    ));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: AiReadingWorkspace(
              controller: controller,
              chatKey: GlobalKey<AiChatStreamState>(),
              quickPromptChips: const [],
              bookTitle: '历史测试书',
              bookAuthor: '作者',
              closureRegistry: const ReadingClosurePolicyRegistry(
                additionalDefinitions: [_fourthClosure],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('阅读闭环 · 历史证据闭环'), findsOneWidget);
    final closureBar = find.ancestor(
      of: find.text('阅读闭环 · 历史证据闭环'),
      matching: find.byType(InkWell),
    );
    await tester.tap(closureBar.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('选择本书阅读闭环'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('区分史料、解释与争议'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('区分史料、解释与争议'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
