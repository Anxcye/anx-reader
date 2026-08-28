import 'package:anx_reader/page/reading_agent_help_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Reading Agent help teaches closure and safety boundaries',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReadingAgentHelpPage()),
    );

    expect(find.text('阅读 Agent 使用方法'), findsOneWidget);
    expect(find.text('四步完成一次阅读闭环'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('什么时候会调用 AI？'), 300);
    expect(find.text('什么时候会调用 AI？'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('写入、撤销与隐私'),
      300,
    );
    expect(find.text('AI 写入都可撤销'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Reading Skill help includes tailored recommendations and catalog',
      (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ReadingSkillHelpPage()),
    );

    expect(find.text('Reading Skill 使用方法'), findsOneWidget);
    expect(find.text('快速上手'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('适合你的三类阅读'), 300);
    expect(find.text('小说'), findsOneWidget);
    expect(find.text('经济学'), findsOneWidget);
    expect(find.text('心理学'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('全部阅读方法'), 300);
    expect(find.text('苏格拉底式概念教学'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
