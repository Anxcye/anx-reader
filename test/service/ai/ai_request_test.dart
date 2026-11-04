import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/ai_request.dart';
import 'package:anx_reader/service/ai/ai_request_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('stream failure delivery preserves legacy text and supports retry UI',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Prefs().initPrefs();
    final legacy = await aiRequestGateway
        .executeStream(AiRequest(
          messages: [ChatMessage.humanText('question')],
          providerId: 'unconfigured',
          fallbackPolicy: AiFallbackPolicy.none,
        ))
        .toList();
    expect(legacy, ['AI service not configured']);

    final chunks = <String>[];
    await expectLater(() async {
      await for (final chunk in aiRequestGateway.executeStream(AiRequest(
        messages: [ChatMessage.humanText('question')],
        providerId: 'unconfigured',
        fallbackPolicy: AiFallbackPolicy.none,
        failureDelivery: AiFailureDelivery.streamError,
      ))) {
        chunks.add(chunk);
      }
    }(), throwsA(isA<AiGenerationFailure>()));
    expect(chunks, isEmpty);
  });

  test('request derives stable workload and a unique trace id', () {
    final first = AiRequest(
      messages: [ChatMessage.humanText('hello')],
      contextTask: AiContextTask.translation,
    );
    final second = AiRequest(
      messages: [ChatMessage.humanText('hello')],
      contextTask: AiContextTask.translation,
    );

    expect(first.workloadId, 'translation.selection');
    expect(first.trace.workloadId, first.workloadId);
    expect(first.trace.requestId, isNotEmpty);
    expect(first.trace.requestId, isNot(second.trace.requestId));
  });

  test('workload descriptors lock structured task defaults', () {
    final fiction = AiWorkloadDescriptorRegistry.find('fiction.story_atlas');
    final summary =
        AiWorkloadDescriptorRegistry.find('context.rolling_summary');

    expect(fiction?.contextTask, AiContextTask.fictionBackfill);
    expect(fiction?.outputContract.kind, AiOutputKind.json);
    expect(
      fiction?.fallbackPolicy,
      AiFallbackPolicy.confirmBeforeFullTextCloud,
    );
    expect(summary?.fallbackPolicy, AiFallbackPolicy.none);
    expect(summary?.providerRole, AiProviderRole.localExtraction);
  });
}
