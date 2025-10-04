import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:anx_reader/utils/ai_reasoning_parser.dart';
import 'package:anx_reader/widgets/ai_reasoning_panel.dart';

class AiStream extends ConsumerStatefulWidget {
  const AiStream({
    super.key,
    required this.prompt,
    this.identifier,
    this.config,
    this.canCopy = true,
    this.regenerate = false,
  });

  final PromptTemplatePayload prompt;
  final String? identifier;
  final Map<String, String>? config;
  final bool canCopy;
  final bool regenerate;

  @override
  AiStreamState createState() => AiStreamState();
}

class AiStreamState extends ConsumerState<AiStream> {
  late Stream<String> stream;
  bool _reasoningExpanded = true;
  bool _userControlled = false;

  @override
  void initState() {
    super.initState();
    stream = _createStream(widget.regenerate);
  }

  Stream<String> _createStream(bool regenerate) {
    final messages = widget.prompt.buildMessages();
    return aiGenerateStream(
      ref,
      messages,
      identifier: widget.identifier,
      config: widget.config,
      regenerate: regenerate,
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
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
            ],
          );
        }

        final data = snapshot.data!;
        final parsed = parseReasoningContent(data);
        _syncReasoningState(parsed);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (parsed.hasThink)
                ReasoningPanel(
                  think: parsed.think,
                  expanded: _reasoningExpanded,
                  streaming: !parsed.hasAnswer,
                  onToggle: () {
                    setState(() {
                      _reasoningExpanded = !_reasoningExpanded;
                      _userControlled = true;
                    });
                  },
                ),
              if (parsed.hasAnswer)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: MarkdownBody(data: parsed.answer),
                )
              else if (!parsed.hasThink)
                Skeletonizer.zone(child: Bone.multiText()),
              if (widget.canCopy)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _userControlled = false;
                          _reasoningExpanded = true;
                          stream = _createStream(true);
                        });
                      },
                      child: Text(L10n.of(context).aiRegenerate),
                    ),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: data));
                        AnxToast.show(L10n.of(context).notesPageCopied);
                      },
                      child: Text(L10n.of(context).commonCopy),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  void _syncReasoningState(ParsedReasoning parsed) {
    if (_userControlled) return;
    final shouldExpand = !parsed.hasAnswer;
    if (_reasoningExpanded != shouldExpand) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _userControlled) return;
        setState(() {
          _reasoningExpanded = shouldExpand;
        });
      });
    }
  }
}
