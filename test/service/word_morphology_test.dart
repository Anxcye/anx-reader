import 'package:anx_reader/service/dictionary/word_morphology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns common English inflection lemmas', () {
    expect(WordMorphology.englishLemmas('children'), contains('child'));
    expect(WordMorphology.englishLemmas('studies'), contains('study'));
    expect(WordMorphology.englishLemmas('running'), contains('run'));
    expect(WordMorphology.englishLemmas('worked'), contains('work'));
  });

  test('does not apply English morphology to Chinese text or phrases', () {
    expect(WordMorphology.englishLemmas('学习'), isEmpty);
    expect(WordMorphology.englishLemmas('two words'), isEmpty);
  });
}
