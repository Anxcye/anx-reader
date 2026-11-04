import 'dart:async';

import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/reading_task.dart';
import 'package:anx_reader/service/ai/reading_task_scheduler.dart';
import 'package:flutter/material.dart';

/// The shared, read-only progress projection for durable reading tasks.
///
/// Wiki and context pages intentionally render the same task state. The task
/// itself lives in [ReadingTaskScheduler], so leaving one page never hides or
/// cancels the work. Controls are delegated to the caller when rehydration
/// needs page-specific input (for example, the current EPUB WebView).
class ReadingTaskProgressCard extends StatelessWidget {
  const ReadingTaskProgressCard({
    super.key,
    required this.task,
    this.busy = false,
    this.onResume,
    this.titlePrefix,
  });

  final ReadingTask? task;
  final bool busy;
  final Future<void> Function(ReadingTask task)? onResume;
  final String? titlePrefix;

  static ReadingTask? latestForBook(
    Iterable<ReadingTask> tasks,
    int bookId, {
    String? type = 'wiki.book_generate',
  }) {
    final matching = tasks
        .where((item) =>
            item.bookId == bookId && (type == null || item.type == type))
        .toList()
      ..sort((a, b) {
        // An active task wins over an older completed task. This is important
        // when a previous run was completed after a new run was queued.
        final active = (b.isTerminal ? 0 : 1).compareTo(a.isTerminal ? 0 : 1);
        return active == 0 ? b.updatedAt.compareTo(a.updatedAt) : active;
      });
    return matching.isEmpty ? null : matching.first;
  }

  String _stageLabel(ReadingTask task, L10n l10n) {
    final stage = switch (task.checkpoint['stage']?.toString()) {
      'preparing_chapters' => l10n.readingTaskProgressPreparing,
      'reading_chapter' => l10n.readingTaskProgressReading,
      'chapter_started' => l10n.readingTaskProgressAnalyzing,
      'chunk_started' => l10n.readingTaskProgressGenerating,
      'chunk_completed' => l10n.readingTaskProgressChunkComplete,
      'chapter_completed' => l10n.readingTaskProgressChapterComplete,
      'skipped' => l10n.readingTaskProgressSkipped,
      _ => task.status == ReadingTaskStatus.queued
          ? l10n.readingTaskProgressQueued
          : l10n.readingTaskProgressWorking,
    };
    final purpose = task.payload['purpose']?.toString();
    final purposeLabel = purpose == 'context_pack'
        ? l10n.readingCompanionAiMaterials
        : l10n.readingTaskProgressTask;
    return '${titlePrefix ?? purposeLabel} · $stage';
  }

  Future<void> _resumeTask(BuildContext context, ReadingTask task) async {
    try {
      if (onResume == null) {
        await readingTaskScheduler.resume(task.id);
      } else {
        await onResume!(task);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                L10n.of(context).readingTaskProgressResumeFailed('$error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!busy && task == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final current = task;
    if (current == null) {
      return Card(
        color: theme.colorScheme.surfaceContainerHighest,
        child: ListTile(
          leading: disableAnimations
              ? const Icon(Icons.hourglass_empty_outlined)
              : const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
          title: Text(l10n.readingTaskProgressPreparing),
          subtitle: Text(l10n.readingTaskProgressPreparingHint),
        ),
      );
    }

    final progress = current.progress.clamp(0, 1).toDouble();
    final checkpoint = current.checkpoint;
    final chapter = checkpoint['currentChapterTitle']?.toString();
    final completedUnits = checkpoint['completedUnits'] ?? 0;
    final totalUnits = checkpoint['totalUnits'] ?? 0;
    final chunkIndex = checkpoint['chunkIndex'] ?? 0;
    final chunkCount = checkpoint['chunkCount'] ?? 0;
    final chapterIndex = checkpoint['readingChapterIndex'] ?? 0;
    final totalChapters = checkpoint['totalChapters'] ?? 0;
    final status = switch (current.status) {
      ReadingTaskStatus.completed => l10n.readingTaskProgressCompleted,
      ReadingTaskStatus.failed => l10n.readingTaskProgressFailed(
          current.error ?? l10n.readingTaskProgressUnknownError),
      ReadingTaskStatus.cancelled => l10n.readingTaskProgressCancelled,
      ReadingTaskStatus.paused => l10n.readingTaskProgressPaused,
      _ => '${_stageLabel(current, l10n)} · ${(progress * 100).round()}%',
    };
    final terminal = current.isTerminal;
    final canResume = readingTaskScheduler.canResume(current.id) ||
        (current.type == 'fiction.backfill' && onResume != null);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    status,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!terminal &&
                    current.canPause &&
                    current.status == ReadingTaskStatus.running)
                  IconButton(
                    tooltip: l10n.readingTaskProgressPause,
                    onPressed: () => readingTaskScheduler.pause(current.id),
                    icon: const Icon(Icons.pause),
                  ),
                if (!terminal)
                  IconButton(
                    tooltip: l10n.readingTaskProgressCancel,
                    onPressed: () => readingTaskScheduler.cancel(current.id),
                    icon: const Icon(Icons.close),
                  ),
                if (current.status == ReadingTaskStatus.paused && canResume)
                  IconButton(
                    tooltip: l10n.readingTaskProgressResume,
                    onPressed: () => unawaited(_resumeTask(context, current)),
                    icon: const Icon(Icons.play_arrow),
                  ),
              ],
            ),
            if (chapter != null && chapter.isNotEmpty)
              Text(
                totalUnits is num && totalUnits > 0
                    ? l10n.readingTaskProgressChunks(chapter, '$chunkIndex',
                        '$chunkCount', '$completedUnits', '$totalUnits')
                    : l10n.readingTaskProgressChapters(
                        chapter, '$chapterIndex', '$totalChapters'),
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            if (current.status == ReadingTaskStatus.failed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.readingTaskProgressFailedHint,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (current.status == ReadingTaskStatus.cancelled)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.readingTaskProgressCancelledHint,
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
