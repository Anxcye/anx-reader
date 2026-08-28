import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/markdown/styled_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:anx_reader/utils/ai_reasoning_parser.dart';
import 'package:anx_reader/widgets/ai/tool_step_tile.dart';
import 'package:anx_reader/widgets/ai/tool_tiles/mindmap_step_tile.dart';
import 'package:anx_reader/widgets/ai/tool_tiles/organize_bookshelf_step_tile.dart';
import 'package:anx_reader/widgets/ai/tool_tiles/apply_book_tags_step_tile.dart';
import 'package:anx_reader/widgets/ai/tool_tiles/reading_agent_step_tile.dart';

class AiStream extends ConsumerStatefulWidget {
  const AiStream({
    super.key,
    required this.prompt,
    this.identifier,
    this.config,
    this.canCopy = true,
    this.regenerate = false,
    this.useAgent = false,
    this.allowFallback = true,
  });

  final PromptTemplatePayload prompt;
  final String? identifier;
  final Map<String, String>? config;
  final bool canCopy;
  final bool regenerate;
  final bool useAgent;
  final bool allowFallback;

  @override
  AiStreamState createState() => AiStreamState();
}

class AiStreamState extends ConsumerState<AiStream> {
  late Stream<String> stream;

  @override
  void initState() {
    super.initState();
    stream = _createStream(widget.regenerate);
  }

  Stream<String> _createStream(bool regenerate) {
    final messages = widget.prompt.buildMessages();
    return aiGenerateStream(
      messages,
      identifier: widget.identifier,
      config: widget.config,
      regenerate: regenerate,
      useAgent: widget.useAgent,
      ref: ref,
      allowFallback: widget.allowFallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return SizedBox(
              width: 300,
              height: 60,
              child: Skeletonizer.zone(
                child: Bone.multiText(),
              ));
        }

        final l10n = L10n.of(context);
        final data = snapshot.data!;
        final parsed = parseReasoningContent(data);
        final answerWidgets = _buildTimeline(parsed.answerTimeline);
        final reasoningWidgets = _buildTimeline(
          parsed.reasoningTimeline,
          fontSize: 13,
        );
        final isCompleted = snapshot.connectionState == ConnectionState.done;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reasoningWidgets.isNotEmpty)
                _buildThinkingPanel(reasoningWidgets),
              if (reasoningWidgets.isNotEmpty && answerWidgets.isNotEmpty)
                const SizedBox(height: 8),
              if (answerWidgets.isNotEmpty)
                ...answerWidgets
              else if (!isCompleted)
                Skeletonizer.zone(child: Bone.multiText())
              else
                const SizedBox.shrink(),
              if (widget.canCopy)
                Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          stream = _createStream(true);
                        });
                      },
                      child: Text(l10n.aiRegenerate),
                    ),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: data));
                        AnxToast.show(l10n.notesPageCopied);
                      },
                      child: Text(l10n.commonCopy),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTimeline(
    List<ParsedReasoningEntry> timeline, {
    double? fontSize,
  }) {
    final widgets = <Widget>[];
    for (var i = 0; i < timeline.length; i++) {
      final entry = timeline[i];
      switch (entry.type) {
        case ParsedReasoningEntryType.reply:
          if (entry.text != null && entry.text!.trim().isNotEmpty) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: StyledMarkdown(
                  data: entry.text!,
                  selectable: true,
                  fontSize: fontSize,
                ),
              ),
            );
          }
          break;
        case ParsedReasoningEntryType.tool:
          if (entry.toolStep != null) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildToolTile(entry.toolStep!),
              ),
            );
          }
          break;
      }
      if (i != timeline.length - 1) {
        widgets.add(const SizedBox(height: 4));
      }
    }
    return widgets;
  }

  Widget _buildThinkingPanel(List<Widget> children) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary.withValues(alpha: 0.82);
    final subtleColor = theme.colorScheme.secondary.withValues(alpha: 0.68);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        dense: true,
        visualDensity: VisualDensity.compact,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.fromLTRB(28, 2, 0, 8),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: subtleColor,
        collapsedIconColor: subtleColor,
        leading: Icon(
          Icons.psychology_alt_outlined,
          size: 15,
          color: accentColor,
        ),
        title: Text(
          L10n.of(context).aiThinkingHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: accentColor,
            fontSize: 12,
          ),
        ),
        children: [
          Container(
            margin: const EdgeInsets.only(left: 7),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: subtleColor.withValues(alpha: 0.55),
                  width: 2,
                ),
              ),
            ),
            child: Opacity(
              opacity: 0.9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolTile(ParsedToolStep step) {
    if (step.name == 'bookshelf_organize') {
      return OrganizeBookshelfStepTile(step: step);
    }
    if (step.name == 'mindmap_draw') {
      return MindmapStepTile(step: step);
    }
    if (step.name == 'apply_book_tags') {
      return ApplyBookTagsStepTile(step: step);
    }
    if (const {
      'reading_goal_set',
      'reading_note_create',
      'reading_difficulty_save',
      'reading_memory_append',
      'reader_navigate',
    }.contains(step.name)) {
      return ReadingAgentStepTile(step: step);
    }
    return ToolStepTile(step: step);
  }
}
