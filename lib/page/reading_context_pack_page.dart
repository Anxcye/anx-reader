import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_context_pack.dart';
import 'package:anx_reader/service/ai/reading_context_pack_service.dart';
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
  });

  final Book book;
  final double visibleProgress;
  final String? chapterHref;
  final Future<void> Function()? onGenerate;
  final Future<void> Function()? onGenerateFullBook;

  @override
  State<ReadingContextPackPage> createState() => _ReadingContextPackPageState();
}

class _ReadingContextPackPageState extends State<ReadingContextPackPage> {
  late Future<ReadingContextPack> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
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
      if (mounted) setState(_reload);
    } finally {
      if (mounted) setState(() => _busy = false);
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
    body: FutureBuilder<ReadingContextPack>(
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
        if (pack.isEmpty) return _empty(context);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                  onPressed: _busy ? null : _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('从已读部分建立/更新'),
                ),
              ),
            if (widget.onGenerateFullBook != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _busy ? null : _generateFullBook,
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
                      node.summary.isEmpty ? node.content : node.summary,
                      if (node.sourceLabel.isNotEmpty) '来源：${node.sourceLabel}',
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
    ),
  );

  Widget _empty(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            onPressed: _busy || widget.onGenerate == null ? null : _generate,
            child: const Text('从已读部分建立'),
          ),
          if (widget.onGenerateFullBook != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _generateFullBook,
              child: const Text('生成全书上下文（可能剧透）'),
            ),
          ],
        ],
      ),
    ),
  );
}
