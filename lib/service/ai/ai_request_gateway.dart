import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/providers/ai_providers.dart';
import 'package:anx_reader/service/ai/ai_request.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compatibility gateway for new AI workloads.
///
/// Existing callers may continue using aiGenerate*; new code should construct
/// an AiRequest so workload, source scope, output contract and trace metadata
/// travel together.
class AiRequestGateway {
  const AiRequestGateway();

  /// Read-only destination disclosure for an explicit request confirmation.
  /// Callers pin the returned ID on the request after confirmation.
  AiProvider? generalProvider([WidgetRef? ref]) {
    if (ref != null) {
      return ref
          .read(aiProvidersProvider.notifier)
          .getRunnableSelectedProvider();
    }
    final providers = Prefs()
        .getAiProviders()
        .map((item) => AiProvider.fromJson(Map<String, dynamic>.from(item)))
        .where((provider) => provider.isRunnable)
        .toList();
    return providers
            .where((provider) => provider.id == Prefs().selectedAiService)
            .firstOrNull ??
        providers.firstOrNull;
  }

  AiStreamResult execute(AiRequest request) => executeAiRequest(request);

  Stream<String> executeStream(AiRequest request) =>
      executeAiRequestStream(request);

  Future<String> executeText(AiRequest request) =>
      executeAiRequestText(request);

  Future<AiGenerationResult<String>> executeTextWithMetadata(
    AiRequest request,
  ) =>
      executeAiRequestTextWithMetadata(request);
}

const aiRequestGateway = AiRequestGateway();
