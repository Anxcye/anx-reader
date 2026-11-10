import 'dart:async';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/reading_lookup.dart';
import 'package:anx_reader/models/selection_snapshot.dart';
import 'package:anx_reader/widgets/context_menu/translation_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReadingLookupCandidate candidate(String text,
        {ReadingLookupCandidateKind kind =
            ReadingLookupCandidateKind.englishWord}) =>
    ReadingLookupCandidate(
      text: text,
      kind: kind,
      trigger: SelectionTrigger.longPress,
      allowContextExpansion: false,
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Prefs().prefs = await SharedPreferences.getInstance();
  });

  Widget host(Widget child, {double textScale = 1}) => MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: child,
          ),
        ),
      );

  TranslationMenu menu({
    Key? key,
    String text = 'reading',
    bool offline = false,
    bool translateImmediately = false,
    bool aiGenerating = false,
    ReadingLookupCandidateKind kind = ReadingLookupCandidateKind.englishWord,
    required SelectionLookup lookup,
    Widget Function(String, String?)? translationBuilder,
    Future<void> Function(String, String?)? pronounce,
    VoidCallback? onExplainWithAi,
  }) =>
      TranslationMenu(
        key: key,
        content: text,
        candidate: candidate(text, kind: kind),
        contextText: 'A source context.',
        decoration: const BoxDecoration(),
        axis: Axis.horizontal,
        embedded: true,
        offline: offline,
        translateImmediately: translateImmediately,
        aiGenerating: aiGenerating,
        lookup: lookup,
        translationBuilder: translationBuilder,
        pronounce: pronounce,
        onExplainWithAi: onExplainWithAi,
      );

  testWidgets('opening a lookup reads local data without translation or audio',
      (tester) async {
    final policies = <NetworkPolicy>[];
    var translations = 0;
    var pronunciations = 0;
    await tester.pumpWidget(host(menu(
      lookup: (
          {required candidate, required networkPolicy, contextText}) async {
        policies.add(networkPolicy);
        return ReadingLookupResult(
          query: candidate.text,
          source: ReadingLookupSource.englishDictionary,
          definition: 'A cached definition.',
        );
      },
      translationBuilder: (text, contextText) {
        translations++;
        return const Text('translated');
      },
      pronounce: (text, audioUrl) async => pronunciations++,
    )));
    await tester.pumpAndSettle();

    expect(policies, [NetworkPolicy.offlineOnly]);
    expect(find.text('A cached definition.'), findsOneWidget);
    expect(translations, 0);
    expect(pronunciations, 0);
  });

  testWidgets('missing local result needs a click before network lookup',
      (tester) async {
    final policies = <NetworkPolicy>[];
    await tester.pumpWidget(host(menu(
      lookup: (
          {required candidate, required networkPolicy, contextText}) async {
        policies.add(networkPolicy);
        expect(candidate.text, 'reading');
        expect(contextText, 'A source context.');
        return networkPolicy == NetworkPolicy.offlineOnly
            ? ReadingLookupResult.empty(candidate.text)
            : ReadingLookupResult(
                query: candidate.text,
                source: ReadingLookupSource.englishDictionary,
                definition: 'An explicitly requested definition.',
              );
      },
    )));
    await tester.pumpAndSettle();
    expect(policies, [NetworkPolicy.offlineOnly]);
    await tester.tap(find.text('Look up online'));
    await tester.pumpAndSettle();
    expect(policies, [NetworkPolicy.offlineOnly, NetworkPolicy.networkAllowed]);
    expect(find.text('An explicitly requested definition.'), findsOneWidget);
  });

  testWidgets('a local lookup failure retries locally only after a click',
      (tester) async {
    final policies = <NetworkPolicy>[];
    await tester.pumpWidget(host(menu(
      offline: true,
      lookup: (
          {required candidate, required networkPolicy, contextText}) async {
        policies.add(networkPolicy);
        if (policies.length == 1) throw StateError('Temporary local failure');
        return ReadingLookupResult(
          query: candidate.text,
          source: ReadingLookupSource.englishDictionary,
          definition: 'Recovered local definition.',
        );
      },
    )));
    await tester.pumpAndSettle();
    expect(policies, [NetworkPolicy.offlineOnly]);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(policies, [NetworkPolicy.offlineOnly, NetworkPolicy.offlineOnly]);
    expect(find.text('Recovered local definition.'), findsOneWidget);
  });

  testWidgets('translation and audio start only from their buttons',
      (tester) async {
    var translations = 0;
    var pronunciations = 0;
    var networkLookups = 0;
    await tester.pumpWidget(host(menu(
      lookup: (
          {required candidate, required networkPolicy, contextText}) async {
        if (networkPolicy.allowsNetwork) networkLookups++;
        return ReadingLookupResult(
          query: candidate.text,
          source: ReadingLookupSource.englishDictionary,
          definition: 'Definition.',
          audioUrl:
              networkPolicy.allowsNetwork ? 'https://example.org/a.mp3' : null,
        );
      },
      translationBuilder: (text, contextText) {
        translations++;
        return const Text('An explicit translation.');
      },
      pronounce: (text, audioUrl) async {
        expect(text, 'reading');
        expect(audioUrl, 'https://example.org/a.mp3');
        pronunciations++;
      },
    )));
    await tester.pumpAndSettle();
    expect(translations, 0);
    expect(networkLookups, 0);
    expect(pronunciations, 0);

    await tester.tap(find.text('Play pronunciation'));
    await tester.pumpAndSettle();
    expect(pronunciations, 1);
    expect(networkLookups, 1);
    await tester.tap(find.text('Translate passage'));
    await tester.pumpAndSettle();
    expect(translations, 1);
    expect(find.text('An explicit translation.'), findsOneWidget);
  });

  testWidgets(
      'changing the live selection does not overwrite the frozen result',
      (tester) async {
    var lookups = 0;
    var originalExplanation = 0;
    var newExplanation = 0;
    Future<ReadingLookupResult> lookup(
        {required ReadingLookupCandidate candidate,
        required NetworkPolicy networkPolicy,
        String? contextText}) async {
      lookups++;
      return ReadingLookupResult(
        query: candidate.text,
        source: ReadingLookupSource.englishDictionary,
        definition: '${candidate.text} definition.',
      );
    }

    await tester.pumpWidget(host(menu(
      key: const ValueKey('frozen-source'),
      lookup: lookup,
      onExplainWithAi: () => originalExplanation++,
    )));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(menu(
      key: const ValueKey('frozen-source'),
      text: 'another',
      lookup: lookup,
      onExplainWithAi: () => newExplanation++,
    )));
    await tester.pumpAndSettle();

    expect(lookups, 1);
    expect(find.text('reading'), findsOneWidget);
    expect(find.text('another'), findsNothing);
    await tester.tap(find.text('AI context explanation'));
    expect(originalExplanation, 1);
    expect(newExplanation, 0);
  });

  testWidgets('a late result from a disposed selection cannot replace the next',
      (tester) async {
    final delayed = Completer<ReadingLookupResult>();
    await tester.pumpWidget(host(menu(
      key: const ValueKey('old'),
      lookup: ({required candidate, required networkPolicy, contextText}) =>
          delayed.future,
    )));
    await tester.pumpWidget(host(menu(
      key: const ValueKey('new'),
      text: 'new',
      lookup: (
              {required candidate,
              required networkPolicy,
              contextText}) async =>
          ReadingLookupResult(
        query: candidate.text,
        source: ReadingLookupSource.englishDictionary,
        definition: 'New result.',
      ),
    )));
    await tester.pumpAndSettle();
    delayed.complete(const ReadingLookupResult(
      query: 'reading',
      source: ReadingLookupSource.englishDictionary,
      definition: 'Stale result.',
    ));
    await tester.pumpAndSettle();
    expect(find.text('New result.'), findsOneWidget);
    expect(find.text('Stale result.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'offline passage keeps its full text and cannot start translation',
      (tester) async {
    var translations = 0;
    const passage = 'A long passage remains selected while offline.';
    await tester.pumpWidget(host(menu(
      text: passage,
      offline: true,
      translateImmediately: true,
      kind: ReadingLookupCandidateKind.passage,
      lookup: (
          {required candidate, required networkPolicy, contextText}) async {
        expect(networkPolicy, NetworkPolicy.offlineOnly);
        return ReadingLookupResult.empty(candidate.text);
      },
      translationBuilder: (text, contextText) {
        translations++;
        return const Text('must not appear');
      },
    )));
    await tester.pumpAndSettle();
    expect(find.text(passage), findsOneWidget);
    expect(find.text('Look up online'), findsNothing);
    expect(find.text('Play pronunciation'), findsNothing);
    final button = tester.widget<OutlinedButton>(find.ancestor(
        of: find.text('Translate passage'),
        matching:
            find.byWidgetPredicate((widget) => widget is OutlinedButton)));
    expect(button.onPressed, isNull);
    expect(translations, 0);
  });

  testWidgets('explicit translation intent starts once and rebuilds stay quiet',
      (tester) async {
    var translations = 0;
    final widget = menu(
      text: 'A selected passage.',
      kind: ReadingLookupCandidateKind.passage,
      translateImmediately: true,
      lookup: (
              {required candidate,
              required networkPolicy,
              contextText}) async =>
          ReadingLookupResult.empty(candidate.text),
      translationBuilder: (text, contextText) {
        translations++;
        return const Text('Translated passage.');
      },
    );
    await tester.pumpWidget(host(widget));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(widget));
    await tester.pumpAndSettle();
    expect(translations, 1);
    expect(find.text('Translated passage.'), findsOneWidget);
    expect(find.text('Look up online'), findsNothing);
  });

  testWidgets('authorized passage translates once when connectivity resolves',
      (tester) async {
    final translations = <String>[];
    final policies = <NetworkPolicy>[];
    Future<ReadingLookupResult> lookup({
      required ReadingLookupCandidate candidate,
      required NetworkPolicy networkPolicy,
      String? contextText,
    }) async {
      policies.add(networkPolicy);
      return ReadingLookupResult.empty(candidate.text);
    }

    Widget scene({required bool offline, required String text}) => host(menu(
          key: const ValueKey('authorized-passage'),
          text: text,
          kind: ReadingLookupCandidateKind.passage,
          offline: offline,
          translateImmediately: true,
          lookup: lookup,
          translationBuilder: (text, contextText) {
            translations.add(text);
            return Text('Translation for: $text');
          },
        ));
    const original = 'The explicitly requested passage.';
    await tester.pumpWidget(scene(offline: true, text: original));
    await tester.pumpAndSettle();
    expect(translations, isEmpty);
    expect(policies, [NetworkPolicy.offlineOnly]);

    await tester.pumpWidget(scene(offline: false, text: original));
    await tester.pumpAndSettle();
    expect(translations, [original]);
    expect(find.text('Translation for: $original'), findsOneWidget);

    // Rebuilding for a new live selection cannot replace or retranslate this
    // frozen result, including through subsequent connectivity changes.
    await tester.pumpWidget(scene(offline: false, text: 'Another selection.'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(scene(offline: true, text: 'Another selection.'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(scene(offline: false, text: 'Another selection.'));
    await tester.pumpAndSettle();
    expect(translations, [original]);
    expect(policies, [NetworkPolicy.offlineOnly]);
    expect(find.text('Another selection.'), findsNothing);
    expect(find.text('Translation for: $original'), findsOneWidget);
  });

  testWidgets('AI lookup entry makes stopping an active answer explicit',
      (tester) async {
    var explanations = 0;
    Widget scene(bool generating) => host(menu(
          key: const ValueKey('ai-state'),
          aiGenerating: generating,
          lookup: (
                  {required candidate,
                  required networkPolicy,
                  contextText}) async =>
              ReadingLookupResult.empty(candidate.text),
          onExplainWithAi: () => explanations++,
        ));
    await tester.pumpWidget(scene(false));
    await tester.pumpAndSettle();
    expect(find.text('AI context explanation'), findsOneWidget);
    expect(explanations, 0);
    await tester.pumpWidget(scene(true));
    await tester.pumpAndSettle();
    expect(find.text('AI context explanation'), findsNothing);
    expect(find.text('Stop and explain selection'), findsOneWidget);
    expect(explanations, 0);
    await tester.tap(find.text('Stop and explain selection'));
    expect(explanations, 1);
  });

  testWidgets('large text and imported markup stay inside the result panel',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(
      menu(
        lookup: (
                {required candidate,
                required networkPolicy,
                contextText}) async =>
            ReadingLookupResult(
          query: candidate.text,
          source: ReadingLookupSource.localMdx,
          dictionaryName: 'Imported dictionary',
          html:
              '<p>A local definition.</p><img src="https://example.org/no.png">',
        ),
      ),
      textScale: 2,
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
