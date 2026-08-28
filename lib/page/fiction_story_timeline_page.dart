import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/fiction_story_atlas_service.dart';
import 'package:anx_reader/service/ai/reading_experience_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _StoryTimelineView { story, mystery, character, relationship }

class FictionStoryTimelinePage extends StatefulWidget {
  const FictionStoryTimelinePage({
    super.key,
    required this.book,
    this.onOpenLocation,
    this.onRequestOrganize,
    this.initialAtlas,
    this.arcId,
    this.readingProfile,
  });

  final Book book;
  final Future<void> Function(String cfi)? onOpenLocation;
  final VoidCallback? onRequestOrganize;
  final FictionStoryAtlas? initialAtlas;
  final String? arcId;
  final BookReadingProfile? readingProfile;

  @override
  State<FictionStoryTimelinePage> createState() =>
      _FictionStoryTimelinePageState();
}

class _FictionStoryTimelinePageState extends State<FictionStoryTimelinePage> {
  late Future<FictionStoryAtlas> _future;
  FictionStoryAtlas? _atlas;
  FictionTimelineDensity _density = FictionTimelineDensity.compact;
  _StoryTimelineView _view = _StoryTimelineView.story;
  final Set<String> _kinds = {};
  String? _participant;
  final Set<String> _expandedChapters = {};
  String? _expandedForSignature;
  int _chapterPage = 1;
  String? _lastViewedChapter;
  bool _restoreJumpPending = false;
  final Map<String, GlobalKey> _chapterKeys = {};
  BookReadingProfile? _profile;
  String? _selectedStoryTrack;

  @override
  void initState() {
    super.initState();
    _future = widget.initialAtlas != null
        ? Future.value(widget.initialAtlas)
        : fictionStoryAtlasService.load(
            bookId: widget.book.id,
            visibleAtProgress: widget.book.readingPercentage,
            arcId: widget.arcId,
          );
    _profile = widget.readingProfile ??
        readingExperienceProfileService.cached(widget.book.id);
    _selectedStoryTrack = _profile?.defaultStoryTrack;
    _restoreLastViewedChapter();
  }

  String get _lastViewedKey =>
      'fictionTimelineLastViewedChapter:${widget.book.id}';

  Future<void> _restoreLastViewedChapter() async {
    final prefs = await SharedPreferences.getInstance();
    final chapter = prefs.getString(_lastViewedKey);
    if (!mounted || chapter == null || chapter.isEmpty) return;
    setState(() {
      _lastViewedChapter = chapter;
      _restoreJumpPending = true;
      _expandedForSignature = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('故事事件时间线')),
        body: FutureBuilder<FictionStoryAtlas>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('无法读取故事档案：${snapshot.error}'));
            }
            final atlas = snapshot.requireData;
            _atlas = atlas;
            if (atlas.timeline.isEmpty) return _emptyState(atlas);
            return AnimatedSwitcher(
              duration: _motionDuration,
              child: KeyedSubtree(
                key: ValueKey(_view),
                child: _timelineBody(atlas),
              ),
            );
          },
        ),
      );

  Duration get _motionDuration => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 240);

  Widget _emptyState(FictionStoryAtlas atlas) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timeline,
                  size: 52, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 14),
              Text('还没有故事事件', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '时间线按正文中遇到事件的顺序展示，不会猜测绝对日期，也不会读取后文。',
                textAlign: TextAlign.center,
              ),
              if (widget.onRequestOrganize != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: widget.onRequestOrganize,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('整理已读部分'),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _boundaryBanner(FictionStoryAtlas atlas) => Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            const Icon(Icons.shield_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                atlas.lastOrganizedProgress == null
                    ? '正文顺序 · 安全边界 ${(atlas.visibleProgress * 100).round()}%'
                    : '正文顺序 · 安全边界 ${(atlas.visibleProgress * 100).round()}% · 上次整理 ${(atlas.lastOrganizedProgress! * 100).round()}%',
              ),
            ),
          ]),
        ),
      );

  Widget _timelineBody(FictionStoryAtlas atlas) {
    var sourceEvents = _view == _StoryTimelineView.relationship
        ? fictionStoryAtlasService.relationshipTimeline(atlas)
        : atlas.timeline;
    if (_view == _StoryTimelineView.story && _selectedStoryTrack != null) {
      final preferred = _selectedStoryTrack!;
      final preferredEvents = sourceEvents.where((event) {
        final raw = event.source.payload['track'];
        return raw == null || FictionEventTrackIds.normalize(raw) == preferred;
      }).toList(growable: false);
      // A profile should never make a valid archive appear empty. If this
      // track has no data yet, show the complete story until it is populated.
      if (preferredEvents.isNotEmpty) sourceEvents = preferredEvents;
    }
    if (_view == _StoryTimelineView.mystery) {
      return _mysteryTimelineBody(atlas);
    }
    final chapters = fictionStoryAtlasService.timelineChapters(
      sourceEvents,
      density: _view == _StoryTimelineView.relationship
          ? FictionTimelineDensity.complete
          : _density,
      kinds: _kinds,
      participant: _view == _StoryTimelineView.character ? _participant : null,
    );
    final signature =
        '${_view.name}|${_density.name}|${_kinds.join(',')}|$_participant';
    if (_expandedForSignature != signature) {
      _expandedForSignature = signature;
      _expandedChapters
        ..clear()
        ..addAll(_nearbyChapterIds(chapters));
      final lastIndex =
          chapters.indexWhere((item) => item.id == _lastViewedChapter);
      final focusIndex =
          lastIndex >= 0 ? lastIndex : _currentChapterIndex(chapters);
      _chapterPage = focusIndex < 0 ? 1 : (focusIndex ~/ 20) + 1;
      if (lastIndex >= 0) _expandedChapters.add(chapters[lastIndex].id);
    }
    final totalPages = chapters.isEmpty ? 1 : ((chapters.length - 1) ~/ 20) + 1;
    _chapterPage = _chapterPage.clamp(1, totalPages);
    final visibleChapters =
        chapters.skip((_chapterPage - 1) * 20).take(20).toList(growable: false);
    final currentChapterId = _currentChapterId(chapters);
    if (_restoreJumpPending &&
        visibleChapters.any((chapter) => chapter.id == _lastViewedChapter)) {
      _restoreJumpPending = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final chapterContext = _chapterKeys[_lastViewedChapter]?.currentContext;
        if (chapterContext != null) {
          Scrollable.ensureVisible(
            chapterContext,
            alignment: .1,
            duration: _motionDuration,
          );
        }
      });
    }
    return Column(
      children: [
        _boundaryBanner(atlas),
        _timelineControls(atlas, chapters.length),
        if (chapters.isNotEmpty) _stageOverview(chapters),
        if (chapters.isNotEmpty) _pageControls(totalPages),
        Expanded(
          child: chapters.isEmpty
              ? Center(
                  child: Text(
                    '当前筛选和显示密度下没有事件，试试切换为“标准”或“完整”。',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  key: const PageStorageKey('fiction-story-timeline'),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
                  itemCount: visibleChapters.length,
                  itemBuilder: (context, index) {
                    final chapter = visibleChapters[index];
                    final previous =
                        index == 0 ? null : visibleChapters[index - 1];
                    final boundary = atlas.lastOrganizedProgress;
                    final crossesBoundary = boundary != null &&
                        chapter.startProgress > boundary &&
                        (previous == null ||
                            previous.startProgress <= boundary);
                    return Column(children: [
                      if (crossesBoundary) _organizedBoundary(boundary),
                      _chapterSection(
                        chapter,
                        isCurrent: chapter.id == currentChapterId,
                      ),
                    ]);
                  },
                ),
        ),
      ],
    );
  }

  Set<String> _nearbyChapterIds(List<FictionTimelineChapter> chapters) {
    if (chapters.isEmpty) return {};
    final current =
        _currentChapterIndex(chapters).clamp(0, chapters.length - 1);
    return {
      for (var index = (current - 1).clamp(0, chapters.length - 1);
          index <= (current + 1).clamp(0, chapters.length - 1);
          index++)
        chapters[index].id,
    };
  }

  int _currentChapterIndex(List<FictionTimelineChapter> chapters) {
    var current = -1;
    for (var index = 0; index < chapters.length; index++) {
      if (chapters[index].startProgress <= widget.book.readingPercentage) {
        current = index;
      }
    }
    return current;
  }

  String? _currentChapterId(List<FictionTimelineChapter> chapters) {
    final index = _currentChapterIndex(chapters);
    return index < 0 ? null : chapters[index].id;
  }

  Widget _pageControls(int totalPages) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(children: [
          IconButton(
            tooltip: '上一组章节',
            onPressed:
                _chapterPage <= 1 ? null : () => setState(() => _chapterPage--),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              '章节页 $_chapterPage / $totalPages',
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            tooltip: '下一组章节',
            onPressed: _chapterPage >= totalPages
                ? null
                : () => setState(() => _chapterPage++),
            icon: const Icon(Icons.chevron_right),
          ),
        ]),
      );

  Widget _timelineControls(FictionStoryAtlas atlas, int chapterCount) {
    final participants = <String>{
      for (final event in atlas.timeline) ...event.participants,
    }.toList()
      ..sort();
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final entry in const {
                _StoryTimelineView.story: '故事主线',
                _StoryTimelineView.mystery: '悬念线索',
                _StoryTimelineView.character: '人物故事线',
                _StoryTimelineView.relationship: '关系变化',
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: _view == entry.key,
                    onSelected: (_) => setState(() {
                      _view = entry.key;
                      _kinds.clear();
                      if (_view == _StoryTimelineView.character) {
                        _density = FictionTimelineDensity.standard;
                      } else if (_view == _StoryTimelineView.relationship) {
                        _density = FictionTimelineDensity.complete;
                      }
                      if (_view != _StoryTimelineView.character) {
                        _participant = null;
                      }
                    }),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 6),
          Row(children: [
            const Text('显示密度'),
            const SizedBox(width: 8),
            Expanded(
              child: SegmentedButton<FictionTimelineDensity>(
                segments: const [
                  ButtonSegment(
                      value: FictionTimelineDensity.compact, label: Text('精简')),
                  ButtonSegment(
                      value: FictionTimelineDensity.standard,
                      label: Text('标准')),
                  ButtonSegment(
                      value: FictionTimelineDensity.complete,
                      label: Text('完整')),
                ],
                selected: {_density},
                onSelectionChanged: (value) =>
                    setState(() => _density = value.first),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          if (_view == _StoryTimelineView.character && participants.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _participant,
              decoration: const InputDecoration(
                labelText: '选择人物',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: participants
                  .map((name) =>
                      DropdownMenuItem(value: name, child: Text(name)))
                  .toList(growable: false),
              onChanged: (value) => setState(() => _participant = value),
            ),
          if (_view == _StoryTimelineView.story)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  FilterChip(
                    label: const Text('全部故事线'),
                    selected: _selectedStoryTrack == null,
                    onSelected: (_) =>
                        setState(() => _selectedStoryTrack = null),
                  ),
                  for (final entry in const {
                    FictionEventTrackIds.caseInvestigation: '案件线',
                    FictionEventTrackIds.family: '家庭线',
                    FictionEventTrackIds.historical: '历史线',
                    FictionEventTrackIds.character: '人物成长线',
                    FictionEventTrackIds.worldbuilding: '世界观线',
                  }.entries)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: FilterChip(
                        label: Text(entry.value),
                        selected: _selectedStoryTrack == entry.key,
                        onSelected: (_) =>
                            setState(() => _selectedStoryTrack = entry.key),
                      ),
                    ),
                ]),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  FilterChip(
                    label: const Text('全部类型'),
                    selected: _kinds.isEmpty,
                    onSelected: (_) => setState(_kinds.clear),
                  ),
                  for (final entry in const {
                    ReadingArtifactKinds.event: '事件',
                    ReadingArtifactKinds.scene: '场景',
                    ReadingArtifactKinds.clue: '线索',
                    ReadingArtifactKinds.mystery: '悬念',
                  }.entries)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: FilterChip(
                        label: Text(entry.value),
                        selected: _kinds.contains(entry.key),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _kinds.add(entry.key);
                          } else {
                            _kinds.remove(entry.key);
                          }
                        }),
                      ),
                    ),
                ]),
              ),
            ]),
          Text('$chapterCount 个章节分组 · 仅在展开章节时显示事件',
              style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }

  Widget _stageOverview(List<FictionTimelineChapter> chapters) {
    final stages = fictionStoryAtlasService.storyStages(chapters);
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: stages.length,
        separatorBuilder: (_, __) => const Icon(Icons.chevron_right, size: 18),
        itemBuilder: (context, index) {
          final stage = stages[index];
          return ActionChip(
            avatar: CircleAvatar(child: Text('${stage.index}')),
            label: Text('${stage.label} · ${stage.eventCount}件'),
            onPressed: () {
              final chapterIndex = chapters.indexWhere(
                  (chapter) => chapter.id == stage.chapterIds.first);
              if (chapterIndex < 0) return;
              setState(() {
                _chapterPage = (chapterIndex ~/ 20) + 1;
                _expandedChapters.add(stage.chapterIds.first);
              });
            },
          );
        },
      ),
    );
  }

  Widget _organizedBoundary(double progress) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('上次整理到这里 · ${(progress * 100).round()}%'),
          ),
          const Expanded(child: Divider()),
          if (widget.onRequestOrganize != null)
            TextButton(
              onPressed: widget.onRequestOrganize,
              child: const Text('整理新增'),
            ),
        ]),
      );

  Widget _mysteryTimelineBody(FictionStoryAtlas atlas) {
    final threads = fictionStoryAtlasService.mysteryThreads(atlas.timeline);
    return Column(children: [
      _boundaryBanner(atlas),
      _timelineControls(atlas, threads.length),
      Expanded(
        child: threads.isEmpty
            ? const Center(child: Text('当前已读范围内没有未解悬念。'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
                itemCount: threads.length,
                itemBuilder: (context, index) {
                  final thread = threads[index];
                  return Card(
                    child: ExpansionTile(
                      expansionAnimationStyle: AnimationStyle(
                        duration: _motionDuration,
                        reverseDuration: _motionDuration,
                      ),
                      initiallyExpanded: index == 0,
                      leading: const Icon(Icons.help_outline),
                      title: Text(thread.mystery.title),
                      subtitle: Text(
                        thread.events.length == 1
                            ? '尚无线索关联'
                            : '${thread.events.length - 1} 条关联线索',
                      ),
                      children: [
                        for (final event in thread.events)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                            child: _eventCard(event),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _chapterSection(
    FictionTimelineChapter chapter, {
    required bool isCurrent,
  }) {
    final expanded = _expandedChapters.contains(chapter.id);
    return Card(
      key: _chapterKeys.putIfAbsent(chapter.id, GlobalKey.new),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Column(children: [
        ListTile(
          dense: true,
          leading: Icon(isCurrent ? Icons.bookmark : Icons.folder_outlined),
          title: Text(chapter.title),
          subtitle: Text(
              '${chapter.events.length} 个事件 · ${(chapter.startProgress * 100).round()}%'),
          trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          onTap: () => setState(() {
            if (expanded) {
              _expandedChapters.remove(chapter.id);
            } else {
              _expandedChapters.add(chapter.id);
            }
          }),
        ),
        AnimatedSize(
          duration: _motionDuration,
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: expanded
              ? Column(
                  children: [
                    for (final event in chapter.events)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                        child: _eventCard(event),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }

  Widget _eventCard(FictionTimelineEvent event) {
    final color = _eventColor(context, event);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showEvent(event),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 5,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(event.title,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ]),
            if (event.summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(event.summary, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _tag(event.storyTimeLabel ?? '时间未明'),
              _tag('${(event.source.sourceProgress * 100).round()}%'),
              _tag(event.source.epistemicStatus ==
                      ReadingArtifactEpistemicStatus.agentInference
                  ? 'AI 推测'
                  : '文本事实'),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text, style: Theme.of(context).textTheme.labelSmall),
      );

  Future<void> _showEvent(FictionTimelineEvent event) async {
    final chapter = event.source.chapterHref?.trim().isNotEmpty == true
        ? event.source.chapterHref!
        : 'title:${event.source.chapterTitle?.trim().isNotEmpty == true ? event.source.chapterTitle! : '未知章节'}';
    _lastViewedChapter = chapter;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastViewedKey, chapter);
    if (!mounted) return;
    final source = event.source;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: ListView(shrinkWrap: true, children: [
            Text(event.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(event.summary.isEmpty ? '当前位置没有更多摘要。' : event.summary),
            if (event.participants.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('参与人物：${event.participants.join('、')}'),
            ],
            const SizedBox(height: 12),
            Text('故事内时间：${event.storyTimeLabel ?? '时间未明'}'),
            Text(
                '来源：${source.chapterTitle ?? '未知章节'} · ${(source.sourceProgress * 100).round()}%'),
            if (source.sourceTextSnapshot.isNotEmpty) ...[
              const Divider(height: 28),
              Text('原文快照', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(source.sourceTextSnapshot),
            ],
            ..._relatedEvents(event),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _sourceTarget(source).isEmpty
                  ? null
                  : () async {
                      Navigator.pop(sheetContext);
                      await widget.onOpenLocation?.call(_sourceTarget(source));
                    },
              icon: const Icon(Icons.short_text),
              label: const Text('返回来源'),
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _relatedEvents(FictionTimelineEvent event) {
    final events = _atlas?.timeline;
    if (events == null || events.length < 2) return const [];
    final index = events.indexWhere((item) => item.id == event.id);
    if (index < 0) return const [];
    final previous = index > 0 ? events[index - 1] : null;
    final next = index < events.length - 1 ? events[index + 1] : null;
    if (previous == null && next == null) return const [];
    return [
      const Divider(height: 28),
      Text('前后相关事件', style: Theme.of(context).textTheme.titleMedium),
      if (previous != null)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.arrow_back),
          title: Text(previous.title),
          subtitle: const Text('上一个正文事件'),
        ),
      if (next != null)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.arrow_forward),
          title: Text(next.title),
          subtitle: const Text('下一个正文事件'),
        ),
    ];
  }

  String _sourceTarget(ReadingArtifact source) =>
      source.sourceStartCfi ??
      source.discoveredAtCfi ??
      source.chapterHref ??
      '';
}

Color _eventColor(BuildContext context, FictionTimelineEvent event) {
  final scheme = Theme.of(context).colorScheme;
  if (event.isMystery) return scheme.tertiary;
  if (event.isClue) return scheme.secondary;
  if (event.isMajor) return scheme.error;
  return scheme.primary;
}
