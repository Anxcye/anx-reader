import 'dart:convert';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/enums/hint_key.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/ai_quick_prompt_chip.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/page/settings_page/ai.dart';
import 'package:anx_reader/page/reading_agent_help_page.dart';
import 'package:anx_reader/providers/ai_history.dart';
import 'package:anx_reader/providers/ai_chat.dart';
import 'package:anx_reader/providers/ai_workspace.dart';
import 'package:anx_reader/providers/reading_coach.dart';
import 'package:anx_reader/providers/reading_memory.dart';
import 'package:anx_reader/providers/book_toc.dart';
import 'package:anx_reader/service/ai/ai_history.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_frameworks.dart';
import 'package:anx_reader/service/ai/reading_skills.dart';
import 'package:anx_reader/service/ai/reading_coach_policy.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/service/ai/reading_coach_phase2.dart';
import 'package:anx_reader/models/toc_item.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/service/ai/reading_memory_ai_service.dart';
import 'package:anx_reader/service/ai/ai_extraction_engine.dart';
import 'package:anx_reader/service/ai/agent_action_service.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:anx_reader/service/reading_note/reading_note_capture_service.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/widgets/ai/ai_chat_stream.dart';
import 'package:anx_reader/widgets/reading_note/quick_capture_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain_core/chat_models.dart';
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
  final Set<String> _revealedCards = {};
  String? _reviewedCardAwaitingAdvance;

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
    final selection = widget.controller.pendingSelection;
    final result = await aiGenerateText(
      [
        ChatMessage.humanText('''只输出 general、history、psychology、finance 之一，不要解释。
根据少量书籍元数据建议 AI 阅读模式：
书名：${widget.bookTitle}
作者：${widget.bookAuthor}
简介：${widget.bookDescription ?? ''}
当前章节：${selection?.chapterTitle ?? ''}
少量正文：${selection?.surroundingText ?? selection?.selectedText ?? ''}'''),
      ],
      useAgent: false,
      ref: ref,
    );
    if (!mounted) return;
    final normalized = result.trim().toLowerCase();
    for (final mode in ReadingAiMode.values) {
      if (normalized == mode.name || normalized.contains(mode.name)) {
        widget.controller.setSuggestedMode(mode);
        return;
      }
    }
  }

  @override
  void didUpdateWidget(covariant AiReadingWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
      _analysisDepth = widget.controller.analysisDepth;
      _analysisOutput = widget.controller.outputTemplate;
      _showAnalysisConfig = false;
      _analysisFrameworks.clear();
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
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: IndexedStack(
        index: controller.view.index,
        children: [
          _buildChat(),
          _buildCoach(),
          _buildHistory(),
          _buildSessionDetail(),
          _buildAgentsAndSources(),
        ],
      ),
    );
  }

  Widget _buildChat() {
    final pending = widget.controller.pendingSelection;
    return Column(
      children: [
        if (widget.controller.suggestedMode != null) _buildModeSuggestion(),
        _buildReadingClosureBar(),
        _buildReadingSkillBar(),
        _buildCurrentAgentTrace(),
        if (pending != null) _buildSelectionCard(pending),
        Expanded(
          child: AiChatStream(
            key: widget.chatKey,
            initialMessage: widget.controller.draft,
            sendImmediate: widget.sendImmediate,
            onDraftChanged: widget.controller.setDraft,
            initialScrollOffset: widget.controller.chatScrollOffset,
            onScrollOffsetChanged: widget.controller.setChatScrollOffset,
            onSaveAnswer: _saveAnswerAsNote,
            quickPromptChips: widget.quickPromptChips,
            title: _modeLabel(widget.controller.mode),
            onOpenHistory: widget.controller.showHistory,
            onOpenAgents: widget.controller.showAgentsAndSources,
            onOpenCoach: widget.controller.showCoach,
            trailing: widget.trailing,
          ),
        ),
      ],
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
              leading: Icon(widget.controller.pinnedClosureId == null
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
              title: const Text('自动匹配'),
              subtitle: const Text('根据阅读模式与书籍信息在本地选择'),
              onTap: () {
                widget.controller.setClosureModule(null);
                Navigator.pop(context);
              },
            ),
            for (final closure in widget.closureRegistry.definitions)
              ListTile(
                leading: Icon(widget.controller.pinnedClosureId == closure.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
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
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(current == null
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
                title: const Text('自动匹配'),
                subtitle: const Text('根据书籍主题和本次任务选择一个主方法'),
                onTap: () {
                  widget.controller.setReadingSkill(null);
                  Navigator.pop(context);
                },
              ),
              for (final skill in ReadingSkillRegistry.definitions)
                ListTile(
                  leading: Icon(current == skill.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked),
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
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall),
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
        const [
          '核心概念与知识体系',
          '作者试图解决的问题',
          '一套可实践的方法',
          '我还不确定',
        ];
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
        false
      ),
      'detail': (
        '作者主要怎么说？',
        ['定义概念', '故事或案例', '因果推理', '数据证据', '反驳其他观点', '暂不确定'],
        true
      ),
      'truth': ('这本书说得有道理吗？', ['基本同意', '部分同意', '暂不认同', '证据不足', '暂不确定'], false),
      'relation': (
        '这本书跟我有什么关系？',
        ['改变认识', '可以实践', '帮助决策', '引发反思', '暂时无关'],
        true
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
      child: Column(children: [
        memory.when(
          loading: () => Text(l10n.readingMemoryCardsLoading),
          error: (error, _) => Text(l10n.readingMemoryCardsLoadFailed(error)),
          data: (memoryState) {
            final cards =
                memoryState.due(DateTime.now().millisecondsSinceEpoch);
            final awaitingAdvance = _reviewedCardAwaitingAdvance != null;
            return Column(children: [
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
                    subtitle: Text(l10n.readingMemoryNoDueCards)),
              if (cards.isNotEmpty && !awaitingAdvance)
                _buildReviewCard(cards.first, memoryState),
              if (memoryState.reviews.isNotEmpty)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(l10n.readingMemoryReviewHistory),
                  subtitle: Text(l10n
                      .readingMemoryReviewCount(memoryState.reviews.length)),
                  children: [
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => ref
                              .read(readingMemoryProvider(
                                      widget.controller.bookId)
                                  .notifier)
                              .undoLatest(),
                          child: Text(l10n.readingMemoryUndoLatest),
                        )),
                    for (final group
                        in _groupReviews(memoryState.reviews).entries.indexed)
                      ExpansionTile(
                        initiallyExpanded: group.$1 == 0,
                        title: Text(group.$2.key),
                        children: [
                          for (final review in group.$2.value)
                            ListTile(
                              dense: true,
                              title: Text(_reviewRatingLabel(review.rating)),
                              subtitle: Text(l10n.readingMemoryStageChange(
                                  review.previousStage, review.nextStage)),
                            )
                        ],
                      ),
                  ],
                ),
            ]);
          },
        ),
        const Divider(),
        if (due.isEmpty)
          const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('章节自测'),
              subtitle: Text('当前没有到期章节')),
        for (final quiz in due.take(5))
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.replay_outlined),
              title: Text(quiz.chapterTitle ?? '未命名章节'),
              subtitle: Text(_masteryLabel(quiz.mastery)),
              trailing: const Text('重新自测'),
              onTap: () => _showQuizSheet(quiz)),
      ]),
    );
  }

  Widget _buildReviewCard(ReadingKnowledgeCard card, ReadingMemoryState state) {
    final l10n = L10n.of(context);
    final revealed = _revealedCards.contains(card.id);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).dividerColor)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.question,
                  style: Theme.of(context).textTheme.titleSmall),
              if (revealed) ...[
                const Divider(),
                Text(card.answer),
                TextButton(
                    onPressed: () =>
                        _showMemorySources(card.sourceIds, state.sources),
                    child: Text(l10n.readingMemoryViewSources)),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () =>
                              _rateCard(card, ReadingReviewRating.hard),
                          child: Text(l10n.readingMemoryHard))),
                  const SizedBox(width: 6),
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () =>
                              _rateCard(card, ReadingReviewRating.remembered),
                          child: Text(l10n.readingMemoryRemembered))),
                  const SizedBox(width: 6),
                  Expanded(
                      child: FilledButton(
                          onPressed: () =>
                              _rateCard(card, ReadingReviewRating.mastered),
                          child: Text(l10n.readingMemoryMastered))),
                ]),
              ] else
                SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _revealedCards.add(card.id)),
                        child: Text(l10n.readingMemoryRevealAnswer))),
            ],
          )),
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
            Row(children: [
              Expanded(
                  child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                          onPressed: _organizingMemory
                              ? null
                              : () => _organizeMemory(includeUsed: false),
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: Text(l10n.readingMemoryOrganizeNew)))),
              PopupMenuButton<String>(
                tooltip: l10n.readingMemoryMore,
                onSelected: (value) {
                  if (value == 'all') _organizeMemory(includeUsed: true);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'all', child: Text(l10n.readingMemoryReanalyzeAll))
                ],
              ),
            ]),
            CheckboxListTile(
              value: _includeAiBlocksInMemory,
              onChanged: _organizingMemory
                  ? null
                  : (value) =>
                      setState(() => _includeAiBlocksInMemory = value == true),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.readingMemoryIncludeAiBlocks),
              subtitle: Text(l10n.readingMemoryIncludeAiBlocksHint),
            ),
            if (state.topics.isEmpty)
              Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(l10n.readingMemoryNoTopics)),
            for (final topic in state.topics)
              Card(
                  elevation: 0,
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topic.title,
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(topic.summary),
                          TextButton(
                              onPressed: () => _showMemorySources(
                                  topic.sourceIds, state.sources),
                              child: Text(l10n.readingMemoryViewSources)),
                          if (topic.status == ReadingMemoryItemStatus.suggested)
                            Row(children: [
                              TextButton(
                                  onPressed: () => _setTopicStatus(
                                      topic, ReadingMemoryItemStatus.ignored),
                                  child: Text(l10n.readingMemoryIgnore)),
                              const Spacer(),
                              FilledButton(
                                  onPressed: () => _setTopicStatus(
                                      topic, ReadingMemoryItemStatus.kept),
                                  child: Text(l10n.readingMemoryKeep)),
                            ]),
                          if (topic.status == ReadingMemoryItemStatus.kept)
                            SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _generateCards(topic, state),
                                    icon: const Icon(Icons.style_outlined),
                                    label:
                                        Text(l10n.readingMemoryGenerateCards))),
                          for (final card in state.cards
                              .where((card) => card.topicId == topic.id))
                            _buildSuggestedCard(card, state),
                        ],
                      ))),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedCard(
      ReadingKnowledgeCard card, ReadingMemoryState state) {
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
      trailing: Wrap(spacing: 4, children: [
        TextButton(
            onPressed: () =>
                _setCardStatus(card, ReadingMemoryItemStatus.ignored),
            child: Text(l10n.readingMemoryIgnore)),
        FilledButton(
            onPressed: () =>
                _setCardStatus(card, ReadingMemoryItemStatus.active),
            child: Text(l10n.readingMemoryKeep)),
      ]),
    );
  }

  Future<void> _organizeMemory({required bool includeUsed}) async {
    final l10n = L10n.of(context);
    setState(() => _organizingMemory = true);
    try {
      final notifier =
          ref.read(readingMemoryProvider(widget.controller.bookId).notifier);
      final sources = await notifier.collect(
          includeUsed: includeUsed, includeAiBlocks: _includeAiBlocksInMemory);
      if (sources.length < 2) {
        AnxToast.show(l10n.readingMemoryNotEnoughSources);
        return;
      }
      final service = ReadingMemoryAiService();
      final prompt = service.topicPrompt(sources);
      var useExtractionEngine = aiExtractionEngine.resolveProvider(ref) != null;
      if (!useExtractionEngine) {
        if (!mounted) return;
        final allowCloud = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('轻量提取引擎不可用'),
                content: const Text(
                  '主题聚类通常由本地或小参数模型处理。若继续，本次收集的阅读记忆内容将发送给通用线上模型；以后仍不会自动切换。',
                ),
                actions: [
                  FilledButton.tonal(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('取消／稍后处理'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('仅本次使用线上模型'),
                  ),
                ],
              ),
            ) ??
            false;
        if (!allowCloud) return;
      }
      final batchId = DateTime.now().millisecondsSinceEpoch.toString();
      final topics = await _generateMemoryStructured(
        prompt: prompt,
        correction: '输出 2-8 个主题，每项必须包含 title、summary 和输入中的 sourceIds。',
        parser: (response) => service.parseTopics(response,
            bookId: widget.controller.bookId,
            batchId: batchId,
            allowedSourceIds: sources.map((s) => s.id).toSet(),
            now: int.parse(batchId)),
        useExtractionEngine: useExtractionEngine,
      );
      await notifier.saveTopics(topics);
      if (mounted) {
        AnxToast.show(l10n.readingMemoryTopicsGenerated);
      }
    } catch (_) {
      if (mounted) {
        AnxToast.show(l10n.readingMemoryOrganizeFailed);
      }
    } finally {
      if (mounted) setState(() => _organizingMemory = false);
    }
  }

  Future<void> _generateCards(
      ReadingMemoryTopic topic, ReadingMemoryState state) async {
    final l10n = L10n.of(context);
    try {
      final sources = state.sources
          .where((source) => topic.sourceIds.contains(source.id))
          .toList();
      final service = ReadingMemoryAiService();
      final prompt = service.cardPrompt(topic, sources);
      final cards = await _generateMemoryStructured(
        prompt: prompt,
        correction: '输出 3-8 张卡片，每项必须包含 question、answer 和输入中的 sourceIds。',
        parser: (response) => service.parseCards(response,
            bookId: widget.controller.bookId,
            topic: topic,
            allowedSourceIds: topic.sourceIds.toSet(),
            now: DateTime.now().millisecondsSinceEpoch),
      );
      await ref
          .read(readingMemoryProvider(widget.controller.bookId).notifier)
          .saveCards(cards);
      if (mounted) AnxToast.show(l10n.readingMemoryCardsGenerated);
    } catch (_) {
      if (mounted) AnxToast.show(l10n.readingMemoryCardsGenerateFailed);
    }
  }

  Future<List<T>> _generateMemoryStructured<T>(
      {required String prompt,
      required String correction,
      required List<T> Function(String response) parser,
      bool useExtractionEngine = false}) async {
    Future<String> generate(String value) async {
      if (!useExtractionEngine) {
        return aiGenerateText([ChatMessage.humanText(value)],
            useAgent: false, ref: ref);
      }
      final extracted = await aiExtractionEngine.extract(
        taskId: AiExtractionTaskIds.readingMemoryTopics,
        prompt: value,
        ref: ref,
      );
      if (!extracted.isValid) {
        throw FormatException(extracted.validationErrors.join('；'));
      }
      return extracted.raw;
    }

    var response = await generate(prompt);
    try {
      return parser(response);
    } on FormatException {
      response = await generate('''返回未通过校验。请只输出合法 JSON 数组，不要解释。
$correction
原始任务：$prompt
待纠正返回：$response''');
      return parser(response);
    }
  }

  Widget _buildResultList(String title, Object? values) {
    final items =
        (values as List? ?? const []).map((value) => value.toString());
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
              color: selected ? scheme.primary : scheme.outlineVariant),
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
                              selected ? FontWeight.w700 : FontWeight.w400),
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

  Future<void> _generatePersonalizedGuide(
    InspectionReadingGuide guide,
  ) async {
    final chapters = _flattenToc(ref.read(bookTocProvider))
        .where((item) => item.href.trim().isNotEmpty)
        .toList(growable: false);
    if (chapters.isEmpty || widget.onFetchChapterSample == null) {
      AnxToast.show('目录尚未准备好');
      return;
    }
    setState(() => _generatingGuide = true);
    try {
      final samples = <Map<String, String>>[];
      for (final index in representativeChapterIndexes(chapters.length)) {
        final chapter = chapters[index];
        final content = await widget.onFetchChapterSample!(chapter.href);
        if (content.trim().isEmpty) continue;
        samples.add({
          'title': chapter.label,
          'href': chapter.href,
          'sample': boundedChapterSample(content),
        });
      }
      final toc = chapters
          .map((item) => {'title': item.label, 'href': item.href})
          .toList(growable: false);
      final prompt = '''根据书籍元数据、目录和限量章节样本生成低输入检视阅读向导。
只输出 JSON 对象，不要 Markdown。格式：
{"bookType":"类型","coreQuestion":"核心问题","topics":["主题1","主题2","主题3"],"structure":["结构1","结构2"],"keyChapters":[{"title":"章节名","href":"目录中的原始href","reason":"原因"}],"plan":["步骤1","步骤2"],"questionOptions":{"whole":["选项1","选项2","选项3"],"detail":["选项1","选项2","选项3"],"truth":["选项1","选项2","选项3"],"relation":["选项1","选项2","选项3"]}}
要求：选项必须具体对应本书、短且互不重复；不得编造目录 href；每组 3-5 项。
书名：${widget.bookTitle}
作者：${widget.bookAuthor}
简介：${widget.bookDescription ?? ''}
目录：${jsonEncode(toc)}
章节样本：${jsonEncode(samples)}''';
      final report = await _generateStructured(
        prompt: prompt,
        correctionRule: '必须输出检视向导 JSON 对象，保留目录原始 href，四组问题各含 3-5 个选项。',
        parser: parsePersonalizedGuideResponse,
      );
      final knownHrefs = chapters.map((chapter) => chapter.href).toSet();
      final keyChapters = report['keyChapters'] as List;
      if (keyChapters.any(
        (chapter) =>
            chapter is! Map ||
            !knownHrefs.contains(chapter['href']?.toString() ?? ''),
      )) {
        throw const FormatException('AI returned an unknown chapter href');
      }
      await _updateGuide(
        guide.copyWith(
          report: {
            ...?guide.report,
            ...report,
            'generatedAt': DateTime.now().millisecondsSinceEpoch,
          },
          status: InspectionGuideStatus.inProgress,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      if (mounted) AnxToast.show('个性化向导已生成');
    } catch (_) {
      if (mounted) AnxToast.show('生成失败，已保留原有向导');
    } finally {
      if (mounted) setState(() => _generatingGuide = false);
    }
  }

  Future<void> _generateReadingSynthesis(ReadingCoachState state) async {
    final answered = state.guide.answers.map(
      (id, answer) => MapEntry(id, answer.selected),
    );
    if (answered.isEmpty &&
        state.quizzes.where((quiz) => quiz.completed).isEmpty &&
        state.difficulties.isEmpty) {
      AnxToast.show('先完成主动问题、自测或暂存难点');
      return;
    }
    setState(() => _generatingSynthesis = true);
    try {
      final evidence = {
        'book': {
          'title': widget.bookTitle,
          'author': widget.bookAuthor,
          'goal': state.guide.goalChoice,
          'guide': state.guide.report,
        },
        'activeAnswers': answered,
        'quizzes': state.quizzes
            .take(30)
            .map((quiz) => {
                  'chapter': quiz.chapterTitle,
                  'mastery': quiz.mastery?.name,
                })
            .toList(growable: false),
        'difficulties': state.difficulties
            .take(30)
            .map((item) => {
                  'text': item.text,
                  'type': item.type.name,
                  'status': item.status.name,
                })
            .toList(growable: false),
      };
      final prompt = '''根据用户已有阅读记录生成整本书成果，不补写用户没有表达的个人观点。
只输出 JSON 对象，不要 Markdown。格式：
{"summary":"理解变化总结","keyIdeas":["观点1","观点2","观点3"],"actions":["行动1"],"openQuestions":["待核查问题1"]}
要求：关键观点 3-6 项，行动 1-4 项，待核查问题 1-4 项；明确区分用户选择和模型归纳。
阅读记录：${jsonEncode(evidence)}''';
      final synthesis = await _generateStructured(
        prompt: prompt,
        correctionRule:
            '必须输出成果 JSON 对象，包含 summary、keyIdeas、actions、openQuestions。',
        parser: parseReadingSynthesisResponse,
      );
      await _updateGuide(
        state.guide.copyWith(
          report: {
            ...?state.guide.report,
            'synthesis': synthesis,
            'synthesisGeneratedAt': DateTime.now().millisecondsSinceEpoch,
          },
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      if (mounted) AnxToast.show('阅读成果已生成');
    } catch (_) {
      if (mounted) AnxToast.show('生成失败，已保留原有成果');
    } finally {
      if (mounted) setState(() => _generatingSynthesis = false);
    }
  }

  Future<Map<String, dynamic>> _generateStructured({
    required String prompt,
    required String correctionRule,
    required Map<String, dynamic> Function(String response) parser,
  }) async {
    var response = await aiGenerateText(
      [ChatMessage.humanText(prompt)],
      useAgent: false,
      ref: ref,
    );
    try {
      return parser(response);
    } on FormatException {
      response = await aiGenerateText(
        [
          ChatMessage.humanText('''下面返回未通过格式校验。请纠正后只输出合法 JSON，不要解释。
$correctionRule
原始任务：$prompt
待纠正返回：$response'''),
        ],
        useAgent: false,
        ref: ref,
      );
      return parser(response);
    }
  }

  List<TocItem> _flattenToc(List<TocItem> items) => [
        for (final item in items) ...[
          item,
          ..._flattenToc(item.subitems),
        ],
      ];

  Future<void> _generateQuiz(ChapterQuiz quiz) async {
    final content = await widget.onFetchChapter?.call(quiz.chapterHref) ?? '';
    if (!mounted || content.trim().isEmpty) {
      AnxToast.show('无法读取章节内容');
      return;
    }
    AnxToast.show('正在生成 3 道选择题');
    final prompt = '''根据下面章节生成 3 道低输入阅读自测题。
只输出 JSON 数组，不要 Markdown。每项格式：
{"id":"q1","question":"问题","options":["选项1","选项2","选项3","暂不确定"],"correct":["选项1"],"multiple":false}
要求：问题依次覆盖主旨、论证路径、联系或批评；每题 3-5 个短选项；必须包含“暂不确定”；错误项来自常见误解。
章节：${quiz.chapterTitle ?? ''}
正文：$content''';
    var response = await aiGenerateText(
      [ChatMessage.humanText(prompt)],
      useAgent: false,
      ref: ref,
    );
    if (!mounted) return;
    try {
      List<Map<String, dynamic>> questions;
      try {
        questions = parseChapterQuizResponse(response);
      } on FormatException {
        response = await aiGenerateText(
          [
            ChatMessage.humanText('''下面返回未通过格式校验。请纠正后只输出合法 JSON 数组，不要解释。
必须恰好 3 题，每题 id 唯一，包含 question、3-5 个 options、correct 和 multiple；options 必须包含“暂不确定”，correct 必须来自 options。
原始任务：$prompt
待纠正返回：$response'''),
          ],
          useAgent: false,
          ref: ref,
        );
        questions = parseChapterQuizResponse(response);
      }
      await ref.read(readingCoachProvider(quiz.bookId).notifier).saveQuiz(
            ChapterQuiz(
              id: quiz.id,
              bookId: quiz.bookId,
              chapterHref: quiz.chapterHref,
              chapterTitle: quiz.chapterTitle,
              questions: questions,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      if (mounted) AnxToast.show('自测已生成');
    } catch (_) {
      AnxToast.show('题目格式异常，可稍后重试');
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
                      final options = (question['options'] as List)
                          .map((value) => value.toString());
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
                                if (answers[id]
                                            ?.toSet()
                                            .containsAll(expected) ==
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
                                  .read(readingCoachProvider(quiz.bookId)
                                      .notifier)
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
    final actions = widget.controller.mode.agentProfile.actionOrder.take(4);
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.format_quote, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    snapshot.selectedText ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.controller.clearPendingSelection,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final action in actions)
                  ActionChip(
                    label: Text(_actionLabel(action)),
                    onPressed: () {
                      if (action == SelectionAiAction.addNote) {
                        _saveSelectionAsNote(snapshot);
                        return;
                      }
                      final prompt = widget.controller.buildActionPrompt(
                        action,
                      );
                      final started =
                          widget.chatKey.currentState?.sendPrompt(prompt) ??
                              false;
                      if (started) {
                        widget.controller.clearPendingSelection();
                      }
                    },
                  ),
                ActionChip(
                  avatar: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('深度分析'),
                  onPressed: () => _openAnalysisConfig(snapshot),
                ),
                ActionChip(
                  avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: const Text('暂存难点'),
                  onPressed: () => _saveDifficulty(snapshot),
                ),
              ],
            ),
            if (_showAnalysisConfig) ...[
              const Divider(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                ),
                child: SingleChildScrollView(
                  child: _buildAnalysisConfig(snapshot),
                ),
              ),
            ],
          ],
        ),
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
    final started = widget.chatKey.currentState?.sendPrompt(prompt) ?? false;
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
        title: const Text('专家与来源'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
    if (entry.bookId != null && entry.bookId != widget.controller.bookId) {
      final openBook = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('这是另一本书的会话'),
          content: Text(
            widget.onOpenBookSession == null
                ? '会话属于《${entry.bookTitle ?? ''}》。当前版本需先从书架打开该书，才能恢复当时的阅读位置；也可以只恢复对话。'
                : '是否打开《${entry.bookTitle ?? ''}》并恢复当时的阅读上下文？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('仅恢复对话'),
            ),
            if (widget.onOpenBookSession != null)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('打开该书'),
              ),
          ],
        ),
      );
      if (openBook == true && widget.onOpenBookSession != null) {
        await widget.onOpenBookSession!(entry);
        return;
      }
    }
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

  Future<void> _updateGuide(InspectionReadingGuide guide) {
    return ref
        .read(readingCoachProvider(widget.controller.bookId).notifier)
        .saveGuide(guide);
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

  Future<void> _saveDifficulty(ReadingContextSnapshot snapshot) async {
    final text = snapshot.selectedText?.trim() ?? '';
    final cfi = snapshot.metadata['cfi']?.toString() ?? '';
    if (text.isEmpty || cfi.isEmpty) {
      AnxToast.show('无法读取选区位置');
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final difficulty = ReadingDifficulty(
      id: '${widget.controller.bookId}-$now',
      bookId: widget.controller.bookId,
      cfi: cfi,
      text: text,
      chapterHref: snapshot.chapterHref,
      chapterTitle: snapshot.chapterTitle,
      context: snapshot.surroundingText,
      createdAt: now,
      updatedAt: now,
    );
    final saved = await ref
        .read(readingCoachProvider(widget.controller.bookId).notifier)
        .saveDifficulty(difficulty);
    if (!mounted) return;
    widget.onDifficultySaved?.call(saved);
    widget.controller.clearPendingSelection();
    AnxToast.show(saved.id == difficulty.id ? '已暂存难点' : '该难点已存在');
  }

  Widget _buildDifficultyTile(ReadingDifficulty item) {
    final resolved = item.status == ReadingDifficultyStatus.resolved;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        resolved ? Icons.check_circle_outline : Icons.more_horiz,
      ),
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
        },
        itemBuilder: (context) => [
          for (final type in ReadingDifficultyType.values)
            PopupMenuItem(
              value: type.name,
              child: Text(_difficultyTypeLabel(type)),
            ),
          if (!resolved) const PopupMenuDivider(),
          if (!resolved)
            const PopupMenuItem(
              value: 'resolve',
              child: Text('标记为已解决'),
            ),
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
          ReadingMemoryTopic item, ReadingMemoryItemStatus status) =>
      ref
          .read(readingMemoryProvider(widget.controller.bookId).notifier)
          .setTopicStatus(item, status);

  Future<void> _setCardStatus(
          ReadingKnowledgeCard item, ReadingMemoryItemStatus status) =>
      ref
          .read(readingMemoryProvider(widget.controller.bookId).notifier)
          .setCardStatus(item, status);

  Future<void> _rateCard(
      ReadingKnowledgeCard card, ReadingReviewRating rating) async {
    await ref
        .read(readingMemoryProvider(widget.controller.bookId).notifier)
        .review(card, rating);
    if (mounted) {
      setState(() {
        _revealedCards.remove(card.id);
        _reviewedCardAwaitingAdvance = card.id;
      });
    }
  }

  Future<void> _showMemorySources(
      List<String> ids, List<ReadingMemorySource> sources) async {
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
          Text(l10n.readingMemoryOriginalSources,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final source in selected)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(source.chapterTitle ??
                  ((source.isAvailable &&
                          (source.cfi?.isNotEmpty == true ||
                              source.chapterHref?.isNotEmpty == true))
                      ? l10n.readingMemoryUntitledChapter
                      : l10n.readingMemoryLocationUnavailable)),
              subtitle: Text(source.text,
                  maxLines: 4, overflow: TextOverflow.ellipsis),
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
                      widget.onNavigateChapter
                          ?.call(source.cfi ?? source.chapterHref!);
                    }
                  : null,
            ),
        ],
      )),
    );
  }

  Map<String, List<ReadingCardReview>> _groupReviews(
      List<ReadingCardReview> reviews) {
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(L10n.of(context).commonSaveSuccess),
      action: SnackBarAction(
        label: '撤销',
        onPressed: () => ReadingNoteCaptureService().undo(document.note.id),
      ),
    ));
  }

  Future<void> _saveAnswerAsNote(String answer) async {
    final snapshot = widget.controller.lastSelection;
    if (snapshot == null) {
      AnxToast.show('请先从阅读页选择一段内容');
      return;
    }
    final sessionId = ref.read(aiChatProvider.notifier).currentSessionId;
    final entry = ref
        .read(aiHistoryProvider)
        .asData
        ?.value
        .where((item) => item.id == sessionId)
        .firstOrNull;
    final sourceLines = entry?.citations
            .map((source) => source['url']?.toString())
            .whereType<String>()
            .take(3)
            .join('\n') ??
        '';
    final analysisLine = entry?.analysisDepth == null
        ? ''
        : '深度分析：${_analysisDepthLabel(ReadingAnalysisDepth.fromJson(entry!.analysisDepth))} · ${entry.frameworks.map((value) {
            final framework = ReadingFramework.fromJson(value);
            return framework == null
                ? value
                : const ReadingFrameworkRegistry().get(framework).label;
          }).join('、')}\n';
    final normalized = answer.replaceAll(RegExp(r'\s+'), ' ').trim();
    final summary = normalized.length <= 480
        ? normalized
        : '${normalized.substring(0, 480)}...';
    final now = DateTime.now();
    if (Prefs().readingAgentBetaEnabled && readingAgentRuntime.isActive) {
      final sourceText = snapshot.selectedText?.trim() ?? '';
      final cfi = snapshot.metadata['cfi']?.toString() ?? '';
      if (sourceText.isEmpty || cfi.isEmpty) {
        AnxToast.show('请先从阅读页选择一段内容');
        return;
      }
      await agentActionService.createSourcedNote(
        bookId: widget.controller.bookId,
        sourceText: sourceText,
        cfi: cfi,
        chapterTitle: snapshot.chapterTitle ?? '',
        chapterHref: snapshot.chapterHref,
        body: 'AI 摘要：$summary\n'
            '$analysisLine'
            '${sourceLines.isEmpty ? '' : '来源：\n$sourceLines\n'}'
            '会话：anx-ai-session://${sessionId ?? ''}',
        model: 'ai-workspace',
      );
      if (mounted) AnxToast.show(L10n.of(context).commonSaveSuccess);
      return;
    }
    await bookNoteDao.save(
      BookNote(
        bookId: widget.controller.bookId,
        content: snapshot.selectedText ?? '',
        cfi: snapshot.metadata['cfi']?.toString() ?? '',
        chapter: snapshot.chapterTitle ?? '',
        type: 'highlight',
        color: Prefs().annotationColor,
        readerNote: 'AI 摘要：$summary\n'
            '$analysisLine'
            '${sourceLines.isEmpty ? '' : '来源：\n$sourceLines\n'}'
            '会话：anx-ai-session://${sessionId ?? ''}',
        createTime: now,
        updateTime: now,
      ),
    );
    if (mounted) AnxToast.show(L10n.of(context).commonSaveSuccess);
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
