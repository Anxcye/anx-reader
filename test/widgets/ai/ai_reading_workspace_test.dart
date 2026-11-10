import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/providers/ai_workspace.dart';
import 'package:anx_reader/providers/ai_chat.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/widgets/ai/ai_chat_stream.dart';
import 'package:anx_reader/widgets/ai/ai_reading_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
  setUpAll(() async {
    final fonts = FontLoader('ReadingVisual')
      ..addFont(rootBundle.load('assets/fonts/SourceHanSerifSC-Regular.otf'));
    await fonts.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs().initPrefs();
    Prefs().saveAiProviders([
      const AiProvider(
        id: 'test-local',
        title: 'Test local',
        url: 'http://localhost:1234/v1',
        protocol: AiProtocol.openai,
        authMode: AiProviderAuthMode.none,
        deployment: AiProviderDeployment.localPrivate,
        model: 'test',
      ).toJson(),
    ]);
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
          theme: ThemeData(fontFamily: 'ReadingVisual'),
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

    expect(find.text('阅读闭环 · 历史证据闭环'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('ai-reading-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Answer options'));
    await tester.pumpAndSettle();
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

  for (final variant in [
    (name: 'phone', size: const Size(390, 472), scale: 1.0, eink: false),
    (name: 'large-text', size: const Size(390, 472), scale: 2.0, eink: false),
    (name: 'eink', size: const Size(390, 472), scale: 1.0, eink: true),
    (name: 'wide', size: const Size(480, 800), scale: 1.0, eink: false),
  ]) {
    testWidgets('assistant visual layout ${variant.name}', (tester) async {
      await tester.binding.setSurfaceSize(variant.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Prefs().eInkMode = variant.eink;
      final chat = _RecordingChat();
      final controller = AiWorkspaceController(bookId: 7);
      final chatKey = GlobalKey<AiChatStreamState>();
      final captureKey = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        overrides: [aiChatProvider.overrideWith(() => chat)],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(variant.scale)),
            child: child!,
          ),
          theme: ThemeData(fontFamily: 'ReadingVisual'),
          home: Scaffold(
              body: RepaintBoundary(
            key: captureKey,
            child: AiReadingWorkspace(
              controller: controller,
              chatKey: chatKey,
              quickPromptChips: const [],
              bookTitle: 'Book',
              bookAuthor: 'Author',
              currentChapterTitle: 'A chapter with a longer title',
              currentProgress: .3,
            ),
          )),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, captureKey, '${variant.name}-empty');
      chatKey.currentState!.setDraft('Keep this unfinished question');
      controller.setDraft('Keep this unfinished question');
      controller.setPendingSelection(const ReadingContextSnapshot(
        bookId: '7',
        selectedText: 'A quotation with enough context to explain the idea.',
        progress: .3,
        metadata: {'cfi': 'epubcfi(/6/2)'},
      ));
      await tester.pumpAndSettle();
      expect(chatKey.currentState!.inputController.text,
          'Keep this unfinished question');
      expect(chat.requests, isEmpty);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(tester.takeException(), isNull);
      await _capture(tester, captureKey, '${variant.name}-selection');
    });
  }

  testWidgets('stop keeps the current question and partial answer',
      (tester) async {
    final completion = Completer<void>();
    final chat = _RecordingChat(completion: completion);
    final chatKey = GlobalKey<AiChatStreamState>();
    await tester.pumpWidget(ProviderScope(
      overrides: [aiChatProvider.overrideWith(() => chat)],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
            body: AiChatStream(
          key: chatKey,
          readingCompanion: true,
        )),
      ),
    ));
    await tester.pumpAndSettle();
    chatKey.currentState!.sendPrompt('Question to stop');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byTooltip('Stop generating'), findsOneWidget);
    chatKey.currentState!.stopGenerating();
    completion.complete();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Stop generating'), findsNothing);
    expect(find.text('Question to stop'), findsOneWidget);
    expect(find.text('A concise explanation.'), findsOneWidget);
    expect(chat.requests, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  for (final stop in [false, true]) {
    testWidgets('eink defers chunks and retains output after stop=$stop',
        (tester) async {
      Prefs().eInkMode = true;
      final completion = Completer<void>();
      final chat =
          _RecordingChat(completion: completion, emitIntermediate: true);
      final chatKey = GlobalKey<AiChatStreamState>();
      await tester.pumpWidget(ProviderScope(
        overrides: [aiChatProvider.overrideWith(() => chat)],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
              body: AiChatStream(
            key: chatKey,
            readingCompanion: true,
          )),
        ),
      ));
      await tester.pumpAndSettle();
      chatKey.currentState!.sendPrompt('A static question');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('A static question'), findsOneWidget);
      expect(find.text('Intermediate chunk.'), findsNothing);
      expect(find.text('A concise explanation.'), findsNothing);
      if (stop) chatKey.currentState!.stopGenerating();
      completion.complete();
      await tester.pumpAndSettle();
      expect(find.text('A concise explanation.'), findsOneWidget);
      expect(find.text('Intermediate chunk.'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'quiet companion offers three actions and retains a selection draft',
      (tester) async {
    final chat = _RecordingChat();
    final controller = AiWorkspaceController(bookId: 7);
    final chatKey = GlobalKey<AiChatStreamState>();
    controller.setDraft('My unfinished question');
    await tester.pumpWidget(ProviderScope(
      overrides: [aiChatProvider.overrideWith(() => chat)],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
            body: AiReadingWorkspace(
          controller: controller,
          chatKey: chatKey,
          quickPromptChips: const [],
          bookTitle: 'Book',
          bookAuthor: 'Author',
          currentChapterTitle: 'Chapter one',
          currentProgress: .3,
        )),
      ),
    ));
    await tester.pumpAndSettle();
    expect(chat.requests, isEmpty);
    expect(find.text('Explain here'), findsOneWidget);
    expect(find.text('Recall what I read'), findsOneWidget);
    expect(find.text('Explore further'), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is OutlinedButton),
        findsNWidgets(3));
    expect(find.text('Chapter one'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);

    controller.setPendingSelection(const ReadingContextSnapshot(
      bookId: '7',
      chapterTitle: 'Chapter one',
      selectedText: 'The exact quotation.',
      progress: .3,
      metadata: {'cfi': 'epubcfi(/6/2)'},
    ));
    await tester.pumpAndSettle();
    expect(chat.requests, isEmpty);
    expect(
        chatKey.currentState!.inputController.text, 'My unfinished question');
    expect(find.text('Explain this passage'), findsOneWidget);
    expect(find.text('Connect to context'), findsOneWidget);
    expect(find.text('Explain here'), findsNothing);
    await tester.tap(find.byTooltip('Remove quotation'));
    await tester.pumpAndSettle();
    expect(controller.pendingSelection, isNull);
    expect(
        chatKey.currentState!.inputController.text, 'My unfinished question');
    expect(chat.requests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'selection explanation requires an explicit action and preserves scope',
      (tester) async {
    final chat = _RecordingChat();
    final controller = AiWorkspaceController(bookId: 7);
    controller.setPendingSelection(const ReadingContextSnapshot(
      bookId: '7',
      chapterTitle: 'Chapter one',
      selectedText: 'Evidence from the book.',
      progress: .3,
      metadata: {'cfi': 'epubcfi(/6/2)'},
    ));
    await tester.pumpWidget(ProviderScope(
      overrides: [aiChatProvider.overrideWith(() => chat)],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
            body: AiReadingWorkspace(
          controller: controller,
          chatKey: GlobalKey<AiChatStreamState>(),
          quickPromptChips: const [],
          bookTitle: 'Book',
          bookAuthor: 'Author',
        )),
      ),
    ));
    await tester.pumpAndSettle();
    expect(chat.requests, isEmpty);
    await tester.tap(find.text('Explain this passage'));
    await tester.pumpAndSettle();
    expect(chat.requests, hasLength(1));
    expect(chat.requests.single, contains('Evidence from the book.'));
    expect(chat.requests.single, contains('不要因模型已知全书而透露后文'));
    expect(controller.pendingSelection, isNull);
    expect(tester.takeException(), isNull);
  });

  for (final requestedBeforeMount in [false, true]) {
    testWidgets(
        'selection intent sends once with frozen source and preserves draft '
        'beforeMount=$requestedBeforeMount', (tester) async {
      final chat = _RecordingChat();
      final controller = AiWorkspaceController(bookId: 7);
      // Persisted settings avoid relying on an unrelated mode suggestion to
      // notify the workspace about an intent that predates its listener.
      controller.setMode(ReadingAiMode.general);
      controller.setDraft('Do not replace this unfinished question');
      final chatKey = GlobalKey<AiChatStreamState>();
      const source = ReadingContextSnapshot(
        bookId: '7',
        bookTitle: 'Book',
        chapterTitle: 'Original chapter',
        chapterHref: 'chapter-one.xhtml',
        selectedText: 'Only this exact passage.',
        surroundingText: 'The context visible at the time of selection.',
        progress: .27,
        metadata: {
          'cfi': 'epubcfi(/6/2!/4/8,/1:2,/1:26)',
          'sourceProgress': .26,
          'visibleFromProgress': .27,
        },
      );
      if (requestedBeforeMount) {
        controller.requestSelectionAction(source, SelectionAiAction.explain);
      }
      await tester.pumpWidget(_workspace(chat, controller, chatKey));
      await tester.pumpAndSettle();
      if (!requestedBeforeMount) {
        expect(chat.requests, isEmpty);
        expect(chat.contextOverrides, isEmpty);
        controller.requestSelectionAction(source, SelectionAiAction.explain);
        await tester.pumpAndSettle();
      }

      expect(chat.requests, hasLength(1));
      expect(chat.requests.single, contains('Only this exact passage.'));
      expect(chat.requests.single, contains('Original chapter'));
      expect(chat.contextOverrides, [same(source)]);
      expect(chat.contextAtRequests, [same(source)]);
      expect(chat.contextAtRequests.single!.metadata['cfi'],
          'epubcfi(/6/2!/4/8,/1:2,/1:26)');
      expect(chat.contextAtRequests.single!.progress, .27);
      expect(chat.contextAtRequests.single!.metadata['sourceProgress'], .26);
      expect(
          chat.contextAtRequests.single!.metadata['visibleFromProgress'], .27);
      expect(controller.pendingSelection, isNull);
      expect(controller.draft, 'Do not replace this unfinished question');
      expect(chatKey.currentState!.inputController.text,
          'Do not replace this unfinished question');
      expect(tester.testTextInput.isVisible, isFalse);

      controller.showHistory();
      controller.showChat();
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpAndSettle();
      expect(chat.requests, hasLength(1));
      expect(chat.contextOverrides, hasLength(1));
      expect(controller.draft, 'Do not replace this unfinished question');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('rejected selection intent leaves draft and source unconsumed',
      (tester) async {
    Prefs().saveAiProviders([
      const AiProvider(
              id: 'missing',
              title: 'Missing',
              url: 'https://example.com/v1',
              protocol: AiProtocol.openai,
              model: 'test')
          .toJson(),
    ]);
    final chat = _RecordingChat();
    final controller = AiWorkspaceController(bookId: 7);
    controller.setDraft('Question still being composed');
    final chatKey = GlobalKey<AiChatStreamState>();
    const source = ReadingContextSnapshot(
      bookId: '7',
      selectedText: 'Keep this quote too.',
      progress: .3,
      metadata: {'cfi': 'epubcfi(/6/2)'},
    );
    await tester.pumpWidget(_workspace(chat, controller, chatKey));
    await tester.pumpAndSettle();

    controller.requestSelectionAction(source, SelectionAiAction.explain);
    await tester.pumpAndSettle();
    expect(chat.requests, isEmpty);
    expect(chat.contextOverrides, isEmpty);
    expect(controller.pendingSelection, same(source));
    expect(controller.draft, 'Question still being composed');
    expect(chatKey.currentState!.inputController.text,
        'Question still being composed');
    expect(find.text('Configure providers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed answer keeps partial text and retries in place',
      (tester) async {
    final chat = _RecordingChat(failFirst: true);
    final chatKey = GlobalKey<AiChatStreamState>();
    await tester.pumpWidget(ProviderScope(
      overrides: [aiChatProvider.overrideWith(() => chat)],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
            body: AiChatStream(
          key: chatKey,
          readingCompanion: true,
        )),
      ),
    ));
    await tester.pumpAndSettle();
    chatKey.currentState!.sendPrompt('Keep my question');
    await tester.pumpAndSettle();
    expect(find.text('Keep my question'), findsOneWidget);
    expect(find.text('Partial answer.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('provider-private-details'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(chat.requests, ['Keep my question', 'Keep my question']);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('A concise explanation.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'unconfigured model keeps the quotation and draft without requesting AI',
      (tester) async {
    Prefs().saveAiProviders([
      const AiProvider(
              id: 'missing',
              title: 'Missing',
              url: 'https://example.com/v1',
              protocol: AiProtocol.openai,
              model: 'test')
          .toJson(),
    ]);
    final chat = _RecordingChat();
    final controller = AiWorkspaceController(bookId: 7);
    controller.setDraft('Keep this draft');
    controller.setPendingSelection(const ReadingContextSnapshot(
      bookId: '7',
      selectedText: 'Quotation',
      progress: .2,
      metadata: {'cfi': 'epubcfi(/6/2)'},
    ));
    final chatKey = GlobalKey<AiChatStreamState>();
    await tester.pumpWidget(ProviderScope(
      overrides: [aiChatProvider.overrideWith(() => chat)],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
            body: AiReadingWorkspace(
          controller: controller,
          chatKey: chatKey,
          quickPromptChips: const [],
          bookTitle: 'Book',
          bookAuthor: 'Author',
        )),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explain this passage'));
    await tester.pump();
    expect(chat.requests, isEmpty);
    expect(controller.pendingSelection, isNotNull);
    expect(chatKey.currentState!.inputController.text, 'Keep this draft');
    expect(find.text('Configure providers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _RecordingChat extends AiChat {
  _RecordingChat(
      {this.failFirst = false, this.completion, this.emitIntermediate = false});

  final bool failFirst;
  final Completer<void>? completion;
  final bool emitIntermediate;
  final List<String> requests = [];
  final List<ReadingContextSnapshot?> contextOverrides = [];
  final List<ReadingContextSnapshot?> contextAtRequests = [];

  @override
  void setReadingContextOverride(ReadingContextSnapshot? snapshot) {
    contextOverrides.add(snapshot);
    super.setReadingContextOverride(snapshot);
  }

  @override
  List<ChatMessage> build() => [];

  @override
  Stream<List<ChatMessage>> sendMessageStream(
      String message, WidgetRef widgetRef, bool isRegenerate) async* {
    requests.add(message);
    contextAtRequests.add(contextOverrides.lastOrNull);
    if (emitIntermediate) {
      final partial = [
        ChatMessage.humanText(message),
        ChatMessage.ai('Intermediate chunk.')
      ];
      state = AsyncData(partial);
      yield partial;
      await Future<void>.delayed(Duration.zero);
    }
    final shouldFail = failFirst && requests.length == 1;
    final messages = [
      ChatMessage.humanText(message),
      ChatMessage.ai(shouldFail ? 'Partial answer.' : 'A concise explanation.')
    ];
    state = AsyncData(messages);
    yield messages;
    if (shouldFail) throw StateError('provider-private-details');
    if (completion != null) await completion!.future;
  }
}

Widget _workspace(_RecordingChat chat, AiWorkspaceController controller,
        GlobalKey<AiChatStreamState> chatKey) =>
    ProviderScope(
      overrides: [aiChatProvider.overrideWith(() => chat)],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: AiReadingWorkspace(
            controller: controller,
            chatKey: chatKey,
            quickPromptChips: const [],
            bookTitle: 'Book',
            bookAuthor: 'Author',
            currentChapterTitle: 'Later live chapter',
            currentProgress: .8,
          ),
        ),
      ),
    );

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('/tmp/anx-reading-visuals');
    await directory.create(recursive: true);
    await File('${directory.path}/assistant-$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
