import 'dart:async';

import 'package:anx_reader/service/sync/sync_request_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('joins duplicate requests to the same Future', () async {
    final gate = SyncRequestGate<int>();
    final release = Completer<void>();
    var calls = 0;

    final first = gate.run(() async {
      calls++;
      await release.future;
      return 7;
    });
    final second = gate.run(() async {
      calls++;
      return 9;
    });

    expect(identical(first, second), isTrue);
    expect(gate.isRunning, isTrue);
    release.complete();
    expect(await second, 7);
    expect(calls, 1);
    expect(gate.isRunning, isFalse);
  });

  test('releases the gate after failure so a later request can retry',
      () async {
    final gate = SyncRequestGate<void>();
    var calls = 0;

    await expectLater(
      gate.run(() async {
        calls++;
        throw StateError('offline');
      }),
      throwsA(isA<StateError>()),
    );
    expect(gate.isRunning, isFalse);

    await gate.run(() async {
      calls++;
    });
    expect(calls, 2);
  });
}
