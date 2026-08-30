import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/ai_quick_prompt_chip.dart';
import 'package:anx_reader/models/user_prompt.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

List<AiQuickPromptChip> buildDefaultAiQuickPromptChips(BuildContext context) {
  final List<UserPrompt> userPrompts = Prefs().userPrompts;

  return [
    AiQuickPromptChip(
      icon: EvaIcons.book,
      label: L10n.of(context).settingsAiPromptSummaryTheChapter,
      prompt: generatePromptSummaryTheChapter().buildString(),
    ),
    AiQuickPromptChip(
      icon: Icons.menu_book_rounded,
      label: L10n.of(context).settingsAiPromptSummaryTheBook,
      prompt: generatePromptSummaryTheBook().buildString(),
    ),
    AiQuickPromptChip(
      icon: Icons.account_tree_outlined,
      label: L10n.of(context).settingsAiPromptMindmap,
      prompt: generatePromptMindmap().buildString(),
    ),
    ...userPrompts.where((prompt) => prompt.enabled).map(
          (prompt) => AiQuickPromptChip(
            icon: Icons.person_outline,
            label: prompt.name,
            prompt: prompt.content,
          ),
        ),
  ];
}
