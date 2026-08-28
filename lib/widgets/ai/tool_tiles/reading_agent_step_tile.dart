import 'dart:convert';

import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/service/ai/agent_action_service.dart';
import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:anx_reader/utils/ai_reasoning_parser.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/ai/tool_tiles/tool_tile_base.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ReadingAgentStepTile extends StatefulWidget {
  const ReadingAgentStepTile({super.key, required this.step});

  final ParsedToolStep step;

  @override
  State<ReadingAgentStepTile> createState() => _ReadingAgentStepTileState();
}

class _ReadingAgentStepTileState extends State<ReadingAgentStepTile> {
  Map<String, dynamic>? _preview;
  bool _requiresConfirmation = false;
  bool _applying = false;
  bool _applied = false;
  bool _canReturn = false;
  bool _completed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _readOutput();
  }

  @override
  void didUpdateWidget(covariant ReadingAgentStepTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.output != widget.step.output) _readOutput();
  }

  void _readOutput() {
    Map<String, dynamic>? preview;
    var requiresConfirmation = false;
    var canReturn = false;
    var completed = false;
    String? error;
    try {
      final decoded = jsonDecode(widget.step.output ?? '');
      final data = decoded is Map ? decoded['data'] : null;
      if (data is Map) {
        requiresConfirmation = data['requiresConfirmation'] == true;
        canReturn = data['canReturn'] == true;
        completed = data['created'] == true || data['saved'] == true;
        final value = data['preview'];
        if (value is Map) preview = Map<String, dynamic>.from(value);
      }
    } catch (_) {
      error = '无法读取 Agent 建议';
    }
    if (preview == null && error == null) {
      error = requiresConfirmation ? '建议内容为空' : null;
    }
    setState(() {
      _preview = preview;
      _requiresConfirmation = requiresConfirmation;
      _error = error;
      _canReturn = canReturn;
      _completed = completed;
      _applied = false;
      _applying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolTileBase(
      title: _title,
      leadingIcon: Icons.auto_awesome_outlined,
      statusColor: ToolTileBase.statusColorFor(widget.step.status),
      initiallyExpanded: _requiresConfirmation,
      contentBuilder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error ?? _previewText),
          if (_requiresConfirmation) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _applying || _applied
                      ? null
                      : () => setState(() {
                            _requiresConfirmation = false;
                          }),
                  child: const Text('忽略'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _applying || _applied ? null : _confirm,
                  child: _applying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_applied ? '已保存' : '确认保存'),
                ),
              ],
            ),
          ],
          if (widget.step.name == 'reader_navigate' && _canReturn) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  final bookId = readingAgentRuntime.state.bookId;
                  if (bookId == null) return;
                  final returned = ReaderCommandGateway.instance
                      .returnToPreviousLocation(bookId: bookId);
                  if (returned) setState(() => _canReturn = false);
                },
                icon: const Icon(Icons.undo),
                label: const Text('返回原位置'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _title => switch (widget.step.name) {
        'reading_goal_set' => '阅读目标建议',
        'reading_note_create' => '阅读笔记建议',
        'reading_difficulty_save' => '阅读难点建议',
        'reading_memory_append' => 'Markdown 记忆建议',
        'reader_navigate' => '阅读器导航',
        _ => '阅读 Agent 建议',
      };

  String get _previewText {
    final preview = _preview;
    if (preview == null) {
      if (widget.step.name == 'reader_navigate') return '已在当前书内导航';
      return _completed ? '已按你的要求保存，可从动作记录撤销' : '等待建议';
    }
    return switch (widget.step.name) {
      'reading_goal_set' => preview['title']?.toString() ?? '',
      'reading_note_create' =>
        '${preview['title'] ?? ''}\n${preview['body'] ?? ''}'.trim(),
      'reading_difficulty_save' => preview['text']?.toString() ?? '',
      'reading_memory_append' => preview['markdown']?.toString() ?? '',
      'reader_navigate' => '已在当前书内导航',
      _ => preview.toString(),
    };
  }

  Future<void> _confirm() async {
    final preview = _preview;
    final state = readingAgentRuntime.state;
    final bookId = state.bookId;
    if (preview == null || bookId == null || state.sessionId == null) {
      AnxToast.show('阅读页面已关闭，无法执行');
      return;
    }
    setState(() => _applying = true);
    try {
      switch (widget.step.name) {
        case 'reading_goal_set':
          final now = DateTime.now().millisecondsSinceEpoch;
          await agentActionService.saveGoal(
            ReadingGoal(
              id: const Uuid().v4(),
              bookId: bookId,
              title: preview['title']?.toString() ?? '',
              range: preview['range'] is Map
                  ? Map<String, dynamic>.from(preview['range'] as Map)
                  : const {},
              timeBudgetMinutes:
                  (preview['timeBudgetMinutes'] as num?)?.toInt(),
              criteria: (preview['criteria'] as List? ?? const [])
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .take(3)
                  .toList(growable: false),
              createdAt: now,
              updatedAt: now,
            ),
          );
          break;
        case 'reading_note_create':
          await agentActionService.createSourcedNote(
            bookId: bookId,
            sourceText: preview['sourceText']?.toString() ?? '',
            cfi: preview['cfi']?.toString() ?? '',
            chapterTitle: preview['chapterTitle']?.toString() ?? '',
            chapterHref: preview['chapterHref']?.toString(),
            body: preview['body']?.toString() ?? '',
            title: preview['title']?.toString() ?? '',
            model: preview['model']?.toString() ?? 'unknown',
          );
          break;
        case 'reading_difficulty_save':
          final now = DateTime.now().millisecondsSinceEpoch;
          await agentActionService.saveDifficulty(
            ReadingDifficulty(
              id: const Uuid().v4(),
              bookId: bookId,
              cfi: preview['cfi']?.toString() ?? '',
              text: preview['text']?.toString() ?? '',
              context: preview['context']?.toString(),
              chapterTitle: preview['chapterTitle']?.toString(),
              chapterHref: preview['chapterHref']?.toString(),
              createdAt: now,
              updatedAt: now,
            ),
          );
          break;
        case 'reading_memory_append':
          final now = DateTime.now().millisecondsSinceEpoch;
          await agentActionService.appendMemory(ReadingMemoryDocument(
              id: const Uuid().v4(),
              bookId: bookId,
              title: preview['title']?.toString() ?? '',
              markdown: preview['markdown']?.toString() ?? '',
              sourceRefs: (preview['sourceRefs'] as List? ?? const [])
                  .map((value) => value.toString())
                  .toList(growable: false),
              createdAt: now,
              updatedAt: now));
          break;
        default:
          throw StateError('Unsupported Reading Agent suggestion');
      }
      if (!mounted) return;
      setState(() {
        _applying = false;
        _applied = true;
        _requiresConfirmation = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _applying = false);
      AnxToast.show('保存失败：$error');
    }
  }
}
