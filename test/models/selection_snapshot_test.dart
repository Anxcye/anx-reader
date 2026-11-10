import 'package:anx_reader/models/selection_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selection snapshot accepts the stable character range type', () {
    final snapshot = SelectionSnapshot.fromJson(const {
      'sessionId': 1,
      'rangeType': 'character',
      'trigger': 'rangeButton',
      'text': '阅',
      'cfi': 'epubcfi(/6/2)',
    });

    expect(snapshot.rangeType, SelectionRangeType.character);
    expect(snapshot.text, '阅');
  });

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

  test('accepts stable character movement triggers', () {
    expect(SelectionTrigger.fromCode('swipe'), SelectionTrigger.swipe);
    expect(
      SelectionTrigger.fromCode('previousCharacter'),
      SelectionTrigger.previousCharacter,
    );
    expect(
      SelectionTrigger.fromCode('nextCharacter'),
      SelectionTrigger.nextCharacter,
    );
  });

  test('legacy payload cannot enable unsupported range controls', () {
    final snapshot = SelectionSnapshot.fromJson(const {
      'text': '原文',
      'cfi': 'epubcfi(/6/2)',
      'contextText': '   ',
    });

    expect(snapshot.sessionId, 0);
    expect(snapshot.revision, 0);
    expect(snapshot.chapterIndex, -1);
    expect(snapshot.rangeType, SelectionRangeType.custom);
    expect(snapshot.trigger, SelectionTrigger.manual);
    expect(snapshot.contextText, isNull);
    expect(snapshot.supportsRangeSelection, isFalse);
    expect(snapshot.canAdjustStartPrevious, isFalse);
    expect(snapshot.canAdjustStartNext, isFalse);
    expect(snapshot.canAdjustEndPrevious, isFalse);
    expect(snapshot.canAdjustEndNext, isFalse);
    expect(snapshot.canExtendNextPage, isFalse);
    expect(snapshot.canUndoExtension, isFalse);
    expect(snapshot.canShowSelectionEnd, isFalse);
    expect(snapshot.sourceProgress, isNull);
    expect(snapshot.visibleFromProgress, isNull);
    expect(snapshot.flow, 'paginated');
  });

  test('modern payload preserves revision, boundary and extension metadata',
      () {
    final snapshot = SelectionSnapshot.fromJson(const {
      'sessionId': 8,
      'revision': 17,
      'trigger': 'extendPage',
      'rangeType': 'custom',
      'canAdjustStartPrevious': true,
      'canAdjustStartNext': true,
      'canAdjustEndPrevious': true,
      'canAdjustEndNext': false,
      'canExtendNextPage': false,
      'canUndoExtension': true,
      'canShowSelectionEnd': true,
      'extensionUnavailableReason': 'chapterEnd',
      'sourceProgress': 0.42,
      'visibleFromProgress': 0.45,
      'flow': 'scrolled',
    });

    expect(snapshot.sessionId, 8);
    expect(snapshot.revision, 17);
    expect(snapshot.trigger, SelectionTrigger.extendPage);
    expect(snapshot.canAdjustStartPrevious, isTrue);
    expect(snapshot.canAdjustStartNext, isTrue);
    expect(snapshot.canAdjustEndPrevious, isTrue);
    expect(snapshot.canAdjustEndNext, isFalse);
    expect(snapshot.canExtendNextPage, isFalse);
    expect(snapshot.canUndoExtension, isTrue);
    expect(snapshot.canShowSelectionEnd, isTrue);
    expect(snapshot.extensionUnavailableReason, 'chapterEnd');
    expect(snapshot.sourceProgress, 0.42);
    expect(snapshot.visibleFromProgress, 0.45);
    expect(snapshot.flow, 'scrolled');
    expect(SelectionTrigger.fromCode('boundaryAdjustment'),
        SelectionTrigger.boundaryAdjustment);
    expect(SelectionTrigger.fromCode('undoExtension'),
        SelectionTrigger.undoExtension);
  });

  test('unverifiable progress is rejected instead of becoming visible', () {
    for (final value in <Object?>[
      null,
      '0.5',
      double.nan,
      double.infinity,
      double.negativeInfinity,
      -0.01,
      1.01,
    ]) {
      final snapshot = SelectionSnapshot.fromJson({
        'sourceProgress': value,
        'visibleFromProgress': value,
      });
      expect(snapshot.sourceProgress, isNull, reason: '$value');
      expect(snapshot.visibleFromProgress, isNull, reason: '$value');
    }
    for (final value in [0, 1]) {
      final snapshot = SelectionSnapshot.fromJson({
        'sourceProgress': value,
        'visibleFromProgress': value,
      });
      expect(snapshot.sourceProgress, value.toDouble());
      expect(snapshot.visibleFromProgress, value.toDouble());
    }
  });
}
