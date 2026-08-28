import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/providers/ai_workspace.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
}
