import 'package:anx_reader/service/dictionary/english_dictionary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnglishDictionaryService.isEnglishWord', () {
    test('accepts common English word selections', () {
      expect(EnglishDictionaryService.isEnglishWord('Developing'), isTrue);
      expect(EnglishDictionaryService.isEnglishWord(' self-aware '), isTrue);
      expect(EnglishDictionaryService.isEnglishWord("reader's"), isTrue);
      expect(EnglishDictionaryService.isEnglishWord('word.'), isTrue);
    });

    test('rejects phrases and non-English selections', () {
      expect(EnglishDictionaryService.isEnglishWord('role self'), isFalse);
      expect(EnglishDictionaryService.isEnglishWord('hello world.'), isFalse);
      expect(EnglishDictionaryService.isEnglishWord('生词'), isFalse);
      expect(EnglishDictionaryService.isEnglishWord('123'), isFalse);
      expect(EnglishDictionaryService.isEnglishWord(''), isFalse);
    });
  });
}
