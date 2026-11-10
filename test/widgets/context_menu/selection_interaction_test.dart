import 'dart:io';
import 'dart:ui' as ui;

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/selection_menu_action.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/models/selection_snapshot.dart';
import 'package:anx_reader/providers/ai_workspace.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/widgets/context_menu/excerpt_menu.dart';
import 'package:anx_reader/widgets/context_menu/selection_panel.dart';
import 'package:anx_reader/widgets/reading_page/reading_workspace_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SelectionSnapshot selection({
  int session = 1,
  int revision = 1,
  String text = 'A question begins with careful reading.',
  String cfi = 'epubcfi(/6/2!/4/2:0)',
  bool extend = true,
}) =>
    SelectionSnapshot(
      sessionId: session,
      revision: revision,
      rangeType: SelectionRangeType.sentence,
      trigger: SelectionTrigger.longPress,
      text: text,
      cfi: cfi,
      contextText: 'Read slowly and follow the evidence.',
      chapterIndex: 0,
      canMovePrevious: true,
      canMoveNext: true,
      supportsRangeSelection: true,
      canAdjustStartPrevious: true,
      canAdjustStartNext: false,
      canAdjustEndPrevious: false,
      canAdjustEndNext: true,
      canExtendNextPage: extend,
      canUndoExtension: true,
      canShowSelectionEnd: extend,
      extensionUnavailableReason: extend ? null : 'chapterEnd',
      sourceProgress: .36,
      visibleFromProgress: .36,
    );

Widget app(Widget child,
        {bool zh = false, double scale = 1, bool eink = false}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(zh ? 'zh' : 'en'),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'ReadingVisual',
        colorScheme: eink
            ? const ColorScheme.light(
                primary: Colors.black,
                surface: Colors.white,
                onSurface: Colors.black,
                outline: Colors.black)
            : ColorScheme.fromSeed(seedColor: const Color(0xff445e53)),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: eink,
        ),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

Widget toolbar(AiWorkspaceController controller,
        {ValueChanged<SelectionMenuAction>? onAction,
        VoidCallback? onMore,
        VoidCallback? onClose,
        ValueChanged<SelectionRangeType>? onRange,
        void Function(String, int, String)? onAdjust,
        VoidCallback? onExtend,
        VoidCallback? onUndo,
        VoidCallback? onShowEnd}) =>
    AnimatedBuilder(
      animation: controller,
      builder: (context, _) => ExcerptMenu(
        controller: controller,
        actions: const [
          SelectionMenuAction.highlight,
          SelectionMenuAction.lookupOrTranslate,
          SelectionMenuAction.ai,
        ],
        dictionary: false,
        onAction: onAction ?? (_) {},
        onMore: onMore ?? () {},
        onClose: onClose ?? () {},
        onRange: onRange ?? (_) {},
        onAdjust: onAdjust ?? (_, __, ___) {},
        onExtend: onExtend ?? () {},
        onUndoExtension: onUndo ?? () {},
        onShowEnd: onShowEnd ?? () {},
      ),
    );

Widget panel(AiWorkspaceController controller,
        {VoidCallback? onSave, ValueChanged<SelectionMenuAction>? onAction}) =>
    AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SelectionPanel(
        controller: controller,
        bookTitle: 'Reading and understanding',
        chapterHref: 'chapter-1.xhtml',
        chapterTitle: 'Chapter 1 · Read slowly',
        offline: true,
        onAction: onAction ?? (_) {},
        onSave: onSave ?? () {},
        onDelete: () {},
        onStyle: () {},
        onSearch: (_) {},
      ),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs().initPrefs();
    await L10n.delegate.load(const Locale('en'));
    await L10n.delegate.load(const Locale('zh'));
  });

  testWidgets(
      'mount and native revision updates stay quiet until explicit action',
      (tester) async {
    final controller = AiWorkspaceController(bookId: 7);
    addTearDown(controller.dispose);
    controller.updateSelection(selection());
    final actions = <SelectionMenuAction>[];
    await tester.pumpWidget(app(Align(
      alignment: Alignment.bottomCenter,
      child: toolbar(controller, onAction: actions.add),
    )));
    await tester.pumpAndSettle();
    expect(actions, isEmpty);
    expect(controller.takeRequestedSelectionAction(), isNull);
    controller.updateSelection(selection(revision: 2, text: 'Revised source.'));
    await tester.pump();
    expect(actions, isEmpty);
    expect(find.text('Revised source.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('selection-action-highlight')));
    await tester.pump();
    expect(actions, [SelectionMenuAction.highlight]);
  });

  testWidgets('endpoint controls respect boundaries and extend only on tap',
      (tester) async {
    final controller = AiWorkspaceController(bookId: 7);
    addTearDown(controller.dispose);
    controller.updateSelection(selection());
    final adjusted = <(String, int, String)>[];
    final ranges = <SelectionRangeType>[];
    var extensions = 0;
    var undone = 0;
    var showEnd = 0;
    await tester.pumpWidget(app(Align(
      alignment: Alignment.bottomCenter,
      child: toolbar(controller,
          onRange: ranges.add,
          onAdjust: (endpoint, direction, unit) =>
              adjusted.add((endpoint, direction, unit)),
          onExtend: () => extensions++,
          onUndo: () => undone++,
          onShowEnd: () => showEnd++),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adjust selection'));
    await tester.pumpAndSettle();
    OutlinedButton button(String text) => tester.widget<OutlinedButton>(find
        .ancestor(
            of: find.text(text),
            matching: find.byWidgetPredicate((w) => w is OutlinedButton))
        .first);
    expect(button('Earlier').onPressed, isNull);
    expect(button('Later').onPressed, isNotNull);
    await tester.tap(find.text('Later'));
    expect(adjusted, [('end', 1, 'character')]);
    await tester.tap(find.text('Adjust start'));
    await tester.pumpAndSettle();
    expect(button('Earlier').onPressed, isNotNull);
    expect(button('Later').onPressed, isNull);
    await tester.tap(find.text('Earlier'));
    expect(adjusted.last, ('start', -1, 'character'));
    await tester.tap(find.text('Paragraph'));
    expect(ranges, [SelectionRangeType.paragraph]);
    expect(extensions, 0);
    await tester.tap(find.text('Extend to next page'));
    await tester.tap(find.text('Undo extension'));
    await tester.tap(find.text('Show selection end'));
    expect((extensions, undone, showEnd), (1, 1, 1));
    controller.updateSelection(selection(revision: 2, extend: false));
    await tester.pump();
    expect(button('Extend to next page').onPressed, isNull);
    expect(button('Show selection end').onPressed, isNull);
    expect(find.text('End of this chapter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('same-session placement is stable and stale revisions cannot replace it',
      () {
    final controller = AiWorkspaceController(bookId: 7);
    addTearDown(controller.dispose);
    controller.updateSelection(selection(revision: 3), dockAtTop: true);
    controller.setSelectionToolPage(SelectionToolPage.range);
    expect(controller.updateSelection(selection(revision: 2)), isFalse);
    expect(controller.selection!.revision, 3);
    controller.updateSelection(selection(revision: 4), dockAtTop: false);
    expect(controller.selectionDockAtTop, isTrue);
    expect(controller.selectionToolPage, SelectionToolPage.range);
    controller.updateSelection(selection(session: 2), dockAtTop: false);
    expect(controller.selectionDockAtTop, isFalse);
    expect(controller.selectionToolPage, SelectionToolPage.actions);
    expect(controller.takeRequestedSelectionAction(), isNull);
  });

  testWidgets('note target stays frozen and draft survives a newer selection',
      (tester) async {
    final controller = AiWorkspaceController(bookId: 7);
    addTearDown(controller.dispose);
    controller.setDraft('Unsent question');
    controller.bookQuery = 'remember';
    controller.setChatScrollOffset(120);
    controller.surface = AiWorkspaceSurface.book;
    controller.view = AiWorkspaceView.history;
    final original = selection();
    controller.updateSelection(original, annotationId: 41);
    controller.openSelectionPanel(SelectionPanelPage.note);
    var saved = 0;
    await tester.pumpWidget(app(panel(controller, onSave: () => saved++)));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).autofocus, isFalse);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
        reason: 'Existing notes cannot be overwritten before loading');
    controller.selectionEditingAnnotation = BookNote(
      id: 41,
      bookId: 7,
      content: original.text,
      cfi: original.cfi,
      chapter: 'Chapter 1',
      type: 'highlight',
      color: 'FFF176',
      updateTime: DateTime(2026),
    );
    controller.setSelectionFeedback();
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'My source note');
    controller.updateSelection(selection(
        session: 2, revision: 5, text: 'New passage.', cfi: 'new-cfi'));
    await tester.pump();
    expect(controller.selectionTarget, same(original));
    expect(controller.selectionTargetAnnotationId, 41);
    expect(controller.selectionNoteDraft, 'My source note');
    expect(find.text(original.text), findsOneWidget);
    expect(find.text('New passage.'), findsNothing);
    expect(
        find.text('Selection changed. This result refers to the source above.'),
        findsOneWidget);
    expect(controller.draft, 'Unsent question');
    expect(controller.surface, AiWorkspaceSurface.book);
    expect(controller.view, AiWorkspaceView.history);
    expect(controller.bookQuery, 'remember');
    expect(controller.chatScrollOffset, 120);
    expect(saved, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    expect(saved, 1);
    controller.returnToSelection();
    expect(controller.visible, isFalse);
    expect(controller.selection!.text, 'New passage.');
    expect(controller.selectionDockVisible, isTrue);
  });

  test(
      'panel nesting restores the prior workspace without replacing navigation',
      () {
    final controller = AiWorkspaceController(bookId: 7);
    addTearDown(controller.dispose);
    controller.visible = true;
    controller.surface = AiWorkspaceSurface.book;
    controller.view = AiWorkspaceView.history;
    controller.sheetExpanded = false;
    controller.updateSelection(selection());
    controller.openSelectionPanel(SelectionPanelPage.more);
    controller.openSelectionPanel(SelectionPanelPage.note);
    controller.setSheetExpanded(true);
    expect(controller.popSelectionPanel(), isTrue);
    expect(controller.selectionPanelPage, SelectionPanelPage.more);
    expect(controller.popSelectionPanel(), isFalse);
    controller.returnToSelection();
    expect(controller.visible, isTrue);
    expect(controller.sheetExpanded, isFalse);
    expect(controller.surface, AiWorkspaceSurface.book);
    expect(controller.view, AiWorkspaceView.history);
    controller.openSelectionPanel(SelectionPanelPage.note);
    controller.setSheetExpanded(true);
    controller.dismissSelectionPanel();
    expect(controller.selection, isNull);
    expect(controller.visible, isTrue);
    expect(controller.sheetExpanded, isFalse);
    expect(controller.surface, AiWorkspaceSurface.book);
    expect(controller.view, AiWorkspaceView.history);
  });

  test('explicit AI intent preserves the question draft and is consumed once',
      () {
    final controller = AiWorkspaceController(bookId: 7);
    addTearDown(controller.dispose);
    controller.setDraft('An unfinished thought');
    controller.updateSelection(selection());
    const source = ReadingContextSnapshot(
        bookId: '7', selectedText: 'Exact quoted text', progress: .36);
    controller.requestSelectionAction(source, SelectionAiAction.explain);
    expect(controller.draft, 'An unfinished thought');
    expect(controller.pendingSelection, same(source));
    expect(
        controller.takeRequestedSelectionAction(), SelectionAiAction.explain);
    expect(controller.takeRequestedSelectionAction(), isNull);
    expect(controller.visible, isTrue);
    expect(controller.surface, AiWorkspaceSurface.assistant);
  });

  testWidgets('saving disables repeated actions and errors retain the source',
      (tester) async {
    final controller = AiWorkspaceController(bookId: 7);
    addTearDown(controller.dispose);
    controller.updateSelection(selection());
    var actions = 0;
    controller.setSelectionFeedback(busy: true);
    await tester.pumpWidget(app(Align(
        alignment: Alignment.bottomCenter,
        child: toolbar(controller, onAction: (_) => actions++))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('selection-action-highlight')));
    expect(actions, 0);
    controller.setSelectionFeedback(error: 'Could not save. Try again.');
    await tester.pump();
    expect(find.text(selection().text), findsOneWidget);
    expect(find.text('Could not save. Try again.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('selection-action-highlight')));
    expect(actions, 1);
  });

  for (final spec in [
    (name: 'phone', size: const Size(400, 800), scale: 1.0, eink: false),
    (name: 'wide', size: const Size(1200, 900), scale: 1.0, eink: false),
    (name: 'eink', size: const Size(1000, 800), scale: 1.0, eink: true),
    (name: 'large-text', size: const Size(400, 800), scale: 1.8, eink: false),
  ]) {
    testWidgets('selection layout ${spec.name}', (tester) async {
      await tester.binding.setSurfaceSize(spec.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final font = FontLoader('ReadingVisual')
        ..addFont(rootBundle.load('assets/fonts/SourceHanSerifSC-Regular.otf'));
      await font.load();
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
      Prefs().eInkMode = spec.eink;
      final controller = AiWorkspaceController(bookId: 7);
      addTearDown(controller.dispose);
      controller.updateSelection(selection(text: '阅读不是被动接受，而是主动建立联系。'));
      final capture = GlobalKey();
      final reader = Stack(children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(children: [
              const Text('第一章  阅读与理解', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 24),
              for (var i = 0; i < 7; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text('阅读不是被动接受，而是主动建立联系。遇到不明白的地方，停下来想一想，再从文字中寻找依据。',
                      style: TextStyle(
                        fontSize: 19,
                        height: 1.7,
                        backgroundColor: i == 1
                            ? (spec.eink
                                ? Colors.black12
                                : const Color(0xfff6edbd))
                            : null,
                      )),
                ),
            ]),
          ),
        ),
        Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) => controller.selectionDockVisible
                    ? toolbar(controller)
                    : const SizedBox.shrink())),
      ]);
      Widget scene() => RepaintBoundary(
          key: capture,
          child: app(
              ReadingWorkspaceHost(
                reader: reader,
                panel: panel(controller),
                visible: controller.selectionPanelPage != null,
                expanded: controller.sheetExpanded,
              ),
              zh: true,
              scale: spec.scale,
              eink: spec.eink));
      await tester.pumpWidget(scene());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final min = spec.eink ? 56.0 : 48.0;
      for (final action in ['highlight', 'lookupOrTranslate', 'ai']) {
        expect(
            tester
                .getSize(find.byKey(ValueKey('selection-action-$action')))
                .height,
            greaterThanOrEqualTo(min));
      }
      await captureVisual(tester, capture, 'selection-${spec.name}');
      controller.setSelectionToolPage(SelectionToolPage.range);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final control
          in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))) {
        expect(tester.getSize(find.byWidget(control)).height,
            greaterThanOrEqualTo(min),
            reason: 'Endpoint controls must meet the device touch target');
      }
      await captureVisual(tester, capture, 'range-${spec.name}',
          monochrome: spec.eink);
      controller.openSelectionPanel(SelectionPanelPage.more);
      await tester.pumpWidget(scene());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await captureVisual(tester, capture, 'panel-${spec.name}');
    });
  }
}

Future<void> captureVisual(WidgetTester tester, GlobalKey key, String name,
    {bool monochrome = false}) async {
  const save = bool.fromEnvironment('READING_VISUALS');
  if (!save && !monochrome) return;
  var colored = 0;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bitmap = await boundary.toImage(pixelRatio: 1);
    if (save) {
      final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('/tmp/anx-selection-visuals')
        ..createSync(recursive: true);
      File('${dir.path}/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    }
    if (monochrome) {
      final raw = await bitmap.toByteData(format: ui.ImageByteFormat.rawRgba);
      final pixels = raw!.buffer.asUint8List();
      for (var i = 0; i < pixels.length; i += 4) {
        if (pixels[i] != pixels[i + 1] || pixels[i] != pixels[i + 2]) colored++;
      }
    }
    bitmap.dispose();
  });
  if (monochrome) {
    expect(colored, 0, reason: 'E-INK selection controls must stay monochrome');
  }
}
