import 'dart:io';
import 'dart:ui' as ui;

import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_materials.dart';
import 'package:anx_reader/models/next_reading_action.dart';
import 'package:anx_reader/service/ai/fiction_story_atlas_service.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/service/ai/reading_outcomes_service.dart';
import 'package:anx_reader/widgets/reading_page/reading_book_hub.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:anx_reader/widgets/reading_page/reading_workspace_host.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final book = Book(
      id: 7,
      title: '测试小说',
      coverPath: '',
      filePath: '',
      lastReadPosition: 'epubcfi(/6/2)',
      readingPercentage: .36,
      author: '作者',
      isDeleted: false,
      rating: 0,
      createTime: DateTime(2026),
      updateTime: DateTime(2026));
  final atlas =
      fictionStoryAtlasService.fromArtifacts(const [], visibleAtProgress: .36);
  const next = NextReadingAction(
      id: 'next',
      kind: NextReadingActionKinds.resumeContext,
      bookId: 7,
      sourceId: 'resume',
      title: '恢复上次阅读上下文',
      reason: '先回顾近期人物和场景。',
      priority: 0,
      target: NextReadingActionTarget(
          kind: NextReadingActionTargetKinds.resumeContext),
      completionFingerprint: 'resume:7');
  const passive = NextReadingAction(
      id: 'continue',
      kind: NextReadingActionKinds.continueReading,
      bookId: 7,
      sourceId: 'reader',
      title: '继续阅读',
      reason: '保持沉浸。',
      priority: 0,
      target:
          NextReadingActionTarget(kind: NextReadingActionTargetKinds.reader),
      completionFingerprint: 'reader:7');

  Widget app(
          {BookMaterialsSnapshot? materials,
          bool quiet = false,
          bool syncing = false,
          bool disableAnimations = false,
          double textScale = 1,
          Future<void> Function(BookMaterialItem)? onOpenMaterial,
          Future<void> Function()? onContext,
          Future<void> Function()? onTimeline}) =>
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh'),
        theme: ThemeData(
            fontFamily: 'ReadingVisual',
            useMaterial3: true,
            colorScheme: disableAnimations
                ? const ColorScheme.light(
                    primary: Colors.black,
                    surface: Colors.white,
                    onSurface: Colors.black,
                    outline: Colors.black)
                : null),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
              disableAnimations: disableAnimations,
              textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
              body: ReadingBookHubContent(
            book: book,
            state: ReadingOutcomesSnapshot(loadedAt: DateTime(2026)),
            closure: ReadingClosurePolicyRegistry.fictionImmersion,
            nextAction: quiet ? passive : next,
            atlas: atlas,
            syncing: syncing,
            syncEnabled: true,
            materials: materials,
            onOpenMaterial: onOpenMaterial,
            onOpenContextPack: onContext,
            onOpenTimeline: onTimeline,
            onNextAction: () async {},
            onOpenOutcomes: () async {},
            onOpenWiki: () async {},
            onOpenStoryArchive: () async {},
            onSync: () async {},
            onOpenReadingSettings: () async {},
          )),
        ),
      );

  for (final spec in [
    (name: 'wide', size: const Size(1200, 900), scale: 1.0, eink: false),
    (name: 'phone', size: const Size(400, 800), scale: 1.0, eink: false),
    (name: 'eink', size: const Size(1000, 800), scale: 1.0, eink: true),
    (name: 'large-text', size: const Size(400, 800), scale: 1.8, eink: false),
  ]) {
    testWidgets('directory visual layout ${spec.name}', (tester) async {
      await tester.binding.setSurfaceSize(spec.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final font = FontLoader('ReadingVisual')
        ..addFont(rootBundle.load('assets/fonts/SourceHanSerifSC-Regular.otf'));
      await font.load();
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
      final capture = GlobalKey();
      final panel = app(
          quiet: true,
          disableAnimations: spec.eink,
          textScale: spec.scale,
          materials: const BookMaterialsSnapshot(
            bookId: 7,
            visibleAtProgress: .36,
            items: [
              BookMaterialItem(
                  id: 'character',
                  sourceId: 'character',
                  section: BookMaterialSection.characters,
                  title: '人物甲',
                  summary: '来自已读章节的人物资料'),
              BookMaterialItem(
                  id: 'record',
                  sourceId: 'record',
                  section: BookMaterialSection.records,
                  title: '我的阅读问题',
                  summary: '为什么作者在这里提出这一点？'),
            ],
          ));
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            fontFamily: 'ReadingVisual',
            useMaterial3: true,
            colorScheme: spec.eink
                ? const ColorScheme.light(
                    primary: Colors.black,
                    surface: Colors.white,
                    onSurface: Colors.black,
                    outline: Colors.black)
                : ColorScheme.fromSeed(seedColor: Colors.teal)),
        home: RepaintBoundary(
            key: capture,
            child: ReadingWorkspaceHost(
              visible: true,
              expanded: false,
              reader: Material(
                  child: ColoredBox(
                      color: const Color(0xfffaf8f1),
                      child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                              '阅读正文\n\n阅读时，疑问往往产生在某一个段落。\n保留当前的位置，再看看本书已留下的资料。',
                              style: TextStyle(
                                  fontSize: 20 * spec.scale, height: 1.8))))),
              panel: panel,
            )),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
          find.byKey(const ValueKey('book-materials-search')), findsOneWidget);
      if (const bool.fromEnvironment('READING_VISUALS')) {
        await tester.runAsync(() async {
          final boundary = capture.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('/tmp/anx-reading-visuals')
            ..createSync(recursive: true);
          File('${directory.path}/book-${spec.name}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }

  testWidgets('book hub has one next step and a local content directory',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('恢复上次阅读上下文'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '开始'), findsOneWidget);
    expect(find.text('书籍 Wiki'), findsNothing);
    expect(find.text('故事档案'), findsNothing);
    expect(find.byKey(const ValueKey('book-materials-search')), findsOneWidget);
    expect(find.text('可建立的资料'), findsOneWidget);
    expect(find.text('人物与关系'), findsNothing);
    await tester.tap(find.text('可建立的资料'));
    await tester.pumpAndSettle();
    expect(find.text('人物与关系'), findsOneWidget);
    expect(find.text('情节与线索'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '开始'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'directory opens original items and keeps graph and timeline secondary',
      (tester) async {
    final opened = <String>[];
    var timelineOpens = 0;
    const person = BookMaterialItem(
        id: 'p',
        sourceId: 'original-person',
        section: BookMaterialSection.characters,
        title: '人物甲',
        summary: '已读人物简介');
    const event = BookMaterialItem(
        id: 'e',
        sourceId: 'original-event',
        section: BookMaterialSection.plot,
        title: '已读事件',
        summary: '先前发生的事');
    await tester.pumpWidget(app(
        materials: const BookMaterialsSnapshot(
            bookId: 7, visibleAtProgress: .36, items: [person, event]),
        onOpenMaterial: (item) async => opened.add(item.sourceId),
        onTimeline: () async => timelineOpens++));
    await tester.pumpAndSettle();
    expect(find.text('查看人物关系图'), findsNothing);
    await tester.tap(find.text('人物与关系'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('人物甲'));
    expect(opened, ['original-person']);
    expect(find.text('查看人物关系图'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('情节与线索'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('情节与线索'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('查看故事时间线'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('查看故事时间线'));
    expect(timelineOpens, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search is local and does not repeat next-action or empty cards',
      (tester) async {
    const target = BookMaterialItem(
        id: 'concept',
        sourceId: 'c',
        section: BookMaterialSection.concepts,
        title: '目标概念',
        summary: '已有解释');
    await tester.pumpWidget(app(
        materials: const BookMaterialsSnapshot(
            bookId: 7, visibleAtProgress: .36, items: [target])));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '目标');
    await tester.pump();
    expect(find.text('目标概念'), findsOneWidget);
    expect(find.text('恢复上次阅读上下文'), findsNothing);
    expect(find.text('可建立的资料'), findsNothing);
    await tester.enterText(find.byType(TextField), '未知谜底');
    await tester.pump();
    expect(find.text('没有找到匹配的已有资料'), findsOneWidget);
    expect(find.text('目标概念'), findsNothing);
  });

  testWidgets('AI material settings stay secondary and retain their callback',
      (tester) async {
    var opens = 0;
    await tester.pumpWidget(app(quiet: true, onContext: () async => opens++));
    await tester.pumpAndSettle();
    expect(find.text('继续阅读'), findsNothing);
    expect(find.text('AI 使用的资料'), findsNothing);
    await tester.scrollUntilVisible(find.text('本书设置'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('本书设置'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('AI 使用的资料'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('AI 使用的资料'));
    expect(opens, 1);
  });

  testWidgets('E-INK uses static sync state at large text and narrow width',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        app(quiet: true, syncing: true, disableAnimations: true, textScale: 2));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('同步状态'), 160,
        scrollable: find.byType(Scrollable).first);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.sync_disabled), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
