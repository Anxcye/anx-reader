import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/service/ai/ai_token_usage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Prefs().prefs = await SharedPreferences.getInstance();
  });

  test('accumulates input and output usage for the current month', () {
    final service = AiTokenUsageService(
      clock: () => DateTime(2026, 8, 24),
    );

    service.record(inputTokens: 120, outputTokens: 30, estimated: false);
    service.record(inputTokens: 80, outputTokens: 20, estimated: true);

    final usage = service.snapshot();
    expect(usage.month, '2026-08');
    expect(usage.inputTokens, 200);
    expect(usage.outputTokens, 50);
    expect(usage.totalTokens, 250);
    expect(usage.requests, 2);
    expect(usage.estimatedRequests, 1);
  });

  test('starts a fresh counter when the calendar month changes', () {
    var now = DateTime(2026, 8, 31);
    final service = AiTokenUsageService(clock: () => now);
    service.record(inputTokens: 100, outputTokens: 10, estimated: false);

    now = DateTime(2026, 9);
    final usage = service.snapshot();
    expect(usage.month, '2026-09');
    expect(usage.totalTokens, 0);
    expect(usage.requests, 0);
  });

  test('reset clears only the current usage snapshot', () {
    final service = AiTokenUsageService(
      clock: () => DateTime(2026, 8, 24),
    );
    service.record(inputTokens: 100, outputTokens: 10, estimated: true);

    service.reset();

    expect(service.snapshot().totalTokens, 0);
    expect(service.snapshot().requests, 0);
  });

  test('separates local extraction and cloud verification usage', () async {
    final service = AiTokenUsageService(
      clock: () => DateTime(2026, 8, 24),
    );
    await service.runWithRole(AiTokenUsageRole.localExtraction, () async {
      service.record(inputTokens: 1000, outputTokens: 80, estimated: false);
    });
    await service.runWithRole(AiTokenUsageRole.cloudVerification, () async {
      service.record(inputTokens: 120, outputTokens: 20, estimated: true);
    });
    service.recordStorySavings(
      baselineInputTokens: 1000,
      cloudInputTokens: 120,
    );

    final usage = service.snapshot();
    expect(usage.byRole[AiTokenUsageRole.localExtraction]?.inputTokens, 1000);
    expect(usage.byRole[AiTokenUsageRole.cloudVerification]?.inputTokens, 120);
    expect(usage.storyCloudSavingRate, closeTo(.88, .0001));
  });

  test('reads legacy aggregate snapshots without role data', () {
    Prefs().prefs.setString(
          AiTokenUsageService.storageKey,
          '{"month":"2026-08","inputTokens":20,"outputTokens":5,'
          '"requests":1,"estimatedRequests":0,"startedAt":1}',
        );
    final service = AiTokenUsageService(
      clock: () => DateTime(2026, 8, 24),
    );
    expect(service.snapshot().totalTokens, 25);
    expect(service.snapshot().byRole, isEmpty);
  });
}
