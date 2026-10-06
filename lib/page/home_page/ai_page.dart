import 'package:anx_reader/service/ai/quick_prompt_chips.dart';
import 'package:anx_reader/widgets/ai/ai_chat_stream.dart';
import 'package:flutter/material.dart';

class AiPage extends StatelessWidget {
  const AiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AiChatStream(
          quickPromptChips: buildDefaultAiQuickPromptChips(context),
        ),
      ),
    );
  }
}
