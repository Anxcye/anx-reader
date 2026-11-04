import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_materials.dart';
import 'package:anx_reader/models/next_reading_action.dart';
import 'package:anx_reader/models/reading_task.dart';
import 'package:anx_reader/service/ai/fiction_story_atlas_service.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/service/ai/reading_outcomes_service.dart';
import 'package:anx_reader/service/ai/reading_task_scheduler.dart';
import 'package:anx_reader/widgets/ai/reading_task_progress_card.dart';
import 'package:flutter/material.dart';

/// One local directory over existing sources. No model, chapter loading,
/// persistence or spoiler/merge policy belongs in this widget.
class ReadingBookHubContent extends StatefulWidget {
  const ReadingBookHubContent({
    super.key,
    required this.book,
    required this.state,
    required this.closure,
    required this.nextAction,
    required this.atlas,
    required this.syncing,
    required this.syncEnabled,
    this.syncNeedsManualResolution = false,
    required this.onNextAction,
    required this.onOpenOutcomes,
    required this.onOpenWiki,
    this.onOpenContextPack,
    required this.onOpenStoryArchive,
    required this.onSync,
    required this.onOpenReadingSettings,
    this.materials,
    this.onOpenMaterial,
    this.onOpenExercises,
    this.onOrganizeStory,
    this.onOrganizeKnowledge,
    this.onOpenTimeline,
    this.onResumeTask,
    this.initialSearch = '',
    this.onSearchChanged,
    this.scrollController,
  });

  final Book book;
  final ReadingOutcomesSnapshot state;
  final ReadingClosurePolicyDefinition closure;
  final NextReadingAction nextAction;
  final FictionStoryAtlas atlas;
  final bool syncing;
  final bool syncEnabled;
  final bool syncNeedsManualResolution;
  final Future<void> Function() onNextAction;
  final Future<void> Function() onOpenOutcomes;
  final Future<void> Function() onOpenWiki;
  final Future<void> Function()? onOpenContextPack;
  final Future<void> Function() onOpenStoryArchive;
  final Future<void> Function() onSync;
  final Future<void> Function() onOpenReadingSettings;
  final BookMaterialsSnapshot? materials;
  final Future<void> Function(BookMaterialItem item)? onOpenMaterial;
  final Future<void> Function()? onOpenExercises;
  final Future<void> Function()? onOrganizeStory;
  final Future<void> Function()? onOrganizeKnowledge;
  final Future<void> Function()? onOpenTimeline;
  final Future<void> Function(ReadingTask task)? onResumeTask;
  final String initialSearch;
  final ValueChanged<String>? onSearchChanged;
  final ScrollController? scrollController;

  @override
  State<ReadingBookHubContent> createState() => _ReadingBookHubContentState();
}

class _ReadingBookHubContentState extends State<ReadingBookHubContent> {
  late final TextEditingController _search =
      TextEditingController(text: widget.initialSearch);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _sectionTitle(BookMaterialSection section, L10n l10n) =>
      switch (section) {
        BookMaterialSection.chapters => l10n.readingCompanionChapters,
        BookMaterialSection.characters => l10n.readingCompanionCharacters,
        BookMaterialSection.plot => l10n.readingCompanionPlot,
        BookMaterialSection.concepts => l10n.readingCompanionConcepts,
        BookMaterialSection.records => l10n.readingCompanionRecords,
      };

  IconData _sectionIcon(BookMaterialSection section) => switch (section) {
        BookMaterialSection.chapters => Icons.subject_outlined,
        BookMaterialSection.characters => Icons.people_outline,
        BookMaterialSection.plot => Icons.route_outlined,
        BookMaterialSection.concepts => Icons.lightbulb_outline,
        BookMaterialSection.records => Icons.edit_note_outlined,
      };

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ReadingTask>>(
        stream: readingTaskScheduler.changes,
        initialData: readingTaskScheduler.tasks,
        builder: (context, snapshot) => _buildContent(
          ReadingTaskProgressCard.latestForBook(
            snapshot.data ?? const [],
            widget.book.id,
            type: null,
          ),
        ),
      );

  Widget _buildContent(ReadingTask? task) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final searching = _search.text.trim().isNotEmpty;
    final materials =
        widget.materials?.bookId == widget.book.id ? widget.materials : null;
    final sections = materials?.sections ??
        const <BookMaterialSection, List<BookMaterialItem>>{};
    final available = materials?.availableSections ??
        {
          BookMaterialSection.chapters,
          BookMaterialSection.concepts,
          BookMaterialSection.records,
          if (widget.closure.supports(ReadingClosureCapability.storyAtlas)) ...{
            BookMaterialSection.characters,
            BookMaterialSection.plot,
          },
        };
    final emptySections = BookMaterialSection.values.where((section) =>
        available.contains(section) && !sections.containsKey(section));
    final progress =
        materials?.visibleAtProgress ?? widget.book.readingPercentage;
    return ListView(
      key: PageStorageKey('book-materials-${widget.book.id}'),
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(widget.book.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('${l10n.readingCompanionProgress} ${(progress * 100).round()}%',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(l10n.readingCompanionSafeScope, style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('book-materials-search'),
          controller: _search,
          autofocus: false,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.readingCompanionSearchMaterials,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.readingCompanionClearSearch,
                    onPressed: () {
                      _search.clear();
                      widget.onSearchChanged?.call('');
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
          onChanged: (value) {
            widget.onSearchChanged?.call(value);
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        if (searching) ...[
          if (materials == null || materials.search(_search.text).isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(l10n.readingCompanionSearchEmpty),
            )
          else
            for (final item in materials.search(_search.text))
              _materialTile(item),
        ] else ...[
          if (!widget.nextAction.isPassive) ...[
            Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.nextAction.title,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(widget.nextAction.reason),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: widget.onNextAction,
                      child: Text(l10n.readingCompanionStart),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          ReadingTaskProgressCard(task: task, onResume: widget.onResumeTask),
          for (final section in sections.entries)
            _directorySection(section.key, section.value),
          if (emptySections.isNotEmpty)
            ExpansionTile(
              key: const PageStorageKey('book-materials-available'),
              tilePadding: EdgeInsets.zero,
              title: Text(l10n.readingCompanionAvailableMaterials),
              children: [
                for (final section in emptySections) _emptySection(section),
              ],
            ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.school_outlined),
            title: Text(l10n.readingCompanionExercises),
            subtitle: Text(l10n.readingCompanionExercisesHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onOpenExercises ?? widget.onOpenOutcomes,
          ),
          ExpansionTile(
            key: const PageStorageKey('book-materials-settings'),
            tilePadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune_outlined),
            title: Text(l10n.readingCompanionBookSettings),
            children: [
              ListTile(
                title: Text(l10n.readingCompanionReadingPreferences),
                onTap: widget.onOpenReadingSettings,
              ),
              if (widget.onOpenContextPack != null)
                ListTile(
                  title: Text(l10n.readingCompanionAiMaterials),
                  onTap: widget.onOpenContextPack,
                ),
              ListTile(
                title: Text(l10n.readingCompanionProgress),
                onTap: widget.onOpenOutcomes,
              ),
            ],
          ),
          const Divider(height: 32),
          _syncTile(l10n),
        ],
      ],
    );
  }

  Widget _directorySection(
      BookMaterialSection section, List<BookMaterialItem> items) {
    final l10n = L10n.of(context);
    return ExpansionTile(
      key: PageStorageKey('book-materials-section-${section.name}'),
      tilePadding: EdgeInsets.zero,
      leading: Icon(_sectionIcon(section)),
      title: Text(_sectionTitle(section, l10n)),
      subtitle: Text('${items.length}'),
      children: [
        for (final item in items) _materialTile(item),
        if (section == BookMaterialSection.characters &&
            widget.closure.supports(ReadingClosureCapability.storyAtlas))
          ListTile(
            leading: const Icon(Icons.account_tree_outlined),
            title: Text(l10n.readingCompanionRelations),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onOpenStoryArchive,
          ),
        if (section == BookMaterialSection.plot &&
            widget.onOpenTimeline != null)
          ListTile(
            leading: const Icon(Icons.timeline),
            title: Text(l10n.readingCompanionTimeline),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onOpenTimeline,
          ),
      ],
    );
  }

  Widget _materialTile(BookMaterialItem item) => ListTile(
        key: ValueKey('book-material-${item.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: item.summary.isEmpty
            ? null
            : Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: widget.onOpenMaterial == null
            ? null
            : () => widget.onOpenMaterial!(item),
      );

  Widget _emptySection(BookMaterialSection section) {
    final l10n = L10n.of(context);
    final story = section == BookMaterialSection.characters ||
        section == BookMaterialSection.plot;
    final records = section == BookMaterialSection.records;
    return ListTile(
      leading: Icon(_sectionIcon(section)),
      title: Text(_sectionTitle(section, l10n)),
      subtitle: Text(records
          ? l10n.readingCompanionRecordsEmpty
          : story
              ? l10n.readingCompanionOrganizeStory
              : l10n.readingCompanionOrganizeKnowledge),
      trailing: records ? null : const Icon(Icons.chevron_right),
      onTap: records
          ? null
          : story
              ? widget.onOrganizeStory ?? widget.onOpenStoryArchive
              : widget.onOrganizeKnowledge ?? widget.onOpenWiki,
    );
  }

  Widget _syncTile(L10n l10n) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(widget.syncEnabled
          ? Icons.cloud_done_outlined
          : Icons.cloud_off_outlined),
      title: Text(l10n.readingCompanionSync),
      subtitle: Text(widget.syncEnabled
          ? widget.syncing
              ? l10n.readingCompanionSyncRunning
              : widget.syncNeedsManualResolution
                  ? l10n.readingCompanionSyncConflict
                  : l10n.readingCompanionSyncIdle
          : l10n.readingCompanionSyncOff),
      trailing: widget.syncEnabled
          ? IconButton(
              tooltip: l10n.readingCompanionSyncNow,
              onPressed: widget.syncing ? null : widget.onSync,
              icon: widget.syncing && !disableAnimations
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(widget.syncing ? Icons.sync_disabled : Icons.sync),
            )
          : null,
    );
  }
}
