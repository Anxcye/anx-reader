import 'package:flutter_test/flutter_test.dart';
import 'package:webview_cef/webview_cef.dart';

void main() {
  test('InjectUserScripts filters scripts by injection time', () {
    final scripts = InjectUserScripts()
      ..add(UserScript('start-1', ScriptInjectTime.LOAD_START))
      ..add(UserScript('end-1', ScriptInjectTime.LOAD_END))
      ..add(UserScript('start-2', ScriptInjectTime.LOAD_START));

    expect(
      scripts.retrieveLoadStartInjectScripts().map((s) => s.script),
      ['start-1', 'start-2'],
    );
    expect(
      scripts.retrieveLoadEndInjectScripts().map((s) => s.script),
      ['end-1'],
    );
  });

  test('JavascriptChannel rejects invalid channel names', () {
    expect(
      () => JavascriptChannel(name: '1invalid', onMessageReceived: (_) {}),
      throwsA(isA<AssertionError>()),
    );
    expect(
      JavascriptChannel(name: 'validName', onMessageReceived: (_) {}).name,
      'validName',
    );
  });
}
