import 'package:anx_reader/service/translate/index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isFailedTranslationResult', () {
    test('detects leaked Chinese translation prompt blocks', () {
      const leakedPrompt = '''
目标语言：汽车

源文本：开发角色自我

要求：
- 仅输出翻译后的文本，不得包含其他内容。
- 不要包含任何解释、注释或原文内容。
- 保留段落结构及格式。
- 保持原文的语气和风格。
''';

      expect(isFailedTranslationResult(leakedPrompt), isTrue);
    });

    test('detects leaked English translation prompt blocks', () {
      const leakedPrompt = '''
Source text:
Developing a Role-Self

Reader context:

Output only the final translated text.
Do not output the source text, titles, labels, explanations, notes, commentary, or quotation marks unless they already belong to the source.
''';

      expect(isFailedTranslationResult(leakedPrompt), isTrue);
    });

    test('does not reject a normal translation', () {
      expect(isFailedTranslationResult('发展角色自我'), isFalse);
    });
  });
}
