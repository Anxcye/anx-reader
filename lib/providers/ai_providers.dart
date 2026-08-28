import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/models/ai_extraction_config.dart';
import 'package:anx_reader/service/ai/ai_services.dart';
import 'package:anx_reader/service/translate/translation_ai_provider_resolver.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'ai_providers.g.dart';

@Riverpod(keepAlive: true)
class AiProviders extends _$AiProviders {
  @override
  List<AiProvider> build() {
    final rawProviders = Prefs().getAiProviders();

    // If empty, initialize with built-in providers migrated from old config
    if (rawProviders.isEmpty) {
      return _initializeDefaultProviders();
    }

    // Convert from JSON
    try {
      final providers = rawProviders
          .map((json) => AiProvider.fromJson(json as Map<String, dynamic>))
          .toList();
      _normalizeSelections(providers);
      return providers;
    } catch (e) {
      // If parsing fails, reinitialize
      return _initializeDefaultProviders();
    }
  }

  /// Initialize default providers from old configuration
  List<AiProvider> _initializeDefaultProviders() {
    final defaultServices = buildDefaultAiServices();
    final now = DateTime.now();

    final providers = defaultServices.map((option) {
      // Try to migrate from old config
      final oldConfig = Prefs().getAiConfig(option.identifier);
      final url = oldConfig['url'] ?? option.defaultUrl;
      final model = oldConfig['model'] ?? option.defaultModel;
      final apiKey = oldConfig['api_key'] ?? option.defaultApiKey;

      // Determine protocol from identifier
      AiProtocol protocol;
      switch (option.identifier) {
        case 'claude':
          protocol = AiProtocol.claude;
          break;
        case 'gemini':
          protocol = AiProtocol.gemini;
          break;
        default:
          protocol = AiProtocol.openai;
      }

      return AiProvider(
        id: option.identifier,
        title: option.title,
        logoAsset: option.logo,
        url: url,
        protocol: protocol,
        enabled: true,
        isBuiltin: true,
        apiKeys: apiKey.isNotEmpty && apiKey != 'YOUR_API_KEY'
            ? [
                AiApiKey(
                  id: const Uuid().v4(),
                  key: apiKey,
                  enabled: true,
                  createdAt: now,
                ),
              ]
            : [],
        model: model,
        keyIndex: 0,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    // Save to storage
    Prefs().saveAiProviders(providers);
    _normalizeSelections(providers);

    return providers;
  }

  /// Get the currently selected provider
  AiProvider? getSelectedProvider() {
    final selectedId = Prefs().selectedAiService;
    return getProviderById(selectedId);
  }

  /// Get a provider by its id, returns null if not found
  AiProvider? getProviderById(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  AiProvider? getRunnableSelectedProvider() {
    final selectedId = Prefs().selectedAiService;
    final selected = getRunnableProviderById(selectedId);
    if (selected != null) return selected;

    return state.where(isRunnableProvider).firstOrNull;
  }

  AiProvider? getRunnableTranslationProvider() {
    final resolution = TranslationAiProviderResolver.resolve(
      providers: state,
      selectedProviderId: Prefs().selectedAiService,
      translationProviderId: Prefs().translationAiProvider,
    );
    final providerId = resolution.effectiveProviderId;
    if (providerId == null) return null;
    return getRunnableProviderById(providerId);
  }

  AiProvider? getDedicatedTranslationProvider() {
    final providerId = Prefs().translationAiProvider;
    if (providerId == null) return null;
    return getRunnableProviderById(providerId);
  }

  AiExtractionConfig getExtractionConfig() =>
      AiExtractionConfig.fromJson(Prefs().aiExtractionConfig);

  AiProvider? getExtractionProvider() {
    final config = getExtractionConfig();
    if (!config.isConfigured) return null;
    return getRunnableProviderById(config.providerId!);
  }

  bool setExtractionProvider(String? providerId) {
    if (providerId == null) {
      Prefs().aiExtractionConfig = const AiExtractionConfig().toJson();
      _notifySelectionChanged();
      return true;
    }
    final provider = getRunnableProviderById(providerId);
    if (provider == null) return false;
    Prefs().aiExtractionConfig = AiExtractionConfig(
      enabled: true,
      providerId: provider.id,
    ).toJson();
    _notifySelectionChanged();
    return true;
  }

  AiProvider? getFallbackProvider() {
    final providerId = Prefs().aiFallbackProvider;
    if (providerId == null || providerId == Prefs().selectedAiService) {
      return null;
    }
    return getRunnableProviderById(providerId);
  }

  AiProvider? getRunnableProviderById(String id) {
    final provider = getProviderById(id);
    if (provider == null || !isRunnableProvider(provider)) {
      return null;
    }
    return provider;
  }

  List<AiProvider> getRunnableFallbackCandidates(String? primaryId) {
    return state
        .where((p) => p.id != primaryId && isRunnableProvider(p))
        .toList(growable: false);
  }

  bool isRunnableProvider(AiProvider provider) {
    return provider.isRunnable;
  }

  /// Set the selected provider
  bool setSelectedProvider(String providerId) {
    final provider = getRunnableProviderById(providerId);
    if (provider == null) return false;

    Prefs().selectedAiService = providerId;
    if (Prefs().aiFallbackProvider == providerId) {
      Prefs().aiFallbackProvider = null;
    }
    if (Prefs().translationAiProvider == providerId) {
      Prefs().translationAiProvider = null;
    }
    _notifySelectionChanged();
    return true;
  }

  /// Set a dedicated translation provider. Null, or selecting the current
  /// general provider, means translation follows the general AI setting.
  bool setTranslationProvider(String? providerId) {
    if (providerId == null || providerId == Prefs().selectedAiService) {
      Prefs().translationAiProvider = null;
      _notifySelectionChanged();
      return true;
    }

    final provider = getRunnableProviderById(providerId);
    if (provider == null) return false;

    Prefs().translationAiProvider = provider.id;
    _notifySelectionChanged();
    return true;
  }

  /// Set the fallback used after an AI provider request fails. The fallback
  /// must be runnable and different from the general provider.
  bool setFallbackProvider(String? providerId) {
    if (providerId == null) {
      Prefs().aiFallbackProvider = null;
      _notifySelectionChanged();
      return true;
    }

    if (providerId == Prefs().selectedAiService ||
        getRunnableProviderById(providerId) == null) {
      return false;
    }

    Prefs().aiFallbackProvider = providerId;
    _notifySelectionChanged();
    return true;
  }

  /// Add a new custom provider
  String addProvider(AiProvider provider) {
    final now = DateTime.now();
    final requestedId = provider.id.trim();
    final providerId = requestedId.isNotEmpty &&
            !state.any((existing) => existing.id == requestedId)
        ? requestedId
        : const Uuid().v4();
    final newProvider = provider.copyWith(
      id: providerId,
      createdAt: now,
      updatedAt: now,
    );

    state = [...state, newProvider];
    Prefs().saveAiProviders(state);
    _normalizeSelections(state);
    return providerId;
  }

  /// Update an existing provider
  void updateProvider(AiProvider provider) {
    final now = DateTime.now();
    final updatedProvider = provider.copyWith(updatedAt: now);

    state = [
      for (final p in state)
        if (p.id == provider.id) updatedProvider else p,
    ];
    Prefs().saveAiProviders(state);

    _normalizeSelections(state);
  }

  /// Delete a provider (only custom providers can be deleted)
  void deleteProvider(String providerId) {
    final provider = state.firstWhere((p) => p.id == providerId);

    if (provider.isBuiltin) {
      throw Exception('Cannot delete built-in provider');
    }

    state = state.where((p) => p.id != providerId).toList();
    Prefs().saveAiProviders(state);

    // If deleted provider was selected, select another
    if (Prefs().selectedAiService == providerId) {
      final runnable = state.where(isRunnableProvider).firstOrNull;
      if (runnable != null) {
        Prefs().selectedAiService = runnable.id;
      }
    }
    _normalizeSelections(state);
  }

  /// Toggle provider enabled state
  void toggleProvider(String providerId, bool enabled) {
    state = [
      for (final p in state)
        if (p.id == providerId) p.copyWith(enabled: enabled) else p,
    ];
    Prefs().saveAiProviders(state);

    if (Prefs().selectedAiService == providerId && !enabled) {
      final nextProvider = state.where(isRunnableProvider).firstOrNull;
      if (nextProvider != null) {
        Prefs().selectedAiService = nextProvider.id;
      }
    }
    _normalizeSelections(state);
  }

  /// Advance the key index for round-robin (called after successful API call)
  void advanceKeyIndex(String providerId) {
    state = [
      for (final p in state)
        if (p.id == providerId)
          p.copyWith(keyIndex: p.keyIndex + 1, updatedAt: DateTime.now())
        else
          p,
    ];
    Prefs().saveAiProviders(state);
  }

  /// Add API key to a provider
  void addApiKey(String providerId, String key, {String? label}) {
    final provider = state.firstWhere((p) => p.id == providerId);
    final newKey = AiApiKey(
      id: const Uuid().v4(),
      key: key,
      enabled: true,
      label: label,
      createdAt: DateTime.now(),
    );

    final updatedProvider = provider.copyWith(
      apiKeys: [...provider.apiKeys, newKey],
      updatedAt: DateTime.now(),
    );

    updateProvider(updatedProvider);
  }

  /// Update an API key
  void updateApiKey(
    String providerId,
    String keyId, {
    String? key,
    String? label,
    bool? enabled,
  }) {
    final provider = state.firstWhere((p) => p.id == providerId);

    final updatedKeys = provider.apiKeys.map((k) {
      if (k.id == keyId) {
        return AiApiKey(
          id: k.id,
          key: key ?? k.key,
          enabled: enabled ?? k.enabled,
          label: label ?? k.label,
          createdAt: k.createdAt,
        );
      }
      return k;
    }).toList();

    final updatedProvider = provider.copyWith(
      apiKeys: updatedKeys,
      updatedAt: DateTime.now(),
    );

    updateProvider(updatedProvider);
  }

  /// Delete an API key
  void deleteApiKey(String providerId, String keyId) {
    final provider = state.firstWhere((p) => p.id == providerId);

    final updatedProvider = provider.copyWith(
      apiKeys: provider.apiKeys.where((k) => k.id != keyId).toList(),
      updatedAt: DateTime.now(),
    );

    updateProvider(updatedProvider);
  }

  /// Refresh providers (reload from storage)
  void refresh() {
    final providers = Prefs().getAiProviders();
    state = providers
        .map((json) => AiProvider.fromJson(json as Map<String, dynamic>))
        .toList();
    _normalizeSelections(state);
  }

  void _normalizeSelections(List<AiProvider> providers) {
    AiProvider? runnableById(String? providerId) {
      if (providerId == null) return null;
      return providers
          .where((provider) => provider.id == providerId)
          .where(isRunnableProvider)
          .firstOrNull;
    }

    final selectedId = Prefs().selectedAiService;
    if (runnableById(selectedId) == null) {
      final replacement = providers.where(isRunnableProvider).firstOrNull;
      if (replacement != null) {
        Prefs().selectedAiService = replacement.id;
      }
    }

    final translationId = Prefs().translationAiProvider;
    if (translationId != null &&
        (translationId == Prefs().selectedAiService ||
            runnableById(translationId) == null)) {
      Prefs().translationAiProvider = null;
    }

    final fallbackId = Prefs().aiFallbackProvider;
    if (fallbackId != null &&
        (fallbackId == Prefs().selectedAiService ||
            runnableById(fallbackId) == null)) {
      Prefs().aiFallbackProvider = null;
    }

    final extraction = getExtractionConfig();
    if (extraction.isConfigured &&
        runnableById(extraction.providerId) == null) {
      Prefs().aiExtractionConfig = const AiExtractionConfig().toJson();
    }
  }

  void _notifySelectionChanged() {
    state = List<AiProvider>.of(state);
  }
}
