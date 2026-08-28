import 'package:anx_reader/models/book_load_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookLoadFailure', () {
    test('parses structured bridge errors', () {
      final failure = BookLoadFailure.fromJson({
        'code': 'invalid_epub',
        'message': 'Central directory is missing',
        'stage': 'parse',
        'details': 'stack trace',
      });

      expect(failure.code, 'invalid_epub');
      expect(failure.message, 'Central directory is missing');
      expect(failure.stage, BookLoadStage.parse);
      expect(failure.details, 'stack trace');
    });

    test('uses safe defaults for malformed bridge payloads', () {
      final failure = BookLoadFailure.fromJson({'stage': 'not-a-stage'});

      expect(failure.code, 'unknown');
      expect(failure.message, 'Unknown reader error');
      expect(failure.stage, BookLoadStage.failed);
    });
  });

  test('load state exposes ready, slow, and failed transitions', () {
    final fetching = const BookLoadState().copyWith(
      stage: BookLoadStage.fetch,
      elapsedMs: 25,
      format: 'epub',
      isSlow: true,
    );
    expect(fetching.isReady, isFalse);
    expect(fetching.isSlow, isTrue);

    final ready = fetching.copyWith(stage: BookLoadStage.ready, isSlow: false);
    expect(ready.isReady, isTrue);

    final failed = BookLoadState(
      stage: BookLoadStage.failed,
      failure: const BookLoadFailure(code: 'parse', message: 'bad zip'),
    );
    expect(failed.hasFailed, isTrue);
  });
}
