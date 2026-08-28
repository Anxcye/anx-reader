import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/page/reading_agent_help_page.dart';
import 'package:anx_reader/page/fiction_character_graph_page.dart';
import 'package:anx_reader/page/fiction_story_timeline_page.dart';
import 'package:anx_reader/page/book_wiki_page.dart';
import 'package:anx_reader/service/ai/fiction_story_atlas_service.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/service/ai/reading_experience_profile_service.dart';
import 'package:anx_reader/service/ai/reading_coach_repository.dart';
import 'package:anx_reader/service/ai/reading_outcomes_service.dart';
import 'package:anx_reader/service/ai/reading_skills.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/markdown/styled_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadingOutcomesPage extends ConsumerStatefulWidget {
  const ReadingOutcomesPage({
    super.key,
    required this.book,
    this.onOpenLocation,
    this.service,
    this.closureTypeOverride,
    this.closureIdOverride,
    this.closureRegistry = const ReadingClosurePolicyRegistry(),
    this.onOrganizeStoryArchive,
  });

  final Book book;

  /// When opened above an active reader, lets the caller close this page and
  /// navigate the existing WebView instead of starting a second reader.
  final Future<void> Function(String cfi)? onOpenLocation;
  final ReadingOutcomesService? service;
  // ignore: deprecated_member_use_from_same_package
  final ReadingClosureType? closureTypeOverride;
  final String? closureIdOverride;
  final ReadingClosurePolicyRegistry closureRegistry;
  final Future<void> Function()? onOrganizeStoryArchive;

  @override
  ConsumerState<ReadingOutcomesPage> createState() =>
      _ReadingOutcomesPageState();
}

class _ReadingOutcomesPageState extends ConsumerState<ReadingOutcomesPage> {
  late Future<ReadingOutcomesSnapshot> _snapshot;
  final _coachRepository = ReadingCoachRepository();
  BookReadingProfile? _readingProfile;

  @override
  void initState() {
    super.initState();
    _snapshot = (widget.service ?? readingOutcomesService).load(widget.book.id);
    if (widget.service == null && widget.closureIdOverride == null) {
      _loadReadingProfile();
    }
  }

  Future<void> _loadReadingProfile() async {
    final mode = Prefs().readingAiModeForBook(widget.book.id);
    final detected =
        ReadingClosurePolicyMatcher(registry: widget.closureRegistry).detect(
      mode: mode,
      title: widget.book.title,
      author: widget.book.author,
      description: widget.book.description ?? '',
    );
    final profile = await readingExperienceProfileService.loadOrCreate(
      bookId: widget.book.id,
      detectedModuleId: detected.moduleId,
      detectedFacets: detected.facets,
      confidence: detected.confidence,
      legacyPreference: Prefs().readingClosureIdForBook(widget.book.id),
    );
    Prefs().removeLegacyReadingClosureForBook(widget.book.id);
    if (mounted) setState(() => _readingProfile = profile);
  }

  Future<void> _setClosureModule(String? id) async {
    final mode = Prefs().readingAiModeForBook(widget.book.id);
    final detected =
        ReadingClosurePolicyMatcher(registry: widget.closureRegistry).detect(
      mode: mode,
      title: widget.book.title,
      author: widget.book.author,
      description: widget.book.description ?? '',
    );
    final profile = id == null
        ? await readingExperienceProfileService.setAutomatic(
            bookId: widget.book.id,
            detectedModuleId: detected.moduleId,
            detectedFacets: detected.facets,
            confidence: detected.confidence,
          )
        : await readingExperienceProfileService.setPinned(
            bookId: widget.book.id,
            moduleId: id,
            facets: _readingProfile?.facets ?? detected.facets,
          );
    if (mounted) setState(() => _readingProfile = profile);
  }

  Future<void> _reload() async {
    final next =
        (widget.service ?? readingOutcomesService).load(widget.book.id);
    setState(() => _snapshot = next);
    await next;
  }

  Future<void> _organizeStoryArchive() async {
    final callback = widget.onOrganizeStoryArchive;
    if (callback == null) {
      AnxToast.show('请从阅读页打开本书阅读成果后整理已读章节');
      return;
    }
    await callback();
    if (mounted) await _reload();
  }

  Future<void> _openLocation(String cfi) async {
    if (cfi.isEmpty) return;
    final callback = widget.onOpenLocation;
    if (callback != null) {
      await callback(cfi);
      return;
    }
    if (!mounted) return;
    await pushToReadingPage(ref, context, widget.book, cfi: cfi);
  }

  Future<void> _resolveDifficulty(ReadingDifficulty difficulty) async {
    await _coachRepository.updateDifficulty(difficulty.copyWith(
      status: ReadingDifficultyStatus.resolved,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    if (!mounted) return;
    AnxToast.show('已标记为解决');
    await _reload();
  }

  Future<void> _reviewCard(KnowledgeCard card, bool remembered) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final interval = remembered ? (card.intervalDays * 2).clamp(2, 60) : 1;
    await readingAgentRepository.saveKnowledgeCard(card.copyWith(
      intervalDays: interval,
      repetitions: card.repetitions + 1,
      dueAt: now + Duration(days: interval).inMilliseconds,
      updatedAt: now,
    ));
    if (!mounted) return;
    AnxToast.show(remembered ? '$interval 天后再次复习' : '明天再次复习');
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本书阅读成果'),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<ReadingOutcomesSnapshot>(
        future: _snapshot,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LoadError(error: snapshot.error, onRetry: _reload);
          }
          return _buildContent(snapshot.requireData);
        },
      ),
    );
  }

  Widget _buildContent(ReadingOutcomesSnapshot state) {
    final dueIds = state.dueCards.map((card) => card.id).toSet();
    ReadingAiMode mode;
    ReadingSkillId? pinnedSkill;
    String? pinnedClosureId;
    try {
      mode = Prefs().readingAiModeForBook(widget.book.id);
      pinnedSkill = Prefs().readingSkillForBook(widget.book.id);
      pinnedClosureId = widget.closureIdOverride ??
          widget.closureTypeOverride?.stableId ??
          (_readingProfile?.pinned == true
              ? _readingProfile!.primaryModuleId
              : null);
    } catch (_) {
      // Widget tests and previews may intentionally build before preferences.
      mode = ReadingAiMode.general;
      pinnedClosureId =
          widget.closureIdOverride ?? widget.closureTypeOverride?.stableId;
    }
    final skill = const ReadingSkillMatcher().match(
      mode: mode,
      title: widget.book.title,
      author: widget.book.author,
      description: widget.book.description ?? '',
      pinnedSkill: pinnedSkill,
    );
    final closure = ReadingClosurePolicyMatcher(
      registry: widget.closureRegistry,
    ).match(
      mode: mode,
      title: widget.book.title,
      author: widget.book.author,
      description: widget.book.description ?? '',
      pinnedId: pinnedClosureId,
    );
    final atlas = fictionStoryAtlasService.fromArtifacts(
      state.artifacts,
      visibleAtProgress: widget.book.readingPercentage,
    );
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _OutcomeHero(book: widget.book, state: state, closure: closure),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('书籍 Wiki'),
              subtitle: const Text('把阅读成果、概念、人物和来源组织成可浏览百科'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BookWikiPage(
                    book: widget.book,
                    visibleProgress: widget.book.readingPercentage),
              )),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: Text(closure.title),
              subtitle: Text(
                '${pinnedClosureId == null ? '自动匹配' : '本书固定'} · ${closure.description}',
              ),
              trailing: PopupMenuButton<String>(
                tooltip: '切换本书阅读闭环',
                onSelected: (value) async {
                  await _setClosureModule(value == 'auto' ? null : value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'auto', child: Text('自动匹配')),
                  for (final item in widget.closureRegistry.definitions)
                    PopupMenuItem(value: item.id, child: Text(item.title)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.auto_stories_outlined),
              title: Text(skill.primary.title),
              subtitle: Text(
                '${skill.pinned ? '本书固定' : '自动匹配'} · ${skill.primary.description}\n'
                '可形成：${skill.primary.closureContributions.map(_contributionLabel).join('、')}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.help_outline),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReadingSkillHelpPage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (closure.supports(ReadingClosureCapability.storyAtlas)) ...[
            _buildStoryAtlasCard(atlas),
            const SizedBox(height: 16),
          ],
          if (state.isEmpty) _buildEmptyState(),
          for (final section in closure.outcomeSections)
            if (section.visibleWhenEmpty ||
                _outcomeCount(section.source, state) > 0)
              _buildOutcomeSection(
                section: section,
                closure: closure,
                state: state,
                dueIds: dueIds,
              ),
        ],
      ),
    );
  }

  Widget _buildStoryAtlasCard(FictionStoryAtlas atlas) {
    final unresolved = atlas.timeline.where((event) => event.isMystery).length;
    final coverage = atlas.coverageStart == null
        ? '尚未建档'
        : '${(atlas.coverageStart! * 100).round()}%～${(atlas.coverageEnd! * 100).round()}%';
    final lastUpdated = atlas.lastIngestedAt == null
        ? '尚未整理'
        : _shortDate(atlas.lastIngestedAt!);
    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.menu_book_outlined,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text('小说故事档案',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Text('安全边界 ${(widget.book.readingPercentage * 100).round()}%',
                style: Theme.of(context).textTheme.labelMedium),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _AtlasMetric(label: '人物', value: atlas.characters.length),
            _AtlasMetric(label: '关系', value: atlas.relationships.length),
            _AtlasMetric(label: '事件', value: atlas.timeline.length),
            _AtlasMetric(label: '未解', value: unresolved),
          ]),
          const SizedBox(height: 12),
          Text('档案覆盖 $coverage · 最近整理 $lastUpdated',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FictionCharacterGraphPage(
                  book: widget.book,
                  initialAtlas: atlas,
                  arcId: atlas.arcId,
                  onOpenLocation: _openLocation,
                  onRequestOrganize: widget.onOrganizeStoryArchive == null
                      ? null
                      : _organizeStoryArchive,
                ),
              )),
              icon: const Icon(Icons.hub_outlined),
              label: const Text('人物关系图'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FictionStoryTimelinePage(
                  book: widget.book,
                  initialAtlas: atlas,
                  arcId: atlas.arcId,
                  readingProfile: _readingProfile,
                  onOpenLocation: _openLocation,
                  onRequestOrganize: widget.onOrganizeStoryArchive == null
                      ? null
                      : _organizeStoryArchive,
                ),
              )),
              icon: const Icon(Icons.timeline),
              label: const Text('故事时间线'),
            ),
            OutlinedButton.icon(
              onPressed: _organizeStoryArchive,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('整理/更新故事档案'),
            ),
          ]),
          const SizedBox(height: 8),
          Text('打开图谱不会调用 AI；只有确认整理已读范围后才会读取正文。',
              style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }

  String _shortDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    return '${date.month}月${date.day}日';
  }

  int _outcomeCount(
          ReadingOutcomeSource source, ReadingOutcomesSnapshot state) =>
      switch (source) {
        ReadingOutcomeSource.goals => state.goals.length,
        ReadingOutcomeSource.checkpoints => state.pendingCheckpoints.length,
        ReadingOutcomeSource.mastery => state.masteryStates.length,
        ReadingOutcomeSource.difficulties =>
          state.unresolvedDifficulties.length,
        ReadingOutcomeSource.knowledgeCards => state.activeCards.length,
        ReadingOutcomeSource.memories => state.memories.length,
        ReadingOutcomeSource.artifacts => _visibleArtifacts(state).length,
      };

  Widget _buildOutcomeSection({
    required ReadingOutcomeSectionSpec section,
    required ReadingClosurePolicyDefinition closure,
    required ReadingOutcomesSnapshot state,
    required Set<String> dueIds,
  }) {
    final icon = switch (section.source) {
      ReadingOutcomeSource.goals => Icons.flag_outlined,
      ReadingOutcomeSource.checkpoints => Icons.fact_check_outlined,
      ReadingOutcomeSource.mastery => Icons.insights_outlined,
      ReadingOutcomeSource.difficulties => Icons.help_outline,
      ReadingOutcomeSource.knowledgeCards => Icons.style_outlined,
      ReadingOutcomeSource.memories => Icons.description_outlined,
      ReadingOutcomeSource.artifacts => Icons.account_tree_outlined,
    };
    final children = switch (section.source) {
      ReadingOutcomeSource.goals => <Widget>[
          for (final goal in state.goals) _GoalTile(goal: goal),
        ],
      ReadingOutcomeSource.checkpoints => <Widget>[
          for (final checkpoint in state.pendingCheckpoints)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_chapterTitle(
                  checkpoint.chapterTitle, checkpoint.chapterHref)),
              subtitle: Text(
                '离开时读到 ${(checkpoint.progress * 100).round()}% · 回到阅读页${closure.checkpointAction}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: checkpoint.chapterHref.isEmpty
                  ? null
                  : () => _openLocation(checkpoint.chapterHref),
            ),
        ],
      ReadingOutcomeSource.mastery => <Widget>[
          for (final mastery in state.masteryStates)
            _MasteryTile(
              mastery: mastery,
              options: closure.checkpoint.masteryOptions,
              onOpen: mastery.chapterHref?.isNotEmpty == true
                  ? () => _openLocation(mastery.chapterHref!)
                  : null,
            ),
        ],
      ReadingOutcomeSource.difficulties => <Widget>[
          for (final difficulty in state.unresolvedDifficulties)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(difficulty.text,
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              subtitle: Text(difficulty.chapterTitle ?? '未知章节'),
              onTap: () => _openLocation(difficulty.cfi),
              trailing: IconButton(
                tooltip: '标记已解决',
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _resolveDifficulty(difficulty),
              ),
            ),
        ],
      ReadingOutcomeSource.knowledgeCards => <Widget>[
          for (final card in state.activeCards)
            _KnowledgeCardTile(
              card: card,
              isDue: dueIds.contains(card.id),
              onReview: (remembered) => _reviewCard(card, remembered),
            ),
        ],
      ReadingOutcomeSource.memories => <Widget>[
          for (final memory in state.memories)
            _MemoryTile(
              memory: memory,
              onOpenSource: (source) => _openLocation(source),
            ),
        ],
      ReadingOutcomeSource.artifacts => <Widget>[
          for (final artifact in _visibleArtifacts(state))
            _ArtifactTile(artifact: artifact, onOpenSource: _openLocation),
        ],
    };
    return _Section(
      icon: icon,
      title: section.title,
      count: _outcomeCount(section.source, state),
      badge: section.source == ReadingOutcomeSource.knowledgeCards &&
              state.dueCards.isNotEmpty
          ? '${state.dueCards.length} 到期'
          : null,
      emptyText: section.emptyText,
      children: children,
    );
  }

  List<ReadingArtifact> _visibleArtifacts(ReadingOutcomesSnapshot state) =>
      state.artifacts
          .where(
              (item) => item.isVisibleAtProgress(widget.book.readingPercentage))
          .toList(growable: false);

  String _contributionLabel(String value) => switch (value) {
        'checkpoint' => '章节检查',
        'mastery' => '掌握度',
        'difficulty' => '未解决问题',
        'knowledgeCard' => '复习卡',
        'markdownMemory' => 'Markdown 记忆',
        'goal' => '阅读目标',
        _ => value,
      };

  Widget _buildEmptyState() {
    return Card.filled(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome_outlined, size: 34),
            const SizedBox(height: 10),
            Text(
              '从下一次阅读开始形成成果',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              Prefs().readingAgentBetaEnabled
                  ? '创建目标、完成一次章节检查，成果会自动汇总到这里。'
                  : '请先在“设置 → AI 设置”中启用阅读 Agent Beta。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openLocation(widget.book.lastReadPosition),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('继续阅读'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtlasMetric extends StatelessWidget {
  const _AtlasMetric({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$label $value'),
      );
}

class _OutcomeHero extends StatelessWidget {
  const _OutcomeHero({
    required this.book,
    required this.state,
    required this.closure,
  });

  final Book book;
  final ReadingOutcomesSnapshot state;
  final ReadingClosurePolicyDefinition closure;

  @override
  Widget build(BuildContext context) {
    final goal = state.activeGoal;
    final next = closure.immersive
        ? goal != null
            ? '继续“${goal.title}”'
            : state.unresolvedDifficulties.isNotEmpty
                ? '保留沉浸感，按需查看未解悬念'
                : '继续沉浸阅读，不必完成测试'
        : closure.showKnowledgeCards && state.dueCards.isNotEmpty
            ? '先复习 ${state.dueCards.length} 张到期卡片'
            : state.pendingCheckpoints.isNotEmpty
                ? '${closure.checkpointAction} ${state.pendingCheckpoints.length} 个章节'
                : state.unresolvedDifficulties.isNotEmpty
                    ? '处理 ${state.unresolvedDifficulties.length} 个${closure.difficultyTitle}'
                    : goal != null
                        ? '继续推进“${goal.title}”'
                        : '继续阅读并建立${closure.goalLabel}';
    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('下一步 · $next'),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(
                  label: '阅读进度',
                  value: '${(book.readingPercentage * 100).round()}%',
                ),
                if (closure.showMastery)
                  _Metric(
                    label: closure.heroMasteryLabel,
                    value: state.masteryStates.isEmpty
                        ? '—'
                        : '${(state.masteryProgress * 100).round()}%',
                  )
                else
                  _Metric(
                    label: '故事记忆',
                    value: '${state.memories.length}',
                  ),
                _Metric(
                  label: closure.heroUnresolvedLabel,
                  value: '${state.unresolvedDifficulties.length}',
                ),
                if (closure.showKnowledgeCards)
                  _Metric(label: '到期复习', value: '${state.dueCards.length}')
                else
                  _Metric(
                    label: '可回顾章节',
                    value: '${state.pendingCheckpoints.length}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 112),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.count,
    required this.emptyText,
    required this.children,
    this.badge,
  });

  final IconData icon;
  final String title;
  final int count;
  final String? badge;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (badge != null) ...[
                  Chip(
                      label: Text(badge!),
                      visualDensity: VisualDensity.compact),
                  const SizedBox(width: 8),
                ],
                Text('$count', style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
            Card.outlined(
              margin: EdgeInsets.zero,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: children.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(emptyText),
                      )
                    : Column(children: children),
              ),
            ),
          ],
        ),
      );
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});

  final ReadingGoal goal;

  @override
  Widget build(BuildContext context) {
    final status = switch (goal.status) {
      ReadingGoalStatus.active => '进行中',
      ReadingGoalStatus.completed => '已完成',
      ReadingGoalStatus.abandoned => '已放弃',
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(goal.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(value: goal.progress.clamp(0, 1)),
      ),
      trailing: Text('$status\n${(goal.progress * 100).round()}%',
          textAlign: TextAlign.end),
    );
  }
}

class _MasteryTile extends StatelessWidget {
  const _MasteryTile({
    required this.mastery,
    required this.options,
    this.onOpen,
  });

  final MasteryState mastery;
  final List<ReadingMasteryOptionSpec> options;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    var label = '未评估';
    for (final option in options) {
      if (option.level == mastery.level) label = option.label;
    }
    final color = switch (mastery.level) {
      MasteryLevel.unknown => Theme.of(context).colorScheme.outline,
      MasteryLevel.emerging => Colors.orange,
      MasteryLevel.familiar => Colors.blue,
      MasteryLevel.mastered => Colors.green,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(mastery.topic),
      subtitle: mastery.nextReviewAt == null
          ? null
          : Text('建议复习：${_formatDate(mastery.nextReviewAt!)}'),
      trailing: Chip(
        avatar: Icon(Icons.circle, size: 10, color: color),
        label: Text(label),
        visualDensity: VisualDensity.compact,
      ),
      onTap: onOpen,
    );
  }
}

class _KnowledgeCardTile extends StatelessWidget {
  const _KnowledgeCardTile({
    required this.card,
    required this.isDue,
    required this.onReview,
  });

  final KnowledgeCard card;
  final bool isDue;
  final ValueChanged<bool> onReview;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        leading:
            Icon(isDue ? Icons.notifications_active_outlined : Icons.style),
        title: Text(card.front),
        subtitle: Text(
          isDue
              ? '已到期 · 展开后检查答案'
              : card.dueAt == null
                  ? '未安排复习'
                  : '${_formatDate(card.dueAt!)}复习',
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(card.back),
          ),
          if (isDue) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => onReview(false),
                  child: const Text('再学习'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => onReview(true),
                  child: const Text('记住了'),
                ),
              ],
            ),
          ],
        ],
      );
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.memory, required this.onOpenSource});

  final ReadingMemoryDocument memory;
  final ValueChanged<String> onOpenSource;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 14),
        leading: const Icon(Icons.description_outlined),
        title: Text(memory.title),
        subtitle: Text('更新于 ${_formatDate(memory.updatedAt)}'),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StyledMarkdown(data: memory.markdown),
          ),
          if (memory.sourceRefs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final source in memory.sourceRefs)
                    ActionChip(
                      avatar: const Icon(Icons.open_in_new, size: 16),
                      label:
                          Text('返回来源 ${memory.sourceRefs.indexOf(source) + 1}'),
                      onPressed: () => onOpenSource(source),
                    ),
                ],
              ),
            ),
          ],
        ],
      );
}

class _ArtifactTile extends StatelessWidget {
  const _ArtifactTile({required this.artifact, required this.onOpenSource});

  final ReadingArtifact artifact;
  final ValueChanged<String> onOpenSource;

  @override
  Widget build(BuildContext context) {
    final title = artifact.payload['name']?.toString() ??
        artifact.payload['question']?.toString() ??
        artifact.payload['title']?.toString() ??
        artifact.kind;
    final summary = artifact.payload['summary']?.toString() ??
        artifact.payload['currentTheory']?.toString() ??
        '';
    final source = artifact.sourceStartCfi ?? artifact.chapterHref;
    final evidenceLabel = switch (artifact.epistemicStatus) {
      ReadingArtifactEpistemicStatus.textFact => '文本事实',
      ReadingArtifactEpistemicStatus.userReflection => '读者记录',
      ReadingArtifactEpistemicStatus.agentInference => 'AI 推测',
      ReadingArtifactEpistemicStatus.externalFact => '外部资料',
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(artifact.kind == ReadingArtifactKinds.character
          ? Icons.person_outline
          : artifact.kind == ReadingArtifactKinds.mystery
              ? Icons.help_outline
              : Icons.bookmark_outline),
      title: Text(title),
      subtitle: Text(
        [if (summary.isNotEmpty) summary, evidenceLabel].join(' · '),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: source == null ? null : const Icon(Icons.chevron_right),
      onTap: source == null ? null : () => onOpenSource(source),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 36),
              const SizedBox(height: 12),
              const Text('阅读成果加载失败'),
              const SizedBox(height: 4),
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ),
        ),
      );
}

String _chapterTitle(String title, String href) =>
    title.trim().isEmpty ? href : title;

String _formatDate(int milliseconds) {
  final date = DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
  return '${date.month}月${date.day}日';
}
