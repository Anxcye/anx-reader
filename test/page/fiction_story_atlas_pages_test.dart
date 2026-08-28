import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/page/fiction_character_graph_page.dart';
import 'package:anx_reader/page/fiction_story_timeline_page.dart';
import 'package:anx_reader/service/ai/fiction_story_atlas_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 24).millisecondsSinceEpoch;
  final book = Book.mock().copyWith(readingPercentage: .5);

  ReadingArtifact artifact(
    String id,
    String kind,
    double progress,
    Map<String, dynamic> payload,
  ) =>
      ReadingArtifact(
        id: id,
        bookId: book.id,
        moduleId: 'fiction.immersion',
        kind: kind,
        payload: payload,
        sourceStartCfi: 'epubcfi(/6/$id)',
        sourceTextSnapshot: '来源正文',
        chapterTitle: '第一章',
        sourceProgress: progress,
        visibleFromProgress: progress,
        ingestedAt: now,
        createdAt: now,
        updatedAt: now,
      );

  final atlas = fictionStoryAtlasService.fromArtifacts([
    artifact('a', ReadingArtifactKinds.character, .1, {
      'entityId': 'a',
      'name': '第五伦',
      'summary': '剑客',
      'role': 'protagonist',
      'courtesyName': '伯鱼',
      'artName': '少君',
    }),
    artifact('b', ReadingArtifactKinds.character, .12,
        {'entityId': 'b', 'name': '诸葛亮', 'summary': '对手'}),
    artifact('r', ReadingArtifactKinds.relationship, .2, {
      'from': 'a',
      'to': 'b',
      'relation': 'rival',
      'summary': '在宫中交锋',
      'state': 'active',
    }),
    artifact('e', ReadingArtifactKinds.event, .25, {
      'title': '宫中交锋',
      'summary': '两人在宫中第一次正面交锋',
      'participants': ['a', 'b'],
      'importance': 'major',
    }),
  ], visibleAtProgress: .5);

  testWidgets('character graph uses initial avatars and relationship labels',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: FictionCharacterGraphPage(book: book, initialAtlas: atlas),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('人物关系图'), findsOneWidget);
    expect(find.text('第五伦'), findsOneWidget);
    expect(find.text('诸葛亮'), findsOneWidget);
    expect(find.text('伦'), findsOneWidget);
    expect(find.text('亮'), findsOneWidget);
    expect(find.text('对手'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    final protagonist =
        atlas.characters.firstWhere((character) => character.name == '第五伦');
    await tester.tap(
      find.byKey(ValueKey('fiction-character-${protagonist.id}')),
    );
    await tester.pump();
    expect(find.text('剑客'), findsOneWidget);
    expect(find.text('字：伯鱼'), findsOneWidget);
    expect(find.text('号：少君'), findsOneWidget);
    expect(find.text('已知关系'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('E-INK disables graph and timeline interaction animations',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget eink(Widget child) => MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child,
            ),
          ),
        );

    await tester.pumpWidget(
      eink(FictionCharacterGraphPage(book: book, initialAtlas: atlas)),
    );
    await tester.pump();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('对手'), findsOneWidget);

    await tester.pumpWidget(
      eink(FictionStoryTimelinePage(book: book, initialAtlas: atlas)),
    );
    await tester.pump();
    expect(
      tester
          .widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher).first)
          .duration,
      Duration.zero,
    );
  });

  testWidgets('dense character graph keeps nodes and relation labels apart',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final denseArtifacts = <ReadingArtifact>[
      artifact('main', ReadingArtifactKinds.character, .05, {
        'entityId': 'main',
        'name': '第五伦',
        'role': 'protagonist',
      }),
      for (var index = 0; index < 12; index++) ...[
        artifact(
            'person-$index', ReadingArtifactKinds.character, .1 + index / 100, {
          'entityId': 'person-$index',
          'name': '人物$index',
        }),
        artifact('relation-$index', ReadingArtifactKinds.relationship,
            .2 + index / 100, {
          'from': 'main',
          'to': 'person-$index',
          'relation': '朋友',
        }),
      ],
    ];
    final denseAtlas = fictionStoryAtlasService.fromArtifacts(
      denseArtifacts,
      visibleAtProgress: .5,
    );

    await tester.pumpWidget(MaterialApp(
      home: FictionCharacterGraphPage(book: book, initialAtlas: denseAtlas),
    ));
    await tester.pumpAndSettle();

    final nodeRects = [
      for (final character in denseAtlas.characters)
        tester.getRect(
          find.byKey(ValueKey('fiction-character-${character.id}')),
        ),
    ];
    for (var left = 0; left < nodeRects.length; left++) {
      for (var right = left + 1; right < nodeRects.length; right++) {
        expect(nodeRects[left].overlaps(nodeRects[right]), isFalse);
      }
    }
    for (final edge in denseAtlas.relationships) {
      final label = tester.getRect(find.byKey(
        ValueKey('fiction-relationship-${edge.from}-${edge.to}'),
      ));
      expect(nodeRects.any(label.overlaps), isFalse);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeline renders narrative order metadata on phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: FictionStoryTimelinePage(book: book, initialAtlas: atlas),
    ));
    await tester.pumpAndSettle();

    expect(find.text('故事事件时间线'), findsOneWidget);
    expect(find.text('宫中交锋'), findsOneWidget);
    expect(find.text('时间未明'), findsOneWidget);
    expect(find.text('正文顺序 · 安全边界 50%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
