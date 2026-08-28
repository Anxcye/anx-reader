import 'package:anx_reader/utils/ai_reasoning_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removes reasoning and protocol tags from answer-only display text', () {
    const content = '<think>internal reasoning</think><text>真正的回答标题</text>';

    expect(
      cleanAiDisplayText(content, answerOnly: true),
      '真正的回答标题',
    );
  });

  test('removes unknown markup from generated titles', () {
    const content = '<thinking>ignore</thinking><reply>历史背景梳理</reply>';

    expect(
      cleanAiDisplayText(content, answerOnly: true),
      '历史背景梳理',
    );
  });
}
