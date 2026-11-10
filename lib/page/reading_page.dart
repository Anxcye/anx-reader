import 'dart:async';

import 'package:anx_reader/enums/selection_menu_action.dart';
import 'package:anx_reader/service/tts/tts_handler.dart';
import 'package:anx_reader/service/vocabulary_capture_service.dart';
import 'package:anx_reader/widgets/book_share/excerpt_share_service.dart';
import 'package:anx_reader/widgets/context_menu/selection_panel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/config/feature_flags.dart';
import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/dao/theme.dart';
import 'package:anx_reader/enums/ai_panel_position.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/enums/sync_trigger.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/ai_quick_prompt_chip.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/models/book_materials.dart';
import 'package:anx_reader/service/ai/book_wiki_service.dart';
import 'package:anx_reader/page/book_wiki_entry_page.dart';
import 'package:anx_reader/page/home_page/notes_page.dart'
    show ReadingNoteDetail;
import 'package:anx_reader/page/fiction_character_graph_page.dart';
import 'package:anx_reader/page/fiction_story_timeline_page.dart';
import 'package:anx_reader/widgets/reading_page/reading_workspace_host.dart';
import 'package:anx_reader/models/next_reading_action.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/providers/ai_workspace.dart';
import 'package:anx_reader/providers/ai_chat.dart';
import 'package:anx_reader/providers/reading_coach.dart';
import 'package:anx_reader/service/ai/reading_coach_policy.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_task.dart';
import 'package:anx_reader/models/selection_snapshot.dart';
import 'package:anx_reader/models/toc_item.dart';
import 'package:anx_reader/page/book_detail.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/page/reading_outcomes_page.dart';
import 'package:anx_reader/page/reading_agent_help_page.dart';
import 'package:anx_reader/page/book_wiki_page.dart';
import 'package:anx_reader/page/reading_context_pack_page.dart';
import 'package:anx_reader/service/ai/book_wiki_generation_service.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:anx_reader/providers/book_toc.dart';
import 'package:anx_reader/dao/reading_agent_sync.dart';
import 'package:anx_reader/service/ai/ai_history.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:anx_reader/service/ai/reading_task_scheduler.dart';
import 'package:anx_reader/service/ai/agent_action_service.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/reading_intervention_policy.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/service/ai/reading_experience_profile_service.dart';
import 'package:anx_reader/service/ai/fiction_reading_service.dart';
import 'package:anx_reader/service/ai/fiction_backfill_service.dart';
import 'package:anx_reader/service/ai/reading_structure_parser.dart';
import 'package:anx_reader/service/ai/fiction_hybrid_extraction_service.dart';
import 'package:anx_reader/service/ai/fiction_story_atlas_service.dart';
import 'package:anx_reader/service/ai/next_reading_action_resolver.dart';
import 'package:anx_reader/service/ai/reading_outcomes_service.dart';
import 'package:anx_reader/service/ai/reading_coverage_service.dart';
import 'package:anx_reader/service/ai/reading_device_identity.dart';
import 'package:anx_reader/service/reading_experience_diagnostics.dart';
import 'package:anx_reader/service/sync/reading_activity_coordinator.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/ui/status_bar.dart';
import 'package:anx_reader/widgets/ai/ai_chat_stream.dart';
import 'package:anx_reader/widgets/ai/ai_reading_workspace.dart';
import 'package:anx_reader/widgets/reading_page/notes_widget.dart';
import 'package:anx_reader/widgets/reading_page/reading_book_hub.dart';
import 'package:anx_reader/models/reading_time.dart';
import 'package:anx_reader/widgets/reading_page/progress_widget.dart';
import 'package:anx_reader/widgets/reading_page/tts_fab.dart';
import 'package:anx_reader/widgets/reading_page/tts_widget.dart';
import 'package:anx_reader/widgets/reading_page/style_widget.dart';
import 'package:anx_reader/widgets/reading_page/toc_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart'
// show debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ReadingPage extends ConsumerStatefulWidget {
  const ReadingPage({
    super.key,
    required this.book,
    this.cfi,
    required this.initialThemes,
    this.heroTag,
    this.initialShowCoach = false,
    this.closureRegistry = const ReadingClosurePolicyRegistry(),
  });

  final Book book;
  final String? cfi;
  final List<ReadTheme> initialThemes;
  final String? heroTag;
  final bool initialShowCoach;
  final ReadingClosurePolicyRegistry closureRegistry;

  @override
  ConsumerState<ReadingPage> createState() => ReadingPageState();
}

final GlobalKey<ReadingPageState> readingPageKey =
    GlobalKey<ReadingPageState>();
final epubPlayerKey = GlobalKey<EpubPlayerState>();

class ReadingPageState extends ConsumerState<ReadingPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const empty = SizedBox.shrink();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Book _book;
  late Widget _currentPage = empty;
  final Stopwatch _readTimeWatch = Stopwatch();
  DateTime? _sessionStart;
  Timer? _awakeTimer;
  bool bottomBarOffstage = true;
  late String heroTag;
  final aiChatKey = GlobalKey<AiChatStreamState>();
  late final AiWorkspaceController aiWorkspaceController;
  static const double _aiChatMinWidth = 360;
  late double _aiChatWidth;
  static const double _aiChatMinHeight = 200;
  late double _aiChatHeight;
  bool bookmarkExists = false;
  bool _readingAgentCapsuleDismissed = false;
  static const _readingInterventionPolicy = ReadingInterventionPolicy();
  String? _lastReadingAgentSnackActionId;
  BookReadingProfile? _readingProfile;
  BookReadingCoverage? _readingCoverage;
  bool _resumeContextAvailable = false;
  String? _lastRemoteProgressPromptFingerprint;
  bool _syncingRemoteProgress = false;
  bool _checkingRemoteProgress = false;
  Future<(ReadingOutcomesSnapshot, BookMaterialsSnapshot)>? _bookMaterials;
  Future<void>? _startingReadingSession;
  AiWorkspaceSurface _lastWorkspaceSurface = AiWorkspaceSurface.assistant;
  bool _workspaceWasVisible = false;
  final PageStorageBucket _workspaceStorage = PageStorageBucket();
  StreamSubscription<List<ReadingTask>>? _workspaceTaskSubscription;
  StreamSubscription<ReadingEvent>? _workspaceActionSubscription;
  String _completedTaskFingerprint = '';

  double get _visibleReadingProgress =>
      epubPlayerKey.currentState?.percentage ?? _book.readingPercentage;

  ReadingClosurePolicyDefinition get _closurePolicy =>
      ReadingClosurePolicyMatcher(registry: widget.closureRegistry).match(
        mode: Prefs().readingAiModeForBook(_book.id),
        title: _book.title,
        author: _book.author,
        description: _book.description ?? '',
        pinnedId: _readingProfile?.pinned == true
            ? _readingProfile!.primaryModuleId
            : readingExperienceProfileService.pinnedModuleId(_book.id),
      );

  Future<void> _loadReadingProfile() async {
    final matcher = ReadingClosurePolicyMatcher(
      registry: widget.closureRegistry,
    );
    final detected = matcher.detect(
      mode: Prefs().readingAiModeForBook(_book.id),
      title: _book.title,
      author: _book.author,
      description: _book.description ?? '',
    );
    final profile = await readingExperienceProfileService.loadOrCreate(
      bookId: _book.id,
      detectedModuleId: detected.moduleId,
      detectedFacets: detected.facets,
      confidence: detected.confidence,
      legacyPreference: Prefs().readingClosureIdForBook(_book.id),
    );
    Prefs().removeLegacyReadingClosureForBook(_book.id);
    final closure = widget.closureRegistry.getById(profile.primaryModuleId);
    final coverage = await readingCoverageService.loadOrInitialize(
      bookId: _book.id,
      currentPosition: _book.readingPercentage,
      supportsArtifacts: closure.supports(
        ReadingClosureCapability.readingArtifacts,
      ),
    );
    final resumeArtifacts =
        closure.supports(ReadingClosureCapability.resumeContext)
            ? await readingAgentRepository.artifacts(
                _book.id,
                kind: ReadingArtifactKinds.resumeContext,
                status: ReadingArtifactStatus.active,
                visibleAtProgress: _book.readingPercentage,
              )
            : const <ReadingArtifact>[];
    if (!mounted) return;
    aiWorkspaceController.setReadingProfile(profile);
    setState(() {
      _readingProfile = profile;
      _readingCoverage = coverage;
      _resumeContextAvailable = resumeArtifacts.isNotEmpty;
    });
  }

  Future<void> _setClosureModule(String? moduleId) async {
    final detected =
        ReadingClosurePolicyMatcher(registry: widget.closureRegistry).detect(
      mode: Prefs().readingAiModeForBook(_book.id),
      title: _book.title,
      author: _book.author,
      description: _book.description ?? '',
    );
    final profile = moduleId == null
        ? await readingExperienceProfileService.setAutomatic(
            bookId: _book.id,
            detectedModuleId: detected.moduleId,
            detectedFacets: detected.facets,
            confidence: detected.confidence,
          )
        : await readingExperienceProfileService.setPinned(
            bookId: _book.id,
            moduleId: moduleId,
            facets: _readingProfile?.facets ?? detected.facets,
          );
    if (!mounted) return;
    aiWorkspaceController.setReadingProfile(profile);
    setState(() {
      _readingProfile = profile;
      if (!_closurePolicy.supports(ReadingClosureCapability.resumeContext)) {
        _resumeContextAvailable = false;
      }
    });
  }

  bool _usesAiSplitLayout(BuildContext context) {
    return ReadingWorkspaceHost.usesSplit(MediaQuery.sizeOf(context).width);
  }

  double _effectiveAiPanelWidth(BuildContext context) {
    return ReadingWorkspaceHost.effectiveWidth(
      MediaQuery.sizeOf(context).width,
      _aiChatWidth,
    );
  }

  late final FocusNode _readerFocusNode;
  // late final VolumeKeyBoard _volumeKeyBoard;
  // bool _volumeKeyListenerAttached = false;

  @override
  void initState() {
    _readerFocusNode = FocusNode(debugLabel: 'reading_page_focus');

    // Initialize AI panel sizes from persistent storage
    _aiChatWidth = Prefs().aiPanelWidth >= 360 ? Prefs().aiPanelWidth : 0;
    _aiChatHeight = Prefs().aiPanelHeight;

    if (widget.book.isDeleted) {
      Navigator.pop(context);
      AnxToast.show(L10n.of(context).bookDeleted);
      return;
    }
    if (Prefs().hideStatusBar) {
      hideStatusBar();
    }

    WidgetsBinding.instance.addObserver(this);
    _readTimeWatch.start();
    _sessionStart = DateTime.now();
    ReadingActivityCoordinator.instance.startReading(this);
    setAwakeTimer(Prefs().awakeTime);

    _book = widget.book;
    // Register the page-owned EPUB executor as soon as the book page exists.
    // Durable tasks restored after process death are paused by the scheduler;
    // this registration makes their checkpoint resumable from Wiki/Context
    // pages instead of leaving a permanently disabled "continue" button.
    readingTaskScheduler.registerExecutor<int>(
      'wiki.book_generate',
      _executeBookWikiTask,
    );
    unawaited(readingExperienceDiagnostics.beginSession(bookId: _book.id));
    readingAgentRuntime.addListener(_onReadingAgentChanged);
    _workspaceActionSubscription = readingAgentRuntime.events.listen((event) {
      if ((event.type == ReadingEventType.agentActionApplied ||
              event.type == ReadingEventType.agentActionUndone) &&
          mounted &&
          _bookMaterials != null) {
        setState(() => _bookMaterials = _loadBookMaterials());
      }
    });
    _workspaceTaskSubscription = readingTaskScheduler.changes.listen((tasks) {
      final fingerprint = tasks
          .where((task) => task.bookId == _book.id && task.isTerminal)
          .map((task) => '${task.id}:${task.status.name}:${task.updatedAt}')
          .join('|');
      if (fingerprint == _completedTaskFingerprint) return;
      _completedTaskFingerprint = fingerprint;
      if (mounted && _bookMaterials != null) {
        setState(() => _bookMaterials = _loadBookMaterials());
      }
    });
    aiWorkspaceController = AiWorkspaceController(
      bookId: _book.id,
      onClosureModuleChanged: _setClosureModule,
    );
    _loadReadingProfile();
    aiWorkspaceController.addListener(_onAiWorkspaceChanged);
    heroTag = widget.heroTag ?? 'preventHeroWhenStart';
    // _volumeKeyBoard = VolumeKeyBoard.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestReaderFocus();
        if (Prefs().readingAgentBetaEnabled) {
          _startingReadingSession = readingAgentRuntime
              .start(bookId: _book.id, bookTitle: _book.title)
              .whenComplete(() => _startingReadingSession = null);
        }
        _registerReaderCommandGateway();
        if (FeatureFlags.readingCoach && widget.initialShowCoach) {
          showReadingCoach();
        }
        // _attachVolumeKeyListener();
      }
    });
    // delay 1000ms to prevent hero animation
    if (widget.heroTag == null) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            heroTag = _book.coverFullPath;
          });
        }
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    // The executor reads from this page's WebView. Pause before disposing it;
    // the durable checkpoint remains visible and can be resumed next time the
    // same book is opened.
    unawaited(_pauseBookWikiTasks());
    ReaderCommandGateway.instance.unregister(_book.id);
    readingAgentRuntime.removeListener(_onReadingAgentChanged);
    unawaited(_workspaceTaskSubscription?.cancel());
    unawaited(_workspaceActionSubscription?.cancel());
    unawaited(readingExperienceDiagnostics.endSession());
    _readTimeWatch.stop();
    _awakeTimer?.cancel();
    WakelockPlus.disable();
    showStatusBar();
    WidgetsBinding.instance.removeObserver(this);
    final progressSaved = epubPlayerKey.currentState?.saveReadingProgress() ??
        Future<void>.value();
    final readingStateSaved = Future.wait<void>([
      progressSaved,
      _saveFictionResumeMarker(),
      readingAgentRuntime.finish(),
      readingTimeDao.insertReadingTime(
        ReadingTime(
          bookId: _book.id,
          readingTime: _readTimeWatch.elapsed.inSeconds,
        ),
        startedAt: _sessionStart,
      ),
    ]);
    unawaited(
      readingStateSaved.whenComplete(() {
        ReadingActivityCoordinator.instance.finishReading(this);
        return Sync().syncData(
          SyncDirection.both,
          null,
          trigger: SyncTrigger.auto,
        );
      }),
    );
    _sessionStart = null;
    audioHandler.stop();
    // if (_volumeKeyListenerAttached) {
    //   unawaited(_volumeKeyBoard.removeListener());
    // }
    _readerFocusNode.dispose();
    aiWorkspaceController.removeListener(_onAiWorkspaceChanged);
    aiWorkspaceController.dispose();
    super.dispose();
  }

  Future<void> _pauseBookWikiTasks() async {
    await readingTaskScheduler.restore();
    for (final task in readingTaskScheduler.tasks) {
      if (task.bookId == _book.id &&
          task.type == 'wiki.book_generate' &&
          !task.isTerminal) {
        await readingTaskScheduler.pause(task.id);
      }
    }
  }

  Future<void> _saveFictionResumeMarker() async {
    if (!_closurePolicy.supports(ReadingClosureCapability.resumeContext)) {
      return;
    }
    final state = readingAgentRuntime.state;
    if (state.bookId != _book.id ||
        (state.chapterHref?.isEmpty ?? true) ||
        state.totalProgress <= 0) {
      return;
    }
    final coverage = _readingCoverage;
    if (coverage != null &&
        state.totalProgress > coverage.safeKnowledgeBoundary) {
      await readingCoverageService.advanceSafeBoundary(
        coverage,
        state.totalProgress,
      );
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await readingAgentRepository.saveSystemArtifact(
      ReadingArtifact(
        id: '${_book.id}-fiction-resume',
        bookId: _book.id,
        moduleId: ReadingClosureIds.fictionImmersion,
        kind: ReadingArtifactKinds.resumeContext,
        payload: {
          'summary': state.chapterTitle?.isNotEmpty == true
              ? '上次读到“${state.chapterTitle}”'
              : '上次读到当前章节',
        },
        epistemicStatus: ReadingArtifactEpistemicStatus.textFact,
        chapterHref: state.chapterHref,
        chapterTitle: state.chapterTitle,
        discoveredAtCfi: state.cfi,
        sourceProgress: state.totalProgress,
        visibleFromProgress: state.totalProgress,
        ingestedAt: now,
        createdBy: 'runtime',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  void _requestReaderFocus() {
    if (bottomBarOffstage && !_readerFocusNode.hasFocus) {
      _readerFocusNode.requestFocus();
    }
  }

  void _onReadingAgentChanged() {
    if (!mounted) return;
    setState(() {});
    final action = readingAgentRuntime.state.lastAgentAction;
    if (action == null || action.id == _lastReadingAgentSnackActionId) return;
    _lastReadingAgentSnackActionId = action.id;
    if (aiWorkspaceController.visible &&
        aiWorkspaceController.surface == AiWorkspaceSurface.assistant) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showAgentUndoSnackBar(action);
    });
  }

  void _registerReaderCommandGateway() {
    ReaderCommandGateway.instance.register(
      bookId: _book.id,
      navigateToCfi: (cfi) => epubPlayerKey.currentState?.goToCfi(cfi),
      navigateToHref: (href) => epubPlayerKey.currentState?.goToHref(href),
      currentCfi: () => epubPlayerKey.currentState?.cfi,
      addAnnotation: (note) => epubPlayerKey.currentState?.addAnnotation(note),
      removeAnnotation: (key) =>
          epubPlayerKey.currentState?.removeAnnotation(key),
      addDifficultyAnnotation: ({required id, required cfi}) =>
          epubPlayerKey.currentState?.addDifficultyAnnotation(id: id, cfi: cfi),
      isValidHref: (href) {
        bool contains(List<TocItem> items) {
          for (final item in items) {
            if (item.href == href ||
                item.href.split('#').first == href.split('#').first) {
              return true;
            }
            if (contains(item.subitems)) return true;
          }
          return false;
        }

        return contains(ref.read(bookTocProvider));
      },
    );
  }

  void _releaseReaderFocus() {
    if (_readerFocusNode.hasFocus) {
      _readerFocusNode.unfocus();
    }
  }

  // Future<void> _attachVolumeKeyListener() async {
  //   if (defaultTargetPlatform != TargetPlatform.iOS ||
  //       _volumeKeyListenerAttached) {
  //     return;
  //   }

  //   try {
  //     await _volumeKeyBoard.addListener(_handleVolumeKeyEvent);
  //     _volumeKeyListenerAttached = true;
  //   } catch (error) {
  //     debugPrint('Failed to attach volume key listener: $error');
  //   }
  // }

  // void _handleVolumeKeyEvent(VolumeKey key) {
  //   if (!Prefs().volumeKeyTurnPage || !_readerFocusNode.hasFocus) {
  //     return;
  //   }

  //   if (key == VolumeKey.up) {
  //     epubPlayerKey.currentState?.prevPage();
  //   } else if (key == VolumeKey.down) {
  //     epubPlayerKey.currentState?.nextPage();
  //   }
  // }

  final Set<PhysicalKeyboardKey> _consumedSelectionKeys = {};

  KeyEventResult _handleReaderKeyEvent(FocusNode node, KeyEvent event) {
    if (_consumedSelectionKeys.contains(event.physicalKey)) {
      if (event is KeyUpEvent) _consumedSelectionKeys.remove(event.physicalKey);
      return KeyEventResult.handled;
    }
    if (!_readerFocusNode.hasFocus) {
      return KeyEventResult.ignored;
    }

    final logicalKey = event.logicalKey;
    final volumeUp = event.physicalKey == PhysicalKeyboardKey.audioVolumeUp ||
        logicalKey == LogicalKeyboardKey.audioVolumeUp;
    final volumeDown =
        event.physicalKey == PhysicalKeyboardKey.audioVolumeDown ||
            logicalKey == LogicalKeyboardKey.audioVolumeDown;
    if (event is! KeyDownEvent) {
      return Prefs().volumeKeyTurnPage && (volumeUp || volumeDown)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed &&
        aiWorkspaceController.selectionDockVisible &&
        {
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.arrowDown
        }.contains(logicalKey)) {
      return KeyEventResult.ignored;
    }
    final pagingKey = {
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.arrowDown,
          LogicalKeyboardKey.pageDown,
          LogicalKeyboardKey.space,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.pageUp,
        }.contains(logicalKey) ||
        (Prefs().volumeKeyTurnPage && (volumeUp || volumeDown));
    if (pagingKey && aiWorkspaceController.selectionDockVisible) {
      _consumedSelectionKeys.add(event.physicalKey);
      epubPlayerKey.currentState?.clearReaderSelection();
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.escape &&
        (aiWorkspaceController.selection != null ||
            aiWorkspaceController.visible)) {
      _dismissTopReadingHelp();
      return KeyEventResult.handled;
    }

    if (logicalKey == LogicalKeyboardKey.arrowRight ||
        logicalKey == LogicalKeyboardKey.arrowDown ||
        logicalKey == LogicalKeyboardKey.pageDown ||
        logicalKey == LogicalKeyboardKey.space) {
      epubPlayerKey.currentState?.nextPage();
      return KeyEventResult.handled;
    }

    if (logicalKey == LogicalKeyboardKey.arrowLeft ||
        logicalKey == LogicalKeyboardKey.arrowUp ||
        logicalKey == LogicalKeyboardKey.pageUp) {
      epubPlayerKey.currentState?.prevPage();
      return KeyEventResult.handled;
    }

    if (logicalKey == LogicalKeyboardKey.enter) {
      showOrHideAppBarAndBottomBar(true);
      return KeyEventResult.handled;
    }

    // Handle Ctrl+[ and Ctrl+] for page turning when keyboard shortcut is enabled
    if (Prefs().keyboardShortcutTurnPage) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed;
      if (isControlPressed && logicalKey == LogicalKeyboardKey.bracketLeft) {
        epubPlayerKey.currentState?.prevPage();
        return KeyEventResult.handled;
      }
      if (isControlPressed && logicalKey == LogicalKeyboardKey.bracketRight) {
        epubPlayerKey.currentState?.nextPage();
        return KeyEventResult.handled;
      }
      final bool isSimulatedCtrlLeft = event.character == '\u001b';
      final bool isSimulatedCtrlRight = event.character == '\u001d';
      if (isSimulatedCtrlLeft) {
        epubPlayerKey.currentState?.prevPage();
        return KeyEventResult.handled;
      }
      if (isSimulatedCtrlRight) {
        epubPlayerKey.currentState?.nextPage();
        return KeyEventResult.handled;
      }
    }

    if (Prefs().volumeKeyTurnPage) {
      if (volumeUp) {
        epubPlayerKey.currentState?.prevPage();
        return KeyEventResult.handled;
      }
      if (volumeDown) {
        epubPlayerKey.currentState?.nextPage();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_readTimeWatch.isRunning) {
          _readTimeWatch.start();
        }
        _sessionStart ??= DateTime.now();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_readTimeWatch.isRunning) {
          _readTimeWatch.stop();
        }
        if (state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.detached) {
          final elapsedSeconds = _readTimeWatch.elapsed.inSeconds;
          final startedAt = _sessionStart;
          final saveOperations = <Future<void>>[
            epubPlayerKey.currentState?.saveReadingProgress() ??
                Future<void>.value(),
          ];
          if (elapsedSeconds > 5) {
            saveOperations.add(
              readingTimeDao.insertReadingTime(
                ReadingTime(bookId: _book.id, readingTime: elapsedSeconds),
                startedAt: startedAt,
              ),
            );
          }
          unawaited(
            Future.wait<void>(saveOperations).whenComplete(() {
              ReadingActivityCoordinator.instance.permitBackgroundFlush();
              return Sync().syncData(
                SyncDirection.both,
                null,
                trigger: SyncTrigger.auto,
              );
            }),
          );
          _readTimeWatch.reset();
          _sessionStart = null;
        }
        break;
    }
  }

  Future<void> setAwakeTimer(int minutes) async {
    _awakeTimer?.cancel();
    _awakeTimer = null;
    WakelockPlus.enable();
    _awakeTimer = Timer.periodic(Duration(minutes: minutes), (timer) {
      WakelockPlus.disable();
      _awakeTimer?.cancel();
      _awakeTimer = null;
    });
  }

  void resetAwakeTimer() {
    setAwakeTimer(Prefs().awakeTime);
  }

  void showBottomBar() {
    setState(() {
      showStatusBarWithoutResize();
      bottomBarOffstage = false;
      _releaseReaderFocus();
    });
  }

  void hideBottomBar() {
    setState(() {
      _currentPage = empty;
      bottomBarOffstage = true;
      if (Prefs().hideStatusBar) {
        hideStatusBar();
      }
      _requestReaderFocus();
    });
  }

  void showOrHideAppBarAndBottomBar(bool show) {
    if (show) {
      showBottomBar();
    } else {
      hideBottomBar();
    }
  }

  Future<void> tocHandler() async {
    hideBottomBar();
    _scaffoldKey.currentState?.openDrawer();
  }

  void noteHandler() {
    setState(() {
      _currentPage = ReadingNotes(book: _book);
    });
  }

  void progressHandler() {
    setState(() {
      _currentPage = ProgressWidget(
        epubPlayerKey: epubPlayerKey,
        showOrHideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
      );
    });
  }

  Future<void> styleHandler(StateSetter modalSetState) async {
    List<ReadTheme> themes = await themeDao.selectThemes();
    setState(() {
      _currentPage = StyleWidget(
        themes: themes,
        epubPlayerKey: epubPlayerKey,
        setCurrentPage: (Widget page) {
          modalSetState(() {
            _currentPage = page;
          });
        },
        hideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
      );
    });
  }

  Future<void> ttsHandler() async {
    setState(() {
      _currentPage = TtsWidget(epubPlayerKey: epubPlayerKey);
    });
  }

  double _aiChatMaxWidth(BuildContext context) => math.max(
      _aiChatMinWidth, math.min(520, MediaQuery.sizeOf(context).width - 400));

  double _aiChatMaxHeight(BuildContext context) {
    final totalHeight = MediaQuery.of(context).size.height;
    final maxByPercentage = totalHeight * 0.60;
    final maxByRemaining = totalHeight - 320;
    final maxHeight = math.min(maxByPercentage, maxByRemaining);
    return math.max(_aiChatMinHeight, maxHeight);
  }

  Future<void> onLoadEnd() async {
    final coach = await ref.read(readingCoachProvider(_book.id).future);
    for (final difficulty in coach.difficulties.where(
      (item) => item.status == ReadingDifficultyStatus.unresolved,
    )) {
      epubPlayerKey.currentState?.addDifficultyAnnotation(
        id: difficulty.id,
        cfi: difficulty.cfi,
      );
    }
    unawaited(_offerRemoteProgressIfAvailable());
  }

  Future<void> _offerRemoteProgressIfAvailable({bool manual = false}) async {
    if (!mounted || (!manual && widget.cfi != null)) return;
    if (_checkingRemoteProgress) return;
    final syncEnabled = Prefs().cloudBaseSyncEnabled ||
        Prefs().selfHostedProgressSyncEnabled ||
        Prefs().webdavStatus;
    if (!syncEnabled) {
      if (manual) {
        AnxToast.show(L10n.of(context).readingRemoteProgressSyncDisabled);
      }
      return;
    }

    _checkingRemoteProgress = true;
    if (manual) setState(() => _syncingRemoteProgress = true);
    try {
      if (!manual && Prefs().selfHostedProgressSyncEnabled) {
        // Opening a book may perform one progress-only request. The call still
        // uses the shared single-flight gate; ordinary relocations never enter
        // this path.
        await ref.read(syncProvider.notifier).syncSelfHostedProgress();
      } else {
        // Other automatic work during active reading remains deferred. An
        // explicit tap may run all configured transports immediately.
        await Sync().syncData(
          SyncDirection.both,
          ref,
          trigger: manual ? SyncTrigger.manual : SyncTrigger.auto,
        );
      }
    } catch (error) {
      if (manual && mounted) {
        AnxToast.show(
          L10n.of(context).readingRemoteProgressSyncFailed(error.toString()),
        );
      }
      // A sync outage must never block opening or reading a book.
      _checkingRemoteProgress = false;
      return;
    } finally {
      if (manual && mounted) setState(() => _syncingRemoteProgress = false);
    }

    final deviceId = await ReadingDeviceIdentity().getOrCreate();
    final current = await readingAgentSyncDao.position(_book.id, deviceId);
    final localProgress = current?.progress ?? _book.readingPercentage;
    final remote = await readingAgentSyncDao.farthestOtherPosition(
      _book.id,
      deviceId,
    );
    if (!mounted || remote == null || remote.progress <= localProgress + .01) {
      if (manual && mounted) {
        AnxToast.show(L10n.of(context).readingRemoteProgressNotFound);
      }
      _checkingRemoteProgress = false;
      return;
    }

    final fingerprint = [
      remote.deviceId,
      remote.cfi,
      remote.progress.toStringAsFixed(6),
      remote.updatedAt,
    ].join(':');
    if (!manual && _lastRemoteProgressPromptFingerprint == fingerprint) {
      _checkingRemoteProgress = false;
      return;
    }
    _lastRemoteProgressPromptFingerprint = fingerprint;
    if (!manual) readingExperienceDiagnostics.recordUnsolicitedDialog();
    final jump = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final localPercent = (localProgress * 100).round();
        final remotePercent = (remote.progress * 100).round();
        return AlertDialog(
          title: Text(L10n.of(dialogContext).readingRemoteProgressTitle),
          content: Text(
            L10n.of(
              dialogContext,
            ).readingRemoteProgressMessage(remotePercent, localPercent),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(L10n.of(dialogContext).readingRemoteProgressStay),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                L10n.of(dialogContext).readingRemoteProgressJump(remotePercent),
              ),
            ),
          ],
        );
      },
    );
    _checkingRemoteProgress = false;
    if (jump != true || !mounted) return;
    epubPlayerKey.currentState?.goToCfi(remote.cfi);
  }

  void _onAiWorkspaceChanged() {
    if (!mounted) return;
    if (_workspaceWasVisible && !aiWorkspaceController.visible) {
      aiChatKey.currentState?.stopGenerating();
      FocusManager.instance.primaryFocus?.unfocus();
    }
    if (aiWorkspaceController.surface == AiWorkspaceSurface.book &&
        (_lastWorkspaceSurface != AiWorkspaceSurface.book ||
            _bookMaterials == null)) {
      _bookMaterials = _loadBookMaterials();
    }
    _workspaceWasVisible = aiWorkspaceController.visible;
    _lastWorkspaceSurface = aiWorkspaceController.surface;
    setState(() {});
  }

  Future<void> _ensureReadingSession() async {
    if (!readingAgentRuntime.isActive ||
        readingAgentRuntime.state.bookId != _book.id) {
      await (_startingReadingSession ??= readingAgentRuntime
          .start(bookId: _book.id, bookTitle: _book.title)
          .whenComplete(() => _startingReadingSession = null));
    }
    if (!mounted) return;
    final player = epubPlayerKey.currentState;
    if (player != null) {
      readingAgentRuntime.captureRequestLocation(
        cfi: player.cfi,
        chapterHref: player.chapterHref,
        chapterTitle: player.chapterTitle,
        totalProgress: player.percentage,
        chapterProgress: player.chapterTotalPages > 0
            ? player.chapterCurrentPage / player.chapterTotalPages
            : 0,
      );
    }
  }

  Widget _buildAiWorkspace({List<Widget>? trailing}) {
    return AiReadingWorkspace(
      key: const ValueKey('ai-reading-workspace'),
      controller: aiWorkspaceController,
      chatKey: aiChatKey,
      quickPromptChips: _getAiQuickPromptChips(),
      bookTitle: _book.title,
      bookAuthor: _book.author,
      bookDescription: _book.description,
      onRestoreReadingContext: _restoreAiReadingContext,
      onFetchChapter: (href) =>
          epubPlayerKey.currentState?.chapterContentByHref(
            href,
            maxCharacters: 6000,
          ) ??
          Future.value(''),
      onFetchChapterSample: (href) =>
          epubPlayerKey.currentState?.chapterContentByHref(href) ??
          Future.value(''),
      onNavigateChapter: (target) {
        _navigateBookSource(target);
      },
      onDifficultySaved: (item) => epubPlayerKey.currentState
          ?.addDifficultyAnnotation(id: item.id, cfi: item.cfi),
      onDifficultyResolved: (item) =>
          epubPlayerKey.currentState?.removeAnnotation('difficulty:${item.id}'),
      closureRegistry: widget.closureRegistry,
      currentChapterTitle: epubPlayerKey.currentState?.chapterTitle,
      currentProgress: _visibleReadingProgress,
      onInputFocused: () => aiWorkspaceController.setSheetExpanded(true),
      onOpenBook: _showBookHub,
      onReturnToQuestion: ReaderCommandGateway.instance
              .canReturnToPreviousLocation(bookId: _book.id)
          ? () {
              ReaderCommandGateway.instance
                  .returnToPreviousLocation(bookId: _book.id);
              setState(() {});
            }
          : null,
      trailing: trailing ?? const [],
    );
  }

  Widget _buildReadingAgentCapsule() {
    final state = readingAgentRuntime.state;
    final closure = _closurePolicy;
    final goal = state.activeGoal;
    final pending = state.pendingProfileCount +
        (closure.checkpointTriggersCapsule ? state.pendingCheckpointCount : 0) +
        (closure.showKnowledgeCards ? state.dueKnowledgeCardCount : 0);
    final coveragePending = _readingCoverage?.setupPending == true;
    final startPercent =
        ((_readingCoverage?.initializedAtProgress ?? 0) * 100).round();
    final title = coveragePending
        ? '你从本书 $startPercent% 开始使用阅读 Agent，可选择建立前情档案'
        : goal?.title ??
            (pending > 0
                ? '有 $pending 项待处理'
                : _resumeContextAvailable
                    ? '可恢复上次阅读上下文'
                    : state.unresolvedDifficultyCount > 0
                        ? '${state.unresolvedDifficultyCount} 个问题待解决'
                        : '最近动作可撤销');
    final semantics = coveragePending
        ? '阅读 Agent，$title'
        : goal == null
            ? '阅读 Agent，$title'
            : '阅读目标：${goal.title}，进度 ${(goal.progress * 100).round()}%'
                '${pending > 0 ? '，$pending 项待处理' : ''}';
    return Align(
      alignment: Alignment.topCenter,
      child: Semantics(
        button: true,
        label: semantics,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () async {
              if (coveragePending) {
                await _showCoverageSetup();
                return;
              }
              if (_usesAiSplitLayout(context)) {
                aiWorkspaceController.show(fullscreen: false);
                setState(() {});
              } else {
                await _showReadingAgentPanel();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 16),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(title, overflow: TextOverflow.ellipsis),
                  ),
                  if (!coveragePending && goal != null) ...[
                    const SizedBox(width: 8),
                    Text('${(goal.progress * 100).round()}%'),
                  ],
                  if (pending > 0) ...[
                    const SizedBox(width: 8),
                    Badge(label: Text('$pending')),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onChapterChanged({
    required String previousHref,
    required String previousTitle,
    required double highestProgress,
    required String currentHref,
  }) async {
    if (Prefs().readingAgentBetaEnabled) {
      readingAgentRuntime.observeChapterChanged(
        currentHref: currentHref,
        completedHref: previousHref,
        completedTitle: previousTitle,
        completedProgress: highestProgress,
      );
      final coverage = _readingCoverage;
      if (coverage != null &&
          highestProgress > coverage.safeKnowledgeBoundary) {
        final updated = await readingCoverageService.advanceSafeBoundary(
          coverage,
          highestProgress,
        );
        if (mounted) setState(() => _readingCoverage = updated);
      }
    }
    if (!FeatureFlags.readingCoach) return;
    final state = await ref.read(readingCoachProvider(_book.id).future);
    if (!shouldCreateChapterQuiz(
      previousHref: previousHref,
      currentHref: currentHref,
      highestProgress: highestProgress,
      existingChapterHrefs: state.quizzes.map((quiz) => quiz.chapterHref),
    )) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await ref.read(readingCoachProvider(_book.id).notifier).saveQuiz(
          ChapterQuiz(
            id: '${_book.id}-${previousHref.hashCode}-$now',
            bookId: _book.id,
            chapterHref: previousHref,
            chapterTitle: previousTitle,
            updatedAt: now,
          ),
        );
  }

  List<AiQuickPromptChip> _getAiQuickPromptChips() {
    final closure = _closurePolicy;
    return [
      for (final prompt in closure.quickPrompts)
        AiQuickPromptChip(
          icon: EvaIcons.book,
          label: prompt.label,
          prompt: prompt.prompt,
        ),
      AiQuickPromptChip(
        icon: Icons.menu_book_rounded,
        label: L10n.of(context).settingsAiPromptSummaryTheBook,
        prompt: generatePromptSummaryTheBook().buildString(),
      ),
      AiQuickPromptChip(
        icon: Icons.account_tree_outlined,
        label: L10n.of(context).settingsAiPromptMindmap,
        prompt: generatePromptMindmap().buildString(),
      ),
      // User custom prompts (enabled only)
      ...Prefs().userPrompts.where((p) => p.enabled).map(
            (userPrompt) => AiQuickPromptChip(
              icon: Icons.person_outline,
              label: userPrompt.name,
              prompt: userPrompt.content,
            ),
          ),
    ];
  }

  Future<bool> showAiChat({
    String? content,
    bool sendImmediate = false,
    ReadingContextSnapshot? selection,
    bool Function()? isCurrent,
  }) async {
    final workspaceContext = context;
    final shouldShowFullscreen = !_usesAiSplitLayout(workspaceContext);
    try {
      await _ensureReadingSession();
    } catch (_) {
      // Reading help remains usable; sourced writes reject an absent session.
    }
    if (!mounted || isCurrent?.call() == false) return false;
    ref.read(aiChatProvider.notifier).ensureBookScope(_book.id);
    aiWorkspaceController.switchSurface(AiWorkspaceSurface.assistant);

    final snapshot = selection;
    if (snapshot != null) {
      aiWorkspaceController.setPendingSelection(snapshot);
    }
    if (content != null && snapshot == null) {
      aiWorkspaceController.setDraft(content);
      aiChatKey.currentState?.setDraft(content);
    }

    if (!shouldShowFullscreen) {
      final maxWidth = _aiChatMaxWidth(navigatorKey.currentContext!);
      final maxHeight = _aiChatMaxHeight(navigatorKey.currentContext!);
      _aiChatWidth = ReadingWorkspaceHost.effectiveWidth(
              MediaQuery.sizeOf(context).width, _aiChatWidth)
          .clamp(_aiChatMinWidth, maxWidth);
      _aiChatHeight = _aiChatHeight.clamp(_aiChatMinHeight, maxHeight);
    }
    aiWorkspaceController.show(fullscreen: shouldShowFullscreen);
    if (sendImmediate && content != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        aiChatKey.currentState?.sendPrompt(content);
      });
    }
    return true;
  }

  bool get selectionAiGenerating =>
      aiChatKey.currentState?.isGenerating ?? false;

  void finishSelection() {
    epubPlayerKey.currentState?.clearReaderSelection();
    aiWorkspaceController.dismissSelectionPanel();
    aiWorkspaceController.hide();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> openSelectionPanel(
    SelectionPanelPage page, {
    SelectionSnapshot? target,
    int? annotationId,
  }) async {
    final source = target ??
        aiWorkspaceController.selectionTarget ??
        aiWorkspaceController.selection;
    if (source == null) return;
    final id = target != null
        ? annotationId
        : aiWorkspaceController.selectionTargetAnnotationId ??
            aiWorkspaceController.selectionAnnotationId;
    final player = epubPlayerKey.currentState;
    final sameTarget = aiWorkspaceController.selectionTarget == source;
    final chapter = sameTarget
        ? aiWorkspaceController.selectionTargetChapterTitle
        : player?.chapterTitle ?? '';
    final href = sameTarget
        ? aiWorkspaceController.selectionTargetChapterHref
        : player?.chapterHref ?? '';
    epubPlayerKey.currentState?.setSelectionClearLocked(true);
    aiWorkspaceController.selectionOffline = true;
    aiWorkspaceController.selectionTargetChapterTitle = chapter;
    aiWorkspaceController.selectionTargetChapterHref = href;
    aiWorkspaceController.openSelectionPanel(page,
        target: source, annotationId: id);
    final revision = aiWorkspaceController.selectionPanelRevision;
    final operationFailed = L10n.of(context).selectionOperationFailed;
    bool stillCurrent() =>
        mounted &&
        aiWorkspaceController.selectionPanelRevision == revision &&
        aiWorkspaceController.selectionTarget == source &&
        aiWorkspaceController.selectionPanelPage == page;
    if (page == SelectionPanelPage.lookup) {
      try {
        final offline = (await Connectivity().checkConnectivity())
            .contains(ConnectivityResult.none);
        if (!stillCurrent()) return;
        aiWorkspaceController.selectionOffline = offline;
        aiWorkspaceController.setSelectionFeedback();
      } catch (_) {
        // Local help remains available without connectivity status.
      }
    }
    if (id != null &&
        (page == SelectionPanelPage.note || page == SelectionPanelPage.style)) {
      aiWorkspaceController.setSelectionFeedback(busy: true);
      try {
        await _ensureReadingSession();
        if (!stillCurrent()) return;
        final note = await AgentActionService().readAnnotation(id);
        if (!stillCurrent()) return;
        if (note == null || note.bookId != _book.id) {
          throw StateError('Annotation unavailable');
        }
        aiWorkspaceController.selectionEditingAnnotation = note;
        aiWorkspaceController.selectionNoteDraft = note.readerNote ?? '';
        aiWorkspaceController.setSelectionFeedback();
      } catch (_) {
        if (stillCurrent()) {
          aiWorkspaceController.setSelectionFeedback(error: operationFailed);
        }
      }
    }
  }

  ReadingContextSnapshot _selectionContext(SelectionSnapshot source) {
    final player = epubPlayerKey.currentState;
    return ReadingContextSnapshot(
      bookId: _book.id.toString(),
      bookTitle: _book.title,
      author: _book.author,
      chapterTitle: aiWorkspaceController.selectionTarget == source
          ? aiWorkspaceController.selectionTargetChapterTitle
          : player?.chapterTitle,
      chapterHref: aiWorkspaceController.selectionTarget == source
          ? aiWorkspaceController.selectionTargetChapterHref
          : player?.chapterHref,
      selectedText: source.text,
      surroundingText: source.contextText,
      progress: source.visibleFromProgress ?? player?.percentage,
      capturedAt: DateTime.now().millisecondsSinceEpoch,
      metadata: {
        'cfi': source.cfi,
        'selectionSessionId': source.sessionId,
        'selectionRevision': source.revision
      },
    );
  }

  bool _selectionWithinVisibleBoundary(SelectionSnapshot source) {
    if (source.revision > 0 && source.sourceProgress == null) {
      aiWorkspaceController.setSelectionFeedback(
          error: L10n.of(context).selectionShowEndFirst);
      return false;
    }
    return true;
  }

  Future<void> handleSelectionAction(SelectionMenuAction action) async {
    final source = aiWorkspaceController.selectionTarget ??
        aiWorkspaceController.selection;
    if (source == null || aiWorkspaceController.selectionBusy) return;
    final targetId = aiWorkspaceController.selectionTarget != null
        ? aiWorkspaceController.selectionTargetAnnotationId
        : aiWorkspaceController.selectionAnnotationId;
    switch (action) {
      case SelectionMenuAction.highlight:
        await _saveSelectionAnnotation(source: source, annotationId: targetId);
      case SelectionMenuAction.lookupOrTranslate:
        await openSelectionPanel(SelectionPanelPage.lookup,
            target: source, annotationId: targetId);
      case SelectionMenuAction.ai:
      case SelectionMenuAction.bringToQuestion:
        if (!_selectionWithinVisibleBoundary(source)) return;
        final snapshot = _selectionContext(source);
        final revision = aiWorkspaceController.selectionPanelRevision;
        bool stillCurrent() =>
            mounted &&
            aiWorkspaceController.selectionPanelRevision == revision &&
            (aiWorkspaceController.selectionTarget ??
                    aiWorkspaceController.selection) ==
                source;
        if (action == SelectionMenuAction.ai && selectionAiGenerating) {
          // The invoking button explicitly says Stop and explain selection.
          aiChatKey.currentState?.stopGenerating();
        }
        epubPlayerKey.currentState?.setSelectionClearLocked(true);
        aiWorkspaceController.selectionDockVisible = false;
        final opened =
            await showAiChat(selection: snapshot, isCurrent: stillCurrent);
        if (!mounted || !opened) return;
        if (action == SelectionMenuAction.ai) {
          aiWorkspaceController.requestSelectionAction(
              snapshot, SelectionAiAction.explain);
        }
      case SelectionMenuAction.note:
        await openSelectionPanel(SelectionPanelPage.note,
            target: source, annotationId: targetId);
      case SelectionMenuAction.copy:
        await Clipboard.setData(ClipboardData(text: source.text));
        finishSelection();
      case SelectionMenuAction.webSearch:
        await openSelectionPanel(SelectionPanelPage.search,
            target: source, annotationId: targetId);
      case SelectionMenuAction.paragraphTranslate:
        if (!_selectionWithinVisibleBoundary(source)) return;
        await openSelectionPanel(SelectionPanelPage.lookup,
            target: source, annotationId: targetId);
      case SelectionMenuAction.saveDifficulty:
        if (!_selectionWithinVisibleBoundary(source)) return;
        await saveReadingDifficulty(_selectionContext(source));
        if (mounted) finishSelection();
      case SelectionMenuAction.addToVocabulary:
        aiWorkspaceController.setSelectionFeedback(busy: true);
        try {
          // Capturing the already selected word does not authorize enrichment.
          await VocabularyCaptureService.captureQuick(
            word: source.text,
            bookId: _book.id.toString(),
            bookTitle: _book.title,
            chapterId: epubPlayerKey.currentState?.chapterHref,
            chapterTitle: epubPlayerKey.currentState?.chapterTitle,
            contextText: source.contextText,
            position: source.cfi,
            dictionaryLookup: (_) async => null,
            translateLookup: (_, {contextText}) async => '',
          );
          if (mounted) finishSelection();
        } catch (_) {
          if (mounted) {
            aiWorkspaceController.setSelectionFeedback(
                error: L10n.of(context).selectionOperationFailed);
          }
        } finally {
          if (mounted) {
            aiWorkspaceController.setSelectionFeedback(
                error: aiWorkspaceController.selectionError);
          }
        }
      case SelectionMenuAction.narrate:
        final player = epubPlayerKey.currentState;
        if (player == null) return;
        try {
          await audioHandler.stop();
          await TtsHandler().init(() => player.initTts(fromCfi: source.cfi),
              player.ttsNext, player.ttsPrev);
          await audioHandler.play();
          if (mounted) finishSelection();
        } catch (_) {
          if (mounted) {
            aiWorkspaceController.setSelectionFeedback(
                error: L10n.of(context).selectionOperationFailed);
          }
        }
      case SelectionMenuAction.share:
        final chapter = epubPlayerKey.currentState?.chapterTitle;
        finishSelection();
        if (!mounted) return;
        await ExcerptShareService.showShareExcerpt(
            context: context,
            bookTitle: _book.title,
            author: _book.author,
            excerpt: source.text,
            chapter: chapter ?? '');
    }
  }

  Future<void> _saveSelectionAnnotation(
      {SelectionSnapshot? source,
      int? annotationId,
      bool delete = false}) async {
    source ??= aiWorkspaceController.selectionTarget ??
        aiWorkspaceController.selection;
    if (source == null ||
        aiWorkspaceController.selectionBusy ||
        !_selectionWithinVisibleBoundary(source)) {
      return;
    }
    final snapshot = source;
    final id = annotationId ??
        aiWorkspaceController.selectionTargetAnnotationId ??
        aiWorkspaceController.selectionAnnotationId;
    final editor = aiWorkspaceController.selectionEditingAnnotation;
    if (id != null &&
        (aiWorkspaceController.selectionPanelPage == SelectionPanelPage.note ||
            aiWorkspaceController.selectionPanelPage ==
                SelectionPanelPage.style) &&
        editor == null) {
      aiWorkspaceController.setSelectionFeedback(
          error: L10n.of(context).selectionOperationFailed);
      return;
    }
    final chapter = aiWorkspaceController.selectionTarget == snapshot
        ? aiWorkspaceController.selectionTargetChapterTitle
        : epubPlayerKey.currentState?.chapterTitle ?? '';
    final href = aiWorkspaceController.selectionTarget == snapshot
        ? aiWorkspaceController.selectionTargetChapterHref
        : epubPlayerKey.currentState?.chapterHref;
    final type = aiWorkspaceController.selectionStyleType ??
        editor?.type ??
        Prefs().annotationType;
    final color = aiWorkspaceController.selectionStyleColor ??
        editor?.color ??
        Prefs().annotationColor;
    final body =
        aiWorkspaceController.selectionPanelPage == SelectionPanelPage.note
            ? aiWorkspaceController.selectionNoteDraft
            : null;
    aiWorkspaceController.setSelectionFeedback(busy: true);
    try {
      await _ensureReadingSession();
      if (!mounted) return;
      final service = AgentActionService();
      final mutation = delete && id != null
          ? await service.deleteManualAnnotation(
              bookId: _book.id,
              annotationId: id,
              expectedUpdatedAt: editor?.updateTime)
          : await service.saveManualAnnotation(
              bookId: _book.id,
              text: snapshot.text,
              cfi: snapshot.cfi,
              chapter: chapter,
              chapterHref: href,
              color: color,
              type: type,
              readerNote: body,
              annotationId: id,
              sourceProgress:
                  snapshot.sourceProgress ?? _visibleReadingProgress,
              visibleFromProgress:
                  snapshot.visibleFromProgress ?? _visibleReadingProgress,
              expectedUpdatedAt: editor?.updateTime);
      if (!mounted) return;
      if (!delete) {
        Prefs().annotationType = type;
        Prefs().annotationColor = color;
      }
      if (aiWorkspaceController.selection?.sessionId == snapshot.sessionId &&
          aiWorkspaceController.selection?.revision == snapshot.revision) {
        finishSelection();
      }
      aiWorkspaceController.setSelectionFeedback();
      aiWorkspaceController.setSelectionUndo(() async {
        if (aiWorkspaceController.selectionBusy) return;
        aiWorkspaceController.setSelectionFeedback(busy: true);
        try {
          final result = await service.undo(mutation.action);
          if (!mounted) return;
          if (result == UndoResult.undone ||
              result == UndoResult.alreadyUndone) {
            aiWorkspaceController.clearSelectionUndo();
          } else {
            aiWorkspaceController.selectionUndoFailed = true;
          }
          _bookMaterials = _loadBookMaterials();
        } catch (_) {
          if (mounted) aiWorkspaceController.selectionUndoFailed = true;
        } finally {
          if (mounted) aiWorkspaceController.setSelectionFeedback();
        }
      });
      _bookMaterials = _loadBookMaterials();
    } catch (_) {
      if (mounted) {
        aiWorkspaceController.setSelectionFeedback(
            error: L10n.of(context).selectionOperationFailed);
      }
    }
  }

  void _returnToSelection() {
    FocusManager.instance.primaryFocus?.unfocus();
    aiWorkspaceController.returnToSelection();
    // The DOM may have collapsed while a keyboard/result panel had focus.
    final selection = aiWorkspaceController.selection;
    if (selection != null) {
      epubPlayerKey.currentState?.restoreSelection(selection.cfi);
    }
  }

  void _dismissTopReadingHelp() {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else if (aiWorkspaceController.selectionPanelPage != null) {
      if (!aiWorkspaceController.popSelectionPanel()) _returnToSelection();
    } else if (aiWorkspaceController.selectionDockVisible &&
        aiWorkspaceController.selectionToolPage != SelectionToolPage.actions) {
      aiWorkspaceController.setSelectionToolPage(SelectionToolPage.actions);
    } else if (aiWorkspaceController.visible &&
        aiWorkspaceController.surface == AiWorkspaceSurface.assistant &&
        aiWorkspaceController.view != AiWorkspaceView.chat) {
      aiWorkspaceController.showChat();
    } else if (aiWorkspaceController.visible &&
        aiWorkspaceController.selection != null) {
      _returnToSelection();
    } else {
      finishSelection();
    }
  }

  Future<void> showReadingCoach() async {
    aiWorkspaceController.showPractice();
    await showAiChat();
  }

  Future<void> saveReadingDifficulty(ReadingContextSnapshot snapshot) async {
    final text = snapshot.selectedText?.trim() ?? '';
    final cfi = snapshot.metadata['cfi']?.toString() ?? '';
    if (text.isEmpty || cfi.isEmpty) {
      AnxToast.show('无法读取选区位置');
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final difficulty = ReadingDifficulty(
      id: '${_book.id}-$now',
      bookId: _book.id,
      cfi: cfi,
      text: text,
      chapterHref: snapshot.chapterHref,
      chapterTitle: snapshot.chapterTitle,
      context: snapshot.surroundingText,
      createdAt: now,
      updatedAt: now,
    );
    await _ensureReadingSession();
    final mutation = await agentActionService.saveDifficulty(difficulty,
        sourceProgress: snapshot.progress,
        visibleFromProgress: snapshot.progress);
    final saved = mutation.value;
    epubPlayerKey.currentState?.addDifficultyAnnotation(
      id: saved.id,
      cfi: saved.cfi,
    );
    AnxToast.show(saved.id == difficulty.id ? '已暂存难点' : '该难点已存在');
  }

  Future<void> _restoreAiReadingContext(AiChatHistoryEntry entry) async {
    if (entry.bookId != _book.id) return;
    final cfi = entry.contextSnapshot?['metadata'] is Map
        ? (entry.contextSnapshot!['metadata'] as Map)['cfi']?.toString()
        : null;
    if (cfi != null && cfi.isNotEmpty) {
      _navigateBookSource(cfi);
    } else if (entry.chapterHref?.isNotEmpty == true) {
      _navigateBookSource(entry.chapterHref!);
    }
  }

  Future<void> _finishChapterCheckpoint(
    ReadingChapterCheckpoint checkpoint,
  ) async {
    final closure = _closurePolicy;
    var reflectionText = '';
    MasteryLevel level = MasteryLevel.familiar;
    var createKnowledgeCard = closure.defaultCreateKnowledgeCard;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            '${closure.checkpointAction} · ${checkpoint.chapterTitle}',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (closure.checkpoint.showsMastery)
                DropdownButtonFormField<MasteryLevel>(
                  initialValue: level,
                  decoration: InputDecoration(
                    labelText: closure.checkpoint.masteryLabel,
                  ),
                  items: [
                    for (final option in closure.checkpoint.masteryOptions)
                      DropdownMenuItem(
                        value: option.level,
                        child: Text(option.label),
                      ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => level = value ?? level),
                ),
              TextField(
                onChanged: (value) => reflectionText = value,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: closure.checkpoint.reflectionLabel,
                  helperText: closure.checkpoint.reflectionHelperText,
                ),
              ),
              if (closure.showKnowledgeCards)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: createKnowledgeCard,
                  title: const Text('生成一张明日复习卡'),
                  subtitle: const Text('默认关闭；只有勾选后才创建'),
                  onChanged: (value) => setDialogState(
                    () => createKnowledgeCard = value ?? false,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('稍后'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('完成${closure.checkpointAction}'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await _ensureReadingSession();
      final mutation = await agentActionService.finishChapterCheckpoint(
        checkpoint: checkpoint,
        reflection: reflectionText,
        masteryLevel: closure.checkpoint.showsMastery ? level : null,
        createKnowledgeCard: createKnowledgeCard,
        saveMemory: closure.checkpoint.saveReflectionAsMemory,
        memoryTitle:
            '${checkpoint.chapterTitle} · ${closure.checkpoint.memoryTitleSuffix}',
      );
      if (mounted) _showAgentUndoSnackBar(mutation.action);
    } catch (_) {
      if (mounted) AnxToast.show(L10n.of(context).readingAssistantSaveFailed);
    }
  }

  Future<void> _reviewKnowledgeCard(KnowledgeCard card, bool remembered) async {
    try {
      await _ensureReadingSession();
      final mutation = await agentActionService.reviewKnowledgeCard(
        card,
        remembered: remembered,
      );
      if (mounted) _showAgentUndoSnackBar(mutation.action);
    } catch (_) {
      if (mounted) AnxToast.show(L10n.of(context).readingAssistantSaveFailed);
    }
  }

  Future<void> _createMarkdownMemory() async {
    final title = TextEditingController();
    final body = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新建 Markdown 记忆'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                maxLength: 80,
                decoration: const InputDecoration(labelText: '标题'),
              ),
              TextField(
                controller: body,
                minLines: 4,
                maxLines: 10,
                decoration: const InputDecoration(labelText: 'Markdown 内容'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (save != true || title.text.trim().isEmpty || body.text.trim().isEmpty) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await agentActionService.appendMemory(
      ReadingMemoryDocument(
        id: '${_book.id}-$now',
        bookId: _book.id,
        title: title.text.trim(),
        markdown: body.text.trim(),
        sourceRefs: [
          if (readingAgentRuntime.state.chapterHref case final href?) href,
        ],
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _showCharacterRecall() async {
    final name = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('这个人物是谁？'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: '人物名或称谓'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('查找'),
          ),
        ],
      ),
    );
    final query = name.text.trim();
    if (confirmed != true || query.isEmpty || !mounted) return;
    final recall = await fictionReadingService.recallCharacter(
      bookId: _book.id,
      query: query,
      currentProgress: readingAgentRuntime.state.totalProgress,
    );
    if (!mounted) return;
    if (recall == null) {
      final useAi = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('尚未保存这个人物'),
          content: const Text('可以让 AI 仅根据当前位置以前的内容查找；保存人物档案仍需要你确认。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('稍后'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('询问 AI'),
            ),
          ],
        ),
      );
      if (useAi == true) {
        await showAiChat(
          content:
              '“$query”是谁？只使用我当前阅读位置以前的信息，说明身份、称谓、关系和最近一次出现；区分文本事实与推测，禁止剧透。',
          sendImmediate: true,
        );
      }
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(recall.name),
        content: Text(
          [
            recall.summary,
            if (recall.aliases.isNotEmpty) '称谓：${recall.aliases.join('、')}',
            if (recall.relationships.isNotEmpty)
              '关系：${recall.relationships.join('、')}',
            recall.epistemicStatus ==
                    ReadingArtifactEpistemicStatus.agentInference
                ? '标记：AI 推测'
                : '标记：文本事实',
          ].where((item) => item.isNotEmpty).join('\n\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
          if (recall.source.sourceStartCfi case final cfi?)
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(dialogContext);
                ReaderCommandGateway.instance.navigateToCfi(
                  bookId: _book.id,
                  cfi: cfi,
                );
              },
              child: const Text('返回来源'),
            ),
        ],
      ),
    );
  }

  Future<void> _createFictionArtifact(String kind) async {
    final primary = TextEditingController();
    final detail = TextEditingController();
    final isCharacter = kind == ReadingArtifactKinds.character;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isCharacter ? '保存人物档案' : '记录未解悬念'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: primary,
              autofocus: true,
              decoration: InputDecoration(
                labelText: isCharacter ? '人物名' : '悬念或问题',
              ),
            ),
            TextField(
              controller: detail,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: isCharacter ? '当前已知身份与关系' : '当前猜测（可选）',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    final title = primary.text.trim();
    if (confirmed != true || title.isEmpty) return;
    final state = readingAgentRuntime.state;
    if ((state.cfi?.isEmpty ?? true) && (state.chapterHref?.isEmpty ?? true)) {
      AnxToast.show('当前位置尚未稳定，请翻页后重试');
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await agentActionService.saveArtifact(
      ReadingArtifact(
        id: '${_book.id}-$now-$kind',
        bookId: _book.id,
        moduleId: ReadingClosureIds.fictionImmersion,
        kind: kind,
        payload: isCharacter
            ? {'name': title, 'summary': detail.text.trim()}
            : {'question': title, 'currentTheory': detail.text.trim()},
        epistemicStatus: ReadingArtifactEpistemicStatus.userReflection,
        sourceStartCfi: state.cfi,
        chapterHref: state.chapterHref,
        chapterTitle: state.chapterTitle,
        discoveredAtCfi: state.cfi,
        sourceProgress: state.totalProgress,
        visibleFromProgress: state.totalProgress,
        ingestedAt: now,
        createdBy: 'user',
        createdAt: now,
        updatedAt: now,
      ),
    );
    AnxToast.show(isCharacter ? '人物档案已保存，可撤销' : '悬念已加入账本，可撤销');
  }

  Future<void> _showFictionResumeContext() async {
    final resume = await fictionReadingService.resumeContext(
      bookId: _book.id,
      currentProgress: readingAgentRuntime.state.totalProgress,
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('恢复阅读上下文'),
        content: resume.isEmpty
            ? const Text('还没有可恢复的故事档案。阅读时可按需保存人物和未解悬念。')
            : Text(
                [
                  if (resume.lastScene?.isNotEmpty == true)
                    '上次场景：${resume.lastScene}',
                  if (resume.activeCharacters.isNotEmpty)
                    '近期人物：${resume.activeCharacters.join('、')}',
                  if (resume.openMysteries.isNotEmpty)
                    '未解悬念：${resume.openMysteries.map((item) => item.payload['question']).join('；')}',
                ].join('\n\n'),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('继续阅读'),
          ),
        ],
      ),
    );
  }

  Future<List<FictionBackfillChapter>> _eligibleBackfillChapters(
    double boundary, {
    double fromProgress = 0,
  }) async {
    final result = <FictionBackfillChapter>[];
    void addItems(List<TocItem> items, [int depth = 0]) {
      for (final item in items) {
        if (item.href.isNotEmpty &&
            !ReadingStructureParser.isNonStoryTitle(item.label.trim())) {
          result.add(
            FictionBackfillChapter(
              href: item.href,
              title: item.label,
              startProgress: item.startPercentage,
              tocDepth: depth,
              hasChildren: item.subitems.isNotEmpty,
            ),
          );
        }
        addItems(item.subitems, depth + 1);
      }
    }

    addItems(ref.read(bookTocProvider));
    // EPUB2 collections sometimes publish only one NCX entry per volume. On
    // explicit archive organization, recover the local spine headings so AI
    // receives real chapters rather than an HTML table of contents.
    if (result.length < 6) {
      final manifest =
          await epubPlayerKey.currentState?.readingAgentChapterManifest() ??
              const <ReadingAgentChapterManifestItem>[];
      if (manifest.length > result.length) {
        result
          ..clear()
          ..addAll([
            for (final item in manifest)
              if (!ReadingStructureParser.isNonStoryTitle(item.title))
                FictionBackfillChapter(
                  href: item.href,
                  title: item.title,
                  startProgress: item.startPercentage,
                  hasChildren: item.isNavigation,
                  isNavigationDocument: item.isNavigation,
                ),
          ]);
      }
    }
    final byHref = <String, FictionBackfillChapter>{};
    for (final chapter in result) {
      byHref.putIfAbsent(chapter.href.split('#').first, () => chapter);
    }
    final unique = byHref.values.toList()
      ..sort((a, b) => a.startProgress.compareTo(b.startProgress));
    final structure = const ReadingStructureParser().parse([
      for (final chapter in unique)
        ReadingStructureChapter(
          href: chapter.href,
          title: chapter.title,
          startProgress: chapter.startProgress,
          tocDepth: chapter.tocDepth,
          hasChildren: chapter.hasChildren,
        ),
    ]);
    final unitsByHref = {
      for (final unit in structure.units) unit.chapter.href: unit,
    };
    return [
      for (var index = 0; index < unique.length; index++)
        FictionBackfillChapter(
          href: unique[index].href,
          title: unique[index].title,
          startProgress: unique[index].startProgress,
          // The current partial chapter is excluded because fetching its full
          // text could cross the safe boundary.
          endProgress:
              index + 1 < unique.length ? unique[index + 1].startProgress : 1,
          workId: unitsByHref[unique[index].href]?.workId,
          workTitle: unitsByHref[unique[index].href]?.workTitle,
          volumeId: unitsByHref[unique[index].href]?.volumeId,
          arcId: unitsByHref[unique[index].href]?.arcId,
          sceneId: unitsByHref[unique[index].href]?.sceneId,
          semanticKind: unitsByHref[unique[index].href]?.semanticKind ??
              ReadingChapterSemanticKind.narrative,
          isNavigationDocument: unique[index].isNavigationDocument,
        ),
    ]
        .where(
          (chapter) =>
              !chapter.isNavigationDocument &&
              chapter.startProgress >= fromProgress - .000001 &&
              chapter.endProgress! <= boundary + .000001,
        )
        .toList(growable: false);
  }

  Future<void> _showCoverageSetup() async {
    final coverage = _readingCoverage;
    if (coverage == null) return;
    final percent = (coverage.initializedAtProgress * 100).round();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '建立小说前情档案',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('你从本书 $percent% 开始使用阅读 Agent。默认从这里开始，不会读取或推测前文。'),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.play_arrow_outlined),
                title: const Text('从这里开始'),
                subtitle: const Text('不处理前文，此后逐步记录人物、关系和悬念'),
                onTap: () async {
                  final updated = await readingCoverageService.startFromHere(
                    coverage,
                  );
                  Prefs().setLocalReadingBackfillStart(
                    _book.id,
                    coverage.initializedAtProgress,
                  );
                  if (!mounted) return;
                  setState(() => _readingCoverage = updated);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_stories_outlined),
                title: const Text('整理已读部分'),
                subtitle: Text('确认后读取 0%～$percent% 内已完整读完的章节并调用 AI，不读取后文'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _confirmAndBackfill(coverage, fromProgressOverride: 0);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('导入已有成果'),
                subtitle: const Text('从笔记、批注、同步 Artifact 和 Markdown 记忆恢复'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _confirmAndImport(coverage);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndBackfill(
    BookReadingCoverage coverage, {
    double? fromProgressOverride,
  }) async {
    final worldState = readingAgentRuntime.state;
    final currentProgress =
        worldState.bookId == _book.id && worldState.totalProgress > 0
            ? worldState.totalProgress.clamp(0, 1).toDouble()
            : _book.readingPercentage.clamp(0, 1).toDouble();
    // This lower bound is installation-local. Synced Artifact coverage and a
    // remote device's farthest position must not silently redefine what this
    // device may scan. No local opt-out means the manual action starts at 0%.
    final fromProgress =
        (fromProgressOverride ?? Prefs().localReadingBackfillStart(_book.id))
            .clamp(0, currentProgress)
            .toDouble();
    final chapters = await _eligibleBackfillChapters(
      currentProgress,
      fromProgress: fromProgress,
    );
    if (!mounted) return;
    final cloudProvider = fictionBackfillService.previewProvider(ref);
    final hybrid = FictionHybridExtractionService(
        ref: ref, verificationProviderId: cloudProvider?.id);
    final extractionProvider = hybrid.provider;
    final destination = extractionProvider ?? cloudProvider;
    if (destination == null) {
      AnxToast.show(L10n.of(context).readingPracticeProviderUnavailable);
      return;
    }
    final estimate =
        fictionBackfillService.estimateCloudPreview(chapters.length);
    final verificationDisclosure = extractionProvider != null &&
            cloudProvider != null
        ? '\n${L10n.of(context).readingMaterialsVerifierDestination(_materialsDestination(cloudProvider))}'
        : '';
    final percent = (currentProgress * 100).round();
    final fromPercent = (fromProgress * 100).round();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认整理已读部分'),
        content: Text(
          '将读取 $fromPercent%～$percent% 内已完整读完的 ${chapters.length} 个目录章节并调用 AI 建立人物、关系和悬念档案。为避免越过边界，当前尚未读完的章节不会读取。\n\n生成内容属于 Agent 推断，可在动作记录中撤销。\n\n${_materialsDestination(destination)}$verificationDisclosure\n${L10n.of(context).readingMaterialsEstimate('${estimate.baselineInputTokens}')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认并整理'),
          ),
        ],
      ),
    );
    if (confirmed != true || chapters.isEmpty) return;
    if (!mounted) return;
    var allowFullTextCloudFallback = false;
    final cloudPreviewContent = <String, String>{};
    if (extractionProvider == null) {
      final estimate = fictionBackfillService.estimateCloudPreview(
        chapters.length,
      );
      allowFullTextCloudFallback = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('轻量提取引擎不可用'),
              content: Text(
                '${_materialsDestination(cloudProvider!)}\n\n'
                '当前没有可用的本地/小模型提取引擎。\n\n'
                '如果继续，将把 $fromPercent%～$percent% 的 ${chapters.length} 个已读章节发送给通用线上模型。'
                '按当前分批计划预计输入约 ${estimate.baselineInputTokens} Token（${estimate.requestCount} 批）；'
                '若结构化响应失败并触发一次拆批重试，最多约 ${estimate.retryUpperBoundInputTokens} Token。',
              ),
              actions: [
                FilledButton.tonal(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消／稍后处理'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('确认使用线上模型'),
                ),
              ],
            ),
          ) ??
          false;
      if (!allowFullTextCloudFallback) return;
    }
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final sessionId = readingAgentRuntime.state.sessionId;
      if (sessionId == null) throw StateError('阅读会话尚未开始');
      final existingArtifacts = await readingAgentRepository.artifacts(
        _book.id,
      );
      await readingTaskScheduler.restore();
      final restoredTask = readingTaskScheduler.tasks
          .where(
            (task) =>
                task.type == 'fiction.backfill' &&
                task.bookId == _book.id &&
                task.status == ReadingTaskStatus.paused,
          )
          .firstOrNull;
      final effectiveFromProgress = restoredTask == null
          ? fromProgress
          : ((restoredTask.payload['fromProgress'] as num?)?.toDouble() ??
                  fromProgress)
              .clamp(0, currentProgress)
              .toDouble();
      final effectiveSafeBoundary = restoredTask == null
          ? currentProgress
          : ((restoredTask.payload['safeBoundary'] as num?)?.toDouble() ??
                  currentProgress)
              .clamp(effectiveFromProgress, currentProgress)
              .toDouble();
      final effectiveChapters = await _eligibleBackfillChapters(
        effectiveSafeBoundary,
        fromProgress: effectiveFromProgress,
      );

      Future<List<ReadingArtifact>> executeBackfill(
        ReadingTaskExecutionContext execution,
      ) async {
        final useHybrid = extractionProvider != null;
        return fictionBackfillService.build(
          bookId: _book.id,
          moduleId: ReadingClosureIds.fictionImmersion,
          safeBoundary: effectiveSafeBoundary,
          chapters: effectiveChapters,
          loadChapter: (href) => cloudPreviewContent[href] != null
              ? Future.value(cloudPreviewContent[href]!)
              : epubPlayerKey.currentState?.chapterContentByHref(href) ??
                  Future.value(''),
          generate: useHybrid ? hybrid.generate : null,
          sessionId: sessionId,
          taskId: execution.taskId,
          providerId: cloudProvider?.id,
          ref: ref,
          ingestedAt: now,
          fromProgress: effectiveFromProgress,
          batchSize: useHybrid ? 1 : 5,
          concurrency: 1,
          maxInputCharacters: useHybrid ? 12000 : 30000,
          // Both extraction routes require exact source evidence. The hybrid
          // route may additionally send only ambiguous short evidence to the
          // cloud verifier; the regular cloud route never accepts ambiguity.
          validateCandidate:
              useHybrid ? hybrid.validate : hybrid.validateDirect,
          artifactMetadata: useHybrid ? hybrid.artifactMetadata : const {},
          onBatchCompleted: ({
            required artifacts,
            required checkpoints,
            required completedChapters,
            required totalChapters,
          }) async {
            execution.safePoint();
            for (final artifact in artifacts) {
              await agentActionService.saveArtifact(artifact);
            }
            for (final checkpoint in checkpoints) {
              await readingAgentRepository.saveSystemArtifact(checkpoint);
            }
            await execution.update(
              progress:
                  totalChapters == 0 ? 1 : completedChapters / totalChapters,
              checkpoint: {'completedChapters': completedChapters},
            );
          },
          existingArtifacts: existingArtifacts,
        );
      }

      final artifacts = restoredTask != null
          ? await readingTaskScheduler.resumeWith<List<ReadingArtifact>>(
              restoredTask.id,
              executeBackfill,
            )
          : await readingTaskScheduler.submit<List<ReadingArtifact>>(
              ReadingTask(
                id: 'fiction-backfill-${_book.id}-$sessionId',
                type: 'fiction.backfill',
                bookId: _book.id,
                priority: ReadingTaskPriority.userInitiated,
                persistence: ReadingTaskPersistence.durable,
                status: ReadingTaskStatus.queued,
                payload: {
                  'fromProgress': fromProgress,
                  'safeBoundary': currentProgress,
                  'chapterCount': chapters.length,
                },
                createdAt: now,
                updatedAt: now,
              ),
              executeBackfill,
            );
      final updated = await readingCoverageService.markBackfilled(
        coverage,
        throughProgress: effectiveSafeBoundary,
      );
      if (mounted) {
        setState(() => _readingCoverage = updated);
        AnxToast.show('已建立 ${artifacts.length} 条前情档案');
      }
    } catch (error) {
      if (mounted) AnxToast.show('整理失败：$error');
    }
  }

  Future<void> _confirmAndImport(BookReadingCoverage coverage) async {
    final notes = await bookNoteDao.selectBookNotesByBookId(_book.id);
    final memories = await readingAgentRepository.memoryDocuments(_book.id);
    final existing = await readingAgentRepository.artifacts(_book.id);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入已有成果'),
        content: Text(
          '找到 ${notes.length} 条笔记/批注、${memories.length} 份 Markdown 记忆、${existing.length} 条已有 Artifact。\n\n本次只恢复这些已存在的成果，不调用 AI，也不把高亮自动解释成人物事实。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final importedText = [
      for (final note in notes)
        if (note.readerNote?.trim().isNotEmpty == true)
          '${note.chapter}：${note.readerNote!.trim()}',
      for (final memory in memories)
        '${memory.title}：${memory.markdown.trim()}',
    ].join('\n');
    if (importedText.isNotEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final snapshot = importedText.length > 2000
          ? importedText.substring(0, 2000)
          : importedText;
      await agentActionService.saveArtifact(
        ReadingArtifact(
          id: '${_book.id}-imported-context-$now',
          bookId: _book.id,
          moduleId: ReadingClosureIds.fictionImmersion,
          kind: ReadingArtifactKinds.resumeContext,
          payload: {
            'summary': snapshot,
            'noteCount': notes.length,
            'memoryCount': memories.length,
          },
          epistemicStatus: ReadingArtifactEpistemicStatus.userReflection,
          sourceTextSnapshot: snapshot,
          chapterHref: readingAgentRuntime.state.chapterHref,
          chapterTitle: readingAgentRuntime.state.chapterTitle,
          sourceProgress: coverage.initializedAtProgress,
          visibleFromProgress: coverage.initializedAtProgress,
          ingestedAt: now,
          ingestionMode: ReadingArtifactIngestionMode.imported,
          createdBy: 'user',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    final progressValues = existing.map((item) => item.sourceProgress).toList();
    final start = progressValues.isEmpty
        ? coverage.initializedAtProgress
        : progressValues.reduce(math.min);
    final end = progressValues.isEmpty
        ? coverage.initializedAtProgress
        : progressValues.reduce(math.max);
    final updated = await readingCoverageService.markImported(
      coverage,
      coverageStart: start,
      coverageEnd: end,
    );
    if (!mounted) return;
    setState(() => _readingCoverage = updated);
    AnxToast.show('已有成果已纳入本书档案');
  }

  Future<void> _showReadingAgentPanel() async {
    final goalTitleController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final state = readingAgentRuntime.state;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                16 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '阅读 Agent',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '阅读 Agent 使用方法',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ReadingAgentHelpPage(),
                            ),
                          ),
                          icon: const Icon(Icons.help_outline),
                        ),
                        TextButton(
                          onPressed: () {
                            _readingAgentCapsuleDismissed = true;
                            Navigator.pop(sheetContext);
                            setState(() {});
                          },
                          child: const Text('本次会话隐藏'),
                        ),
                      ],
                    ),
                    const Text('所有阅读事件均在本地处理；只有你主动使用 AI 时才调用模型。'),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.all_inclusive),
                      title: Text(_closurePolicy.title),
                      subtitle: Text(
                        '${_readingProfile?.pinned == true ? '本书固定' : '自动匹配'} · ${_closurePolicy.description}',
                      ),
                      trailing: PopupMenuButton<String>(
                        tooltip: '切换本书阅读闭环',
                        onSelected: (value) async {
                          await _setClosureModule(
                            value == 'auto' ? null : value,
                          );
                          setSheetState(() {});
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'auto',
                            child: Text('自动匹配'),
                          ),
                          for (final closure
                              in widget.closureRegistry.definitions)
                            PopupMenuItem(
                              value: closure.id,
                              child: Text(closure.title),
                            ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _showReadingOutcomes();
                        },
                        icon: const Icon(Icons.auto_graph_outlined),
                        label: const Text('查看完整阅读成果'),
                      ),
                    ),
                    if (_closurePolicy.supports(
                      ReadingClosureCapability.readingArtifacts,
                    )) ...[
                      const SizedBox(height: 8),
                      Card.filled(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '小说辅助 · 严格按当前位置防剧透',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.person_search,
                                      size: 18,
                                    ),
                                    label: const Text('这个人物是谁'),
                                    onPressed: _showCharacterRecall,
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.history, size: 18),
                                    label: const Text('恢复上下文'),
                                    onPressed: _showFictionResumeContext,
                                  ),
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.person_add_alt,
                                      size: 18,
                                    ),
                                    label: const Text('保存人物'),
                                    onPressed: () => _createFictionArtifact(
                                      ReadingArtifactKinds.character,
                                    ),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.help_outline,
                                      size: 18,
                                    ),
                                    label: const Text('记录悬念'),
                                    onPressed: () => _createFictionArtifact(
                                      ReadingArtifactKinds.mystery,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (state.activeGoal case final goal?) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.flag_outlined),
                        title: Text(goal.title),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: goal.progress,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${(goal.progress * 100).round()}%'),
                          ],
                        ),
                        trailing: PopupMenuButton<ReadingGoalStatus>(
                          tooltip: '更新目标状态',
                          onSelected: (status) async {
                            await agentActionService.saveGoal(
                              goal.copyWith(
                                status: status,
                                progress: status == ReadingGoalStatus.completed
                                    ? 1
                                    : goal.progress,
                                updatedAt:
                                    DateTime.now().millisecondsSinceEpoch,
                              ),
                            );
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: ReadingGoalStatus.completed,
                              child: Text('标记完成'),
                            ),
                            PopupMenuItem(
                              value: ReadingGoalStatus.abandoned,
                              child: Text('放弃目标'),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text('创建${_closurePolicy.goalLabel}'),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final template
                              in _closurePolicy.goalTemplateSpecs)
                            ActionChip(
                              label: Text(template.title),
                              onPressed: () {
                                goalTitleController.text = template.title;
                                setSheetState(() {});
                              },
                            ),
                        ],
                      ),
                      TextField(
                        controller: goalTitleController,
                        maxLength: 80,
                        decoration: const InputDecoration(
                          labelText: '目标描述',
                          helperText: '先预览，确认后才保存',
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () async {
                            final title = goalTitleController.text.trim();
                            if (title.isEmpty) return;
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('确认阅读目标'),
                                content: Text(title),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('取消'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('保存'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            final now = DateTime.now().millisecondsSinceEpoch;
                            final goal = ReadingGoal(
                              id: '${_book.id}-$now',
                              bookId: _book.id,
                              title: title,
                              range: {
                                'startCfi': readingAgentRuntime.state.cfi,
                                'chapterHref':
                                    readingAgentRuntime.state.chapterHref,
                                'closureId': _closurePolicy.id,
                              },
                              criteria: const [],
                              createdAt: now,
                              updatedAt: now,
                            );
                            await agentActionService.saveGoal(goal);
                            if (!sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('预览并保存'),
                        ),
                      ),
                    ],
                    if (state.pendingCheckpointCount > 0) ...[
                      const Divider(height: 32),
                      Text(
                        _closurePolicy.checkpointTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      FutureBuilder<List<ReadingChapterCheckpoint>>(
                        future: _loadBookMaterials().then((result) =>
                            result.$2.outcomes?.pendingCheckpoints ?? const []),
                        builder: (context, snapshot) => Column(
                          children: [
                            for (final checkpoint
                                in (snapshot.connectionState ==
                                            ConnectionState.done
                                        ? snapshot.data ?? const []
                                        : const <ReadingChapterCheckpoint>[])
                                    .take(3))
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.fact_check_outlined),
                                title: Text(
                                  checkpoint.chapterTitle.isEmpty
                                      ? checkpoint.chapterHref
                                      : checkpoint.chapterTitle,
                                ),
                                subtitle: Text(
                                  '${(checkpoint.progress * 100).round()}% · 点击后再开始${_closurePolicy.checkpointAction}',
                                ),
                                trailing: FilledButton.tonal(
                                  onPressed: () async {
                                    await _finishChapterCheckpoint(checkpoint);
                                    setSheetState(() {});
                                  },
                                  child: Text(_closurePolicy.checkpointAction),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (state.unresolvedDifficultyCount > 0) ...[
                      const Divider(height: 32),
                      Text(
                        _closurePolicy.difficultyTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      FutureBuilder<ReadingCoachState>(
                        future: ref.read(readingCoachProvider(_book.id).future),
                        builder: (context, snapshot) {
                          final items =
                              (snapshot.connectionState == ConnectionState.done
                                      ? snapshot.data?.difficulties ??
                                          const <ReadingDifficulty>[]
                                      : const <ReadingDifficulty>[])
                                  .where(
                                    (item) =>
                                        item.status ==
                                        ReadingDifficultyStatus.unresolved,
                                  )
                                  .take(5);
                          return Column(
                            children: [
                              for (final item in items)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.help_outline),
                                  title: Text(
                                    item.text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(item.chapterTitle ?? '未知章节'),
                                  onTap: () => ReaderCommandGateway.instance
                                      .navigateToCfi(
                                    bookId: _book.id,
                                    cfi: item.cfi,
                                  ),
                                  trailing: IconButton(
                                    tooltip: '标记已解决',
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                    ),
                                    onPressed: () async {
                                      await ref
                                          .read(
                                            readingCoachProvider(
                                              _book.id,
                                            ).notifier,
                                          )
                                          .updateDifficulty(
                                            item.copyWith(
                                              status: ReadingDifficultyStatus
                                                  .resolved,
                                              updatedAt: DateTime.now()
                                                  .millisecondsSinceEpoch,
                                            ),
                                          );
                                      readingAgentRuntime.difficultyResolved();
                                      setSheetState(() {});
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                    if (_closurePolicy.showKnowledgeCards &&
                        state.dueKnowledgeCardCount > 0) ...[
                      const Divider(height: 32),
                      const Text(
                        '到期知识卡片',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      FutureBuilder<List<KnowledgeCard>>(
                        future: _loadBookMaterials().then((result) =>
                            result.$2.outcomes?.knowledgeCards ?? const []),
                        builder: (context, snapshot) => Column(
                          children: [
                            for (final card in (snapshot.connectionState ==
                                        ConnectionState.done
                                    ? snapshot.data ?? const []
                                    : const <KnowledgeCard>[])
                                .take(
                              3,
                            ))
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.style_outlined),
                                title: Text(card.front),
                                subtitle: Text(
                                  card.back,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: '再学习',
                                      icon: const Icon(Icons.refresh),
                                      onPressed: () async {
                                        await _reviewKnowledgeCard(card, false);
                                        setSheetState(() {});
                                      },
                                    ),
                                    IconButton(
                                      tooltip: '记住了',
                                      icon: const Icon(Icons.check),
                                      onPressed: () async {
                                        await _reviewKnowledgeCard(card, true);
                                        setSheetState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _closurePolicy.memoryTitle,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await _createMarkdownMemory();
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('新建'),
                        ),
                      ],
                    ),
                    FutureBuilder<List<ReadingMemoryDocument>>(
                      future: _loadBookMaterials().then(
                          (result) => result.$2.outcomes?.memories ?? const []),
                      builder: (context, snapshot) => Column(children: [
                        if (snapshot.connectionState == ConnectionState.done)
                          for (final memory in snapshot.data ??
                              const <ReadingMemoryDocument>[])
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.description_outlined),
                              title: Text(memory.title),
                            ),
                      ]),
                    ),
                    if (state.pendingProfileCount > 0) ...[
                      const Divider(height: 32),
                      const Text(
                        '待确认的阅读偏好',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      FutureBuilder<List<ReaderProfileItem>>(
                        future: readingAgentRepository.profileCandidates(),
                        builder: (context, snapshot) {
                          final candidates = (snapshot.data ?? const [])
                              .where(
                                (item) =>
                                    item.evidenceCount >= 3 ||
                                    item.confidence >= 1,
                              )
                              .toList(growable: false);
                          return Column(
                            children: [
                              for (final item in candidates)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.key),
                                  subtitle: Text(item.value.toString()),
                                  trailing: Wrap(
                                    children: [
                                      IconButton(
                                        tooltip: '拒绝，90 天内不再建议',
                                        onPressed: () async {
                                          await agentActionService
                                              .setProfileStatus(
                                            key: item.key,
                                            status:
                                                ReaderProfileStatus.rejected,
                                          );
                                          readingAgentRuntime
                                              .profileCandidateResolved();
                                          setSheetState(() {});
                                        },
                                        icon: const Icon(Icons.close),
                                      ),
                                      IconButton(
                                        tooltip: '确认偏好',
                                        onPressed: () async {
                                          await agentActionService
                                              .setProfileStatus(
                                            key: item.key,
                                            status:
                                                ReaderProfileStatus.confirmed,
                                          );
                                          readingAgentRuntime
                                              .profileCandidateResolved();
                                          setSheetState(() {});
                                        },
                                        icon: const Icon(Icons.check),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                    const Divider(height: 32),
                    const Text(
                      '最近 30 天动作',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    FutureBuilder<List<AgentAction>>(
                      future: readingAgentRepository.recentActions(
                        bookId: _book.id,
                      ),
                      builder: (context, snapshot) {
                        final actions = snapshot.data ?? const [];
                        if (actions.isEmpty) {
                          return const ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('暂无动作'),
                          );
                        }
                        return Column(
                          children: [
                            for (final action in actions)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.history),
                                title: Text(_agentActionLabel(action.type)),
                                subtitle: Text(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    action.createdAt,
                                  ).toLocal().toString(),
                                ),
                                trailing:
                                    action.status == AgentActionStatus.applied
                                        ? TextButton(
                                            onPressed: () async {
                                              final result =
                                                  await agentActionService.undo(
                                                action,
                                              );
                                              if (!context.mounted) return;
                                              AnxToast.show(
                                                _undoResultLabel(result),
                                              );
                                              setSheetState(() {});
                                            },
                                            child: const Text('撤销'),
                                          )
                                        : Text(action.status.name),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    goalTitleController.dispose();
  }

  Future<void> _showReadingOutcomes() async {
    await _ensureReadingSession();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingOutcomesPage(
          book: _book,
          coverage: _readingCoverage,
          visibleProgress: readingAgentRuntime.state.totalProgress > 0
              ? readingAgentRuntime.state.totalProgress
              : _book.readingPercentage,
          onOrganizeStoryArchive: () async {
            Navigator.of(context).pop();
            final coverage = _readingCoverage;
            if (coverage != null) await _confirmAndBackfill(coverage);
          },
          onOpenLocation: (target) async {
            if (!mounted) return;
            Navigator.of(context).pop();
            if (target.startsWith('epubcfi(')) {
              ReaderCommandGateway.instance.navigateToCfi(
                bookId: _book.id,
                cfi: target,
              );
            } else {
              ReaderCommandGateway.instance.navigateToHref(
                bookId: _book.id,
                href: target,
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _showBookHub() async {
    showOrHideAppBarAndBottomBar(false);
    _bookMaterials = _loadBookMaterials();
    aiWorkspaceController.showSurface(
      AiWorkspaceSurface.book,
      wide: _usesAiSplitLayout(context),
    );
  }

  Future<(ReadingOutcomesSnapshot, BookMaterialsSnapshot)>
      _loadBookMaterials() async {
    final progress = _visibleReadingProgress;
    final cfi = epubPlayerKey.currentState?.cfi;
    final state = await readingOutcomesService.load(_book.id);
    final materials = await bookWikiService.loadMaterials(
      _book.id,
      visibleAtProgress: progress,
      closure: _closurePolicy,
      outcomes: state,
      currentCfi: cfi,
    );
    return (
      materials.outcomes ?? ReadingOutcomesSnapshot(loadedAt: state.loadedAt),
      materials
    );
  }

  void _navigateBookSource(String target) {
    final gateway = ReaderCommandGateway.instance;
    final navigated = target.startsWith('epubcfi(')
        ? gateway.navigateToCfi(bookId: _book.id, cfi: target)
        : gateway.navigateToHref(bookId: _book.id, href: target);
    if (!navigated) {
      AnxToast.show(L10n.of(context).readingWorkspaceSourceUnavailable);
    }
    if (mounted) setState(() {});
  }

  Future<void> _openBookMaterial(BookMaterialItem requested) async {
    // Recheck after a location change; an old list cannot widen visibility.
    final (_, materials) = await _loadBookMaterials();
    if (!mounted ||
        materials.visibleAtProgress > _visibleReadingProgress + .000001) {
      return;
    }
    final item =
        materials.items.where((entry) => entry.id == requested.id).firstOrNull;
    if (!mounted || item == null) return;
    final entry = item.wikiEntry;
    final note = item.noteItem;
    if (entry != null) {
      await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => BookWikiEntryPage(
                book: _book,
                entry: entry,
                onOpenLocation: (target) async {
                  Navigator.pop(context);
                  _navigateBookSource(target);
                }),
          ));
    } else if (note != null) {
      await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(item.title), actions: [
                      if (item.location?.isNotEmpty == true)
                        IconButton(
                          tooltip: L10n.of(context).readingMemoryViewSources,
                          icon: const Icon(Icons.menu_book_outlined),
                          onPressed: () {
                            Navigator.pop(context);
                            _navigateBookSource(item.location!);
                          },
                        ),
                    ]),
                    body: SafeArea(child: ReadingNoteDetail(item: note)),
                  )));
    } else if (item.difficulty != null) {
      final difficulty = item.difficulty!;
      // A saved question is a reader record, never an exact book quotation.
      // Keep its original locator and avoid manufacturing new source evidence.
      final l10n = L10n.of(context);
      await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                    appBar: AppBar(
                        title: Text(l10n.readingCompanionRecords),
                        actions: [
                          IconButton(
                              tooltip: l10n.readingMemoryViewSources,
                              icon: const Icon(Icons.menu_book_outlined),
                              onPressed: () {
                                Navigator.pop(context);
                                _navigateBookSource(difficulty.cfi);
                              }),
                        ]),
                    body:
                        ListView(padding: const EdgeInsets.all(24), children: [
                      Text(difficulty.text,
                          style: Theme.of(context).textTheme.titleLarge),
                      if (difficulty.chapterTitle?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(difficulty.chapterTitle!),
                      ],
                      if (difficulty.context?.isNotEmpty == true) ...[
                        const SizedBox(height: 24),
                        Text(l10n.readingCompanionSavedContext,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        SelectableText(difficulty.context!),
                      ],
                      if (difficulty.note?.isNotEmpty == true) ...[
                        const SizedBox(height: 24),
                        Text(l10n.readingCompanionSavedAnswer,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        SelectableText(difficulty.note!),
                      ],
                      const SizedBox(height: 24),
                      OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            unawaited(showReadingCoach());
                          },
                          child: Text(l10n.readingCompanionExercises)),
                    ]),
                  )));
    }
    if (mounted) setState(() => _bookMaterials = _loadBookMaterials());
  }

  Future<void> _showBookSettings() async {
    final l10n = L10n.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: !MediaQuery.disableAnimationsOf(context),
      builder: (sheetContext) => SafeArea(
          child: ListView(shrinkWrap: true, children: [
        ListTile(
            title: Text(l10n.readingWorkspaceSettings,
                style: Theme.of(context).textTheme.titleLarge)),
        ListTile(
            leading: const Icon(Icons.memory_outlined),
            title: Text(l10n.readingWorkspaceContext),
            onTap: () => Navigator.pop(sheetContext, 'context')),
        ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: Text(l10n.readingWorkspaceReaderOptions),
            onTap: () => Navigator.pop(sheetContext, 'preferences')),
        ListTile(
            leading: const Icon(Icons.ios_share_outlined),
            title: Text(l10n.readingWorkspaceLibrary),
            onTap: () => Navigator.pop(sheetContext, 'library')),
      ])),
    );
    if (!mounted) return;
    switch (action) {
      case 'context':
        await _showReadingContextPack();
      case 'preferences':
        await _ensureReadingSession();
        if (mounted) await _showReadingAgentPanel();
      case 'library':
        await _showBookWiki();
    }
  }

  Widget _buildBookDirectory() =>
      FutureBuilder<(ReadingOutcomesSnapshot, BookMaterialsSnapshot)>(
        future: _bookMaterials,
        builder: (context, snapshot) {
          final l10n = L10n.of(context);
          if (snapshot.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(l10n.readingWorkspaceLoadFailed),
                TextButton(
                    onPressed: () =>
                        setState(() => _bookMaterials = _loadBookMaterials()),
                    child: Text(l10n.readingWorkspaceRetry)),
              ]),
            ));
          }
          if (snapshot.connectionState != ConnectionState.done ||
              !snapshot.hasData) {
            return Center(child: Text(l10n.readingWorkspaceLoading));
          }
          final (state, materials) = snapshot.requireData;
          final atlas = fictionStoryAtlasService.fromArtifacts(state.artifacts,
              visibleAtProgress: materials.visibleAtProgress,
              arcScoped: _readingProfile?.usesArcScopedStoryAtlas == true);
          final next = const NextReadingActionResolver().resolve(
              bookId: _book.id,
              outcomes: state,
              closure: _closurePolicy,
              coverage: _readingCoverage,
              atlas: atlas,
              resumeContextAvailable: state.artifacts.any((item) =>
                  item.kind == ReadingArtifactKinds.resumeContext &&
                  item.isVisibleAtProgress(materials.visibleAtProgress)));
          return ReadingBookHubContent(
            key: const ValueKey('book-material-directory'),
            book: _book,
            state: state,
            materials: materials,
            closure: _closurePolicy,
            nextAction: next,
            atlas: atlas,
            syncing: _syncingRemoteProgress,
            syncEnabled: Prefs().cloudBaseSyncEnabled || Prefs().webdavStatus,
            syncNeedsManualResolution: Sync().automaticConflictPending,
            onNextAction: () => _handleBookHubNextAction(next),
            onOpenOutcomes: _showReadingOutcomes,
            onOpenWiki: _showBookWiki,
            onOpenContextPack: _showReadingContextPack,
            onOpenMaterial: _openBookMaterial,
            initialSearch: aiWorkspaceController.bookQuery,
            onSearchChanged: (query) => aiWorkspaceController.bookQuery = query,
            onOpenExercises: showReadingCoach,
            onOrganizeStory: () async {
              await _ensureReadingSession();
              final coverage = _readingCoverage;
              if (coverage != null) {
                await _confirmAndBackfill(coverage);
              } else {
                await _showCoverageSetup();
              }
            },
            onOrganizeKnowledge: () async {
              await _ensureReadingSession();
              if (mounted) await _generateBookWiki(false);
            },
            onResumeTask: _resumeReadingTask,
            onOpenStoryArchive: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => FictionCharacterGraphPage(
                          book: _book,
                          initialAtlas: atlas,
                          readingProfile: _readingProfile,
                          onOpenLocation: (target) async {
                            Navigator.pop(context);
                            _navigateBookSource(target);
                          })));
            },
            onOpenTimeline: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => FictionStoryTimelinePage(
                          book: _book,
                          initialAtlas: atlas,
                          readingProfile: _readingProfile,
                          onOpenLocation: (target) async {
                            Navigator.pop(context);
                            _navigateBookSource(target);
                          })));
            },
            onSync: () => _offerRemoteProgressIfAvailable(manual: true),
            onOpenReadingSettings: _showBookSettings,
          );
        },
      );

  Widget _buildReadingWorkspace() {
    final l10n = L10n.of(context);
    final wide = _usesAiSplitLayout(context);
    return PageStorage(
        bucket: _workspaceStorage,
        child: Column(children: [
          SizedBox(
              height: Prefs().eInkMode ? 56 : 48,
              child: Row(children: [
                const SizedBox(width: 8),
                if (aiWorkspaceController.selectionPanelPage != null ||
                    (aiWorkspaceController.selection != null &&
                        !aiWorkspaceController.selectionDockVisible))
                  Expanded(
                      child: TextButton.icon(
                          onPressed: _returnToSelection,
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l10n.selectionReturn)))
                else
                  for (final surface in AiWorkspaceSurface.values)
                    TextButton(
                        onPressed: () {
                          if (surface == AiWorkspaceSurface.assistant) {
                            unawaited(showAiChat());
                          } else {
                            unawaited(_showBookHub());
                          }
                        },
                        style: TextButton.styleFrom(
                            foregroundColor:
                                aiWorkspaceController.surface == surface
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                        child: Text(surface == AiWorkspaceSurface.assistant
                            ? 'AI'
                            : l10n.readingWorkspaceBook)),
                if (aiWorkspaceController.selectionPanelPage == null &&
                    (aiWorkspaceController.selection == null ||
                        aiWorkspaceController.selectionDockVisible))
                  const Spacer(),
                if (ReaderCommandGateway.instance
                    .canReturnToPreviousLocation(bookId: _book.id))
                  IconButton(
                      tooltip: l10n.readingAssistantReturn,
                      icon: const Icon(Icons.keyboard_return),
                      onPressed: () {
                        ReaderCommandGateway.instance
                            .returnToPreviousLocation(bookId: _book.id);
                        setState(() {});
                      }),
                if (wide)
                  PopupMenuButton<AiPanelPositionEnum>(
                    tooltip: l10n.readingWorkspaceMove,
                    icon: const Icon(Icons.dock_outlined),
                    onSelected: (position) =>
                        setState(() => Prefs().aiPanelPosition = position),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: AiPanelPositionEnum.right,
                          child: Text(l10n.aiShowAtRight)),
                      PopupMenuItem(
                          value: AiPanelPositionEnum.bottom,
                          child: Text(l10n.aiShowAtBottom)),
                    ],
                  )
                else
                  IconButton(
                      tooltip: aiWorkspaceController.sheetExpanded
                          ? l10n.readingWorkspaceCollapse
                          : l10n.readingWorkspaceExpand,
                      icon: Icon(aiWorkspaceController.sheetExpanded
                          ? Icons.unfold_less
                          : Icons.unfold_more),
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        aiWorkspaceController.setSheetExpanded(
                            !aiWorkspaceController.sheetExpanded);
                      }),
                IconButton(
                    tooltip: l10n.selectionContinue,
                    icon: const Icon(Icons.close),
                    onPressed: finishSelection),
              ])),
          const Divider(height: 1),
          Expanded(
              child: IndexedStack(
                  index: aiWorkspaceController.selectionPanelPage != null
                      ? 2
                      : aiWorkspaceController.surface.index,
                  children: [
                _buildAiWorkspace(),
                _bookMaterials == null
                    ? const SizedBox.shrink()
                    : _buildBookDirectory(),
                SelectionPanel(
                    controller: aiWorkspaceController,
                    generating: selectionAiGenerating,
                    bookTitle: _book.title,
                    chapterTitle:
                        aiWorkspaceController.selectionTargetChapterTitle,
                    chapterHref:
                        aiWorkspaceController.selectionTargetChapterHref,
                    offline: aiWorkspaceController.selectionOffline,
                    onAction: handleSelectionAction,
                    onSave: () => _saveSelectionAnnotation(),
                    onDelete: () => _saveSelectionAnnotation(delete: true),
                    onStyle: () => openSelectionPanel(SelectionPanelPage.style),
                    onSearch: (engine) async {
                      final target = aiWorkspaceController.selectionTarget;
                      if (target == null) return;
                      await Prefs()
                          .prefs
                          .setString('webSearchEngine', engine.code);
                      await launchUrl(engine.buildSearchUri(target.text),
                          mode: LaunchMode.externalApplication);
                      if (mounted) finishSelection();
                    }),
              ])),
        ]));
  }

  Future<void> _handleBookHubNextAction(NextReadingAction action) async {
    switch (action.target.kind) {
      case NextReadingActionTargetKinds.checkpoint:
      case NextReadingActionTargetKinds.difficulty:
        final location = action.target.location;
        if (location == null || location.isEmpty) return;
        if (location.startsWith('epubcfi(')) {
          ReaderCommandGateway.instance.navigateToCfi(
            bookId: _book.id,
            cfi: location,
          );
        } else {
          ReaderCommandGateway.instance.navigateToHref(
            bookId: _book.id,
            href: location,
          );
        }
        return;
      case NextReadingActionTargetKinds.resumeContext:
        await _showFictionResumeContext();
        return;
      case NextReadingActionTargetKinds.organizeArchive:
        final coverage = _readingCoverage;
        if (coverage != null) await _confirmAndBackfill(coverage);
        return;
      case NextReadingActionTargetKinds.reviewCard:
      case NextReadingActionTargetKinds.goal:
        await _showReadingAgentPanel();
        return;
      case NextReadingActionTargetKinds.storyMysteries:
        await _showReadingOutcomes();
        return;
      case NextReadingActionTargetKinds.reader:
        return;
    }
  }

  String _materialsDestination(AiProvider provider) {
    final l10n = L10n.of(context);
    return l10n.readingMaterialsDestination(
      provider.title,
      provider.model,
      provider.deployment == AiProviderDeployment.localPrivate
          ? l10n.readingPracticeLocalDestination
          : l10n.readingPracticeCloudDestination,
    );
  }

  Future<void> _generateBookWiki(
    bool fullBook, {
    bool contextPack = false,
  }) async {
    final localProgress = readingAgentRuntime.state.totalProgress > 0
        ? readingAgentRuntime.state.totalProgress
        : _book.readingPercentage;
    final boundary = fullBook ? 1.0 : localProgress.clamp(0, 1).toDouble();
    final chapters = (await _eligibleBackfillChapters(boundary))
        .where(
          (chapter) =>
              BookWikiGenerationService.isEligibleChapterTitle(chapter.title),
        )
        .toList(growable: false);
    if (!mounted) return;
    final provider = bookWikiGenerationService.previewProvider(ref);
    if (provider == null) {
      AnxToast.show(L10n.of(context).readingPracticeProviderUnavailable);
      return;
    }
    final estimatedTokens = chapters.length * 3000;
    final artifactLabel = contextPack ? '上下文' : 'Wiki';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:
            Text(fullBook ? '确认生成全书 $artifactLabel' : '确认生成已读 $artifactLabel'),
        content: Text(
          '${fullBook ? '将读取全书 ${chapters.length} 个章节，可能包含未读内容并产生剧透。预计输入约 $estimatedTokens Token，可随时取消后重新开始。' : '将读取 0%～${(boundary * 100).round()}% 内 ${chapters.length} 个已完整读完的章节，不读取后文。预计输入约 $estimatedTokens Token。'}\n\n${_materialsDestination(provider)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认并生成'),
          ),
        ],
      ),
    );
    if (confirmed != true || chapters.isEmpty || !mounted) return;
    final sessionId = readingAgentRuntime.state.sessionId;
    if (sessionId == null) return;
    try {
      await readingTaskScheduler.restore();
      final existingTask = readingTaskScheduler.tasks
          .where(
        (task) =>
            task.bookId == _book.id &&
            task.type == 'wiki.book_generate' &&
            !task.isTerminal,
      )
          .fold<ReadingTask?>(null, (current, task) {
        if (current == null || task.updatedAt > current.updatedAt) return task;
        return current;
      });
      if (existingTask != null) {
        if (mounted) {
          AnxToast.show(
            existingTask.status == ReadingTaskStatus.paused
                ? '已有暂停的生成任务，请在本书 AI 上下文中继续'
                : '已有生成任务正在进行，请在本书 AI 上下文中查看进度',
          );
        }
        return;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      await readingTaskScheduler.submit<int>(
        ReadingTask(
          id: 'wiki-${_book.id}-$now',
          type: 'wiki.book_generate',
          bookId: _book.id,
          priority: ReadingTaskPriority.userInitiated,
          persistence: ReadingTaskPersistence.durable,
          status: ReadingTaskStatus.queued,
          payload: {
            'scope': fullBook ? 'full_book' : 'read_boundary',
            'safeBoundary': boundary,
            'chapterCount': chapters.length,
            'estimatedInputTokens': estimatedTokens,
            'purpose': contextPack ? 'context_pack' : 'book_wiki',
            'sessionId': sessionId,
            'providerId': provider.id,
          },
          checkpoint: {
            'stage': 'preparing_chapters',
            'completedChapters': 0,
            'totalChapters': chapters.length,
          },
          createdAt: now,
          updatedAt: now,
        ),
        _executeBookWikiTask,
      );
      aiContextAssembler.invalidateBookContext(_book.id);
    } on ReadingTaskCancelled {
      // Cancellation is a deliberate user action; the task card remains
      // available so the user can see the terminal state and prior results.
    } catch (error) {
      if (mounted) AnxToast.show('生成未完成：$error');
    }
  }

  /// Shared executor for newly submitted and process-restored Wiki/context
  /// tasks. It reconstructs the chapter manifest from the current reader and
  /// resumes safely from durable hashes, so a paused task is not tied to the
  /// closure of the page that originally created it.
  Future<int> _executeBookWikiTask(
    ReadingTaskExecutionContext execution, {
    String? confirmedProviderId,
  }) async {
    final task = execution.task;
    final payload = task.payload;
    final fullBook = payload['scope']?.toString() == 'full_book';
    final boundary = ((payload['safeBoundary'] as num?)?.toDouble() ?? 0)
        .clamp(0, 1)
        .toDouble();
    final chapters = (await _eligibleBackfillChapters(boundary))
        .where(
          (chapter) =>
              BookWikiGenerationService.isEligibleChapterTitle(chapter.title),
        )
        .toList(growable: false);
    final sessionId = payload['sessionId']?.toString().trim().isNotEmpty == true
        ? payload['sessionId']!.toString()
        : readingAgentRuntime.state.sessionId ?? 'task-${task.id}';
    final inputs = <BookWikiChapter>[];
    for (var index = 0; index < chapters.length; index++) {
      final chapter = chapters[index];
      execution.safePoint();
      await execution.update(
        progress: chapters.isEmpty ? 0 : index / chapters.length * .05,
        checkpoint: {
          ...execution.task.checkpoint,
          'stage': 'reading_chapter',
          'readingChapterIndex': index + 1,
          'totalChapters': chapters.length,
          'currentChapterHref': chapter.href,
          'currentChapterTitle': chapter.title,
        },
      );
      final content = await (epubPlayerKey.currentState?.chapterContentByHref(
            chapter.href,
            maxCharacters: 24000,
          ) ??
          Future.value(''));
      if (content.trim().isEmpty) continue;
      inputs.add(
        BookWikiChapter(
          href: chapter.href,
          title: chapter.title,
          progress: chapter.startProgress,
          content: content,
        ),
      );
    }
    final result = await bookWikiGenerationService.generate(
      bookId: _book.id,
      chapters: inputs,
      safeBoundary: boundary,
      sessionId: sessionId,
      taskId: execution.taskId,
      providerId: confirmedProviderId ?? payload['providerId']?.toString(),
      ref: ref,
      scope: fullBook
          ? BookWikiGenerationScope.fullBook
          : BookWikiGenerationScope.readBoundary,
      onProgress: (done, total, href) async {
        execution.safePoint();
        final nextProgress = total == 0 ? 1.0 : .05 + .95 * done / total;
        await execution.update(
          progress: math.max(execution.task.progress, nextProgress),
          checkpoint: {
            ...execution.task.checkpoint,
            'completedChapters': done,
            'totalChapters': total,
            'lastChapterHref': href,
          },
        );
      },
      onStage: ({
        required completedUnits,
        required totalUnits,
        required chapterHref,
        required chapterTitle,
        required chunkIndex,
        required chunkCount,
        required stage,
      }) async {
        execution.safePoint();
        final nextProgress =
            totalUnits == 0 ? 1.0 : .05 + .95 * completedUnits / totalUnits;
        await execution.update(
          progress: math.max(execution.task.progress, nextProgress),
          checkpoint: {
            ...execution.task.checkpoint,
            'completedUnits': completedUnits,
            'totalUnits': totalUnits,
            'currentChapterHref': chapterHref,
            'currentChapterTitle': chapterTitle,
            'chunkIndex': chunkIndex,
            'chunkCount': chunkCount,
            'stage': stage,
          },
        );
      },
    );
    aiContextAssembler.invalidateBookContext(_book.id);
    return result;
  }

  Future<void> _showBookWiki() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookWikiPage(
            book: _book,
            visibleProgress: _visibleReadingProgress,
            onGenerate: _generateBookWiki,
            onResumeTask: _resumeReadingTask,
            onOpenLocation: (target) async {
              Navigator.pop(context);
              _navigateBookSource(target);
            },
          ),
        ),
      );

  Future<void> _showReadingContextPack() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReadingContextPackPage(
            book: _book,
            visibleProgress: readingAgentRuntime.state.totalProgress > 0
                ? readingAgentRuntime.state.totalProgress
                : _book.readingPercentage,
            chapterHref: readingAgentRuntime.state.chapterHref,
            // Wiki generation already owns user confirmation, task
            // checkpointing and validated writes. The context pack is a
            // read-only projection of that same traceable source set.
            onGenerate: () => _generateBookWiki(false, contextPack: true),
            onGenerateFullBook: () =>
                _generateBookWiki(true, contextPack: true),
            onResumeTask: _resumeReadingTask,
          ),
        ),
      );

  Future<void> _resumeReadingTask(ReadingTask task) async {
    await _ensureReadingSession();
    if (!mounted || task.bookId != _book.id) return;
    if (task.type == 'wiki.book_generate') {
      await _resumeBookWikiTask(task);
    } else if (task.type == 'fiction.backfill') {
      final coverage = _readingCoverage;
      if (coverage != null) await _confirmAndBackfill(coverage);
    } else {
      await readingTaskScheduler.resume(task.id);
    }
  }

  Future<void> _resumeBookWikiTask(ReadingTask task) async {
    if (task.bookId != _book.id || task.type != 'wiki.book_generate') return;
    final provider = bookWikiGenerationService.previewProvider(ref);
    if (provider == null) {
      AnxToast.show(L10n.of(context).readingPracticeProviderUnavailable);
      return;
    }
    final l10n = L10n.of(context);
    final boundary = (task.payload['safeBoundary'] as num?)?.toDouble() ?? 0;
    final allowed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.readingMaterialsResumeTitle),
        content: Text(
            '${l10n.readingMaterialsResumeScope('${(boundary * 100).round()}', '${task.payload['chapterCount'] ?? 0}')}\n\n${_materialsDestination(provider)}\n${l10n.readingMaterialsEstimate('${task.payload['estimatedInputTokens'] ?? 0}')}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.readingMaterialsResumeTitle)),
        ],
      ),
    );
    if (allowed != true || !mounted) return;
    try {
      await readingTaskScheduler.resumeWith<int>(
        task.id,
        (execution) =>
            _executeBookWikiTask(execution, confirmedProviderId: provider.id),
      );
    } on ReadingTaskCancelled {
      // The task card already exposes the terminal cancelled state.
    } catch (error) {
      if (mounted) AnxToast.show('继续生成失败：$error');
    }
  }

  void _showAgentUndoSnackBar(AgentAction action) {
    if (!mounted) return;
    _lastReadingAgentSnackActionId = action.id;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_agentActionLabel(action.type)}已完成'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            final result = await agentActionService.undo(action);
            if (mounted) AnxToast.show(_undoResultLabel(result));
          },
        ),
      ),
    );
  }

  String _agentActionLabel(AgentActionType type) => switch (type) {
        AgentActionType.goal => '阅读目标',
        AgentActionType.profile => '阅读偏好',
        AgentActionType.note => 'AI 笔记',
        AgentActionType.difficulty => '阅读难点',
        AgentActionType.memory => 'Markdown 记忆',
        AgentActionType.artifact => '阅读档案',
        AgentActionType.wiki => '书籍 Wiki',
      };

  String _undoResultLabel(UndoResult result) => switch (result) {
        UndoResult.undone => '已撤销',
        UndoResult.alreadyUndone => '该动作已撤销',
        UndoResult.expired => '撤销期限已过',
        UndoResult.conflict => '内容之后已被修改，未覆盖你的修改',
        UndoResult.missing => '找不到该动作',
      };

  void updateState() {
    if (mounted) {
      setState(() {
        bookmarkExists = epubPlayerKey.currentState!.bookmarkExists;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var aiButton = IconButton(
      tooltip: L10n.of(context).aiChat,
      icon: const Icon(Icons.auto_awesome),
      onPressed: () async {
        final shouldShowAsSplit = _usesAiSplitLayout(context);

        if (shouldShowAsSplit &&
            aiWorkspaceController.visible &&
            aiWorkspaceController.surface == AiWorkspaceSurface.assistant) {
          aiWorkspaceController.hide();
          return;
        }

        showOrHideAppBarAndBottomBar(false);
        showAiChat();
      },
    );
    Offstage controller = Offstage(
      offstage: bottomBarOffstage,
      child: PointerInterceptor(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  showOrHideAppBarAndBottomBar(false);
                },
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {},
                onVerticalDragEnd: (details) {},
                child: Container(color: Colors.black.withAlpha(30)),
              ),
            ),
            Column(
              children: [
                AppBar(
                  title: Text(_book.title, overflow: TextOverflow.ellipsis),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      // close reading page
                      Navigator.pop(context);
                    },
                  ),
                  actions: [
                    if (EnvVar.enableAIFeature) aiButton,
                    IconButton(
                      tooltip: L10n.of(context).readingWorkspaceBook,
                      onPressed: _showBookHub,
                      icon: const Icon(Icons.library_books_outlined),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: L10n.of(context).readingPageCopyChapterContent,
                      onPressed: () async {
                        try {
                          var content = await epubPlayerKey.currentState
                              ?.theChapterContent();
                          var len = content?.length ?? 0;
                          if (len > 0) {
                            await Clipboard.setData(
                              ClipboardData(text: content!),
                            );
                          }
                          if (!context.mounted) return;
                          AnxToast.show(
                            L10n.of(context).readingPageCopiedCharacters(len),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          AnxToast.show(
                            L10n.of(context).readingPageErrorCopyingContent,
                          );
                        }
                      },
                    ),
                    IconButton(
                      tooltip: L10n.of(context).readingPageBookmark,
                      onPressed: () {
                        if (bookmarkExists) {
                          epubPlayerKey.currentState!.removeAnnotation(
                            epubPlayerKey.currentState!.bookmarkCfi,
                          );
                        } else {
                          epubPlayerKey.currentState!.addBookmarkHere();
                        }
                      },
                      icon: bookmarkExists
                          ? const Icon(Icons.bookmark)
                          : const Icon(Icons.bookmark_border),
                    ),
                    IconButton(
                      tooltip: L10n.of(context).readingPageBookDetails,
                      icon: const Icon(EvaIcons.more_vertical),
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => BookDetail(
                              book: widget.book,
                              onOrganizeStoryArchive: () async {
                                final readerRoute = ModalRoute.of(context);
                                if (readerRoute != null) {
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route == readerRoute);
                                }
                                final coverage = _readingCoverage;
                                if (coverage != null) {
                                  await _confirmAndBackfill(coverage);
                                }
                              },
                              onOpenReadingLocation: (target) async {
                                final readerRoute = ModalRoute.of(context);
                                if (readerRoute != null) {
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route == readerRoute);
                                }
                                if (target.startsWith('epubcfi(')) {
                                  ReaderCommandGateway.instance.navigateToCfi(
                                    bookId: _book.id,
                                    cfi: target,
                                  );
                                } else {
                                  ReaderCommandGateway.instance.navigateToHref(
                                    bookId: _book.id,
                                    href: target,
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (Prefs().readingAgentBetaEnabled &&
                    _readingInterventionPolicy.decide(
                          state: readingAgentRuntime.state,
                          controlsVisible: true,
                          dismissedForSession: _readingAgentCapsuleDismissed,
                          closurePolicy: _closurePolicy,
                          resumeContextAvailable: _resumeContextAvailable,
                          coverageSetupPending:
                              _readingCoverage?.setupPending == true,
                        ) ==
                        ReadingIntervention.passiveCapsule)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildReadingAgentCapsule(),
                  ),
                const Spacer(),
                BottomSheet(
                  onClosing: () {},
                  enableDrag: false,
                  builder: (context) => SafeArea(
                    top: false,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          final hasContent = !identical(_currentPage, empty);
                          return IntrinsicHeight(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasContent) Expanded(child: _currentPage),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.toc),
                                      onPressed: tocHandler,
                                    ),
                                    IconButton(
                                      icon: const Icon(EvaIcons.edit),
                                      onPressed: noteHandler,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.data_usage),
                                      onPressed: progressHandler,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.color_lens),
                                      onPressed: () {
                                        styleHandler(setState);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(EvaIcons.headphones),
                                      onPressed: ttsHandler,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final hasSelection = aiWorkspaceController.selection != null;
    final hasHelp = aiWorkspaceController.visible;
    return PopScope<void>(
      canPop: !hasSelection && !hasHelp,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _dismissTopReadingHelp();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Hero(
          tag: widget.heroTag ??
              (Prefs().openBookAnimation ? _book.coverFullPath : heroTag),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Scaffold(
                key: _scaffoldKey,
                resizeToAvoidBottomInset: false,
                drawer: PointerInterceptor(
                  child: Drawer(
                    width: math.min(
                      MediaQuery.of(context).size.width * 0.8,
                      420,
                    ),
                    child: SafeArea(
                      child: TocWidget(
                        epubPlayerKey: epubPlayerKey,
                        hideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
                        closeDrawer: () {
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    ),
                  ),
                ),
                body: Stack(
                  children: [
                    ReadingWorkspaceHost(
                      visible: aiWorkspaceController.visible,
                      expanded: aiWorkspaceController.sheetExpanded,
                      atBottom:
                          Prefs().aiPanelPosition == AiPanelPositionEnum.bottom,
                      panelWidth: _aiChatWidth,
                      panelHeight: _aiChatHeight,
                      onResize: (delta) {
                        setState(() {
                          if (Prefs().aiPanelPosition ==
                              AiPanelPositionEnum.right) {
                            _aiChatWidth =
                                (_effectiveAiPanelWidth(context) + delta)
                                    .clamp(360.0, _aiChatMaxWidth(context));
                            Prefs().aiPanelWidth = _aiChatWidth;
                          } else {
                            _aiChatHeight = (_aiChatHeight + delta)
                                .clamp(200.0, _aiChatMaxHeight(context));
                            Prefs().aiPanelHeight = _aiChatHeight;
                          }
                        });
                      },
                      panel:
                          PointerInterceptor(child: _buildReadingWorkspace()),
                      reader: MouseRegion(
                        onHover: (PointerHoverEvent detail) {
                          if (!Prefs().showMenuOnHover) return;
                          var y = detail.position.dy;
                          if (y < 30 ||
                              y > MediaQuery.of(context).size.height - 30) {
                            showOrHideAppBarAndBottomBar(true);
                          }
                        },
                        child: Focus(
                          focusNode: _readerFocusNode,
                          onKeyEvent: _handleReaderKeyEvent,
                          child: Stack(
                            children: [
                              EpubPlayer(
                                key: epubPlayerKey,
                                book: _book,
                                cfi: widget.cfi,
                                showOrHideAppBarAndBottomBar:
                                    showOrHideAppBarAndBottomBar,
                                onLoadEnd: onLoadEnd,
                                initialThemes: widget.initialThemes,
                                updateParent: updateState,
                                onChapterChanged: _onChapterChanged,
                                onReadingLocationChanged: ({
                                  required cfi,
                                  required chapterHref,
                                  required chapterTitle,
                                  required totalProgress,
                                  required chapterProgress,
                                }) {
                                  // Invalidate synchronously on backtracking so a
                                  // previously loaded directory cannot show later sources.
                                  if (_bookMaterials != null) {
                                    setState(() =>
                                        _bookMaterials = _loadBookMaterials());
                                  }
                                  if (!readingAgentRuntime.isActive) {
                                    return;
                                  }
                                  readingAgentRuntime.observeLocation(
                                    cfi: cfi,
                                    chapterHref: chapterHref,
                                    chapterTitle: chapterTitle,
                                    totalProgress: totalProgress,
                                    chapterProgress: chapterProgress,
                                  );
                                },
                                onSelectionCreated:
                                    (SelectionSnapshot selection) {
                                  if (!readingAgentRuntime.isActive) {
                                    return;
                                  }
                                  readingAgentRuntime.selectionCreated(
                                    ReadingSelectionState(
                                      text: selection.text,
                                      cfi: selection.cfi,
                                      surroundingText: selection.contextText,
                                    ),
                                  );
                                },
                                onSelectionCleared: () {
                                  aiWorkspaceController.clearReaderSelection();
                                  if (readingAgentRuntime.isActive) {
                                    readingAgentRuntime.selectionCleared();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    controller,
                    if (aiWorkspaceController.selectionUndo != null)
                      Positioned(
                          left: 16,
                          right: 16,
                          bottom: MediaQuery.paddingOf(context).bottom + 16,
                          child: PointerInterceptor(
                              child: Material(
                            color: Prefs().eInkMode
                                ? Colors.white
                                : Theme.of(context).colorScheme.surface,
                            shape: Border.all(
                                color: Theme.of(context).colorScheme.onSurface),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: Row(children: [
                                  Expanded(
                                      child: Text(aiWorkspaceController
                                              .selectionUndoFailed
                                          ? L10n.of(context)
                                              .selectionUndoConflict
                                          : L10n.of(context).selectionSaved)),
                                  TextButton(
                                      onPressed: aiWorkspaceController
                                                  .selectionBusy ||
                                              aiWorkspaceController
                                                  .selectionUndoFailed
                                          ? null
                                          : aiWorkspaceController.selectionUndo,
                                      style: TextButton.styleFrom(
                                          minimumSize: Size(
                                              48, Prefs().eInkMode ? 56 : 48)),
                                      child:
                                          Text(L10n.of(context).selectionUndo)),
                                  IconButton(
                                      tooltip: L10n.of(context)
                                          .readingWorkspaceClose,
                                      onPressed: aiWorkspaceController
                                          .clearSelectionUndo,
                                      icon: const Icon(Icons.close)),
                                ])),
                          ))),
                    // TTS floating action button: always in the tree when toolbar
                    // is hidden; TtsFab handles its own show/hide internally so
                    // its State (expanded flag) is never destroyed mid-session.
                    if (bottomBarOffstage)
                      const Positioned(right: 16, bottom: 24, child: TtsFab()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
