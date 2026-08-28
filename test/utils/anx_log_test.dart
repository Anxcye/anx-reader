import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  test('parses a persisted log without truncating message delimiters', () {
    const raw = 'SEVERE^*^ 2026-08-10T10:20:30.000Z^*^ [BookImport[x] '
        'stage=copy_failed detail=a^*^b] : IOException';

    final log = AnxLog.parse(raw);

    expect(log.level, Level.SEVERE);
    expect(log.time, DateTime.utc(2026, 8, 10, 10, 20, 30));
    expect(log.message, contains('detail=a^*^b'));
    expect(log.raw, raw);
  });

  test('keeps malformed native lines visible', () {
    final log = AnxLog.parse('incomplete native log');

    expect(log.level, Level.SHOUT);
    expect(log.message, contains('incomplete native log'));
  });
}
