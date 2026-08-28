import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/device_display_profile.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/page/settings_page/ai.dart';
import 'package:anx_reader/page/settings_page/ai_provider_list_page.dart';
import 'package:anx_reader/page/settings_page/translate.dart';
import 'package:anx_reader/widgets/common/container/outlined_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Prefs().prefs = await SharedPreferences.getInstance();
    Prefs().saveAiProviders([
      _provider('general').toJson(),
      _provider('translation').toJson(),
      _provider('fallback').toJson(),
    ]);
    Prefs().selectedAiService = 'general';
  });

  testWidgets('AI settings presents all four provider role cards',
      (tester) async {
    await _pumpAtSize(tester, const Size(500, 900), const AISettings());

    expect(find.text('General AI'), findsOneWidget);
    expect(find.text('Translation Engine'), findsOneWidget);
    expect(find.text('Failover'), findsWidgets);
    expect(
        find.byKey(const ValueKey('ai-general-provider-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('ai-translation-provider-card')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('ai-extraction-provider-card')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('ai-fallback-provider-card')),
        findsOneWidget);
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.text('Token 用量'), findsWidgets);
    expect(find.text('输入'), findsOneWidget);
    expect(find.text('输出'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet layout arranges provider roles in a two by two grid',
      (tester) async {
    await _pumpAtSize(tester, const Size(700, 900), const AISettings());

    final general = tester.getRect(
      find.byKey(const ValueKey('ai-general-provider-card')),
    );
    final translation = tester.getRect(
      find.byKey(const ValueKey('ai-translation-provider-card')),
    );
    final extraction = tester.getRect(
      find.byKey(const ValueKey('ai-extraction-provider-card')),
    );
    final fallback = tester.getRect(
      find.byKey(const ValueKey('ai-fallback-provider-card')),
    );

    expect(general.top, extraction.top);
    expect(translation.top, greaterThan(general.bottom));
    expect(translation.top, fallback.top);
    expect(extraction.width, closeTo(general.width, 1));
    expect(translation.width, closeTo(general.width, 1));
    expect(fallback.width, closeTo(general.width, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('translation provider list offers follow-general selection',
      (tester) async {
    Prefs().prefs.setString(
          'deviceDisplayProfile',
          DeviceDisplayProfile.eInk.code,
        );
    await _pumpAtSize(
      tester,
      const Size(500, 800),
      const AiProviderListPage(mode: AiProviderListMode.translation),
    );

    expect(find.text('Use Default AI Provider'), findsOneWidget);
    expect(find.byType(OutlinedContainer), findsWidgets);
    final selectionButton = find
        .ancestor(
          of: find.byIcon(Icons.check_circle),
          matching: find.byType(IconButton),
        )
        .first;
    final size = tester.getSize(selectionButton);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('translation settings has no duplicate AI provider selector',
      (tester) async {
    await _pumpAtSize(tester, const Size(500, 900), const TranslateSetting());

    expect(find.text('Translation Engine'), findsNothing);
    expect(find.text('Automatic fallback'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Translation Service Configuration'),
      250,
    );
    expect(find.text('Translation Service Configuration'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpAtSize(
  WidgetTester tester,
  Size size,
  Widget child,
) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AiProvider _provider(String id) {
  return AiProvider(
    id: id,
    title: id,
    url: 'http://localhost:1234/v1',
    protocol: AiProtocol.openai,
    apiKeys: [AiApiKey(id: '$id-key', key: '$id-api-key')],
    model: '$id-model',
  );
}
