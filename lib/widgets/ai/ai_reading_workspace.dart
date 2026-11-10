import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/hint_key.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/ai_quick_prompt_chip.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/page/settings_page/ai.dart';
import 'package:anx_reader/page/reading_agent_help_page.dart';
import 'package:anx_reader/providers/ai_history.dart';
import 'package:anx_reader/providers/ai_chat.dart';
import 'package:anx_reader/providers/ai_workspace.dart';
import 'package:anx_reader/providers/reading_coach.dart';
import 'package:anx_reader/providers/reading_memory.dart';
import 'package:anx_reader/providers/book_toc.dart';
import 'package:anx_reader/providers/current_reading.dart';
import 'package:anx_reader/service/ai/ai_history.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_frameworks.dart';
import 'package:anx_reader/service/ai/reading_experts.dart';
import 'package:anx_reader/service/ai/reading_skills.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/service/ai/reading_experience_profile_service.dart';
import 'package:anx_reader/service/ai/reading_coach_phase2.dart';
import 'package:anx_reader/service/ai/reading_practice_ai_service.dart';
import 'package:anx_reader/models/toc_item.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/agent_action_service.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:anx_reader/service/reading_note/reading_note_capture_service.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/widgets/ai/ai_chat_stream.dart';
import 'package:anx_reader/widgets/reading_note/quick_capture_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class AiReadingWorkspace extends ConsumerStatefulWidget {
  const AiReadingWorkspace({
    super.key,
    required this.controller,
    required this.chatKey,
    required this.quickPromptChips,
    required this.bookTitle,
    required this.bookAuthor,
    this.bookDescription,
    this.trailing,
    this.onOpenBookSession,
    this.onRestoreReadingContext,
    this.onFetchChapter,
    this.onFetchChapterSample,
    this.onNavigateChapter,
    this.onDifficultySaved,
    this.onDifficultyResolved,
    this.closureRegistry = const ReadingClosurePolicyRegistry(),
    this.sendImmediate = false,
    this.currentChapterTitle,
    this.currentProgress,
    this.onInputFocused,
    this.onReturnToQuestion,
    this.onOpenBook,
  });

  final AiWorkspaceController controller;
  final GlobalKey<AiChatStreamState> chatKey;
  final List<AiQuickPromptChip> quickPromptChips;
  final String bookTitle;
  final String bookAuthor;
  final String? bookDescription;
  final List<Widget>? trailing;
  final Future<void> Function(AiChatHistoryEntry entry)? onOpenBookSession;
  final Future<void> Function(AiChatHistoryEntry entry)?
      onRestoreReadingContext;
  final Future<String> Function(String href)? onFetchChapter;
  final Future<String> Function(String href)? onFetchChapterSample;
  final ValueChanged<String>? onNavigateChapter;
  final ValueChanged<ReadingDifficulty>? onDifficultySaved;
  final ValueChanged<ReadingDifficulty>? onDifficultyResolved;
  final ReadingClosurePolicyRegistry closureRegistry;
  final bool sendImmediate;
  final String? currentChapterTitle;
  final double? currentProgress;
  final VoidCallback? onInputFocused;
  final VoidCallback? onReturnToQuestion;
  final VoidCallback? onOpenBook;

  @override
  ConsumerState<AiReadingWorkspace> createState() => _AiReadingWorkspaceState();
}

class _AiReadingWorkspaceState extends ConsumerState<AiReadingWorkspace> {
  bool _requestedModeSuggestion = false;
  bool _showAnalysisConfig = false;
  bool _analysisAutoRecommend = true;
  late ReadingAnalysisDepth _analysisDepth;
  late ReadingOutputTemplate _analysisOutput;
  final Set<ReadingFramework> _analysisFrameworks = {};
  final TextEditingController _readingGoalController = TextEditingController();
  bool _generatingGuide = false;
  bool _generatingSynthesis = false;
  bool _organizingMemory = false;
  bool _includeAiBlocksInMemory = true;
  bool _rememberExpertSelection = false;
  final Set<String> _revealedCards = {};
  String? _reviewedCardAwaitingAdvance;
  ReadingContextSnapshot? _submittedSource;
  String? _submittedQuestion;
  String? _nextQuestionTitle;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _analysisDepth = widget.controller.analysisDepth;
    _analysisOutput = widget.controller.outputTemplate;
    _analysisAutoRecommend = Prefs().readingAnalysisAutoRecommend;
    if (!Prefs().hasReadingAiModeForBook(widget.controller.bookId)) {
      widget.controller.suggestMode(
        title: widget.bookTitle,
        description: widget.bookDescription,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _changed();
    });
  }

  Future<void> _suggestModeWithAi() async {
    if (_requestedModeSuggestion ||
        Prefs().hasReadingAiModeForBook(widget.controller.bookId)) {
      return;
    }
    if (EnvVar.isAppStore &&
        Prefs().shouldShowHint(HintKey.aiDataSharingConsent)) {
      return;
    }
    _requestedModeSuggestion = true;
    setState(() {});
    try {
      final mode = await readingExperienceProfileService.suggestAnswerMode(
          bookId: widget.controller.bookId,
          title: widget.bookTitle,
          author: widget.bookAuthor,
          description: widget.bookDescription,
          selection: widget.controller.pendingSelection,
          ref: ref);
      if (!mounted) return;
      if (mode != null) widget.controller.setSuggestedMode(mode);
    } catch (_) {
      if (!mounted) return;
      setState(() => _requestedModeSuggestion = false);
      AnxToast.show(L10n.of(context).commonFailed);
    }
  }

  @override
  void didUpdateWidget(covariant AiReadingWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
      _submittedSource = null;
      _submittedQuestion = null;
      _nextQuestionTitle = null;
      _analysisDepth = widget.controller.analysisDepth;
      _analysisOutput = widget.controller.outputTemplate;
      _showAnalysisConfig = false;
      _analysisFrameworks.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _changed();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _readingGoalController.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    final action = widget.controller.takeRequestedSelectionAction();
    final source = widget.controller.pendingSelection;
    if (action != null && source != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !widget.controller.visible ||
            widget.controller.pendingSelection != source) {
          return;
        }
        _runSelectionAction(source, action);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: IndexedStack(
        index: controller.view.index,
        children: [
          TickerMode(
            enabled: controller.view == AiWorkspaceView.chat,
            child: _buildChat(),
          ),
          TickerMode(
            enabled: controller.view == AiWorkspaceView.coach,
            child: _buildCoach(),
          ),
          TickerMode(
            enabled: controller.view == AiWorkspaceView.history,
            child: _buildHistory(),
          ),
          TickerMode(
            enabled: controller.view == AiWorkspaceView.sessionDetail,
            child: _buildSessionDetail(),
          ),
          TickerMode(
            enabled: controller.view == AiWorkspaceView.agentsAndSources,
            child: _buildAgentsAndSources(),
          ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    final pending = widget.controller.pendingSelection;
    final l10n = L10n.of(context);
    final chapter = pending?.chapterTitle ?? widget.currentChapterTitle;
    final scope = pending == null
        ? l10n.readingAssistantScope
        : l10n.readingAssistantSelectionScope;
    return AiChatStream(
      key: widget.chatKey,
      readingCompanion: true,
      initialMessage: widget.controller.draft,
      sendImmediate: widget.sendImmediate,
      onDraftChanged: widget.controller.setDraft,
      initialScrollOffset: widget.controller.chatScrollOffset,
      onScrollOffsetChanged: widget.controller.setChatScrollOffset,
      onSaveAnswer: _saveAnswerAsNote,
      onSaveQuestion: _saveAnswerAsQuestion,
      answerSources: _buildAnswerSources(),
      onInputFocused: widget.onInputFocused,
      onRequestStarted: (message) {
        _submittedSource = widget.controller.pendingSelection ??
            _submittedSource ??
            _currentLocationSnapshot();
        ref.read(aiChatProvider.notifier).setReadingContextOverride(
            _submittedSource?.selectedText?.trim().isNotEmpty == true
                ? _submittedSource
                : null);
        _submittedQuestion = _nextQuestionTitle ??
            message
                .split(
                  '\n\n先用简短、直接的回答帮助继续阅读',
                )
                .first
                .trim();
        _nextQuestionTitle = null;
        widget.controller.clearPendingSelection();
      },
      onNewConversation: () {
        _submittedSource = null;
        _submittedQuestion = null;
      },
      onReturnToQuestion: widget.onReturnToQuestion,
      pendingContext: pending == null ? null : _buildSelectionCard(pending),
      quickPromptChips: [
        for (final spec in _currentClosurePolicy().contextualPrompts.take(3))
          AiQuickPromptChip(
            icon: Icons.menu_book_outlined,
            label: _contextPromptLabel(spec),
            prompt: spec.buildCompanionPrompt(),
          ),
      ],
      title: chapter?.isNotEmpty == true ? chapter : l10n.readingAssistantTitle,
      subtitle:
          '$scope${widget.currentProgress == null ? '' : ' · ${(widget.currentProgress! * 100).round()}%'}',
      onOpenHistory: widget.controller.showHistory,
      onOpenAgents: widget.controller.showAgentsAndSources,
      onOpenCoach: widget.controller.showPractice,
      onShowMore: _showMoreActions,
      trailing: widget.trailing,
    );
  }

  Widget _buildAnswerSources() {
    final sessionId = ref.read(aiChatProvider.notifier).currentSessionId;
    final entry = ref
        .watch(aiHistoryProvider)
        .asData
        ?.value
        .where((item) => item.id == sessionId)
        .firstOrNull;
    final source = _submittedSource;
    final citations = entry?.citations ?? const <Map<String, dynamic>>[];
    if (source == null && citations.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(L10n.of(context).readingAssistantEvidence,
          style: Theme.of(context).textTheme.labelLarge),
      children: [
        if (source != null && _isUsableSource(source))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.menu_book_outlined, size: 20),
            title: Text(L10n.of(context).readingAssistantOriginalSource),
            subtitle: Text(
                '${source.chapterTitle ?? ''}\n${source.selectedText ?? ''}',
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
            onTap: () {
              final cfi = source.metadata['cfi'].toString();
              if (widget.onNavigateChapter != null) {
                widget.onNavigateChapter!(cfi);
              } else {
                ReaderCommandGateway.instance
                    .navigateToCfi(bookId: widget.controller.bookId, cfi: cfi);
              }
            },
          ),
        for (final citation in citations)
          if (Uri.tryParse(citation['url']?.toString() ?? '') case final uri?
              when uri.scheme == 'https' || uri.scheme == 'http')
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.open_in_new, size: 20),
              title: Text(citation['title']?.toString() ?? uri.host,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${L10n.of(context).readingAssistantExternalSource} · ${uri.host}'),
              onTap: () => launchUrl(uri),
            ),
      ],
    );
  }

  String _contextPromptLabel(ReadingQuickPromptSpec spec) {
    final l10n = L10n.of(context);
    return switch (spec.id) {
      'reading.explain_current' => l10n.readingAssistantExplainCurrent,
      'reading.recall_read' => l10n.readingAssistantRecall,
      'reading.explore' => l10n.readingAssistantExplore,
      'reading.explain_selection' => l10n.readingAssistantExplainSelection,
      'reading.connect_selection' => l10n.readingAssistantConnect,
      _ => spec.label,
    };
  }

  void _runSelectionAction(
      ReadingContextSnapshot snapshot, SelectionAiAction action) {
    if (action == SelectionAiAction.addNote) {
      _saveSelectionAsNote(snapshot);
      return;
    }
    final prompt = ReadingQuickPromptSpec.concisePrompt(
      widget.controller.buildActionPrompt(action),
    );
    _nextQuestionTitle = switch (action) {
      SelectionAiAction.explain =>
        L10n.of(context).readingAssistantExplainSelection,
      SelectionAiAction.contextualize =>
        L10n.of(context).readingAssistantConnect,
      _ => _actionLabel(action),
    };
    final started =
        widget.chatKey.currentState?.sendPrompt(prompt, preserveDraft: true) ??
            false;
    if (!started) _nextQuestionTitle = null;
    if (started) widget.controller.clearPendingSelection();
  }

  Future<void> _showMoreActions() async {
    final snapshot = widget.controller.pendingSelection ?? _submittedSource;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(L10n.of(context).readingAssistantMore,
                  style: Theme.of(context).textTheme.titleLarge),
              if (snapshot != null) ...[
                for (final action
                    in widget.controller.mode.agentProfile.actionOrder)
                  ListTile(
                    title: Text(_actionLabel(action)),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      widget.controller.setPendingSelection(snapshot);
                      _runSelectionAction(snapshot, action);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: Text(_actionLabel(SelectionAiAction.deepAnalyze)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    widget.controller.setPendingSelection(snapshot);
                    _openAnalysisConfig(snapshot);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined),
                title: Text(L10n.of(context).readingAssistantSaveQuestion),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final draft = widget
                          .chatKey.currentState?.inputController.text
                          .trim() ??
                      '';
                  final location = snapshot ?? _currentLocationSnapshot();
                  if (location == null) {
                    _showSaveMessage(
                        L10n.of(context).readingAssistantNeedSource);
                    return;
                  }
                  _saveDifficulty(location,
                      question: draft.isNotEmpty
                          ? draft
                          : _submittedQuestion ??
                              L10n.of(context)
                                  .readingAssistantExplainSelection);
                },
              ),
              for (final spec in _currentClosurePolicy().quickPrompts)
                ListTile(
                  title: Text(spec.label),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    widget.chatKey.currentState
                        ?.sendPrompt(spec.buildCompanionPrompt());
                  },
                ),
              ListTile(
                leading: const Icon(Icons.tune_outlined),
                title: Text(L10n.of(context).readingAssistantOptions),
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.controller.showAgentsAndSources();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  ReadingSkillSelection _currentReadingSkill() =>
      const ReadingSkillMatcher().match(
        mode: widget.controller.mode,
        title: widget.bookTitle,
        author: widget.bookAuthor,
        description: widget.bookDescription ?? '',
        chapterTitle: widget.controller.pendingSelection?.chapterTitle ?? '',
        pinnedSkill: widget.controller.pinnedReadingSkill,
      );

  ReadingClosurePolicyDefinition _currentClosurePolicy() =>
      ReadingClosurePolicyMatcher(registry: widget.closureRegistry).match(
        mode: widget.controller.mode,
        title: widget.bookTitle,
        author: widget.bookAuthor,
        description: widget.bookDescription ?? '',
        pinnedId: widget.controller.pinnedClosureId,
      );

  Widget _buildReadingClosureBar() {
    final closure = _currentClosurePolicy();
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: _showClosurePolicyPicker,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.all_inclusive, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '阅读闭环 · ${closure.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                widget.controller.pinnedClosureId == null ? '自动匹配' : '本书固定',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showClosurePolicyPicker() async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text('选择本书阅读闭环', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('闭环决定目标、章节回顾、成果指标和介入强度；不会改变书籍内容。'),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(
                widget.controller.pinnedClosureId == null
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: const Text('自动匹配'),
              subtitle: const Text('根据阅读模式与书籍信息在本地选择'),
              onTap: () {
                widget.controller.setClosureModule(null);
                Navigator.pop(context);
              },
            ),
            for (final closure in widget.closureRegistry.definitions)
              ListTile(
                leading: Icon(
                  widget.controller.pinnedClosureId == closure.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(closure.title),
                subtitle: Text(closure.description),
                onTap: () => Navigator.pop(context, closure.id),
              ),
          ],
        ),
      ),
    );
    if (selected != null) widget.controller.setClosureModule(selected);
  }

  Widget _buildReadingSkillBar() {
    final selection = _currentReadingSkill();
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: _showReadingSkillPicker,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.auto_stories_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '阅读方法 · ${selection.primary.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                selection.pinned ? '本书固定' : '自动匹配',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Reading Skill 使用方法',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReadingSkillHelpPage(),
                  ),
                ),
                icon: const Icon(Icons.help_outline, size: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showReadingSkillPicker() async {
    final current = widget.controller.pinnedReadingSkill;
    final selected = await showModalBottomSheet<ReadingSkillId?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          maxChildSize: 0.92,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text('选择阅读方法', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('阅读方法决定 AI 如何陪你读。只有发起分析、回顾或明确调用时才加载完整方法。'),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReadingSkillHelpPage(),
                    ),
                  ),
                  icon: const Icon(Icons.help_outline),
                  label: const Text('查看使用方法'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _importReadingSkill(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('导入自定义 Skill JSON'),
              ),
              OutlinedButton.icon(
                onPressed: () => _createReadingSkill(context),
                icon: const Icon(Icons.add),
                label: const Text('新建自定义 Skill'),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  current == null
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: const Text('自动匹配'),
                subtitle: const Text('根据书籍主题和本次任务选择一个主方法'),
                onTap: () {
                  widget.controller.setReadingSkill(null);
                  Navigator.pop(context);
                },
              ),
              for (final skill in ReadingSkillRegistry().allDefinitions)
                ListTile(
                  leading: Icon(
                    current == skill.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(skill.title),
                  subtitle: Text(skill.description),
                  onTap: () => Navigator.pop(context, skill.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (selected != null) {
      widget.controller.setReadingSkill(selected);
    }
  }

  Future<void> _importReadingSkill(BuildContext sheetContext) async {
    final controller = TextEditingController();
    final imported = await showDialog<ReadingSkillDefinition>(
      context: sheetContext,
      builder: (context) => AlertDialog(
        title: const Text('导入自定义 Skill'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: '{"id":"custom.my-skill","title":"..."}',
            labelText: 'Skill JSON',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final skill = readingSkillFromJsonText(controller.text);
              if (skill != null) Navigator.pop(context, skill);
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || imported == null) return;
    Prefs().saveCustomReadingSkill(imported);
    ReadingSkillRegistry.registerCustom(imported);
    setState(() {});
  }

  Future<void> _createReadingSkill(BuildContext sheetContext) async {
    final title = TextEditingController();
    final id = TextEditingController(text: 'custom.');
    final summary = TextEditingController();
    final full = TextEditingController();
    final created = await showDialog<ReadingSkillDefinition>(
      context: sheetContext,
      builder: (context) => AlertDialog(
        title: const Text('新建自定义 Skill'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              TextField(
                controller: id,
                decoration: const InputDecoration(
                  labelText: '稳定 ID（custom. 开头）',
                ),
              ),
              TextField(
                controller: summary,
                decoration: const InputDecoration(labelText: '摘要指导'),
                maxLines: 2,
              ),
              TextField(
                controller: full,
                decoration: const InputDecoration(labelText: '完整指导'),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final skill = ReadingSkillDefinition(
                id: ReadingSkillId.custom(id.text.trim()),
                title: title.text.trim(),
                description: summary.text.trim(),
                summaryInstruction: summary.text.trim(),
                fullInstruction: full.text.trim().isEmpty
                    ? summary.text.trim()
                    : full.text.trim(),
                supportedModes: {ReadingAiMode.general},
                triggerKeywords: const [],
                closureContributions: const [],
                isCustom: true,
              );
              if (skill.title.isNotEmpty &&
                  skill.id.name.startsWith('custom.')) {
                Navigator.pop(context, skill);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    title.dispose();
    id.dispose();
    summary.dispose();
    full.dispose();
    if (!mounted || created == null) return;
    Prefs().saveCustomReadingSkill(created);
    ReadingSkillRegistry.registerCustom(created);
    setState(() {});
  }

  Widget _buildCoach() {
    final coach = ref.watch(readingCoachProvider(widget.controller.bookId));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 96,
        leading: TextButton.icon(
          key: const ValueKey('ai-coach-back'),
          onPressed: widget.controller.showChat,
          icon: const Icon(Icons.arrow_back, size: 20),
          label: const Text('对话'),
        ),
        title: const Text('阅读教练'),
      ),
      body: coach.when(
        loading: () => Center(
          child: Prefs().reduceMotion
              ? const Text('Loading...')
              : const CircularProgressIndicator(),
        ),
        error: (error, _) => Center(child: Text('加载失败：$error')),
        data: (state) => ListView(
          key: const PageStorageKey('reading-coach-overview'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _buildInspectionGuide(state.guide),
            const SizedBox(height: 16),
            _buildActiveQuestions(state.guide),
            const SizedBox(height: 16),
            _buildMemoryOrganizer(),
            const SizedBox(height: 16),
            _buildReviewQueue(state),
            const SizedBox(height: 16),
            _buildCoachSection(
              icon: Icons.quiz_outlined,
              title: '章节自测',
              subtitle: state.quizzes.isEmpty
                  ? '读完章节后，用 3 道选择题检查理解'
                  : '已生成 ${state.quizzes.length} 次自测',
              child: state.quizzes.isEmpty
                  ? const Text('达到章节 80% 后切换章节，这里会出现待完成自测。')
                  : Column(
                      children: [
                        for (final quiz in state.quizzes.take(3))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              quiz.completed
                                  ? Icons.check_circle_outline
                                  : Icons.radio_button_unchecked,
                            ),
                            title: Text(quiz.chapterTitle ?? '未命名章节'),
                            subtitle: Text(
                              quiz.completed
                                  ? _masteryLabel(quiz.mastery)
                                  : '待完成 · 无需键盘输入',
                            ),
                            trailing: quiz.questions.isEmpty
                                ? TextButton(
                                    onPressed: widget.onFetchChapter == null
                                        ? null
                                        : () => _generateQuiz(quiz),
                                    child: const Text('生成'),
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap: quiz.questions.isEmpty
                                ? null
                                : () => _showQuizSheet(quiz),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _buildCoachSection(
              icon: Icons.inventory_2_outlined,
              title: '难点暂存箱',
              subtitle: '${state.unresolvedDifficultyCount} 个待处理难点',
              child: state.difficulties.isEmpty
                  ? const Text('长按选中文字，选择“暂存难点”即可加入。')
                  : Column(
                      children: [
                        for (final item in state.difficulties.take(5))
                          _buildDifficultyTile(item),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _buildReadingSynthesis(state),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionGuide(InspectionReadingGuide guide) {
    final report = guide.report;
    final generatedTopics = (report?['topics'] as List?)
        ?.map((value) => value.toString())
        .toList(growable: false);
    final topics = generatedTopics ??
        const ['核心概念与知识体系', '作者试图解决的问题', '一套可实践的方法', '我还不确定'];
    const goals = ['了解全貌', '学习知识', '解决问题', '批判分析', '休闲阅读'];
    return _buildCoachSection(
      icon: Icons.travel_explore_outlined,
      title: '检视阅读向导',
      subtitle: guide.topicChoice == null ? '先判断这本书大概在谈什么' : '已保存，可随时修订',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report == null ? '使用通用向导，也可让 AI 根据本书生成' : '已生成本书个性化向导',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton.icon(
                onPressed: _generatingGuide
                    ? null
                    : () => _generatePersonalizedGuide(guide),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(report == null ? 'AI 个性化' : '重新生成'),
              ),
            ],
          ),
          if (report != null) ...[
            Text('核心问题：${report['coreQuestion'] ?? ''}'),
            const SizedBox(height: 6),
            Text(
              '结构：${(report['structure'] as List? ?? const []).join(' → ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final chapter in (report['keyChapters'] as List? ?? const []))
              if (chapter is Map)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.bookmark_border, size: 20),
                  title: Text(chapter['title']?.toString() ?? ''),
                  subtitle: Text(chapter['reason']?.toString() ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final href = chapter['href']?.toString() ?? '';
                    if (href.isNotEmpty) widget.onNavigateChapter?.call(href);
                  },
                ),
            Text('阅读计划', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final depth in const ['轻量', '标准', '深入'])
                  ChoiceChip(
                    label: Text(depth),
                    selected: report['selectedPlanDepth'] == depth,
                    onSelected: (_) => _updateGuide(
                      guide.copyWith(
                        report: {...report, 'selectedPlanDepth': depth},
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text('这本书可能在谈什么？', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final option in topics)
            _buildChoiceRow(
              label: option,
              selected: guide.topicChoice == option,
              onTap: () => _updateGuide(
                guide.copyWith(
                  status: InspectionGuideStatus.inProgress,
                  topicChoice: option,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text('这次阅读的目标', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final option in goals)
            _buildChoiceRow(
              label: option,
              selected: guide.goalChoice == option,
              onTap: () => _updateGuide(
                guide.copyWith(
                  status: InspectionGuideStatus.completed,
                  goalChoice: option,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveQuestions(InspectionReadingGuide guide) {
    const fallbackQuestions = <String, (String, List<String>, bool)>{
      'whole': (
        '整体来说，这本书在谈什么？',
        ['概念体系', '核心问题', '实践方法', '故事与经验', '暂不确定'],
        false,
      ),
      'detail': (
        '作者主要怎么说？',
        ['定义概念', '故事或案例', '因果推理', '数据证据', '反驳其他观点', '暂不确定'],
        true,
      ),
      'truth': ('这本书说得有道理吗？', ['基本同意', '部分同意', '暂不认同', '证据不足', '暂不确定'], false),
      'relation': (
        '这本书跟我有什么关系？',
        ['改变认识', '可以实践', '帮助决策', '引发反思', '暂时无关'],
        true,
      ),
    };
    final personalized = guide.report?['questionOptions'];
    final questions = fallbackQuestions.map((id, definition) {
      if (personalized is! Map || personalized[id] is! List) {
        return MapEntry(id, definition);
      }
      final options = (personalized[id] as List)
          .map((value) => value.toString())
          .toList(growable: false);
      return MapEntry(id, (definition.$1, options, definition.$3));
    });
    return _buildCoachSection(
      icon: Icons.help_outline,
      title: '四个主动问题',
      subtitle: '选择即可作答，不要求输入长文字',
      child: Column(
        children: [
          for (final entry in questions.entries)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 12),
              initiallyExpanded: guide.answers[entry.key] == null,
              title: Text(entry.value.$1),
              subtitle: Text(
                guide.answers[entry.key] == null
                    ? '待回答'
                    : guide.answers[entry.key]!.selected.join('、'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              children: [
                for (final option in entry.value.$2)
                  _buildChoiceRow(
                    label: option,
                    selected:
                        guide.answers[entry.key]?.selected.contains(option) ==
                            true,
                    multiple: entry.value.$3,
                    onTap: () => _answerQuestion(
                      guide,
                      entry.key,
                      option,
                      multiple: entry.value.$3,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReviewQueue(ReadingCoachState state) {
    final l10n = L10n.of(context);
    final due = dueReviewQuizzes(
      state.quizzes,
      now: DateTime.now().millisecondsSinceEpoch,
    );
    final memory = ref.watch(readingMemoryProvider(widget.controller.bookId));
    return _buildCoachSection(
      icon: Icons.event_repeat_outlined,
      title: l10n.readingMemoryTodayReview,
      subtitle: l10n.readingMemoryReviewSubtitle,
      child: Column(
        children: [
          memory.when(
            loading: () => Text(l10n.readingMemoryCardsLoading),
            error: (error, _) => Text(l10n.readingMemoryCardsLoadFailed(error)),
            data: (memoryState) {
              final cards = memoryState.due(
                DateTime.now().millisecondsSinceEpoch,
              );
              final awaitingAdvance = _reviewedCardAwaitingAdvance != null;
              return Column(
                children: [
                  if (awaitingAdvance)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(l10n.readingMemoryReviewRecorded),
                      trailing: FilledButton(
                        onPressed: () =>
                            setState(() => _reviewedCardAwaitingAdvance = null),
                        child: Text(l10n.readingMemoryNextCard),
                      ),
                    ),
                  if (cards.isEmpty && !awaitingAdvance)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.readingMemoryKnowledgeCards),
                      subtitle: Text(l10n.readingMemoryNoDueCards),
                    ),
                  if (cards.isNotEmpty && !awaitingAdvance)
                    _buildReviewCard(cards.first, memoryState),
                  if (memoryState.reviews.isNotEmpty)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(l10n.readingMemoryReviewHistory),
                      subtitle: Text(
                        l10n.readingMemoryReviewCount(
                          memoryState.reviews.length,
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => ref
                                .read(
                                  readingMemoryProvider(
                                    widget.controller.bookId,
                                  ).notifier,
                                )
                                .undoLatest(),
                            child: Text(l10n.readingMemoryUndoLatest),
                          ),
                        ),
                        for (final group in _groupReviews(
                          memoryState.reviews,
                        ).entries.indexed)
                          ExpansionTile(
                            initiallyExpanded: group.$1 == 0,
                            title: Text(group.$2.key),
                            children: [
                              for (final review in group.$2.value)
                                ListTile(
                                  dense: true,
                                  title: Text(
                                    _reviewRatingLabel(review.rating),
                                  ),
                                  subtitle: Text(
                                    l10n.readingMemoryStageChange(
                                      review.previousStage,
                                      review.nextStage,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
          const Divider(),
          if (due.isEmpty)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('章节自测'),
              subtitle: Text('当前没有到期章节'),
            ),
          for (final quiz in due.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.replay_outlined),
              title: Text(quiz.chapterTitle ?? '未命名章节'),
              subtitle: Text(_masteryLabel(quiz.mastery)),
              trailing: const Text('重新自测'),
              onTap: () => _showQuizSheet(quiz),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReadingKnowledgeCard card, ReadingMemoryState state) {
    final l10n = L10n.of(context);
    final revealed = _revealedCards.contains(card.id);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.question, style: Theme.of(context).textTheme.titleSmall),
            if (revealed) ...[
              const Divider(),
              Text(card.answer),
              TextButton(
                onPressed: () =>
                    _showMemorySources(card.sourceIds, state.sources),
                child: Text(l10n.readingMemoryViewSources),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _rateCard(card, ReadingReviewRating.hard),
                      child: Text(l10n.readingMemoryHard),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _rateCard(card, ReadingReviewRating.remembered),
                      child: Text(l10n.readingMemoryRemembered),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          _rateCard(card, ReadingReviewRating.mastered),
                      child: Text(l10n.readingMemoryMastered),
                    ),
                  ),
                ],
              ),
            ] else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => setState(() => _revealedCards.add(card.id)),
                  child: Text(l10n.readingMemoryRevealAnswer),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingSynthesis(ReadingCoachState state) {
    final synthesis = state.guide.report?['synthesis'];
    return _buildCoachSection(
      icon: Icons.account_tree_outlined,
      title: '整本书成果',
      subtitle: synthesis is Map ? '已形成可复习的阅读成果' : '汇总选择、自测和难点，不上传整本书',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (synthesis is Map) ...[
            Text(synthesis['summary']?.toString() ?? ''),
            const SizedBox(height: 12),
            _buildResultList('关键观点', synthesis['keyIdeas']),
            _buildResultList('可以行动', synthesis['actions']),
            _buildResultList('仍待核查', synthesis['openQuestions']),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _generatingSynthesis
                  ? null
                  : () => _generateReadingSynthesis(state),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(synthesis is Map ? '重新生成成果' : '生成阅读成果'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryOrganizer() {
    final l10n = L10n.of(context);
    final memory = ref.watch(readingMemoryProvider(widget.controller.bookId));
    return _buildCoachSection(
      icon: Icons.psychology_alt_outlined,
      title: l10n.readingMemoryOrganizer,
      subtitle: l10n.readingMemoryOrganizerSubtitle,
      child: memory.when(
        loading: () => Text(l10n.readingMemoryLoading),
        error: (error, _) => Text(l10n.readingMemoryLoadFailed(error)),
        data: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _organizingMemory
                          ? null
                          : () => _organizeMemory(includeUsed: false),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text(l10n.readingMemoryOrganizeNew),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.readingMemoryMore,
                  onSelected: (value) {
                    if (value == 'all') _organizeMemory(includeUsed: true);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'all',
                      child: Text(l10n.readingMemoryReanalyzeAll),
                    ),
                  ],
                ),
              ],
            ),
            CheckboxListTile(
              value: _includeAiBlocksInMemory,
              onChanged: _organizingMemory
                  ? null
                  : (value) => setState(
                        () => _includeAiBlocksInMemory = value == true,
                      ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.readingMemoryIncludeAiBlocks),
              subtitle: Text(l10n.readingMemoryIncludeAiBlocksHint),
            ),
            if (state.topics.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(l10n.readingMemoryNoTopics),
              ),
            for (final topic in state.topics)
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(topic.summary),
                      TextButton(
                        onPressed: () =>
                            _showMemorySources(topic.sourceIds, state.sources),
                        child: Text(l10n.readingMemoryViewSources),
                      ),
                      if (topic.status == ReadingMemoryItemStatus.suggested)
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => _setTopicStatus(
                                topic,
                                ReadingMemoryItemStatus.ignored,
                              ),
                              child: Text(l10n.readingMemoryIgnore),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: () => _setTopicStatus(
                                topic,
                                ReadingMemoryItemStatus.kept,
                              ),
                              child: Text(l10n.readingMemoryKeep),
                            ),
                          ],
                        ),
                      if (topic.status == ReadingMemoryItemStatus.kept)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => _generateCards(topic, state),
                            icon: const Icon(Icons.style_outlined),
                            label: Text(l10n.readingMemoryGenerateCards),
                          ),
                        ),
                      for (final card in state.cards.where(
                        (card) => card.topicId == topic.id,
                      ))
                        _buildSuggestedCard(card, state),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedCard(
    ReadingKnowledgeCard card,
    ReadingMemoryState state,
  ) {
    final l10n = L10n.of(context);
    if (card.status == ReadingMemoryItemStatus.ignored ||
        card.status == ReadingMemoryItemStatus.active) {
      return const SizedBox.shrink();
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.style_outlined),
      title: Text(card.question),
      subtitle: Text(card.answer, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => _showMemorySources(card.sourceIds, state.sources),
      trailing: Wrap(
        spacing: 4,
        children: [
          TextButton(
            onPressed: () =>
                _setCardStatus(card, ReadingMemoryItemStatus.ignored),
            child: Text(l10n.readingMemoryIgnore),
          ),
          FilledButton(
            onPressed: () =>
                _setCardStatus(card, ReadingMemoryItemStatus.active),
            child: Text(l10n.readingMemoryKeep),
          ),
        ],
      ),
    );
  }

  double get _practiceBoundary {
    final reading = ref.read(currentReadingProvider);
    if (reading.book?.id == widget.controller.bookId) {
      return reading.percentage ?? widget.currentProgress ?? 0;
    }
    return widget.currentProgress ?? 0;
  }

  Future<void> _organizeMemory({required bool includeUsed}) async {
    final l10n = L10n.of(context);
    setState(() => _organizingMemory = true);
    try {
      final notifier = ref.read(
        readingMemoryProvider(widget.controller.bookId).notifier,
      );
      final sources = await notifier.collect(
        includeUsed: includeUsed,
        includeAiBlocks: _includeAiBlocksInMemory,
      );
      if (sources.length < 2) {
        AnxToast.show(l10n.readingMemoryNotEnoughSources);
        return;
      }
      final service = ReadingPracticeAiService();
      var allowCloud = false;
      if (service.topicCloudConfirmationRequired(ref)) {
        if (!mounted) return;
        allowCloud = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.readingPracticeExtractionUnavailable),
                content: Text(l10n.readingPracticeTopicCloudScope),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(l10n.commonCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(l10n.readingPracticeAllowOnce),
                  ),
                ],
              ),
            ) ??
            false;
        if (!allowCloud) return;
      }
      final topics = await service.organizeMemory(
        bookId: widget.controller.bookId,
        visibleAtProgress: _practiceBoundary,
        sources: sources,
        allowCloudFallback: allowCloud,
        ref: ref,
      );
      await notifier.saveTopics(topics);
      if (mounted) AnxToast.show(l10n.readingMemoryTopicsGenerated);
    } catch (_) {
      if (mounted) AnxToast.show(l10n.readingMemoryOrganizeFailed);
    } finally {
      if (mounted) setState(() => _organizingMemory = false);
    }
  }

  Future<void> _generateCards(
    ReadingMemoryTopic topic,
    ReadingMemoryState state,
  ) async {
    final l10n = L10n.of(context);
    try {
      final cards = await ReadingPracticeAiService().generateCards(
        bookId: widget.controller.bookId,
        visibleAtProgress: _practiceBoundary,
        topic: topic,
        sources: state.sources,
        ref: ref,
      );
      await ref
          .read(readingMemoryProvider(widget.controller.bookId).notifier)
          .saveCards(cards);
      if (mounted) AnxToast.show(l10n.readingMemoryCardsGenerated);
    } catch (_) {
      if (mounted) AnxToast.show(l10n.readingMemoryCardsGenerateFailed);
    }
  }

  Widget _buildResultList(String title, Object? values) {
    final items = (values as List? ?? const []).map(
      (value) => value.toString(),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          for (final item in items) Text('• $item'),
        ],
      ),
    );
  }

  Widget _buildChoiceRow({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool multiple = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? (multiple
                            ? Icons.check_box
                            : Icons.radio_button_checked)
                        : (multiple
                            ? Icons.check_box_outline_blank
                            : Icons.radio_button_unchecked),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _practicePreviewText(ReadingPracticeExecutionPreview preview) {
    final l10n = L10n.of(context);
    final provider = preview.provider;
    return l10n.readingPracticeExecutionPreview(
      provider?.title ?? l10n.readingPracticeProviderUnavailable,
      provider?.model ?? '—',
      provider?.deployment == AiProviderDeployment.localPrivate
          ? l10n.readingPracticeLocalDestination
          : l10n.readingPracticeCloudDestination,
      '${preview.chapterCount}',
      '${preview.maxSourceCharacters}',
      '${preview.estimatedInputTokenLimit}',
    );
  }

  Future<void> _generatePersonalizedGuide(InspectionReadingGuide guide) async {
    final l10n = L10n.of(context);
    final chapters = _flattenToc(ref.read(bookTocProvider))
        .where((item) => item.href.trim().isNotEmpty)
        .toList(growable: false);
    if (chapters.isEmpty || widget.onFetchChapterSample == null) {
      AnxToast.show(l10n.readingPracticeChaptersUnavailable);
      return;
    }
    final service = ReadingPracticeAiService();
    final executionPreview = service.previewGuide(
        representativeChapterIndexes(chapters.length).length, ref);
    // This authorization occurs before fetching samples, including unread text.
    final allowed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.readingPracticeGuideScopeTitle),
            content: Text(
                '${l10n.readingPracticeGuideScope}\n\n${_practicePreviewText(executionPreview)}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.readingPracticeAllowOnce),
              ),
            ],
          ),
        ) ??
        false;
    if (!allowed || !mounted) return;
    setState(() => _generatingGuide = true);
    try {
      final samples = <ReadingPracticeChapter>[];
      for (final index in representativeChapterIndexes(chapters.length)) {
        final chapter = chapters[index];
        final content = await widget.onFetchChapterSample!(chapter.href);
        if (content.trim().isNotEmpty) {
          samples.add(ReadingPracticeChapter(
              title: chapter.label, href: chapter.href, content: content));
        }
      }
      final report = await service.generateGuide(
        bookId: widget.controller.bookId,
        title: widget.bookTitle,
        author: widget.bookAuthor,
        description: widget.bookDescription ?? '',
        chapters: samples,
        fullBookSamplesAuthorized: allowed,
        executionPreview: executionPreview,
        ref: ref,
      );
      await _updateGuide(guide.copyWith(
        report: {
          ...?guide.report,
          ...report,
          'generatedAt': DateTime.now().millisecondsSinceEpoch
        },
        status: InspectionGuideStatus.inProgress,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: Text(l10n.readingPracticeGuideGenerated),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report['coreQuestion']?.toString() ?? ''),
              const SizedBox(height: 16),
              _buildResultList(l10n.readingPracticeTopics, report['topics']),
              _buildResultList(
                  l10n.readingPracticeStructure, report['structure']),
              _buildResultList(l10n.readingPracticePlan, report['plan']),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonOk),
            )
          ],
        ),
      );
    } catch (_) {
      if (mounted) AnxToast.show(l10n.readingPracticeGuideFailed);
    } finally {
      if (mounted) setState(() => _generatingGuide = false);
    }
  }

  Future<void> _generateReadingSynthesis(ReadingCoachState state) async {
    final l10n = L10n.of(context);
    if (state.guide.answers.isEmpty &&
        state.quizzes.where((quiz) => quiz.completed).isEmpty &&
        state.difficulties.isEmpty) {
      AnxToast.show(l10n.readingPracticeRecordsNeeded);
      return;
    }
    setState(() => _generatingSynthesis = true);
    try {
      final synthesis = await ReadingPracticeAiService().generateSynthesis(
        bookId: widget.controller.bookId,
        visibleAtProgress: _practiceBoundary,
        title: widget.bookTitle,
        author: widget.bookAuthor,
        guide: state.guide,
        quizzes: state.quizzes,
        difficulties: state.difficulties,
        ref: ref,
      );
      await _updateGuide(state.guide.copyWith(
        report: {
          ...?state.guide.report,
          'synthesis': synthesis,
          'synthesisGeneratedAt': DateTime.now().millisecondsSinceEpoch,
          'synthesisSourceProgress': _practiceBoundary,
          'synthesisVisibleFromProgress': _practiceBoundary
        },
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      if (mounted) AnxToast.show(l10n.readingPracticeSynthesisGenerated);
    } catch (_) {
      if (mounted) AnxToast.show(l10n.readingPracticeSynthesisFailed);
    } finally {
      if (mounted) setState(() => _generatingSynthesis = false);
    }
  }

  List<TocItem> _flattenToc(List<TocItem> items) => [
        for (final item in items) ...[item, ..._flattenToc(item.subitems)],
      ];

  Future<void> _generateQuiz(ChapterQuiz quiz) async {
    final l10n = L10n.of(context);
    final service = ReadingPracticeAiService();
    final executionPreview = service.previewQuiz(ref);
    final allowed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.readingPracticeQuizScopeTitle),
            content: Text(
                '${l10n.readingPracticeQuizScope(quiz.chapterTitle ?? '')}\n\n'
                '${_practicePreviewText(executionPreview)}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.readingPracticeAllowOnce),
              ),
            ],
          ),
        ) ??
        false;
    if (!allowed || !mounted) return;
    try {
      final content = await widget.onFetchChapter?.call(quiz.chapterHref) ?? '';
      if (!mounted || content.trim().isEmpty) {
        if (mounted) AnxToast.show(l10n.readingPracticeChaptersUnavailable);
        return;
      }
      AnxToast.show(l10n.readingPracticeQuizGenerating);
      final questions = await service.generateQuiz(
        bookId: widget.controller.bookId,
        visibleAtProgress: _practiceBoundary,
        quiz: quiz,
        content: content,
        chapterAuthorized: allowed,
        executionPreview: executionPreview,
        ref: ref,
      );
      if (!mounted) return;
      final generated = ChapterQuiz(
        id: quiz.id,
        bookId: quiz.bookId,
        chapterHref: quiz.chapterHref,
        chapterTitle: quiz.chapterTitle,
        questions: questions,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await ref
          .read(readingCoachProvider(quiz.bookId).notifier)
          .saveQuiz(generated);
      if (mounted) await _showQuizSheet(generated);
    } catch (_) {
      if (mounted) AnxToast.show(l10n.readingPracticeQuizFailed);
    }
  }

  Future<void> _showQuizSheet(ChapterQuiz quiz) async {
    final answers = <String, List<String>>{
      for (final entry in quiz.answers.entries) entry.key: [...entry.value],
    };
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.85,
            child: Column(
              children: [
                ListTile(
                  title: Text(quiz.chapterTitle ?? '章节自测'),
                  subtitle: const Text('选择即可完成，不需要输入'),
                  trailing: IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: quiz.questions.length,
                    itemBuilder: (context, index) {
                      final question = quiz.questions[index];
                      final id = question['id']?.toString() ?? 'q$index';
                      final multiple = question['multiple'] == true;
                      final selected = answers[id] ??= [];
                      final options = (question['options'] as List).map(
                        (value) => value.toString(),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${question['question']}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            for (final option in options)
                              _buildChoiceRow(
                                label: option,
                                selected: selected.contains(option),
                                multiple: multiple,
                                onTap: () => setSheetState(() {
                                  if (!multiple) selected.clear();
                                  selected.contains(option)
                                      ? selected.remove(option)
                                      : selected.add(option);
                                }),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: answers.length < quiz.questions.length ||
                              answers.values.any((value) => value.isEmpty)
                          ? null
                          : () async {
                              var correct = 0;
                              for (final question in quiz.questions) {
                                final id = question['id']?.toString() ?? '';
                                final expected =
                                    (question['correct'] as List? ?? const [])
                                        .map((value) => value.toString())
                                        .toSet();
                                if (answers[id]?.toSet().containsAll(
                                              expected,
                                            ) ==
                                        true &&
                                    expected.containsAll(answers[id]!)) {
                                  correct++;
                                }
                              }
                              final mastery = correct >= 3
                                  ? ReadingMasteryLevel.solid
                                  : correct >= 2
                                      ? ReadingMasteryLevel.developing
                                      : ReadingMasteryLevel.needsReview;
                              await ref
                                  .read(
                                    readingCoachProvider(quiz.bookId).notifier,
                                  )
                                  .saveQuiz(
                                    ChapterQuiz(
                                      id: quiz.id,
                                      bookId: quiz.bookId,
                                      chapterHref: quiz.chapterHref,
                                      chapterTitle: quiz.chapterTitle,
                                      questions: quiz.questions,
                                      answers: answers,
                                      mastery: mastery,
                                      completed: true,
                                      updatedAt:
                                          DateTime.now().millisecondsSinceEpoch,
                                    ),
                                  );
                              _showPracticeSaved(ref
                                  .read(readingCoachProvider(quiz.bookId)
                                      .notifier)
                                  .lastAction);
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                      child: const Text('提交选择'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentAgentTrace() {
    final sessionId = ref.read(aiChatProvider.notifier).currentSessionId;
    if (sessionId == null) return const SizedBox.shrink();
    final history = ref.watch(aiHistoryProvider).asData?.value ?? const [];
    AiChatHistoryEntry? current;
    for (final entry in history) {
      if (entry.id == sessionId) {
        current = entry;
        break;
      }
    }
    if (current == null ||
        (current.agentTraces.isEmpty &&
            current.citations.isEmpty &&
            current.analysisDepth == null)) {
      return const SizedBox.shrink();
    }
    final frameworkLabels = current.frameworks.map((value) {
      final framework = ReadingFramework.fromJson(value);
      return framework == null
          ? value
          : const ReadingFrameworkRegistry().get(framework).label;
    }).join('、');
    return ExpansionTile(
      initiallyExpanded: false,
      leading: const Icon(Icons.hub_outlined, size: 18),
      title: Text(
        current.analysisDepth == null
            ? '专家任务 ${current.agentTraces.length}'
            : '${_analysisDepthLabel(ReadingAnalysisDepth.fromJson(current.analysisDepth))}分析 · $frameworkLabels',
      ),
      subtitle: Text(
        '专家 ${current.agentTraces.length} · 来源 ${current.citations.length} · 点击查看详情',
      ),
      children: [
        if (current.analysisDepth != null)
          ListTile(
            dense: true,
            leading: const Icon(Icons.auto_awesome, size: 18),
            title: Text(
              _analysisOutputLabel(
                ReadingOutputTemplate.fromJson(current.outputTemplate),
              ),
            ),
            subtitle: Text(
              current.readingGoal?.isNotEmpty == true
                  ? '目标：${current.readingGoal}'
                  : '目标：理解当前内容及其在本书中的作用',
            ),
          ),
        for (final trace in current.agentTraces)
          ListTile(
            dense: true,
            leading: Icon(
              trace['status'] == 'completed'
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              size: 18,
            ),
            title: Text(trace['agentId']?.toString() ?? 'agent'),
            subtitle: Text(
              trace['detail']?.toString().isNotEmpty == true
                  ? trace['detail'].toString()
                  : trace['status']?.toString() ?? '',
            ),
          ),
        for (final citation in current.citations)
          ListTile(
            dense: true,
            leading: const Icon(Icons.link, size: 18),
            title: Text(
              citation['title']?.toString() ??
                  citation['url']?.toString() ??
                  'Source',
            ),
            subtitle: Text(
              [
                citation['url']?.toString() ?? '',
                if (citation['publishedAt'] != null)
                  '发布：${citation['publishedAt']}',
                if (citation['accessedAt'] != null)
                  '访问：${citation['accessedAt']}',
              ].where((value) => value.isNotEmpty).join('\n'),
            ),
            onTap: () {
              final uri = Uri.tryParse(citation['url']?.toString() ?? '');
              if (uri != null) launchUrl(uri);
            },
          ),
      ],
    );
  }

  Widget _buildModeSuggestion() {
    final suggested = widget.controller.suggestedMode!;
    return MaterialBanner(
      content: Text('建议使用“${_modeLabel(suggested)}”模式，确认后仅对本书生效。'),
      actions: [
        TextButton(
          onPressed: _requestedModeSuggestion ? null : _suggestModeWithAi,
          child: const Text('AI 识别'),
        ),
        TextButton(
          onPressed: () => _setMode(suggested),
          child: Text(L10n.of(context).commonConfirm),
        ),
        TextButton(
          onPressed: () => _setMode(ReadingAiMode.general),
          child: Text(L10n.of(context).commonCancel),
        ),
      ],
    );
  }

  Widget _buildSelectionCard(ReadingContextSnapshot snapshot) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote, size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(snapshot.selectedText ?? '',
                      maxLines: 3, overflow: TextOverflow.ellipsis)),
              IconButton(
                tooltip: L10n.of(context).readingAssistantRemoveQuote,
                onPressed: widget.controller.clearPendingSelection,
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final spec in _currentClosurePolicy()
                  .selectionPrompts
                  .where((spec) => spec.selectionAction != null)
                  .take(2))
                OutlinedButton(
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: () =>
                      _runSelectionAction(snapshot, spec.selectionAction!),
                  child: Text(_contextPromptLabel(spec)),
                ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: _showMoreActions,
                child: Text(L10n.of(context).readingAssistantMore),
              ),
            ],
          ),
          if (_showAnalysisConfig) ...[
            const Divider(height: 24),
            _buildAnalysisConfig(snapshot),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisConfig(ReadingContextSnapshot snapshot) {
    const registry = ReadingFrameworkRegistry();
    final maxFrameworks = Prefs().readingAnalysisMaxFrameworks;
    final researchEnabled = Prefs().readingResearchWebSearch &&
        Prefs().readingWebSearchConfig.enabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('深度阅读', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<ReadingAnalysisDepth>(
                initialValue: _analysisDepth,
                decoration: const InputDecoration(
                  labelText: '分析深度',
                  isDense: true,
                ),
                items: ReadingAnalysisDepth.values
                    .map(
                      (depth) => DropdownMenuItem(
                        value: depth,
                        child: Text(_analysisDepthLabel(depth)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (depth) {
                  if (depth == null) return;
                  setState(() {
                    _analysisDepth = depth;
                    if (_analysisAutoRecommend) {
                      _recommendFrameworks(snapshot);
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<ReadingOutputTemplate>(
                initialValue: _analysisOutput,
                decoration: const InputDecoration(
                  labelText: '输出形式',
                  isDense: true,
                ),
                items: ReadingOutputTemplate.values
                    .map(
                      (output) => DropdownMenuItem(
                        value: output,
                        child: Text(_analysisOutputLabel(output)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (output) {
                  if (output != null) setState(() => _analysisOutput = output);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _readingGoalController,
          maxLines: 2,
          minLines: 1,
          decoration: const InputDecoration(
            labelText: '本次阅读目标（可选）',
            hintText: '例如：判断作者的论证是否成立',
            isDense: true,
          ),
          onChanged: (_) {
            if (_analysisAutoRecommend) {
              setState(() => _recommendFrameworks(snapshot));
            }
          },
        ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: _analysisAutoRecommend,
          title: const Text('自动推荐主要框架'),
          subtitle: Text('本地推荐，不调用模型；最多 $maxFrameworks 个'),
          onChanged: (value) {
            setState(() {
              _analysisAutoRecommend = value;
              if (value) _recommendFrameworks(snapshot);
            });
          },
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final framework in ReadingFramework.values)
              ChoiceChip(
                label: Text(registry.get(framework).label),
                selected: _analysisFrameworks.contains(framework),
                onSelected: (selected) {
                  setState(() {
                    _analysisAutoRecommend = false;
                    if (selected) {
                      if (_analysisFrameworks.length >= maxFrameworks) {
                        _analysisFrameworks.remove(_analysisFrameworks.first);
                      }
                      _analysisFrameworks.add(framework);
                    } else if (_analysisFrameworks.length > 1) {
                      _analysisFrameworks.remove(framework);
                    }
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (final framework in _analysisFrameworks)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${registry.get(framework).label}：${registry.get(framework).description}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (_analysisDepth == ReadingAnalysisDepth.research)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              researchEnabled
                  ? '研究档将使用已配置的可信网络来源。'
                  : '研究档未获得联网条件，将仅使用本书并列出待核查问题。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _showAnalysisConfig = false),
              child: Text(L10n.of(context).commonCancel),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _analysisFrameworks.isEmpty
                  ? null
                  : () => _startDeepAnalysis(snapshot),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('开始分析'),
            ),
          ],
        ),
      ],
    );
  }

  void _openAnalysisConfig(ReadingContextSnapshot snapshot) {
    _analysisDepth = widget.controller.analysisDepth;
    _analysisOutput = widget.controller.outputTemplate;
    _analysisAutoRecommend = Prefs().readingAnalysisAutoRecommend;
    _readingGoalController.clear();
    _recommendFrameworks(snapshot);
    if (!Prefs().readingAnalysisConfirmBeforeSend) {
      _startDeepAnalysis(snapshot);
      return;
    }
    setState(() => _showAnalysisConfig = true);
  }

  void _recommendFrameworks(ReadingContextSnapshot snapshot) {
    final frameworks = const ReadingFrameworkRecommender().recommend(
      depth: _analysisDepth,
      mode: widget.controller.mode,
      readingGoal: _readingGoalController.text,
      text: snapshot.selectedText,
      maxFrameworks: Prefs().readingAnalysisMaxFrameworks,
    );
    _analysisFrameworks
      ..clear()
      ..addAll(frameworks);
  }

  void _startDeepAnalysis(ReadingContextSnapshot snapshot) {
    if (_analysisFrameworks.isEmpty) _recommendFrameworks(snapshot);
    final request = widget.controller.buildAnalysisRequest(
      depth: _analysisDepth,
      output: _analysisOutput,
      frameworks: _analysisFrameworks.toList(growable: false),
      readingGoal: _readingGoalController.text,
      recommendedAutomatically: _analysisAutoRecommend,
    );
    widget.controller.setAnalysisDefaults(
      depth: _analysisDepth,
      output: _analysisOutput,
    );
    ref.read(aiChatProvider.notifier).setReadingAnalysisRequest(request);
    final prompt = widget.controller.buildDeepAnalysisPrompt(request);
    _nextQuestionTitle = _actionLabel(SelectionAiAction.deepAnalyze);
    final started = widget.chatKey.currentState?.sendPrompt(prompt) ?? false;
    if (!started) _nextQuestionTitle = null;
    if (started) {
      widget.controller.clearPendingSelection();
      setState(() => _showAnalysisConfig = false);
    }
  }

  Widget _buildHistory() {
    final state = ref.watch(aiHistoryProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 96,
        leading: TextButton.icon(
          key: const ValueKey('ai-history-back'),
          onPressed: widget.controller.showChat,
          icon: const Icon(Icons.arrow_back, size: 20),
          label: const Text('返回'),
        ),
        title: Text(L10n.of(context).conversationHistory),
        actions: [
          TextButton(
            onPressed: () => widget.controller.setHistoryScope(
              !widget.controller.showAllHistory,
            ),
            child: Text(widget.controller.showAllHistory ? '当前书' : '全部会话'),
          ),
        ],
      ),
      body: state.when(
        loading: () => Center(
          child: Prefs().reduceMotion
              ? const Text('Loading...')
              : const CircularProgressIndicator(),
        ),
        error: (_, __) =>
            Center(child: Text(L10n.of(context).failedToLoadHistoryTip)),
        data: (entries) {
          final visible = widget.controller.showAllHistory
              ? entries
              : entries
                  .where((entry) => entry.bookId == widget.controller.bookId)
                  .toList(growable: false);
          if (visible.isEmpty) {
            return Center(child: Text(L10n.of(context).noConversationTip));
          }
          if (widget.controller.showAllHistory) {
            final groups = <String, List<AiChatHistoryEntry>>{};
            for (final entry in visible) {
              final label = entry.bookTitle ?? '未关联书籍';
              groups.putIfAbsent(label, () => []).add(entry);
            }
            return ListView(
              key: const PageStorageKey('ai-history-all'),
              children: [
                for (final group in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      group.key,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final entry in group.value) _buildHistoryTile(entry),
                ],
              ],
            );
          }
          return ListView.builder(
            key: PageStorageKey('ai-history-${widget.controller.bookId}'),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final entry = visible[index];
              return _buildHistoryTile(entry);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryTile(AiChatHistoryEntry entry) {
    return ListTile(
      leading: const Icon(Icons.chat_bubble_outline),
      title: Text(entry.title ?? _historyTitle(entry)),
      subtitle: Text(
        '${entry.bookTitle ?? '未关联书籍'} · ${entry.chapterTitle ?? entry.model}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => widget.controller.showSessionDetail(entry),
    );
  }

  Widget _buildSessionDetail() {
    final entry = widget.controller.selectedSession;
    if (entry == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 96,
        leading: TextButton.icon(
          key: const ValueKey('ai-session-back'),
          onPressed: widget.controller.showHistory,
          icon: const Icon(Icons.arrow_back, size: 20),
          label: const Text('返回'),
        ),
        title: Text(entry.title ?? _historyTitle(entry)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            entry.bookTitle ?? '未关联书籍',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (entry.chapterTitle != null) Text(entry.chapterTitle!),
          const SizedBox(height: 12),
          Text('模式：${entry.readingMode ?? 'general'}'),
          if (entry.analysisDepth != null)
            Text(
              '深度：${_analysisDepthLabel(ReadingAnalysisDepth.fromJson(entry.analysisDepth))}',
            ),
          if (entry.frameworks.isNotEmpty)
            Text(
              '框架：${entry.frameworks.map((value) {
                final framework = ReadingFramework.fromJson(value);
                return framework == null
                    ? value
                    : const ReadingFrameworkRegistry().get(framework).label;
              }).join('、')}',
            ),
          if (entry.outputTemplate != null)
            Text(
              '输出：${_analysisOutputLabel(ReadingOutputTemplate.fromJson(entry.outputTemplate))}',
            ),
          Text('模型：${entry.serviceId} · ${entry.model}'),
          Text('消息：${entry.messages.length}'),
          Text('专家任务：${entry.agentTraces.length}'),
          Text('引用：${entry.citations.length}'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _restoreSession(entry),
            icon: const Icon(Icons.restore),
            label: const Text('恢复并继续对话'),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsAndSources() {
    final profile = widget.controller.mode.agentProfile;
    final search = Prefs().readingWebSearchConfig;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 96,
        leading: TextButton.icon(
          key: const ValueKey('ai-agents-back'),
          onPressed: widget.controller.showChat,
          icon: const Icon(Icons.arrow_back, size: 20),
          label: const Text('返回'),
        ),
        title: Text(L10n.of(context).readingAssistantOptions),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.controller.suggestedMode != null) _buildModeSuggestion(),
          _buildReadingClosureBar(),
          _buildReadingSkillBar(),
          _buildCurrentAgentTrace(),
          const SizedBox(height: 16),
          DropdownButtonFormField<ReadingAiMode>(
            initialValue: widget.controller.mode,
            decoration: const InputDecoration(labelText: '阅读模式'),
            items: ReadingAiMode.values
                .map(
                  (mode) => DropdownMenuItem(
                    value: mode,
                    child: Text(_modeLabel(mode)),
                  ),
                )
                .toList(growable: false),
            onChanged: (mode) {
              if (mode != null) _setMode(mode);
            },
          ),
          const SizedBox(height: 20),
          Text('本轮专家', style: Theme.of(context).textTheme.titleMedium),
          const Text('自动模式由主助手推荐；手动选择会覆盖本轮自动推荐。'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: ReadingExpertRegistry()
                .forMode(widget.controller.mode)
                .map((expert) {
              final selected = widget.controller.selectedExpertIds.contains(
                expert.id,
              );
              return FilterChip(
                label: Text(expert.title),
                selected: selected,
                onSelected: (value) {
                  final ids = [...widget.controller.selectedExpertIds];
                  if (value) {
                    final limit = widget.controller.analysisDepth ==
                            ReadingAnalysisDepth.quick
                        ? 1
                        : 3;
                    if (ids.length >= limit) ids.removeAt(0);
                    ids.add(expert.id);
                  } else {
                    ids.remove(expert.id);
                  }
                  widget.controller.setExpertSelection(
                    ids,
                    persist: _rememberExpertSelection,
                  );
                },
              );
            }).toList(growable: false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _rememberExpertSelection,
            title: const Text('记住到本书'),
            subtitle: const Text('仅保存专家 ID，不同步 Provider、地址或密钥'),
            onChanged: (value) =>
                setState(() => _rememberExpertSelection = value == true),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: widget.controller.allowExpertWebSearch,
            title: const Text('允许本轮联网核查'),
            subtitle: const Text('默认关闭；仅支持联网的专家可使用可信来源检索'),
            onChanged: (value) {
              widget.controller.allowExpertWebSearch = value;
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ReadingAnalysisDepth>(
            initialValue: widget.controller.analysisDepth,
            decoration: const InputDecoration(
              labelText: '本书默认分析深度',
              helperText: '仅影响之后发起的深度分析',
            ),
            items: ReadingAnalysisDepth.values
                .map(
                  (depth) => DropdownMenuItem(
                    value: depth,
                    child: Text(_analysisDepthLabel(depth)),
                  ),
                )
                .toList(growable: false),
            onChanged: (depth) {
              if (depth == null) return;
              widget.controller.setAnalysisDefaults(
                depth: depth,
                output: widget.controller.outputTemplate,
              );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ReadingOutputTemplate>(
            initialValue: widget.controller.outputTemplate,
            decoration: const InputDecoration(labelText: '本书默认输出形式'),
            items: ReadingOutputTemplate.values
                .map(
                  (output) => DropdownMenuItem(
                    value: output,
                    child: Text(_analysisOutputLabel(output)),
                  ),
                )
                .toList(growable: false),
            onChanged: (output) {
              if (output == null) return;
              widget.controller.setAnalysisDefaults(
                depth: widget.controller.analysisDepth,
                output: output,
              );
            },
          ),
          if (Prefs().hasReadingAnalysisConfigForBook(widget.controller.bookId))
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.controller.resetAnalysisDefaults,
                child: const Text('恢复全局默认'),
              ),
            ),
          const SizedBox(height: 20),
          Text('主助手', style: Theme.of(context).textTheme.titleMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.account_tree_outlined),
            value: Prefs().readingMultiAgentEnabled,
            title: const Text('主助手调度专家'),
            subtitle: const Text('简单问题直接回答；复杂问题最多并行调用两个专家'),
            onChanged: (value) {
              Prefs().readingMultiAgentEnabled = value;
              setState(() {});
            },
          ),
          ListTile(
            enabled: Prefs().readingMultiAgentEnabled,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.psychology_outlined),
            title: Text(profile.displayName),
            subtitle: Text('当前模式专家 · 可使用 ${profile.allowedTools.length} 个阅读工具'),
          ),
          ListTile(
            enabled: Prefs().readingMultiAgentEnabled,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('来源研究员与事实核查员'),
            subtitle: const Text('负责出处、时间、数字、证据冲突和不确定性'),
          ),
          const Divider(),
          Text('网络检索', style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(search.enabled ? Icons.cloud_done : Icons.cloud_off),
            title: Text(search.enabled ? '已启用' : '默认关闭'),
            subtitle: Text(search.enabled ? '仅保留可信域名中的结果' : '将使用本书、笔记、书架和内置词典'),
          ),
          const Divider(),
          Text('可信来源', style: Theme.of(context).textTheme.titleMedium),
          for (final domain in Prefs()
              .readingTrustedSourcePack(widget.controller.mode)
              .domains)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_outlined, size: 18),
              title: Text(domain),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _openGlobalAiSettings,
            icon: const Icon(Icons.tune),
            label: const Text('打开完整 AI 设置'),
          ),
        ],
      ),
    );
  }

  void _openGlobalAiSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(L10n.of(context).settingsAi)),
          body: const AISettings(),
        ),
      ),
    );
  }

  Future<void> _restoreSession(AiChatHistoryEntry entry) async {
    if (entry.bookId == null) {
      widget.controller.showSessionDetail(entry);
      return;
    }
    if (entry.bookId != widget.controller.bookId) {
      final openBook = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(L10n.of(context).readingAssistantOtherBook),
          content: Text(L10n.of(context).readingAssistantOtherBookHelp),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(L10n.of(context).readingAssistantViewHistory),
            ),
            if (widget.onOpenBookSession != null)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(L10n.of(context).readingAssistantOpenBook),
              ),
          ],
        ),
      );
      if (openBook == true && widget.onOpenBookSession != null) {
        await widget.onOpenBookSession!(entry);
        return;
      }
      if (openBook == false && mounted) {
        widget.controller.showSessionDetail(entry);
      }
      return;
    }
    _submittedSource = null;
    _submittedQuestion = null;
    _nextQuestionTitle = null;
    await widget.chatKey.currentState?.restoreSession(entry);
    await widget.onRestoreReadingContext?.call(entry);
    final restoredMode = ReadingAiMode.fromJson(entry.readingMode);
    widget.controller.setMode(restoredMode, persist: false);
    if (entry.analysisDepth != null) {
      widget.controller.setAnalysisDefaults(
        depth: ReadingAnalysisDepth.fromJson(entry.analysisDepth),
        output: ReadingOutputTemplate.fromJson(entry.outputTemplate),
        persist: false,
      );
    }
    ref.read(aiChatProvider.notifier).setReadingModeOverride(restoredMode);
    widget.controller.showChat();
    await widget.chatKey.currentState?.scrollToBottom(waitForLayout: true);
  }

  Future<void> _updateGuide(InspectionReadingGuide guide) async {
    final notifier =
        ref.read(readingCoachProvider(widget.controller.bookId).notifier);
    await notifier.saveGuide(guide);
    _showPracticeSaved(notifier.lastAction);
  }

  void _showPracticeSaved(AgentAction? action) {
    if (!mounted || action == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(L10n.of(context).commonSaved),
      action: SnackBarAction(
        label: L10n.of(context).readingAssistantUndo,
        onPressed: () async {
          await agentActionService.undo(action);
          if (!mounted) return;
          ref.invalidate(readingCoachProvider(widget.controller.bookId));
          ref.invalidate(readingMemoryProvider(widget.controller.bookId));
          setState(() => _reviewedCardAwaitingAdvance = null);
        },
      ),
    ));
  }

  Future<void> _answerQuestion(
    InspectionReadingGuide guide,
    String questionId,
    String option, {
    required bool multiple,
  }) {
    final previous = guide.answers[questionId];
    final selected = <String>[...?previous?.selected];
    if (multiple) {
      if (selected.contains(option)) {
        selected.remove(option);
      } else {
        selected.add(option);
      }
    } else {
      selected
        ..clear()
        ..add(option);
    }
    final answers = Map<String, ActiveReadingAnswer>.from(guide.answers);
    answers[questionId] = ActiveReadingAnswer(
      questionId: questionId,
      selected: selected,
      note: previous?.note,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    return _updateGuide(
      guide.copyWith(
        answers: answers,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  bool _isUsableSource(ReadingContextSnapshot? snapshot) {
    return snapshot?.selectedText?.trim().isNotEmpty == true &&
        _isUsableLocation(snapshot);
  }

  ReadingContextSnapshot? _currentLocationSnapshot() {
    final reading = ref.read(currentReadingProvider);
    if (reading.book?.id != widget.controller.bookId) return null;
    return ReadingContextSnapshot(
      bookId: widget.controller.bookId.toString(),
      chapterTitle: reading.chapterTitle,
      chapterHref: reading.chapterHref,
      progress: reading.percentage,
      metadata: {'cfi': reading.cfi},
    );
  }

  bool _isUsableLocation(ReadingContextSnapshot? snapshot) {
    if (snapshot == null ||
        snapshot.bookId != widget.controller.bookId.toString() ||
        !readingAgentRuntime.isActive ||
        readingAgentRuntime.state.bookId != widget.controller.bookId) {
      return false;
    }
    final cfi = snapshot.metadata['cfi']?.toString() ?? '';
    final progress = snapshot.progress;
    return cfi.startsWith('epubcfi(') &&
        cfi.endsWith(')') &&
        progress != null &&
        progress.isFinite &&
        progress >= 0 &&
        progress <= 1 &&
        progress <=
            (widget.currentProgress ??
                    readingAgentRuntime.state.totalProgress) +
                .000001;
  }

  Future<void> _saveAnswerAsQuestion(String answer) async {
    final snapshot = _submittedSource;
    if (!_isUsableLocation(snapshot)) {
      _showSaveMessage(L10n.of(context).readingAssistantNeedSource);
      return;
    }
    await _saveDifficulty(snapshot!,
        answer: answer, question: _submittedQuestion);
  }

  Future<void> _saveDifficulty(ReadingContextSnapshot snapshot,
      {String? answer, String? question}) async {
    if (!_isUsableLocation(snapshot)) {
      _showSaveMessage(L10n.of(context).readingAssistantNeedSource);
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      final mutation = await agentActionService.saveDifficulty(
          ReadingDifficulty(
            id: '${widget.controller.bookId}-$now',
            bookId: widget.controller.bookId,
            cfi: snapshot.metadata['cfi'].toString(),
            text: question?.trim().isNotEmpty == true
                ? question!.trim()
                : L10n.of(context).readingAssistantExplainSelection,
            chapterHref: snapshot.chapterHref,
            chapterTitle: snapshot.chapterTitle,
            context: [snapshot.selectedText, snapshot.surroundingText]
                .whereType<String>()
                .where((text) => text.trim().isNotEmpty)
                .join('\n\n'),
            type: ReadingDifficultyType.question,
            note: answer,
            createdAt: now,
            updatedAt: now,
          ),
          sourceProgress: snapshot.progress,
          visibleFromProgress: snapshot.progress);
      if (!mounted) return;
      widget.onDifficultySaved?.call(mutation.value);
      widget.controller.clearPendingSelection();
      ref.invalidate(readingCoachProvider(widget.controller.bookId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L10n.of(context).readingAssistantSavedQuestion),
        action: SnackBarAction(
          label: L10n.of(context).readingAssistantUndo,
          onPressed: () async {
            await agentActionService.undo(mutation.action);
            ref.invalidate(readingCoachProvider(widget.controller.bookId));
          },
        ),
      ));
    } catch (_) {
      if (mounted) {
        _showSaveMessage(L10n.of(context).readingAssistantSaveFailed);
      }
    }
  }

  void _showSaveMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _buildDifficultyTile(ReadingDifficulty item) {
    final resolved = item.status == ReadingDifficultyStatus.resolved;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(resolved ? Icons.check_circle_outline : Icons.more_horiz),
      title: Text(item.text, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${item.chapterTitle ?? '当前章节'} · ${_difficultyTypeLabel(item.type)}',
      ),
      trailing: PopupMenuButton<String>(
        tooltip: '难点类型',
        onSelected: (value) async {
          final notifier = ref.read(
            readingCoachProvider(widget.controller.bookId).notifier,
          );
          if (value == 'resolve') {
            final resolvedItem = item.copyWith(
              status: ReadingDifficultyStatus.resolved,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            );
            await notifier.updateDifficulty(resolvedItem);
            _showPracticeSaved(notifier.lastAction);
            widget.onDifficultyResolved?.call(resolvedItem);
            return;
          }
          final type = ReadingDifficultyType.values.byName(value);
          await notifier.updateDifficulty(
            item.copyWith(
              type: type,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
          _showPracticeSaved(notifier.lastAction);
        },
        itemBuilder: (context) => [
          for (final type in ReadingDifficultyType.values)
            PopupMenuItem(
              value: type.name,
              child: Text(_difficultyTypeLabel(type)),
            ),
          if (!resolved) const PopupMenuDivider(),
          if (!resolved)
            const PopupMenuItem(value: 'resolve', child: Text('标记为已解决')),
        ],
      ),
      onTap: () {
        final action = item.type == ReadingDifficultyType.background
            ? SelectionAiAction.sourceLookup
            : SelectionAiAction.explain;
        widget.controller.setPendingSelection(
          ReadingContextSnapshot(
            bookId: widget.controller.bookId.toString(),
            bookTitle: widget.bookTitle,
            author: widget.bookAuthor,
            chapterTitle: item.chapterTitle,
            chapterHref: item.chapterHref,
            selectedText: item.text,
            surroundingText: item.context,
            capturedAt: item.updatedAt,
            metadata: {'cfi': item.cfi},
          ),
        );
        widget.controller.showChat();
        final prompt = widget.controller.buildActionPrompt(action);
        widget.chatKey.currentState?.setDraft(prompt);
      },
    );
  }

  String _difficultyTypeLabel(ReadingDifficultyType type) => switch (type) {
        ReadingDifficultyType.concept => '概念不懂',
        ReadingDifficultyType.argument => '论证没跟上',
        ReadingDifficultyType.background => '背景缺失',
        ReadingDifficultyType.question => '有疑问',
        ReadingDifficultyType.later => '稍后再想',
      };

  String _masteryLabel(ReadingMasteryLevel? mastery) => switch (mastery) {
        ReadingMasteryLevel.needsReview => '待复习',
        ReadingMasteryLevel.developing => '基本掌握',
        ReadingMasteryLevel.solid => '理解扎实',
        null => '已完成',
      };

  Future<void> _setTopicStatus(
    ReadingMemoryTopic item,
    ReadingMemoryItemStatus status,
  ) async {
    final notifier =
        ref.read(readingMemoryProvider(widget.controller.bookId).notifier);
    await notifier.setTopicStatus(item, status);
    _showPracticeSaved(notifier.lastAction);
  }

  Future<void> _setCardStatus(
    ReadingKnowledgeCard item,
    ReadingMemoryItemStatus status,
  ) async {
    final notifier =
        ref.read(readingMemoryProvider(widget.controller.bookId).notifier);
    await notifier.setCardStatus(item, status);
    _showPracticeSaved(notifier.lastAction);
  }

  Future<void> _rateCard(
    ReadingKnowledgeCard card,
    ReadingReviewRating rating,
  ) async {
    final notifier =
        ref.read(readingMemoryProvider(widget.controller.bookId).notifier);
    await notifier.review(card, rating);
    _showPracticeSaved(notifier.lastAction);
    if (mounted) {
      setState(() {
        _revealedCards.remove(card.id);
        _reviewedCardAwaitingAdvance = card.id;
      });
    }
  }

  Future<void> _showMemorySources(
    List<String> ids,
    List<ReadingMemorySource> sources,
  ) async {
    final l10n = L10n.of(context);
    final selected =
        sources.where((source) => ids.contains(source.id)).toList();
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.readingMemoryOriginalSources,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final source in selected)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  source.chapterTitle ??
                      ((source.isAvailable &&
                              (source.cfi?.isNotEmpty == true ||
                                  source.chapterHref?.isNotEmpty == true))
                          ? l10n.readingMemoryUntitledChapter
                          : l10n.readingMemoryLocationUnavailable),
                ),
                subtitle: Text(
                  source.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: source.isAvailable &&
                        (source.cfi?.isNotEmpty == true ||
                            source.chapterHref?.isNotEmpty == true)
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: source.isAvailable &&
                        (source.cfi?.isNotEmpty == true ||
                            source.chapterHref?.isNotEmpty == true)
                    ? () {
                        Navigator.pop(sheetContext);
                        widget.onNavigateChapter?.call(
                          source.cfi ?? source.chapterHref!,
                        );
                      }
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Map<String, List<ReadingCardReview>> _groupReviews(
    List<ReadingCardReview> reviews,
  ) {
    final result = <String, List<ReadingCardReview>>{};
    for (final review in reviews) {
      result.putIfAbsent(_dateLabel(review.reviewedAt), () => []).add(review);
    }
    return result;
  }

  String _dateLabel(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _reviewRatingLabel(ReadingReviewRating rating) => switch (rating) {
        ReadingReviewRating.hard => L10n.of(context).readingMemoryHard,
        ReadingReviewRating.remembered =>
          L10n.of(context).readingMemoryRemembered,
        ReadingReviewRating.mastered => L10n.of(context).readingMemoryMastered,
      };

  void _setMode(ReadingAiMode mode) {
    widget.controller.setMode(mode);
    ref.read(aiChatProvider.notifier).setReadingModeOverride(mode);
  }

  Future<void> _saveSelectionAsNote(ReadingContextSnapshot snapshot) async {
    final cfi = snapshot.metadata['cfi']?.toString() ?? '';
    final choice = await showReadingNoteQuickCaptureSheet(context);
    if (choice == null || !mounted) return;
    final document = await ReadingNoteCaptureService().capture(
      bookId: widget.controller.bookId,
      text: snapshot.selectedText ?? '',
      cfi: cfi,
      chapter: snapshot.chapterTitle ?? '',
      chapterHref: snapshot.chapterHref,
      annotationType: 'highlight',
      annotationColor: Prefs().annotationColor,
      kind: choice.kind,
      body: choice.body,
    );
    widget.controller.clearPendingSelection();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10n.of(context).commonSaveSuccess),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => ReadingNoteCaptureService().undo(document.note.id),
        ),
      ),
    );
  }

  Future<void> _saveAnswerAsNote(String answer) async {
    final snapshot = _submittedSource;
    if (!_isUsableSource(snapshot)) {
      _showSaveMessage(L10n.of(context).readingAssistantNeedSource);
      return;
    }
    final sessionId = ref.read(aiChatProvider.notifier).currentSessionId;
    final entry = ref
        .read(aiHistoryProvider)
        .asData
        ?.value
        .where((item) => item.id == sessionId)
        .firstOrNull;
    try {
      final mutation = await agentActionService.createSourcedNote(
        bookId: widget.controller.bookId,
        sourceText: snapshot!.selectedText!.trim(),
        cfi: snapshot.metadata['cfi'].toString(),
        chapterTitle: snapshot.chapterTitle ?? '',
        chapterHref: snapshot.chapterHref,
        body: answer,
        model: entry?.model ?? 'ai-workspace',
        sourceProgress: snapshot.progress,
        visibleFromProgress: snapshot.progress,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L10n.of(context).commonSaveSuccess),
        action: SnackBarAction(
          label: L10n.of(context).readingAssistantUndo,
          onPressed: () => agentActionService.undo(mutation.action),
        ),
      ));
    } catch (_) {
      if (mounted) {
        _showSaveMessage(L10n.of(context).readingAssistantSaveFailed);
      }
    }
  }

  String _historyTitle(AiChatHistoryEntry entry) {
    for (final message in entry.messages) {
      final text = message.contentAsString.trim();
      if (text.isNotEmpty) return text.split('\n').first;
    }
    return 'Conversation';
  }

  String _modeLabel(ReadingAiMode mode) => switch (mode) {
        ReadingAiMode.general => '通用陪读',
        ReadingAiMode.history => '历史陪读',
        ReadingAiMode.psychology => '心理陪读',
        ReadingAiMode.finance => '理财陪读',
      };

  String _actionLabel(SelectionAiAction action) => switch (action) {
        SelectionAiAction.explain => '解释',
        SelectionAiAction.summarize => '总结',
        SelectionAiAction.contextualize =>
          widget.controller.mode == ReadingAiMode.history ? '时间线/背景' : '联系全书',
        SelectionAiAction.factCheck =>
          widget.controller.mode == ReadingAiMode.history ? '史料核查' : '事实核查',
        SelectionAiAction.analyze =>
          widget.controller.mode == ReadingAiMode.psychology
              ? '反思对话'
              : widget.controller.mode == ReadingAiMode.finance
                  ? '验证假设/风险'
                  : '分析',
        SelectionAiAction.translate => '翻译',
        SelectionAiAction.connectToBook => '联系全书',
        SelectionAiAction.addNote => '加入笔记',
        SelectionAiAction.sourceLookup => '查典籍',
        SelectionAiAction.timeline => '时间线',
        SelectionAiAction.reflection => '反思对话',
        SelectionAiAction.exercise => '生成练习',
        SelectionAiAction.validateAssumption => '验证假设',
        SelectionAiAction.calculate => '计算',
        SelectionAiAction.riskCheck => '风险检查',
        SelectionAiAction.deepAnalyze => '深度分析',
      };

  String _analysisDepthLabel(ReadingAnalysisDepth depth) => switch (depth) {
        ReadingAnalysisDepth.quick => '快读',
        ReadingAnalysisDepth.standard => '精读',
        ReadingAnalysisDepth.deep => '深读',
        ReadingAnalysisDepth.research => '研究',
      };

  String _analysisOutputLabel(ReadingOutputTemplate output) => switch (output) {
        ReadingOutputTemplate.learningNote => '学习笔记',
        ReadingOutputTemplate.argumentAnalysis => '论证分析',
        ReadingOutputTemplate.conceptMap => '概念图',
        ReadingOutputTemplate.practicePlan => '实践计划',
      };
}
