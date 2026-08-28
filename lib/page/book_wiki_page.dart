import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/page/book_wiki_entry_page.dart';
import 'package:anx_reader/service/ai/book_wiki_service.dart';
import 'package:flutter/material.dart';
import 'package:anx_reader/service/ai/book_wiki_export_service.dart';
import 'package:anx_reader/utils/convert_string_to_uint8list.dart';
import 'package:anx_reader/utils/save_file_to_download.dart';

class BookWikiPage extends StatefulWidget {
  const BookWikiPage(
      {super.key,
      required this.book,
      this.visibleProgress,
      this.onGenerate,
      this.onOpenLocation});
  final Book book;
  final double? visibleProgress;
  final Future<void> Function(bool fullBook)? onGenerate;
  final Future<void> Function(String target)? onOpenLocation;
  @override
  State<BookWikiPage> createState() => _BookWikiPageState();
}

class _BookWikiPageState extends State<BookWikiPage> {
  late Future<BookWikiSnapshot> _future;
  bool _showAll = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = bookWikiService.load(widget.book.id,
      visibleAtProgress:
          widget.visibleProgress ?? widget.book.readingPercentage,
      showAll: _showAll);

  Future<void> _generate(bool fullBook) async {
    final callback = widget.onGenerate;
    if (callback == null) return;
    await callback(fullBook);
    if (mounted) {
      setState(() {
        _reload();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('书籍 Wiki'), actions: [
          IconButton(
              tooltip: '刷新',
              onPressed: () => setState(() {
                    _reload();
                  }),
              icon: const Icon(Icons.refresh)),
          IconButton(
              tooltip: '导出 Markdown',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final snapshot = await _future;
                final path = await saveFileToDownload(
                    bytes: convertStringToUint8List(bookWikiExportService
                        .toMarkdown(widget.book, snapshot)),
                    fileName: '${widget.book.title}.md',
                    mimeType: 'text/markdown');
                if (path != null && mounted) {
                  messenger.showSnackBar(SnackBar(content: Text('已导出：$path')));
                }
              },
              icon: const Icon(Icons.ios_share)),
          PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'all') {
                  setState(() {
                    _showAll = !_showAll;
                    _reload();
                  });
                }
              },
              itemBuilder: (_) => [
                    CheckedPopupMenuItem(
                        value: 'all',
                        checked: _showAll,
                        child: const Text('显示全部内容（可能剧透）')),
                  ]),
        ]),
        body: FutureBuilder<BookWikiSnapshot>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snap.data!;
              if (data.entries.isEmpty) return _empty(context);
              final groups = data.sections.entries.toList();
              return ListView(padding: const EdgeInsets.all(16), children: [
                Card(
                    child: ListTile(
                        leading: const Icon(Icons.menu_book),
                        title: Text(widget.book.title),
                        subtitle: Text(
                            '覆盖 ${(data.wiki?.coverageEnd ?? 0) * 100 ~/ 1}% · ${_showAll ? '显示全部' : '当前阅读边界'}'))),
                if (widget.onGenerate != null)
                  Card(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        TextButton.icon(
                            onPressed: () => _generate(false),
                            icon: const Icon(Icons.update),
                            label: const Text('更新 Wiki')),
                        TextButton.icon(
                            onPressed: () => _generate(true),
                            icon: const Icon(Icons.public),
                            label: const Text('生成全书 Wiki')),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                for (final group in groups)
                  _section(context, group.key, group.value),
              ]);
            }),
      );
  Widget _section(
          BuildContext context, String kind, List<BookWikiEntry> entries) =>
      Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(_label(kind),
                style: Theme.of(context).textTheme.titleMedium)),
        for (final entry in entries.take(8))
          ListTile(
              title: Text(entry.title),
              subtitle: Text(entry.summary,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BookWikiEntryPage(
                          book: widget.book,
                          entry: entry,
                          onOpenLocation: widget.onOpenLocation)))),
      ]));
  Widget _empty(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.menu_book_outlined, size: 56),
            const SizedBox(height: 12),
            const Text('这本书还没有 Wiki'),
            const SizedBox(height: 8),
            Text(
                '从已读部分生成，当前边界 ${(widget.visibleProgress ?? widget.book.readingPercentage) * 100 ~/ 1}%。'),
            const SizedBox(height: 16),
            FilledButton(
                onPressed:
                    widget.onGenerate == null ? null : () => _generate(false),
                child: const Text('从已读部分生成')),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed:
                    widget.onGenerate == null ? null : () => _generate(true),
                child: const Text('生成全书 Wiki'))
          ])));
  String _label(String kind) =>
      const {
        BookWikiEntryKinds.overview: '简介',
        BookWikiEntryKinds.chapter: '章节',
        BookWikiEntryKinds.part: '篇章',
        BookWikiEntryKinds.concept: '核心概念',
        BookWikiEntryKinds.method: '阅读方法',
        BookWikiEntryKinds.argument: '主要观点',
        BookWikiEntryKinds.character: '主要人物',
        BookWikiEntryKinds.relationship: '人物关系',
        BookWikiEntryKinds.event: '重要事件',
        BookWikiEntryKinds.theme: '核心主题',
        BookWikiEntryKinds.question: '未解决问题',
        BookWikiEntryKinds.memory: '阅读成果'
      }[kind] ??
      '专题';
}
