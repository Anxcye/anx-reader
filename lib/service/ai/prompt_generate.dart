import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/ai_prompts.dart';

String generatePromptTest() {
  String prompt = Prefs().getAiPrompt(AiPrompts.test);
  String currentLocale = Prefs().locale?.languageCode ?? Platform.localeName;
  prompt = prompt.replaceAll('{{language_locale}}', currentLocale);
  return prompt;
}

String generatePromptSummaryTheChapter(String chapter) {
  String prompt = Prefs().getAiPrompt(AiPrompts.summaryTheChapter);
  prompt = prompt.replaceAll('{{chapter}}', chapter);
  return prompt;
}

String generatePromptSummaryTheBook(String book, String author) {
  String prompt = Prefs().getAiPrompt(AiPrompts.summaryTheBook);
  prompt = prompt.replaceAll('{{book}}', book);
  prompt = prompt.replaceAll('{{author}}', author);
  return prompt;
}

String generatePromptSummaryThePreviousContent(String previousContent) {
  String prompt = Prefs().getAiPrompt(AiPrompts.summaryThePreviousContent);
  prompt = prompt.replaceAll('{{previous_content}}', previousContent);
  return prompt;
}
