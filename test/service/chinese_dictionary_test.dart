import 'package:anx_reader/service/dictionary/chinese_dictionary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChineseDictionaryService', () {
    test('recognizes Chinese lookup candidates only', () {
      expect(ChineseDictionaryService.isLookupCandidate('作家'), isTrue);
      expect(ChineseDictionaryService.isLookupCandidate('家'), isTrue);
      expect(
          ChineseDictionaryService.isLookupCandidate('中文 dictionary'), isFalse);
      expect(ChineseDictionaryService.isLookupCandidate('一二三四五六七八九'), isFalse);
    });

    test('loads an exact entry with multiple senses from bundled assets',
        () async {
      final entry = await ChineseDictionaryService.lookup('作家');

      expect(entry, isNotNull);
      expect(entry!.word, '作家');
      expect(entry.senses.length, greaterThan(1));
      expect(
          entry.senses.any((sense) => sense.definition.contains('文学')), isTrue);
    });

    test('expands a one-character selection using context boundaries',
        () async {
      final entry = await ChineseDictionaryService.lookup(
        '家',
        contextText: '他是一位著名作家。',
      );

      expect(entry, isNotNull);
      expect(entry!.word, '作家');
    });

    test('returns null for a missing phrase without network access', () async {
      final entry = await ChineseDictionaryService.lookup('龘龘龘');

      expect(entry, isNull);
    });

    test('resolves the longest dictionary word around the clicked offset',
        () async {
      final boundary = await ChineseDictionaryService.resolveBoundary(
        '他是一位著名作家。',
        7,
      );

      expect(boundary.word, '作家');
      expect(boundary.startOffset, 6);
      expect(boundary.endOffset, 8);
    });

    test('falls back to the clicked Chinese character', () async {
      final boundary = await ChineseDictionaryService.resolveBoundary(
        '甲龘乙',
        1,
      );

      expect(boundary.word, '龘');
      expect(boundary.startOffset, 1);
      expect(boundary.endOffset, 2);
    });
  });
}
