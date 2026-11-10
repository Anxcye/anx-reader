import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/providers/ai_workspace.dart';
import 'package:anx_reader/models/selection_snapshot.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('shared surfaces retain independent navigation and drafts', () async {
    SharedPreferences.setMockInitialValues({});
    await Prefs().initPrefs();
    final controller = AiWorkspaceController(bookId: 99);
    controller.setDraft('Keep this question');
    controller.setChatScrollOffset(72);
    controller.showHistory();
    controller.showSurface(AiWorkspaceSurface.book, wide: true);
    controller.bookQuery = 'characters';
    controller.setSheetExpanded(true);
    controller.hide();
    controller.showSurface(AiWorkspaceSurface.assistant, wide: false);
    expect(controller.view, AiWorkspaceView.history);
    expect(controller.draft, 'Keep this question');
    expect(controller.chatScrollOffset, 72);
    expect(controller.bookQuery, 'characters');
    expect(controller.sheetExpanded, isTrue);
    controller.showPractice();
    expect(controller.view, AiWorkspaceView.coach);
    expect(controller.surface, AiWorkspaceSurface.assistant);
    controller.dispose();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs().initPrefs();
  });

  test('reading mode is suggested, confirmed, and persisted per book', () {
    final controller = AiWorkspaceController(bookId: 42);
    controller.suggestMode(
      title: 'A Short History of an Empire',
      description: 'War, archives, and a dynasty',
    );

    expect(controller.suggestedMode, ReadingAiMode.history);
    expect(Prefs().hasReadingAiModeForBook(42), isFalse);

    controller.setMode(ReadingAiMode.history);
    expect(Prefs().hasReadingAiModeForBook(42), isTrue);
    expect(
      AiWorkspaceController(bookId: 42).mode,
      ReadingAiMode.history,
    );
  });

  test('selection remains pending until an action builds layered context', () {
    final controller = AiWorkspaceController(bookId: 7);
    controller.setMode(ReadingAiMode.finance);
    controller.setPendingSelection(const ReadingContextSnapshot(
      bookId: '7',
      bookTitle: 'Finance Book',
      chapterTitle: 'Risk',
      selectedText: 'Returns are guaranteed.',
      surroundingText: 'The author assumes stable rates.',
      progress: 0.4,
    ));

    expect(controller.pendingSelection, isNotNull);
    expect(
      controller.mode.agentProfile.actionOrder,
      containsAllInOrder([
        SelectionAiAction.explain,
        SelectionAiAction.validateAssumption,
        SelectionAiAction.calculate,
        SelectionAiAction.riskCheck,
      ]),
    );

    final prompt =
        controller.buildActionPrompt(SelectionAiAction.validateAssumption);
    expect(prompt, contains('Returns are guaranteed.'));
    expect(prompt, contains('The author assumes stable rates.'));
    expect(prompt, contains('不要假装已读取整本书'));
    expect(controller.pendingSelection, isNotNull);

    controller.clearPendingSelection();
    expect(controller.pendingSelection, isNull);
    expect(controller.lastSelection?.bookTitle, 'Finance Book');
  });

  test('trusted domains can be overridden independently by mode', () {
    Prefs().setReadingTrustedSourceDomains(
      ReadingAiMode.psychology,
      ['who.int', 'example.edu'],
    );

    final pack = Prefs().readingTrustedSourcePack(ReadingAiMode.psychology);
    expect(pack.domains, ['who.int', 'example.edu']);
    expect(pack.trusts(Uri.parse('https://lab.example.edu/study')), isTrue);
    expect(pack.trusts(Uri.parse('https://sec.gov/report')), isFalse);
    expect(
      Prefs().readingTrustedSourcePack(ReadingAiMode.finance).domains,
      contains('sec.gov'),
    );
  });

  test('deep analysis uses confirmed local configuration and book context', () {
    final controller = AiWorkspaceController(bookId: 8);
    controller.setPendingSelection(const ReadingContextSnapshot(
      bookId: '8',
      bookTitle: 'Systems Book',
      selectedText: 'A reinforcing loop increases growth.',
      surroundingText: 'The loop also creates delayed constraints.',
    ));
    const request = ReadingAnalysisRequest(
      depth: ReadingAnalysisDepth.deep,
      frameworks: <ReadingFramework>[
        ReadingFramework.firstPrinciples,
        ReadingFramework.systemsThinking,
      ],
      outputTemplate: ReadingOutputTemplate.conceptMap,
      readingGoal: '识别反馈关系',
    );

    final prompt = controller.buildDeepAnalysisPrompt(request);

    expect(prompt, contains('识别反馈关系'));
    expect(prompt, contains('第一性原理'));
    expect(prompt, contains('系统思维'));
    expect(prompt, contains('A reinforcing loop increases growth.'));
    expect(prompt, contains('不要发起联网检索'));
  });

  test('workspace navigation and hide preserve draft and scroll state', () {
    final controller = AiWorkspaceController(bookId: 9);
    controller.setDraft('unfinished question');
    controller.setChatScrollOffset(128);
    controller.show(fullscreen: true);
    controller.showHistory();

    expect(controller.visible, isTrue);
    expect(controller.mobileFullscreen, isTrue);
    expect(controller.view, AiWorkspaceView.history);

    controller.showChat();
    controller.hide();
    expect(controller.visible, isFalse);
    expect(controller.draft, 'unfinished question');
    expect(controller.chatScrollOffset, 128);
    expect(controller.view, AiWorkspaceView.chat);
  });

  test('reading coach entry falls back to chat while feature is paused', () {
    final controller = AiWorkspaceController(bookId: 10);

    controller.showHistory();
    controller.showCoach();

    expect(controller.view, AiWorkspaceView.chat);
  });

  test('late revisions cannot replace current range or move the dock', () {
    final controller = AiWorkspaceController(bookId: 10);
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);
    final current = _selection(session: 1, revision: 4, text: 'new range');
    expect(controller.updateSelection(current, dockAtTop: true), isTrue);
    controller.setSelectionToolPage(SelectionToolPage.range);
    final beforeLateResult = notifications;

    expect(
        controller.updateSelection(
            _selection(session: 1, revision: 3, text: 'late range'),
            dockAtTop: false),
        isFalse);
    expect(controller.selection, same(current));
    expect(notifications, beforeLateResult);
    expect(controller.selectionDockAtTop, isTrue);
    expect(controller.selectionToolPage, SelectionToolPage.range);

    controller.updateSelection(
        _selection(session: 1, revision: 5, text: 'adjusted range'),
        dockAtTop: false);
    expect(controller.selectionDockAtTop, isTrue);
    expect(controller.selectionToolPage, SelectionToolPage.range);

    controller.updateSelection(_selection(session: 2, revision: 1),
        dockAtTop: false);
    expect(controller.selectionDockAtTop, isFalse);
    expect(controller.selectionToolPage, SelectionToolPage.actions);
  });

  test('result source stays frozen while the live selection changes', () {
    final controller = AiWorkspaceController(bookId: 10);
    addTearDown(controller.dispose);
    final original = _selection(session: 1, revision: 1, text: 'original word');
    controller.updateSelection(original, annotationId: 42);
    controller.openSelectionPanel(SelectionPanelPage.lookup);

    final changed = _selection(session: 1, revision: 2, text: 'different word');
    controller.updateSelection(changed);
    expect(controller.selection, same(changed));
    expect(controller.selectionTarget, same(original));
    expect(controller.selectionTargetAnnotationId, 42);
    expect(controller.selectionDockVisible, isFalse);
    expect(controller.pendingSelection, isNull);
    expect(controller.takeRequestedSelectionAction(), isNull);

    controller.openSelectionPanel(SelectionPanelPage.more);
    expect(controller.selectionTarget, same(original));
    controller.returnToSelection();
    expect(controller.selectionTarget, isNull);
    expect(controller.selection, same(changed));
    expect(controller.selectionDockVisible, isTrue);
  });

  test('selection subpages return without losing AI and book navigation', () {
    final controller = AiWorkspaceController(bookId: 10);
    addTearDown(controller.dispose);
    controller.setDraft('unfinished question');
    controller.setChatScrollOffset(128);
    controller.bookQuery = 'remembered search';
    controller.showHistory();
    controller.showSurface(AiWorkspaceSurface.book, wide: true);
    controller.setSheetExpanded(false);
    controller.updateSelection(_selection(session: 1, revision: 1));
    controller.openSelectionPanel(SelectionPanelPage.more);
    controller.openSelectionPanel(SelectionPanelPage.note);
    controller.setSheetExpanded(true);
    controller.setSelectionFeedback(busy: true, error: 'old result');

    expect(controller.popSelectionPanel(), isTrue);
    expect(controller.selectionPanelPage, SelectionPanelPage.more);
    expect(controller.selectionBusy, isFalse);
    expect(controller.selectionError, isNull);
    expect(controller.popSelectionPanel(), isFalse);

    controller.setSelectionFeedback(busy: true);
    controller.returnToSelection();
    expect(controller.selectionBusy, isFalse);
    expect(controller.visible, isTrue);
    expect(controller.sheetExpanded, isFalse);
    expect(controller.surface, AiWorkspaceSurface.book);
    expect(controller.view, AiWorkspaceView.history);
    expect(controller.draft, 'unfinished question');
    expect(controller.chatScrollOffset, 128);
    expect(controller.bookQuery, 'remembered search');
  });

  test('closing selection cancels its busy state and restores hidden workspace',
      () {
    final controller = AiWorkspaceController(bookId: 10);
    addTearDown(controller.dispose);
    controller.updateSelection(_selection(session: 1, revision: 1));
    controller.openSelectionPanel(SelectionPanelPage.style);
    controller.setSelectionFeedback(busy: true);
    expect(controller.visible, isTrue);

    controller.dismissSelectionPanel();
    expect(controller.selection, isNull);
    expect(controller.selectionTarget, isNull);
    expect(controller.selectionPanelPage, isNull);
    expect(controller.selectionDockVisible, isFalse);
    expect(controller.selectionBusy, isFalse);
    expect(controller.visible, isFalse);
    expect(controller.popSelectionPanel(), isFalse);
  });

  test('explicit explain intent is consumed once and preserves the draft', () {
    final controller = AiWorkspaceController(bookId: 10);
    addTearDown(controller.dispose);
    controller.setDraft('keep composing this question');
    controller.setChatScrollOffset(75);
    const source = ReadingContextSnapshot(
        bookId: '10', selectedText: 'exact selected text', progress: 0.3);

    controller.setPendingSelection(source);
    expect(controller.takeRequestedSelectionAction(), isNull);
    controller.requestSelectionAction(source, SelectionAiAction.explain);
    expect(controller.pendingSelection, same(source));
    expect(controller.visible, isTrue);
    expect(controller.surface, AiWorkspaceSurface.assistant);
    expect(
        controller.takeRequestedSelectionAction(), SelectionAiAction.explain);
    expect(controller.takeRequestedSelectionAction(), isNull);
    expect(controller.draft, 'keep composing this question');
    expect(controller.chatScrollOffset, 75);
  });
}

SelectionSnapshot _selection(
        {required int session,
        required int revision,
        String text = 'selected'}) =>
    SelectionSnapshot.fromJson({
      'sessionId': session,
      'revision': revision,
      'text': text,
      'cfi': 'epubcfi(/6/2/$revision)',
      'rangeType': 'word',
    });
