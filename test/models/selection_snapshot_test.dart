import 'package:anx_reader/models/selection_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses selection range metadata and safe defaults', () {
    final snapshot = SelectionSnapshot.fromJson({
      'sessionId': 4,
      'rangeType': 'sentence',
      'trigger': 'longPress',
      'text': ' Selected sentence. ',
      'cfi': 'epubcfi(/6/2)',
      'contextText': 'Context',
      'index': 2,
      'canMovePrevious': true,
      'canMoveNext': false,
      'supportsRangeSelection': true,
    });

    expect(snapshot.sessionId, 4);
    expect(snapshot.rangeType, SelectionRangeType.sentence);
    expect(snapshot.trigger, SelectionTrigger.longPress);
    expect(snapshot.text, 'Selected sentence.');
    expect(snapshot.canMovePrevious, isTrue);
    expect(snapshot.canMoveNext, isFalse);
    expect(snapshot.supportsRangeSelection, isTrue);
  });
}
