import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

Widget aiStream(
  String prompt, {
  String? identifier,
  Map<String, String>? config,
  bool canCopy = true,
}) {
  return StreamBuilder(
      stream: aiGenerateStream(
        prompt,
        identifier: identifier,
        config: config,
      ),
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
        return SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(child: MarkdownBody(data: snapshot.data!)),
                ],
              ),
              if (canCopy)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
      });
}
