import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_note_ai.dart';
import 'package:anx_reader/providers/reading_note_ai_organizer.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadingNoteAiReviewPage extends ConsumerWidget {
  const ReadingNoteAiReviewPage({super.key, required this.book});
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizer = ref.watch(readingNoteAiOrganizerProvider(book.id));
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).readingNoteAiReviewTitle),
        actions: [
          TextButton(
            onPressed: () => _abandon(context, ref),
            child: Text(L10n.of(context).readingNoteAiAbandon),
          ),
        ],
      ),
      body: SafeArea(
        child: organizer.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('加载失败：$error')),
          data: (state) => _body(context, ref, state),
        ),
      ),
    );
  }

  Widget _body(
      BuildContext context, WidgetRef ref, ReadingNoteAiOrganizerState state) {
    final batch = state.activeBatch;
    if (batch == null) {
      return Center(child: Text(L10n.of(context).readingNoteAiEmpty));
    }
    if (state.isGenerating ||
        batch.status == ReadingNoteAiBatchStatus.running) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(L10n.of(context).readingNoteAiRunning),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => ref
                  .read(readingNoteAiOrganizerProvider(book.id).notifier)
                  .cancel(),
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(L10n.of(context).readingNoteAiCancel),
            ),
          ),
        ]),
      );
    }
    if (batch.status == ReadingNoteAiBatchStatus.failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 12),
            Text(batch.error ?? 'AI 整理失败', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => ref
                    .read(readingNoteAiOrganizerProvider(book.id).notifier)
                    .retry(book),
                icon: const Icon(Icons.refresh),
                label: Text(L10n.of(context).readingNoteAiRetry),
              ),
            ),
          ]),
        ),
      );
    }
    return Column(children: [
      Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: Text(
                '${state.suggestions.length} 条建议'
                '${batch.remainingCount > 0 ? ' · 还有 ${batch.remainingCount} 条未处理' : ''}',
              ),
            ),
            if (batch.model?.isNotEmpty == true)
              Text('${batch.providerId ?? ''} · ${batch.model}'),
          ]),
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
          children: [
            for (final suggestion in state.suggestions)
              _SuggestionCard(book: book, suggestion: suggestion),
            if (batch.remainingCount > 0)
              Card(
                elevation: 0,
                child: ListTile(
                  minTileHeight: 56,
                  leading: const Icon(Icons.queue_outlined),
                  title: Text(L10n.of(context)
                      .readingNoteAiRemaining(batch.remainingCount)),
                  subtitle: const Text('本批完成后返回工作台，再次主动选择 AI 整理'),
                ),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          if (state.suggestions.any(
              (item) => item.status == ReadingNoteAiSuggestionStatus.adopted))
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _undoBatch(context, ref),
                icon: const Icon(Icons.undo),
                label: Text(L10n.of(context).readingNoteAiUndoBatch),
              ),
            ),
          if (batch.status == ReadingNoteAiBatchStatus.completed &&
              batch.remainingCount > 0)
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => ref
                    .read(readingNoteAiOrganizerProvider(book.id).notifier)
                    .startNext(book),
                icon: const Icon(Icons.navigate_next),
                label: Text(L10n.of(context)
                    .readingNoteAiStartNext(batch.remainingCount)),
              ),
            ),
          if (batch.status == ReadingNoteAiBatchStatus.completed &&
              batch.remainingCount == 0)
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => ref
                    .read(readingNoteAiOrganizerProvider(book.id).notifier)
                    .clearCompleted(),
                icon: const Icon(Icons.cleaning_services_outlined),
                label: Text(L10n.of(context).readingNoteAiClear),
              ),
            ),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: state.suggestions.any((item) =>
                      item.status == ReadingNoteAiSuggestionStatus.pending)
                  ? () => _applyAll(context, ref)
                  : null,
              icon: const Icon(Icons.done_all),
              label: Text(L10n.of(context).readingNoteAiApplyAll),
            ),
          ),
        ]),
      ),
    ]);
  }

  Future<void> _applyAll(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(readingNoteAiOrganizerProvider(book.id).notifier)
          .applyAll();
    } catch (error) {
      if (context.mounted) AnxToast.show('应用失败：$error');
    }
  }

  Future<void> _abandon(BuildContext context, WidgetRef ref) async {
    await ref.read(readingNoteAiOrganizerProvider(book.id).notifier).abandon();
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _undoBatch(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(readingNoteAiOrganizerProvider(book.id).notifier)
          .undoBatch();
    } catch (_) {
      if (context.mounted) AnxToast.show('部分笔记已被编辑，请从修订历史恢复');
    }
  }
}

class _SuggestionCard extends ConsumerWidget {
  const _SuggestionCard({required this.book, required this.suggestion});
  final Book book;
  final ReadingNoteAiSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(readingNoteAiOrganizerProvider(book.id).notifier);
    final pending = suggestion.status == ReadingNoteAiSuggestionStatus.pending;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          width: Prefs().isEInkMode ? 1.5 : 1,
          color: Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.auto_awesome, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(suggestion.suggestedTitle.isEmpty
                  ? '未命名整理建议'
                  : suggestion.suggestedTitle),
            ),
            Text(_statusLabel(suggestion.status)),
          ]),
          if (suggestion.suggestedTitle.isNotEmpty)
            _field(
              context,
              ref,
              ReadingNoteAiAdoptableField.title,
              L10n.of(context).readingNoteAiFieldTitle,
              suggestion.suggestedTitle,
              pending,
            ),
          if (suggestion.suggestedBody.isNotEmpty)
            _field(
              context,
              ref,
              ReadingNoteAiAdoptableField.aiBlock,
              L10n.of(context).readingNoteAiFieldBody,
              suggestion.suggestedBody,
              pending,
            ),
          if (suggestion.suggestedTags.isNotEmpty)
            _field(
              context,
              ref,
              ReadingNoteAiAdoptableField.tags,
              L10n.of(context).readingNoteAiFieldTags,
              suggestion.suggestedTags.join(' · '),
              pending,
            ),
          if (suggestion.existingTopicIds.isNotEmpty ||
              suggestion.newTopics.isNotEmpty)
            _field(
              context,
              ref,
              ReadingNoteAiAdoptableField.topics,
              L10n.of(context).readingNoteAiFieldTopics,
              [
                ...suggestion.existingTopicIds,
                ...suggestion.newTopics.map((item) => item['title'])
              ].join(' · '),
              pending,
            ),
          const SizedBox(height: 8),
          if (pending)
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => notifier.ignore(suggestion),
                  child: Text(L10n.of(context).readingNoteAiIgnore),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _apply(context, notifier),
                  child: Text(L10n.of(context).readingNoteAiApply),
                ),
              ),
            ])
          else if (suggestion.status == ReadingNoteAiSuggestionStatus.adopted)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _undo(context, notifier),
                icon: const Icon(Icons.undo),
                label: Text(L10n.of(context).readingNoteAiUndo),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _field(
      BuildContext context,
      WidgetRef ref,
      ReadingNoteAiAdoptableField field,
      String title,
      String content,
      bool enabled) {
    final selected = suggestion.selectedFields.contains(field);
    return CheckboxListTile(
      value: selected,
      onChanged: enabled
          ? (value) => ref
              .read(readingNoteAiOrganizerProvider(book.id).notifier)
              .toggleField(suggestion, field, value == true)
          : null,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(title),
      subtitle: Text(content),
    );
  }

  Future<void> _apply(
      BuildContext context, ReadingNoteAiOrganizerController notifier) async {
    try {
      await notifier.applyOne(suggestion);
    } catch (error) {
      if (context.mounted) AnxToast.show('应用失败：$error');
    }
  }

  Future<void> _undo(
      BuildContext context, ReadingNoteAiOrganizerController notifier) async {
    try {
      await notifier.undo(suggestion);
    } catch (_) {
      if (context.mounted) AnxToast.show('笔记已被编辑，请从修订历史恢复');
    }
  }

  String _statusLabel(ReadingNoteAiSuggestionStatus status) => switch (status) {
        ReadingNoteAiSuggestionStatus.pending => '待确认',
        ReadingNoteAiSuggestionStatus.adopted => '已采用',
        ReadingNoteAiSuggestionStatus.ignored => '已忽略',
        ReadingNoteAiSuggestionStatus.archived => '已归档',
      };
}
