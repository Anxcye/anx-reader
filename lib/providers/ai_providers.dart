import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/service/ai/ai_services.dart';
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
      return rawProviders.map((json) {
        final map = json as Map<String, dynamic>;
        return AiProvider.migrateLegacyReasoning(
          AiProvider.fromJson(map),
          map,
        );
      }).toList();
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
                )
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

    return providers;
  }

  /// Get the currently selected provider
  AiProvider? getSelectedProvider() {
    final selectedId = Prefs().selectedAiService;
    try {
      return state.firstWhere((p) => p.id == selectedId);
    } catch (_) {
      // If not found, return first enabled provider
      final enabled = state.where((p) => p.enabled).toList();
      return enabled.isNotEmpty ? enabled.first : null;
    }
  }

  /// Get a provider by its id, returns null if not found
  AiProvider? getProviderById(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Set the selected provider
  void setSelectedProvider(String providerId) {
    Prefs().selectedAiService = providerId;
    ref.notifyListeners();
  }

  /// Add a new custom provider
  void addProvider(AiProvider provider) {
    final now = DateTime.now();
    final newProvider = provider.copyWith(
      id: const Uuid().v4(),
      createdAt: now,
      updatedAt: now,
    );

    state = [...state, newProvider];
    Prefs().saveAiProviders(state);
  }

  /// Update an existing provider
  void updateProvider(AiProvider provider) {
    final now = DateTime.now();
    final updatedProvider = provider.copyWith(updatedAt: now);

    state = [
      for (final p in state)
        if (p.id == provider.id) updatedProvider else p
    ];
    Prefs().saveAiProviders(state);
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
      final enabled = state.where((p) => p.enabled).toList();
      if (enabled.isNotEmpty) {
        setSelectedProvider(enabled.first.id);
      }
    }
  }

  /// Toggle provider enabled state
  void toggleProvider(String providerId, bool enabled) {
    state = [
      for (final p in state)
        if (p.id == providerId) p.copyWith(enabled: enabled) else p
    ];
    Prefs().saveAiProviders(state);
  }

  /// Advance the key index for round-robin (called after successful API call)
  void advanceKeyIndex(String providerId) {
    state = [
      for (final p in state)
        if (p.id == providerId)
          p.copyWith(keyIndex: p.keyIndex + 1, updatedAt: DateTime.now())
        else
          p
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
  void updateApiKey(String providerId, String keyId,
      {String? key, String? label, bool? enabled}) {
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
    state = providers.map((json) {
      final map = json as Map<String, dynamic>;
      return AiProvider.migrateLegacyReasoning(
        AiProvider.fromJson(map),
        map,
      );
    }).toList();
  }
}
