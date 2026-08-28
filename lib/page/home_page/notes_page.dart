import 'dart:async';

import 'package:anx_reader/config/feature_flags.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/models/reading_note_ai.dart';
import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/providers/reading_coach.dart';
import 'package:anx_reader/providers/reading_memory.dart';
import 'package:anx_reader/providers/reading_note_workspace.dart';
import 'package:anx_reader/providers/reading_note_ai_organizer.dart';
import 'package:anx_reader/page/reading_note_ai_review_page.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key, this.controller});

  final ScrollController? controller;

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  Timer? _searchDebounce;
  bool _selectionMode = false;
  final Set<String> _selectedNotes = {};

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(readingNoteWorkspaceProvider);
    return SafeArea(
      bottom: false,
      child: workspace.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (state) => LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth >= 1000) {
            return Row(children: [
              SizedBox(width: 230, child: _buildLibrary(state)),
              const VerticalDivider(width: 1),
              SizedBox(width: 390, child: _buildList(state, mobile: false)),
              const VerticalDivider(width: 1),
              Expanded(child: _buildDetail(state.selected)),
            ]);
          }
          if (constraints.maxWidth >= 600) {
            return Row(children: [
              SizedBox(width: 280, child: _buildLibrary(state)),
              const VerticalDivider(width: 1),
              Expanded(
                child: state.selected == null
                    ? _buildList(state, mobile: false)
                    : Column(children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => ref
                                .read(readingNoteWorkspaceProvider.notifier)
                                .select(null),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(L10n.of(context).historyBack),
                          ),
                        ),
                        Expanded(child: _buildDetail(state.selected)),
                      ]),
              ),
            ]);
          }
          return _buildMobile(state);
        }),
      ),
    );
  }

  Widget _buildMobile(ReadingNoteWorkspaceState state) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text('阅读笔记', style: Theme.of(context).textTheme.headlineSmall),
      ),
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final entry in _collections.entries)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text(entry.value.$2),
                  avatar: Icon(entry.value.$1, size: 18),
                  selected: state.collection == entry.key,
                  onSelected: (_) => ref
                      .read(readingNoteWorkspaceProvider.notifier)
                      .setCollection(entry.key),
                ),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: DropdownButtonFormField<int?>(
          initialValue: state.bookId,
          decoration: const InputDecoration(
            labelText: '书籍范围',
            prefixIcon: Icon(Icons.menu_book_outlined),
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('全部书籍')),
            for (final book in state.books.where((book) => !book.isDeleted))
              DropdownMenuItem<int?>(
                value: book.id,
                child: Text(book.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (bookId) =>
              ref.read(readingNoteWorkspaceProvider.notifier).setBook(bookId),
        ),
      ),
      Expanded(child: _buildList(state, mobile: true)),
    ]);
  }

  Widget _buildLibrary(ReadingNoteWorkspaceState state) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 12, 12),
        child: Text('阅读笔记', style: Theme.of(context).textTheme.headlineSmall),
      ),
      for (final entry in _collections.entries)
        ListTile(
          minTileHeight: 48,
          leading: Icon(entry.value.$1),
          title: Text(entry.value.$2),
          selected: state.collection == entry.key,
          selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
          onTap: () => ref
              .read(readingNoteWorkspaceProvider.notifier)
              .setCollection(entry.key),
        ),
      const Divider(),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 12, 4),
        child: Text('所有书籍', style: Theme.of(context).textTheme.titleSmall),
      ),
      SizedBox(
        height: state.tags.isEmpty ? 240 : 160,
        child: ListView(
          children: [
            for (final book in state.books.where((book) => !book.isDeleted))
              ListTile(
                minTileHeight: 44,
                leading: const Icon(Icons.menu_book_outlined, size: 18),
                title: Text(book.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                selected: state.bookId == book.id,
                onTap: () => ref
                    .read(readingNoteWorkspaceProvider.notifier)
                    .setBook(book.id),
              ),
          ],
        ),
      ),
      if (state.tags.isNotEmpty) ...[
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 12, 4),
          child: Text('标签', style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final tag in state.tags)
                ListTile(
                  minTileHeight: 44,
                  leading: const Icon(Icons.tag, size: 18),
                  title: Text(tag.name),
                  selected: state.collection == ReadingNoteCollection.tag &&
                      state.tagId == tag.id,
                  onTap: () => ref
                      .read(readingNoteWorkspaceProvider.notifier)
                      .setCollection(ReadingNoteCollection.tag, tagId: tag.id),
                ),
            ],
          ),
        ),
      ] else
        const Spacer(),
    ]);
  }

  Widget _buildList(ReadingNoteWorkspaceState state, {required bool mobile}) {
    final groups = state.bookView == ReadingNoteBookView.chapters
        ? _groupByChapter(state.items)
        : null;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: SearchBar(
          hintText: '搜索标题、想法、原文、标签或章节',
          leading: const Icon(Icons.search),
          onChanged: (value) {
            _searchDebounce?.cancel();
            _searchDebounce = Timer(const Duration(milliseconds: 350), () {
              ref.read(readingNoteWorkspaceProvider.notifier).setSearch(value);
            });
          },
        ),
      ),
      if (state.bookId != null)
        SegmentedButton<ReadingNoteBookView>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
                value: ReadingNoteBookView.timeline, label: Text('时间流')),
            ButtonSegment(
                value: ReadingNoteBookView.chapters, label: Text('章节')),
            if (FeatureFlags.readingCoach) ...[
              ButtonSegment(
                  value: ReadingNoteBookView.topics, label: Text('主题')),
              ButtonSegment(
                  value: ReadingNoteBookView.outcomes, label: Text('成果')),
            ],
          ],
          selected: {state.bookView},
          onSelectionChanged: (values) => ref
              .read(readingNoteWorkspaceProvider.notifier)
              .setBookView(values.first),
        ),
      if (state.bookId != null &&
          state.bookView != ReadingNoteBookView.topics &&
          state.bookView != ReadingNoteBookView.outcomes)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
          child: Row(children: [
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _selectionMode = !_selectionMode;
                if (!_selectionMode) _selectedNotes.clear();
              }),
              icon: Icon(_selectionMode ? Icons.close : Icons.checklist),
              label: Text(
                  _selectionMode ? '取消选择 (${_selectedNotes.length})' : '选择笔记'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openAiOrganizer(state),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('AI 整理'),
            ),
          ]),
        ),
      const SizedBox(height: 6),
      Expanded(
        child: state.bookId != null &&
                state.bookView == ReadingNoteBookView.topics
            ? _ReadingNoteTopics(bookId: state.bookId!)
            : state.bookId != null &&
                    state.bookView == ReadingNoteBookView.outcomes
                ? _ReadingNoteOutcomes(bookId: state.bookId!)
                : state.items.isEmpty
                    ? _emptyState(state)
                    : groups == null
                        ? ListView.builder(
                            controller: widget.controller,
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 90),
                            itemCount: state.items.length,
                            itemBuilder: (_, index) =>
                                _noteTile(state.items[index], state, mobile),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 90),
                            children: [
                              for (final group in groups.entries)
                                ExpansionTile(
                                  initiallyExpanded: true,
                                  title: Text(
                                      group.key.isEmpty ? '未命名章节' : group.key),
                                  children: [
                                    for (final item in group.value)
                                      _noteTile(item, state, mobile),
                                  ],
                                ),
                            ],
                          ),
      ),
    ]);
  }

  Widget _noteTile(
      ReadingNoteListItem item, ReadingNoteWorkspaceState state, bool mobile) {
    final selected = state.selectedIdentity == item.identity;
    final doc = item.document;
    return Card(
      elevation: 0,
      color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          width: selected || Prefs().isEInkMode ? 1.5 : 1,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          if (_selectionMode) {
            setState(() {
              _selectedNotes.contains(item.identity)
                  ? _selectedNotes.remove(item.identity)
                  : _selectedNotes.add(item.identity);
            });
            return;
          }
          _openItem(item, mobile);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (_selectionMode)
                Checkbox(
                  value: _selectedNotes.contains(item.identity),
                  onChanged: (checked) => setState(() {
                    checked == true
                        ? _selectedNotes.add(item.identity)
                        : _selectedNotes.remove(item.identity);
                  }),
                ),
              Icon(_captureIcon(doc?.note.captureKind), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title.isNotEmpty ? item.title : item.book.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (doc?.note.isFavorite == true)
                const Icon(Icons.star, size: 18),
            ]),
            if (item.quote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(item.quote, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            if (item.body.isNotEmpty) ...[
              const Divider(),
              Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Text(
              '${item.book.title} · ${item.chapter.isEmpty ? '未命名章节' : item.chapter}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _openItem(ReadingNoteListItem item, bool mobile) async {
    if (mobile) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(item.book.title)),
          body: SafeArea(child: ReadingNoteDetail(item: item)),
        ),
      ));
      await ref.read(readingNoteWorkspaceProvider.notifier).refresh();
      return;
    }
    ref.read(readingNoteWorkspaceProvider.notifier).select(item.identity);
  }

  Future<void> _openAiOrganizer(ReadingNoteWorkspaceState state) async {
    final book = state.books.where((book) => book.id == state.bookId).first;
    final organizer = ref.read(readingNoteAiOrganizerProvider(book.id));
    final active = organizer.valueOrNull?.activeBatch;
    if (active == null ||
        !const {
          ReadingNoteAiBatchStatus.reviewing,
          ReadingNoteAiBatchStatus.failed,
          ReadingNoteAiBatchStatus.running,
          ReadingNoteAiBatchStatus.completed,
        }.contains(active.status)) {
      final scope = await showDialog<ReadingNoteAiScope>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('选择 AI 整理范围'),
          children: [
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.pop(dialogContext, ReadingNoteAiScope.inbox),
              child: const ListTile(
                leading: Icon(Icons.inbox_outlined),
                title: Text('当前书未整理笔记'),
                subtitle: Text('只处理未整理箱中的内容'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.pop(dialogContext, ReadingNoteAiScope.filtered),
              child: const ListTile(
                leading: Icon(Icons.filter_alt_outlined),
                title: Text('当前筛选结果'),
                subtitle: Text('使用当前搜索、标签和章节范围'),
              ),
            ),
            SimpleDialogOption(
              onPressed: _selectedNotes.isEmpty
                  ? null
                  : () =>
                      Navigator.pop(dialogContext, ReadingNoteAiScope.selected),
              child: ListTile(
                enabled: _selectedNotes.isNotEmpty,
                leading: const Icon(Icons.checklist),
                title: Text('已选择 ${_selectedNotes.length} 条'),
                subtitle: const Text('仅处理手动勾选内容'),
              ),
            ),
          ],
        ),
      );
      if (scope == null || !mounted) return;
      unawaited(
          ref.read(readingNoteAiOrganizerProvider(book.id).notifier).start(
                book: book,
                scope: scope,
                visibleItems: state.items,
                selectedIdentities: _selectedNotes,
              ));
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReadingNoteAiReviewPage(book: book),
    ));
    await ref.read(readingNoteWorkspaceProvider.notifier).refresh();
  }

  Widget _buildDetail(ReadingNoteListItem? item) => item == null
      ? const Center(child: Text('选择一条笔记查看详情'))
      : ReadingNoteDetail(item: item);

  Widget _emptyState(ReadingNoteWorkspaceState state) {
    final text = state.search.isNotEmpty
        ? '没有匹配的笔记'
        : state.collection == ReadingNoteCollection.trash
            ? '回收站为空'
            : '还没有阅读笔记\n在阅读页长按原文即可开始记录';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }

  Map<String, List<ReadingNoteListItem>> _groupByChapter(
      List<ReadingNoteListItem> items) {
    final result = <String, List<ReadingNoteListItem>>{};
    for (final item in items) {
      result.putIfAbsent(item.chapter, () => []).add(item);
    }
    return result;
  }
}

class _ReadingNoteTopics extends ConsumerWidget {
  const _ReadingNoteTopics({required this.bookId});
  final int bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(readingMemoryProvider(bookId)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('主题加载失败：$error')),
          data: (state) {
            final topics = state.topics
                .where((topic) => topic.status == ReadingMemoryItemStatus.kept)
                .toList();
            if (topics.isEmpty) {
              return const Center(child: Text('还没有已保留主题\n可在 AI 阅读工作台的知识整理中创建'));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
              children: [
                for (final topic in topics)
                  Card(
                    elevation: 0,
                    child: ListTile(
                      minTileHeight: 56,
                      leading: const Icon(Icons.topic_outlined),
                      title: Text(topic.title),
                      subtitle: Text(topic.summary),
                      trailing: Text('${topic.sourceIds.length} 条来源'),
                    ),
                  ),
              ],
            );
          },
        );
  }
}

class _ReadingNoteOutcomes extends ConsumerWidget {
  const _ReadingNoteOutcomes({required this.bookId});
  final int bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coach = ref.watch(readingCoachProvider(bookId));
    final memory = ref.watch(readingMemoryProvider(bookId));
    if (coach.isLoading || memory.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (coach.hasError || memory.hasError) {
      return const Center(child: Text('主动阅读成果加载失败'));
    }
    final coachState = coach.requireValue;
    final memoryState = memory.requireValue;
    final rows = <(IconData, String, String)>[
      (Icons.explore_outlined, '检视阅读向导', coachState.guide.status.name),
      (
        Icons.question_answer_outlined,
        '四个主动问题',
        '${coachState.guide.answers.length} 已回答'
      ),
      (Icons.quiz_outlined, '章节自测', '${coachState.quizzes.length} 章'),
      (
        Icons.inventory_2_outlined,
        '难点暂存箱',
        '${coachState.difficulties.length} 条'
      ),
      (Icons.style_outlined, '知识卡', '${memoryState.cards.length} 张'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
      children: [
        for (final row in rows)
          Card(
            elevation: 0,
            child: ListTile(
              minTileHeight: 56,
              leading: Icon(row.$1),
              title: Text(row.$2),
              trailing: Text(row.$3),
            ),
          ),
      ],
    );
  }
}

class ReadingNoteDetail extends ConsumerStatefulWidget {
  const ReadingNoteDetail({super.key, required this.item});
  final ReadingNoteListItem item;

  @override
  ConsumerState<ReadingNoteDetail> createState() => _ReadingNoteDetailState();
}

class _ReadingNoteDetailState extends ConsumerState<ReadingNoteDetail>
    with WidgetsBindingObserver {
  ReadingNoteDocument? _document;
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _tags;
  Timer? _saveDebounce;
  bool _dirty = false;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _document = widget.item.document;
    _title = TextEditingController(text: widget.item.title);
    _body = TextEditingController(text: widget.item.body);
    _tags = TextEditingController(
        text:
            widget.item.document?.tags.map((tag) => tag.name).join(', ') ?? '');
  }

  @override
  void didUpdateWidget(covariant ReadingNoteDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.identity != widget.item.identity) {
      unawaited(_flush());
      _document = widget.item.document;
      _title.text = widget.item.title;
      _body.text = widget.item.body;
      _tags.text =
          widget.item.document?.tags.map((tag) => tag.name).join(', ') ?? '';
      _dirty = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveDebounce?.cancel();
    unawaited(_flush());
    _title.dispose();
    _body.dispose();
    _tags.dispose();
    super.dispose();
  }

  void _changed() {
    _dirty = true;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 900), _flush);
  }

  Future<void> _ensureDocument() async {
    final controller = ref.read(readingNoteWorkspaceProvider.notifier);
    _document ??= await controller.ensureDocument(widget.item);
  }

  Future<void> _flush({bool recordRevision = false}) async {
    if (!_dirty || _saving) return;
    _saveDebounce?.cancel();
    _saving = true;
    final controller = ref.read(readingNoteWorkspaceProvider.notifier);
    final item = widget.item;
    final title = _title.text;
    final body = _body.text;
    final tags = _parseTags();
    try {
      final document = _document ?? await controller.ensureDocument(item);
      final saved = await controller.save(
        document: document,
        title: title,
        body: body,
        status: document.note.status,
        favorite: document.note.isFavorite,
        tags: tags,
        recordRevision: recordRevision,
      );
      _document = saved;
      _dirty = false;
      _failed = false;
    } catch (_) {
      _failed = true;
    } finally {
      _saving = false;
      if (mounted) setState(() {});
    }
  }

  List<String> _parseTags() => _tags.text
      .split(RegExp(r'[,，]'))
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList();

  @override
  Widget build(BuildContext context) {
    final source = _document?.sources.firstOrNull;
    final quote = _document?.quote ?? widget.item.quote;
    final note = _document?.note;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 80),
      children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _title,
              onChanged: (_) => _changed(),
              decoration: const InputDecoration(
                hintText: '给这条笔记一个标题',
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton(
            tooltip: note?.isFavorite == true ? '取消收藏' : '收藏',
            onPressed: () async {
              await _ensureDocument();
              final current = _document!;
              _document = ReadingNoteDocument(
                note:
                    current.note.copyWith(isFavorite: !current.note.isFavorite),
                blocks: current.blocks,
                sources: current.sources,
                tags: current.tags,
              );
              _dirty = true;
              await _flush(recordRevision: true);
            },
            icon:
                Icon(note?.isFavorite == true ? Icons.star : Icons.star_border),
          ),
        ]),
        _sectionTitle('原文引用', Icons.format_quote),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(quote.isEmpty ? '没有原文引用' : quote),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title:
              Text(widget.item.chapter.isEmpty ? '未命名章节' : widget.item.chapter),
          subtitle: Text(widget.item.book.title),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _goToSource(source),
        ),
        _sectionTitle('我的想法', Icons.edit_note),
        TextField(
          controller: _body,
          minLines: 6,
          maxLines: null,
          onChanged: (_) => _changed(),
          decoration: const InputDecoration(
            hintText: '记录你的理解、疑问、反例或行动…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () async {
              _dirty = true;
              await _flush(recordRevision: true);
              if (mounted && !_failed) AnxToast.show('已保存一个历史版本');
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('保存版本'),
          ),
        ),
        if ((_document?.blocks ?? const <ReadingNoteBlock>[])
            .any((block) => block.type == ReadingNoteBlockType.ai)) ...[
          _sectionTitle('AI 整理内容', Icons.auto_awesome),
          for (final block in _document!.blocks
              .where((block) => block.type == ReadingNoteBlockType.ai))
            _aiBlock(block),
        ],
        _sectionTitle('标签与状态', Icons.sell_outlined),
        TextField(
          controller: _tags,
          onChanged: (_) => _changed(),
          decoration: const InputDecoration(
            labelText: '全局标签',
            hintText: '用逗号分隔，例如：认知，待实践',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ReadingNoteStatus>(
          initialValue: note?.status ?? ReadingNoteStatus.active,
          decoration: const InputDecoration(labelText: '状态'),
          items: const [
            DropdownMenuItem(
                value: ReadingNoteStatus.inbox, child: Text('未整理')),
            DropdownMenuItem(
                value: ReadingNoteStatus.active, child: Text('进行中')),
            DropdownMenuItem(
                value: ReadingNoteStatus.archived, child: Text('已归档')),
            DropdownMenuItem(
                value: ReadingNoteStatus.trashed, child: Text('回收站')),
          ],
          onChanged: (value) async {
            if (value == null) return;
            await _ensureDocument();
            final current = _document!;
            _document = ReadingNoteDocument(
              note: current.note.copyWith(status: value),
              blocks: current.blocks,
              sources: current.sources,
              tags: current.tags,
            );
            _dirty = true;
            await _flush(recordRevision: true);
          },
        ),
        if (FeatureFlags.readingCoach) ...[
          _sectionTitle('主动阅读关联', Icons.auto_awesome_outlined),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final relation
                  in _document?.sources ?? const <ReadingNoteSource>[])
                Chip(label: Text(_sourceLabel(relation.type))),
              OutlinedButton.icon(
                onPressed: _openKnowledgeCardFlow,
                icon: const Icon(Icons.style_outlined),
                label: const Text('生成知识卡'),
              ),
            ],
          ),
        ],
        if (_saving) const LinearProgressIndicator(),
        if (_failed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.error_outline),
            title: const Text('保存失败，草稿仍保留在当前页面'),
            trailing: TextButton(onPressed: _flush, child: const Text('重试')),
          ),
        const SizedBox(height: 16),
        if (note?.status == ReadingNoteStatus.trashed)
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await ref
                      .read(readingNoteWorkspaceProvider.notifier)
                      .restore(note!);
                },
                child: const Text('恢复'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  await ref
                      .read(readingNoteWorkspaceProvider.notifier)
                      .deletePermanently(note!.id);
                },
                child: const Text('永久删除'),
              ),
            ),
          ])
        else if (note != null)
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(readingNoteWorkspaceProvider.notifier).trash(note),
            icon: const Icon(Icons.delete_outline),
            label: const Text('移到回收站'),
          ),
      ],
    );
  }

  Widget _aiBlock(ReadingNoteBlock block) {
    final provider = block.metadata['providerId']?.toString() ?? '';
    final model = block.metadata['model']?.toString() ?? '';
    final provenance =
        [provider, model].where((value) => value.isNotEmpty).join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(block.content),
        if (provenance.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('AI 整理 · $provenance',
              style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: () => _copyAiBlock(block),
            icon: const Icon(Icons.copy_outlined),
            label: const Text('复制编辑'),
          ),
          OutlinedButton.icon(
            onPressed: () => _convertAiBlock(block),
            icon: const Icon(Icons.edit_note),
            label: const Text('转为我的想法'),
          ),
          TextButton.icon(
            onPressed: () => _deleteAiBlock(block),
            icon: const Icon(Icons.delete_outline),
            label: const Text('删除'),
          ),
        ]),
      ]),
    );
  }

  void _copyAiBlock(ReadingNoteBlock block) {
    final current = _body.text.trim();
    _body.text = [current, block.content.trim()]
        .where((value) => value.isNotEmpty)
        .join('\n\n');
    _body.selection = TextSelection.collapsed(offset: _body.text.length);
    _changed();
  }

  Future<void> _convertAiBlock(ReadingNoteBlock block) async {
    await _ensureDocument();
    final repository = ref.read(readingNoteRepositoryProvider);
    _document = await repository.convertAiBlockToBody(_document!, block);
    _body.text = _document!.body;
    if (mounted) setState(() {});
  }

  Future<void> _deleteAiBlock(ReadingNoteBlock block) async {
    await _ensureDocument();
    _document = await ref
        .read(readingNoteRepositoryProvider)
        .deleteAiBlock(_document!, block);
    if (mounted) setState(() {});
  }

  Widget _sectionTitle(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Row(children: [
          Icon(icon, size: 19),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ]),
      );

  Future<void> _goToSource(ReadingNoteSource? source) async {
    final cfi = source?.cfi ?? widget.item.cfi;
    if (widget.item.book.isDeleted ||
        source?.isAvailable == false ||
        cfi == null ||
        cfi.isEmpty) {
      AnxToast.show('原位置不可用，已保留文本快照');
      return;
    }
    await _flush();
    if (!mounted) return;
    await pushToReadingPage(ref, context, widget.item.book, cfi: cfi);
  }

  Future<void> _openKnowledgeCardFlow() async {
    await _flush();
    if (!mounted) return;
    final memory =
        await ref.read(readingMemoryProvider(widget.item.book.id).future);
    final topics = memory.topics
        .where((topic) => topic.status == ReadingMemoryItemStatus.kept)
        .toList();
    if (!mounted) return;
    if (topics.isEmpty) {
      await ref
          .read(readingMemoryProvider(widget.item.book.id).notifier)
          .collect();
      if (!mounted) return;
      AnxToast.show('已加入知识整理来源，请在阅读教练中先保留一个主题');
    } else {
      final selected = await showDialog<ReadingMemoryTopic>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('选择知识主题'),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final topic in topics)
                  ListTile(
                    minTileHeight: 56,
                    title: Text(topic.title),
                    subtitle: Text(topic.summary,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.pop(dialogContext, topic),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
          ],
        ),
      );
      if (selected == null || !mounted) return;
      AnxToast.show('已选择“${selected.title}”，请在阅读教练中确认生成');
    }
    if (!mounted) return;
    await pushToReadingPage(
      ref,
      context,
      widget.item.book,
      cfi: widget.item.cfi,
      initialShowCoach: true,
    );
  }

  String _sourceLabel(ReadingNoteSourceType type) => switch (type) {
        ReadingNoteSourceType.annotation => '原文划线',
        ReadingNoteSourceType.difficulty => '难点',
        ReadingNoteSourceType.aiSession => 'AI 会话',
        ReadingNoteSourceType.memoryTopic => '知识主题',
        ReadingNoteSourceType.knowledgeCard => '知识卡',
        ReadingNoteSourceType.guide => '检视向导',
        ReadingNoteSourceType.quiz => '章节自测',
      };
}

const _collections = <ReadingNoteCollection, (IconData, String)>{
  ReadingNoteCollection.recent: (Icons.schedule, '最近笔记'),
  ReadingNoteCollection.allBooks: (Icons.library_books_outlined, '所有书籍'),
  ReadingNoteCollection.inbox: (Icons.inbox_outlined, '未整理'),
  ReadingNoteCollection.questions: (Icons.help_outline, '难点与问题'),
  if (FeatureFlags.readingCoach)
    ReadingNoteCollection.activeReading: (
      Icons.auto_awesome_outlined,
      '主动阅读关联'
    ),
  ReadingNoteCollection.favorites: (Icons.star_outline, '收藏'),
  ReadingNoteCollection.trash: (Icons.delete_outline, '回收站'),
};

IconData _captureIcon(ReadingNoteCaptureKind? kind) => switch (kind) {
      ReadingNoteCaptureKind.keyPoint => Icons.priority_high,
      ReadingNoteCaptureKind.question => Icons.help_outline,
      ReadingNoteCaptureKind.disagree => Icons.balance_outlined,
      ReadingNoteCaptureKind.actionable => Icons.task_alt,
      ReadingNoteCaptureKind.later => Icons.inbox_outlined,
      ReadingNoteCaptureKind.manual => Icons.edit_note,
      _ => Icons.format_quote,
    };

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
