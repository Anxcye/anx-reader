import 'package:anx_reader/enums/ai_prompts.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anx_reader/config/shared_preference_provider.dart';

void main() {
  test('full text translation prompt preserves batch separators', () async {
    SharedPreferences.setMockInitialValues({});
    Prefs().prefs = await SharedPreferences.getInstance();
    Prefs().saveAiPrompt(
      AiPrompts.fullTextTranslate,
      'Translate from {{from_locale}} to {{to_locale}}.',
    );

    final payload = generatePromptFullTextTranslate(
      'one\x1ftwo',
      '简体中文',
      'English',
    );
    final prompt = payload
        .buildMessages()
        .map((message) => message.contentAsString)
        .join('\n');

    expect(prompt, contains('U+001F'));
    expect(prompt, contains('same number of U+001F-separated segments'));
    expect(prompt, contains('one\x1ftwo'));
  });
}
