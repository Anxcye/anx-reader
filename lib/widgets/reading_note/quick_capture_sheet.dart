import 'package:anx_reader/models/reading_note.dart';
import 'package:flutter/material.dart';

class ReadingNoteCaptureChoice {
  const ReadingNoteCaptureChoice(this.kind, {this.body = ''});
  final ReadingNoteCaptureKind kind;
  final String body;
}

Future<ReadingNoteCaptureChoice?> showReadingNoteQuickCaptureSheet(
    BuildContext context) async {
  return showModalBottomSheet<ReadingNoteCaptureChoice>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const _QuickCaptureSheet(),
  );
}

class _QuickCaptureSheet extends StatefulWidget {
  const _QuickCaptureSheet();

  @override
  State<_QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<_QuickCaptureSheet> {
  bool _showInput = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('记笔记', style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('选择一个动作即可保存，不需要输入'),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _choice(Icons.format_quote, '只保存划线',
                  ReadingNoteCaptureKind.highlight),
              _choice(
                  Icons.priority_high, '这是重点', ReadingNoteCaptureKind.keyPoint),
              _choice(
                  Icons.help_outline, '我有疑问', ReadingNoteCaptureKind.question),
              _choice(Icons.balance_outlined, '我不同意',
                  ReadingNoteCaptureKind.disagree),
              _choice(
                  Icons.task_alt, '可以实践', ReadingNoteCaptureKind.actionable),
              _choice(
                  Icons.inbox_outlined, '稍后整理', ReadingNoteCaptureKind.later),
              ActionChip(
                avatar: const Icon(Icons.edit_note, size: 18),
                label: const Text('补充文字'),
                onPressed: () => setState(() => _showInput = true),
              ),
            ],
          ),
          if (_showInput) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '记录你的想法…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  ReadingNoteCaptureChoice(
                    ReadingNoteCaptureKind.manual,
                    body: _controller.text.trim(),
                  ),
                ),
                child: const Text('保存笔记'),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _choice(IconData icon, String label, ReadingNoteCaptureKind kind) =>
      ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: () => Navigator.pop(
          context,
          ReadingNoteCaptureChoice(kind),
        ),
      );
}
