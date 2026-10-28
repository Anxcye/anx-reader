import 'package:anx_reader/models/chapter_split_presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('default chapter split pattern', () {
    final pattern = getDefaultChapterSplitRule().buildRegExp();

    test('matches headings with trailing ASCII whitespace', () {
      expect(pattern.hasMatch('第一章 '), isTrue);
      expect(pattern.hasMatch('第二章  '), isTrue);
    });

    test('matches headings with trailing ideographic whitespace', () {
      expect(pattern.hasMatch('第三章　'), isTrue);
    });
  });
}
