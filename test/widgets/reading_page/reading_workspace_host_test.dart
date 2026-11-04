import 'package:anx_reader/widgets/reading_page/reading_workspace_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _StateProbe extends StatefulWidget {
  const _StateProbe({super.key});
  @override
  State<_StateProbe> createState() => _StateProbeState();
}

class _StateProbeState extends State<_StateProbe> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(controller: controller);
}

void main() {
  Widget host(
          {bool visible = true,
          bool expanded = false,
          bool atBottom = false,
          double keyboard = 0}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: keyboard)),
          child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: ReadingWorkspaceHost(
                visible: visible,
                expanded: expanded,
                atBottom: atBottom,
                reader: const ColoredBox(
                    key: ValueKey('reader'), color: Colors.white),
                panel: const _StateProbe(key: ValueKey('companion')),
              )),
        ),
      );

  testWidgets('phone starts at 56 percent and keyboard expands above inset',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host());
    expect(tester.getSize(find.byKey(const ValueKey('companion'))).height,
        closeTo(447, 1));
    await tester.pumpWidget(host(keyboard: 300));
    expect(tester.getSize(find.byKey(const ValueKey('companion'))).height,
        closeTo(499, 1));
    expect(
        tester.getBottomLeft(find.byKey(const ValueKey('companion'))).dy, 500);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resize and close preserve companion state and reader element',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host());
    final reader = tester.element(find.byKey(const ValueKey('reader')));
    final companion = tester.state<_StateProbeState>(find.byType(_StateProbe));
    companion.controller.text = 'A question to keep';
    expect(tester.getSize(find.byKey(const ValueKey('reader'))).width, 720);
    await tester.pumpWidget(host(visible: false));
    expect(tester.getSize(find.byKey(const ValueKey('reader'))).width, 1200);
    await tester.binding.setSurfaceSize(const Size(400, 800));
    await tester.pumpWidget(host(expanded: true));
    expect(tester.element(find.byKey(const ValueKey('reader'))), same(reader));
    expect(tester.state<_StateProbeState>(find.byType(_StateProbe)),
        same(companion));
    expect(find.text('A question to keep'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom preference keeps the reading surface available',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(atBottom: true));
    expect(tester.getSize(find.byKey(const ValueKey('reader'))),
        const Size(1200, 620));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet keyboard leaves the assistant input visible',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(keyboard: 300));
    expect(
        tester.getBottomLeft(find.byKey(const ValueKey('companion'))).dy, 600);
    expect(tester.getSize(find.byKey(const ValueKey('companion'))).height, 600);
    expect(tester.takeException(), isNull);
  });

  test('wide layout reserves 400dp and clamps preferred panel sizes', () {
    expect(ReadingWorkspaceHost.usesSplit(839), isFalse);
    expect(ReadingWorkspaceHost.usesSplit(840), isTrue);
    expect(ReadingWorkspaceHost.effectiveWidth(840, 900), 440);
    expect(ReadingWorkspaceHost.effectiveWidth(1200, 0), 480);
    expect(ReadingWorkspaceHost.effectiveWidth(1400, 900), 520);
    expect(ReadingWorkspaceHost.effectiveWidth(1200, 200), 360);
  });
}
