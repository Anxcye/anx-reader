import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        return SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(child: MarkdownBody(data: data)),
                ],
              ),
              if (widget.canCopy)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
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
}
