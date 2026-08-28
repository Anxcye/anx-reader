import 'package:anx_reader/models/ai_provider.dart';

class TranslationAiProviderResolution {
  const TranslationAiProviderResolution({
    required this.effectiveProviderId,
    required this.usedDedicatedProvider,
    required this.invalidDedicatedProviderId,
  });

  final String? effectiveProviderId;
  final bool usedDedicatedProvider;
  final String? invalidDedicatedProviderId;
}

class TranslationAiProviderResolver {
  const TranslationAiProviderResolver._();

  static TranslationAiProviderResolution resolve({
    required List<AiProvider> providers,
    required String selectedProviderId,
    required String? translationProviderId,
  }) {
    final dedicatedId = translationProviderId?.trim();
    if (dedicatedId != null && dedicatedId.isNotEmpty) {
      final dedicated = providerById(providers, dedicatedId);
      if (dedicated != null && isRunnableProvider(dedicated)) {
        return TranslationAiProviderResolution(
          effectiveProviderId: dedicated.id,
          usedDedicatedProvider: true,
          invalidDedicatedProviderId: null,
        );
      }
    }

    final selected = providerById(providers, selectedProviderId);
    final fallback = selected != null && isRunnableProvider(selected)
        ? selected
        : providers.where(isRunnableProvider).firstOrNull;

    return TranslationAiProviderResolution(
      effectiveProviderId: fallback?.id,
      usedDedicatedProvider: false,
      invalidDedicatedProviderId:
          dedicatedId == null || dedicatedId.isEmpty ? null : dedicatedId,
    );
  }

  static AiProvider? providerById(List<AiProvider> providers, String id) {
    try {
      return providers.firstWhere((provider) => provider.id == id);
    } catch (_) {
      return null;
    }
  }

  static bool isRunnableProvider(AiProvider provider) {
    return provider.isRunnable;
  }
}
