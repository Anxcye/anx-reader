import 'package:anx_reader/service/vocabulary_capture_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VocabularyCaptureService.extractSourceSentence', () {
    test('returns the sentence containing the target word', () {
      final sentence = VocabularyCaptureService.extractSourceSentence(
        'world',
        'First line. Hello world, again! Last line.',
      );

      expect(sentence, 'Hello world, again!');
    });

    test('falls back to the whole context when the word is absent', () {
      final sentence = VocabularyCaptureService.extractSourceSentence(
        'missing',
        'Hello world, again!',
      );

      expect(sentence, 'Hello world, again!');
    });
  });

  group('VocabularyCaptureService.extractContextWindow', () {
    test('splits context around the extracted source sentence', () {
      final sourceSentence = VocabularyCaptureService.extractSourceSentence(
        'world',
        'Intro part. Hello world, again! Tail section.',
      );
      final window = VocabularyCaptureService.extractContextWindow(
        'world',
        'Intro part. Hello world, again! Tail section.',
        sourceSentence,
      );

      expect(sourceSentence, 'Hello world, again!');
      expect(window.before, 'Intro part.');
      expect(window.after, 'Tail section.');
    });

    test('returns empty side windows when there is no extra context', () {
      final window = VocabularyCaptureService.extractContextWindow(
        'world',
        'Hello world, again!',
        'Hello world, again!',
      );

      expect(window.before, isNull);
      expect(window.after, isNull);
    });
  });
}
