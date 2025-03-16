import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/ai_chat_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiChatPage extends ConsumerWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).ai_chat),
      ),
      body: const SafeArea(
        child: AiChatStream(),
      ),
    );
  }
}
