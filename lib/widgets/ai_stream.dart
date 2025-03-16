import 'package:anx_reader/enums/ai_role.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/ai_message.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiStream extends ConsumerStatefulWidget {
  final String prompt;
  final String? identifier;
  final Map<String, String>? config;
  final bool canCopy;

  const AiStream({
    super.key,
    required this.prompt,
    this.identifier,
    this.config,
    this.canCopy = true,
  });

  @override
  AiStreamState createState() => AiStreamState();
}

class AiStreamState extends ConsumerState<AiStream> {
  late Stream stream;

  @override
  void initState() {
    super.initState();
    stream = aiGenerateStream(
      ref,
      [AiMessage(content: widget.prompt, role: AiRole.user)],
      identifier: widget.identifier,
      config: widget.config,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (kDebugMode) {
            throw snapshot.error!;
          }
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
        return SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(child: MarkdownBody(data: snapshot.data!)),
                ],
              ),
              if (widget.canCopy)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          stream = aiGenerateStream(
                            ref,
                            [AiMessage(content: widget.prompt, role: AiRole.user)],
                            identifier: widget.identifier,
                            config: widget.config,
                            regenerate: true,
                          );
                        });
                      },
                      child: Text(L10n.of(context).ai_regenerate),
                    ),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: snapshot.data!));
                        AnxToast.show(L10n.of(context).notes_page_copied);
                      },
                      child: Text(L10n.of(context).common_copy),
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
