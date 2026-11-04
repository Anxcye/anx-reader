import 'dart:async';

import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_context_pack.dart';
import 'package:anx_reader/models/reading_task.dart';
import 'package:anx_reader/service/ai/reading_context_pack_service.dart';
import 'package:anx_reader/service/ai/reading_task_scheduler.dart';
import 'package:anx_reader/widgets/ai/reading_task_progress_card.dart';
import 'package:flutter/material.dart';

/// Read-only browser for the AI context projection. Generation is deliberately
/// injected by the caller so this page cannot choose a provider or start work
/// just because it was opened.
class ReadingContextPackPage extends StatefulWidget {
  const ReadingContextPackPage({
    super.key,
    required this.book,
    required this.visibleProgress,
    this.chapterHref,
    this.onGenerate,
    this.onGenerateFullBook,
    this.onResumeTask,
  });

  final Book book;
  final double visibleProgress;
  final String? chapterHref;
  final Future<void> Function()? onGenerate;
  final Future<void> Function()? onGenerateFullBook;
  final Future<void> Function(ReadingTask task)? onResumeTask;

  @override
  State<ReadingContextPackPage> createState() => _ReadingContextPackPageState();
}

class _ReadingContextPackPageState extends State<ReadingContextPackPage> {
  late Future<ReadingContextPack> _future;
  StreamSubscription<List<ReadingTask>>? _taskSubscription;
  String? _lastCompletedTaskId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
    _taskSubscription = readingTaskScheduler.changes.listen((tasks) {
      final task = ReadingTaskProgressCard.latestForBook(tasks, widget.book.id);
      if (task?.status != ReadingTaskStatus.completed ||
          task!.id == _lastCompletedTaskId ||
          !mounted) {
        return;
      }
      _lastCompletedTaskId = task.id;
      setState(_reload);
    });
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    super.dispose();
  }

  void _reload() {
    _future = readingContextPackService.load(
      widget.book.id,
      visibleAtProgress: widget.visibleProgress,
      chapterHref: widget.chapterHref,
    );
  }

  Future<void> _generate() async {
    final action = widget.onGenerate;
    await _runGeneration(action);
  }

  Future<void> _generateFullBook() async {
    await _runGeneration(widget.onGenerateFullBook);
  }

  Future<void> _runGeneration(Future<void> Function()? action) async {
    if (action == null || _busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on ReadingTaskCancelled {
      // Cancellation is an intentional user action.
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成未完成：$error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _reload();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('本书 AI 上下文'),
          actions: [
            IconButton(
              tooltip: '刷新',
              onPressed: () => setState(_reload),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: StreamBuilder<List<ReadingTask>>(
          stream: readingTaskScheduler.changes,
          initialData: readingTaskScheduler.tasks,
          builder: (context, taskSnapshot) {
            final task = ReadingTaskProgressCard.latestForBook(
              taskSnapshot.data ?? const [],
              widget.book.id,
            );
            final taskActive = task != null && !task.isTerminal;
            return FutureBuilder<ReadingContextPack>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('读取上下文失败：${snapshot.error}'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pack = snapshot.requireData;
                if (pack.isEmpty) return _empty(context, task);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ReadingTaskProgressCard(
                      task: task,
                      busy: _busy,
                      onResume: widget.onResumeTask,
                    ),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.memory_outlined),
                        title: Text(widget.book.title),
                        subtitle: Text(
                          '覆盖 ${(pack.coverageEnd * 100).round()}% · '
                          '当前可见 ${(widget.visibleProgress * 100).round()}% · '
                          '${pack.nodes.length} 个上下文节点',
                        ),
                      ),
                    ),
                    if (widget.onGenerate != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _busy || taskActive ? null : _generate,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('从已读部分建立/更新'),
                        ),
                      ),
                    if (widget.onGenerateFullBook != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed:
                              _busy || taskActive ? null : _generateFullBook,
                          icon: const Icon(Icons.public_outlined),
                          label: const Text('生成全书上下文（可能剧透）'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text('上下文包只供 AI 按需读取，保留来源和剧透边界；打开页面不会调用模型。'),
                    const SizedBox(height: 12),
                    for (final node in pack.nodes)
                      Card(
                        child: ListTile(
                          title: Text(node.title),
                          subtitle: Text(
                            [
                              node.summary.isEmpty
                                  ? node.content
                                  : node.summary,
                              if (node.sourceLabel.isNotEmpty)
                                '来源：${node.sourceLabel}',
                            ].join('\n'),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            node.epistemicStatus == 'textFact' ? '事实' : '推断',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      );

  Widget _empty(BuildContext context, ReadingTask? task) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Empty state is still a live task surface: an in-progress
              // task disables duplicate starts while its card remains visible.
              ReadingTaskProgressCard(
                task: task,
                busy: _busy,
                onResume: widget.onResumeTask,
              ),
              const Icon(Icons.memory_outlined, size: 56),
              const SizedBox(height: 12),
              const Text('尚未建立本书 AI 上下文'),
              const SizedBox(height: 8),
              Text(
                '当前安全边界 ${(widget.visibleProgress * 100).round()}%，不会读取后文。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ||
                        (task != null && !task.isTerminal) ||
                        widget.onGenerate == null
                    ? null
                    : _generate,
                child: const Text('从已读部分建立'),
              ),
              if (widget.onGenerateFullBook != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy || (task != null && !task.isTerminal)
                      ? null
                      : _generateFullBook,
                  child: const Text('生成全书上下文（可能剧透）'),
                ),
              ],
            ],
          ),
        ),
      );
}
