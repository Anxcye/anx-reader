import 'package:anx_reader/models/ai_provider.dart';

/// Helper class for API key rotation logic
class AiKeyRotator {
  /// Get the next available API key from the provider using round-robin strategy
  /// Returns null if no enabled keys are available
  static String? getNextKey(AiProvider provider) {
    if (provider.authMode == AiProviderAuthMode.none) return '';
    final enabledKeys = provider.apiKeys
        .where((key) => key.enabled && key.key.trim().isNotEmpty)
        .toList();

    if (enabledKeys.isEmpty) {
      return null;
    }

    // Use modulo to wrap around the key index
    final index = provider.keyIndex % enabledKeys.length;
    return enabledKeys[index].key.trim();
  }

  /// Check if the provider has any valid (enabled and non-empty) API keys
  static bool hasValidKey(AiProvider provider) {
    return provider.apiKeys.any((k) => k.enabled && k.key.trim().isNotEmpty);
  }

  /// Get all enabled keys for this provider
  static List<String> getEnabledKeys(AiProvider provider) {
    return provider.apiKeys
        .where((k) => k.enabled && k.key.trim().isNotEmpty)
        .map((k) => k.key.trim())
        .toList();
  }
}
