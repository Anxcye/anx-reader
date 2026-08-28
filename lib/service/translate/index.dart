import 'dart:core';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/service/config/config_item.dart';
import 'package:anx_reader/service/translate/ai.dart';
import 'package:anx_reader/service/translate/deepl.dart';
import 'package:anx_reader/service/translate/google_api.dart';
import 'package:anx_reader/service/translate/microsoft_api.dart';
import 'package:anx_reader/service/translate/translation_ai_provider_resolver.dart';
import 'package:anx_reader/service/translate/web_view.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final Map<String, String> _selectionTranslationCache = {};

enum TranslateService {
  bingWeb,
  googleWeb,
  microsoftApi,
  googleApi,
  deepl,
  ai;

  TranslateServiceProvider get provider {
    switch (this) {
      case TranslateService.bingWeb:
        return BingWebTranslateProvider();
      case TranslateService.googleWeb:
        return GoogleWebTranslateProvider();
      case TranslateService.microsoftApi:
        return MicrosoftApiTranslateProvider();
      case TranslateService.googleApi:
        return GoogleApiTranslateProvider();
      case TranslateService.deepl:
        return DeepLTranslateProvider();
      case TranslateService.ai:
        return AiTranslateProvider();
    }
  }

  /// Get the display label from the provider.
  String getLabel(BuildContext context) => provider.getLabel(context);

  /// Check if the service is a WebView provider.
  bool get isWebView => provider is WebViewTranslateProvider;

  static List<TranslateService> get activeValues => values
      .where((e) => e != TranslateService.ai || EnvVar.enableAIFeature)
      .toList();
}

TranslateService getTranslateService(String name) {
  if (name == 'microsoft') {
    return TranslateService.microsoftApi;
  }

  try {
    return TranslateService.values.firstWhere((e) => e.name == name);
  } catch (e) {
    return TranslateService.bingWeb;
  }
}

/// Base class for all translation service providers.
/// Subclasses must implement [service], [label], [translate], and [translateStream].
abstract class TranslateServiceProvider {
  /// The service enum value this provider corresponds to.
  TranslateService get service;

  /// The display label for this service.
  String getLabel(BuildContext context);

  /// Override this method if the service uses a different code format.
  /// Default implementation returns [lang.code].
  String mapLanguageCode(LangListEnum lang) => lang.code;

  /// Get the configuration items for this service.
  List<ConfigItem> getConfigItems(BuildContext context) {
    return [];
  }

  /// Returns the widget for displaying the translation result.
  Widget translate(
    String text,
    LangListEnum from,
    LangListEnum to, {
    String? contextText,
  });

  /// Returns a stream of translation results.
  Stream<String> translateStream(
    String text,
    LangListEnum from,
    LangListEnum to, {
    String? contextText,
    bool isFullText = false,
  });

  /// Translate text only (no widget), with retry logic.
  Future<String> translateTextOnly(
    String text,
    LangListEnum from,
    LangListEnum to, {
    String? contextText,
    bool isFullText = false,
  }) async {
    const int maxRetries = 2;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        String? lastResult;
        await for (String result in translateStream(
          text,
          from,
          to,
          contextText: contextText,
          isFullText: isFullText,
        )) {
          lastResult = result;
        }

        if (lastResult != null &&
            lastResult.trim().isNotEmpty &&
            lastResult != '...' &&
            !isFailedTranslationResult(lastResult)) {
          return lastResult;
        }

        throw Exception(
            'Translation returned no valid result: ${lastResult ?? 'No result'}');
      } catch (e) {
        if (attempt < maxRetries) {
          AnxLog.warning(
              'Translation attempt ${attempt + 1} failed with exception: $e. Retrying...');
          await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
          continue;
        } else {
          throw Exception(
              'Translation failed after ${maxRetries + 1} attempts: $e');
        }
      }
    }

    throw Exception('Translation failed after all retry attempts');
  }

  /// Returns the current configuration.
  Map<String, dynamic> getConfig() => {};

  /// Saves the configuration.
  void saveConfig(Map<String, dynamic> config) {}

  /// Helper to convert a stream to a widget with copy button.
  Widget convertStreamToWidget(Stream<String> stream) {
    return StreamBuilder<String>(
      stream: stream,
      builder: (context, snapshot) {
        Widget content() {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('...');
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return Text(snapshot.data!);
          } else {
            return const Text('');
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            content(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: snapshot.data!)),
                    child: Text(L10n.of(context).commonCopy))
              ],
            )
          ],
        );
      },
    );
  }
}

bool isFailedTranslationResult(String text) {
  final raw = text.trim();
  final normalized = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  if (normalized.isEmpty || normalized == '...') return true;

  if (normalized.startsWith('translation error:') ||
      normalized.startsWith('translation failed:') ||
      normalized.startsWith('translate error') ||
      normalized.startsWith('error:') ||
      normalized.startsWith('failed:')) {
    return true;
  }

  if ((normalized.contains('api key') && normalized.contains('please set')) ||
      (normalized.contains('api key') && normalized.contains('invalid')) ||
      normalized.contains('authentication failed') ||
      normalized.contains('service not configured')) {
    return true;
  }

  if (normalized.contains('ai service') &&
      (normalized.contains('configure') ||
          normalized.contains('configured') ||
          normalized.contains('setting') ||
          normalized.contains('settins'))) {
    return true;
  }

  if (raw.contains('AI配置') ||
      raw.contains('AI 配置') ||
      raw.contains('AI設定') ||
      raw.contains('AI 設定') ||
      raw.contains('AI服务') ||
      raw.contains('AI 服務')) {
    return true;
  }

  // Some models occasionally echo the translation prompt or instruction block
  // instead of returning only the translated content. Treat these as failures
  // so they won't be shown or cached as valid translations.
  final leakedPromptMarkers = <String>[
    '目标语言：',
    '源文本：',
    '要求：',
    '仅输出翻译后的文本',
    '不要包含任何解释',
    '保留段落结构及格式',
    '保持原文的语气和风格',
    'source text:',
    'reader context:',
    'output only the final translated text',
    'do not output the source text',
  ];
  final matchedMarkers = leakedPromptMarkers
      .where((marker) => normalized.contains(marker.toLowerCase()))
      .length;
  if (matchedMarkers >= 2) {
    return true;
  }

  return false;
}

// ============================================================================
// Helper functions (use service.provider instead of TranslateFactory)
// ============================================================================

Widget translateText(String text,
    {TranslateService? service, String? contextText}) {
  service ??= Prefs().translateService;
  final from = Prefs().translateFrom;
  final to = Prefs().translateTo;

  return service.provider.translate(
    text,
    from,
    to,
    contextText: contextText,
  );
}

List<ConfigItem> getTranslateServiceConfigItems(
    BuildContext context, TranslateService service) {
  return service.provider.getConfigItems(context);
}

Map<String, dynamic> getTranslateServiceConfig(TranslateService service) {
  return service.provider.getConfig();
}

void saveTranslateServiceConfig(
    TranslateService service, Map<String, dynamic> config) {
  return service.provider.saveConfig(config);
}

Future<String> translateTextOnly(String text,
    {TranslateService? service, String? contextText}) async {
  service ??= Prefs().translateService;
  final from = Prefs().translateFrom;
  final to = Prefs().translateTo;

  return await translateTextOnlyWithFallback(
    text,
    from,
    to,
    service: service,
    contextText: contextText,
  );
}

Future<String> translateTextOnlyWithFallback(
  String text,
  LangListEnum from,
  LangListEnum to, {
  required TranslateService service,
  String? contextText,
  bool isFullText = false,
}) async {
  final candidates = _fallbackTranslateServices(service);
  Object? firstError;

  for (final candidate in candidates) {
    try {
      final translated = await candidate.provider.translateTextOnly(
        text,
        from,
        to,
        contextText: contextText,
        isFullText: isFullText,
      );

      if (translated.trim().isNotEmpty &&
          translated != '...' &&
          !isFailedTranslationResult(translated)) {
        if (candidate != service) {
          AnxLog.info(
              'Translation fallback succeeded: ${service.name} -> ${candidate.name}');
        }
        return translated;
      }

      throw Exception('Translation returned no valid result: $translated');
    } catch (e) {
      firstError ??= e;
      if (candidate == service) {
        AnxLog.warning('Primary translation failed: $e');
      } else {
        AnxLog.warning('Fallback translation failed (${candidate.name}): $e');
      }
    }
  }

  throw Exception('Translation failed after fallback chain: $firstError');
}

bool supportsFastTextTranslation(TranslateService service) {
  return !service.isWebView;
}

TranslateService? resolveFastTextTranslateService(TranslateService preferred) {
  return _fallbackTranslateServices(preferred)
      .where(supportsFastTextTranslation)
      .firstOrNull;
}

List<TranslateService> _fallbackTranslateServices(TranslateService primary) {
  final services = <TranslateService>[primary];
  const fallbacks = [
    TranslateService.microsoftApi,
    TranslateService.googleApi,
    TranslateService.deepl,
  ];

  for (final service in fallbacks) {
    if (service != primary && _hasUsableTranslateConfig(service)) {
      services.add(service);
    }
  }

  if (primary != TranslateService.ai &&
      !services.contains(TranslateService.ai) &&
      _hasRunnableAiTranslateProvider()) {
    services.add(TranslateService.ai);
  }

  return services;
}

@visibleForTesting
List<TranslateService> fallbackTranslateServicesForTest(
  TranslateService primary,
) {
  return _fallbackTranslateServices(primary);
}

bool _hasRunnableAiTranslateProvider() {
  if (!EnvVar.enableAIFeature) return false;

  try {
    final providers = Prefs()
        .getAiProviders()
        .map((json) => AiProvider.fromJson(json as Map<String, dynamic>))
        .toList();
    final resolution = TranslationAiProviderResolver.resolve(
      providers: providers,
      selectedProviderId: Prefs().selectedAiService,
      translationProviderId: Prefs().translationAiProvider,
    );
    final providerId = resolution.effectiveProviderId;
    if (providerId == null) return false;
    return providers.any(
      (provider) => provider.id == providerId && provider.isRunnable,
    );
  } catch (e) {
    AnxLog.warning('Failed to resolve AI translation fallback provider: $e');
    return false;
  }
}

Future<String> translateTextOnlyCached(
  String text, {
  TranslateService? service,
  String? contextText,
}) async {
  service ??= Prefs().translateService;
  final from = Prefs().translateFrom;
  final to = Prefs().translateTo;
  final cacheKey = _selectionTranslationCacheKey(
    service: service,
    from: from,
    to: to,
    text: text,
    contextText: contextText,
  );

  final cached = _selectionTranslationCache[cacheKey];
  if (cached != null && cached.trim().isNotEmpty) {
    if (isFailedTranslationResult(cached)) {
      _selectionTranslationCache.remove(cacheKey);
    } else {
      return cached;
    }
  }

  final translated = await translateTextOnlyWithFallback(
    text,
    from,
    to,
    service: service,
    contextText: contextText,
  );

  if (translated.trim().isNotEmpty &&
      translated != '...' &&
      !isFailedTranslationResult(translated)) {
    _selectionTranslationCache[cacheKey] = translated;
  }
  return translated;
}

bool _hasUsableTranslateConfig(TranslateService service) {
  final config = Prefs().getTranslateServiceConfig(service);
  if (config == null) return false;

  switch (service) {
    case TranslateService.microsoftApi:
    case TranslateService.googleApi:
    case TranslateService.deepl:
      return (config['api_key']?.toString().trim().isNotEmpty ?? false);
    case TranslateService.ai:
      return true;
    case TranslateService.bingWeb:
    case TranslateService.googleWeb:
      return false;
  }
}

String _selectionTranslationCacheKey({
  required TranslateService service,
  required LangListEnum from,
  required LangListEnum to,
  required String text,
  required String? contextText,
}) {
  final normalizedText = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  final normalizedContext =
      contextText?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
  return [
    service.name,
    translationServiceCacheScope(service),
    from.code,
    to.code,
    normalizedText,
    normalizedContext,
  ].join('|');
}

/// Identifies the complete execution route used by text-only translation.
///
/// The route is part of both selection and full-text cache namespaces so a
/// provider, model, or fallback change cannot surface results produced by an
/// older configuration.
String translationServiceCacheScope(TranslateService service) {
  final fingerprints = _fallbackTranslateServices(service)
      .map(_translationServiceFingerprint)
      .join('||');
  return 'v2_${_stableTranslationFingerprint(fingerprints)}';
}

String _translationServiceFingerprint(TranslateService service) {
  if (service == TranslateService.ai) {
    final providers = _loadStoredAiProviders();
    final resolution = TranslationAiProviderResolver.resolve(
      providers: providers,
      selectedProviderId: Prefs().selectedAiService,
      translationProviderId: Prefs().translationAiProvider,
    );
    final primary = resolution.effectiveProviderId == null
        ? null
        : TranslationAiProviderResolver.providerById(
            providers,
            resolution.effectiveProviderId!,
          );
    final fallbackId = Prefs().aiFallbackProvider;
    final fallback = fallbackId == null || fallbackId == primary?.id
        ? null
        : TranslationAiProviderResolver.providerById(providers, fallbackId);

    return [
      service.name,
      _aiProviderFingerprint(primary),
      _aiProviderFingerprint(
        fallback != null && fallback.isRunnable ? fallback : null,
      ),
    ].join('|');
  }

  final config = Prefs().getTranslateServiceConfig(service);
  return [
    service.name,
    _hasUsableTranslateConfig(service) ? 'configured' : 'unconfigured',
    config?['api_url']?.toString().trim() ?? '',
    config?['region']?.toString().trim() ?? '',
  ].join('|');
}

String _aiProviderFingerprint(AiProvider? provider) {
  if (provider == null) return 'none';
  return [
    provider.id,
    provider.protocol.code,
    provider.url.trim(),
    provider.model.trim(),
    provider.reasoningEffort.name,
    provider.requestTimeoutSeconds,
  ].join(':');
}

List<AiProvider> _loadStoredAiProviders() {
  try {
    return Prefs()
        .getAiProviders()
        .map((json) => AiProvider.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    AnxLog.warning('Failed to load AI providers for translation routing: $e');
    return const [];
  }
}

String _stableTranslationFingerprint(String value) {
  const int fnvPrime = 0x01000193;
  int hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * fnvPrime) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
