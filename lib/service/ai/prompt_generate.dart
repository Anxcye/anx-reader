import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/ai_prompts.dart';

String generatePromptTest() {
  String prompt = Prefs().getAiPrompt(AiPrompts.test);
  String currentLocale = Prefs().locale?.languageCode ?? Platform.localeName;
  prompt = prompt.replaceAll('{{language_locale}}', currentLocale);
  return prompt;
}
