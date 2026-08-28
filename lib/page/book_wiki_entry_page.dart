import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/service/ai/agent_action_service.dart';
import 'package:anx_reader/service/ai/reading_device_identity.dart';
import 'package:anx_reader/widgets/markdown/styled_markdown.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BookWikiEntryPage extends StatefulWidget {
  const BookWikiEntryPage(
      {super.key,
      required this.book,
      required this.entry,
      this.onOpenLocation});
  final Book book;
  final BookWikiEntry entry;
  final Future<void> Function(String target)? onOpenLocation;
  @override
  State<BookWikiEntryPage> createState() => _BookWikiEntryPageState();
}

class _BookWikiEntryPageState extends State<BookWikiEntryPage> {
  late BookWikiEntry entry = widget.entry;

  Future<void> _correct() async {
    final controller = TextEditingController();
    final save = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('提交纠正说明'),
                content: TextField(
                    controller: controller,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 6),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('取消')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('保存纠正'))
                ]));
    final correction = controller.text.trim();
    controller.dispose();
    if (save != true || correction.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = entry.copyWith(
        contentMarkdown: '${entry.contentMarkdown}\n\n## 用户纠正\n\n$correction',
        userCorrected: true,
        version: entry.version + 1,
        updatedAt: now);
    final device = await ReadingDeviceIdentity().getOrCreate();
    await agentActionService.saveWikiEntry(updated,
        revision: BookWikiRevision(
            id: const Uuid().v4(),
            entryId: updated.id,
            bookId: updated.bookId,
            baseVersion: entry.version,
            kind: 'correction',
            correction: correction,
            beforeSnapshot: entry.toDb(),
            afterSnapshot: updated.toDb(),
            deviceId: device,
            createdAt: now));
    if (mounted) setState(() => entry = updated);
  }

  Future<void> _hide() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = entry.copyWith(
        status: BookWikiEntryStatus.hidden,
        userCorrected: true,
        version: entry.version + 1,
        updatedAt: now);
    final device = await ReadingDeviceIdentity().getOrCreate();
    await agentActionService.saveWikiEntry(updated,
        revision: BookWikiRevision(
            id: const Uuid().v4(),
            entryId: updated.id,
            bookId: updated.bookId,
            baseVersion: entry.version,
            kind: 'hide',
            beforeSnapshot: entry.toDb(),
            afterSnapshot: updated.toDb(),
            deviceId: device,
            createdAt: now));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(entry.title), actions: [
        PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'correct') _correct();
              if (value == 'hide') _hide();
            },
            itemBuilder: (_) => const [
                  PopupMenuItem(value: 'correct', child: Text('这条信息不准确')),
                  PopupMenuItem(value: 'hide', child: Text('隐藏此条'))
                ])
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(entry.summary, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        if (entry.contentMarkdown.isNotEmpty)
          StyledMarkdown(data: entry.contentMarkdown),
        const SizedBox(height: 20),
        Text(entry.epistemicStatus == 'agentInference' ? 'AI 推断' : '文本事实/用户内容',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 12),
        for (final source in entry.sources)
          ListTile(
              leading: const Icon(Icons.link),
              title: Text(source.chapterTitle ?? '来源章节'),
              subtitle: Text(source.textSnapshot,
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              onTap: widget.onOpenLocation == null
                  ? null
                  : () => widget.onOpenLocation!(source.cfi?.isNotEmpty == true
                      ? source.cfi!
                      : source.chapterHref ?? '')),
      ]));
}
