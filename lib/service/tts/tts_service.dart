import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/tts/aliyun/aliyun_tts_backend.dart';
import 'package:anx_reader/service/tts/azure_tts_backend.dart';
import 'package:anx_reader/service/tts/openai_tts_backend.dart';
import 'package:anx_reader/service/tts/tts_service_provider.dart';
import 'package:flutter/material.dart';

/// TTS service enumeration.
/// Defines available TTS services (system TTS and online TTS services).
enum TtsService {
  system,
  aliyun,
  azure,
  openai;
  // Future services can be added here: google, aws, elevenlabs, etc.

  /// Get the provider for this TTS service.
  TtsServiceProvider get provider {
    switch (this) {
      case TtsService.system:
        return SystemTtsProvider();
      case TtsService.aliyun:
        return AliyunTtsProvider();
      case TtsService.azure:
        return AzureTtsProvider();
      case TtsService.openai:
        return OpenAiTtsProvider();
    }
  }

  /// Get the display label from the provider.
  String getLabel(BuildContext context) => provider.getLabel(context);

  /// Check if the service is an online TTS provider.
  bool get isOnline => this != TtsService.system;
}

/// Get TTS service from service ID string.
TtsService getTtsService(String serviceId) {
  try {
    return TtsService.values
        .firstWhere((e) => e.toString().split('.').last == serviceId);
  } catch (e) {
    return TtsService.system;
  }
}

/// System TTS provider (placeholder for service provider pattern).
/// System TTS doesn't need configuration, so it returns empty config items.
class SystemTtsProvider extends TtsServiceProvider {
  @override
  TtsService get service => TtsService.system;

  @override
  String getLabel(BuildContext context) =>
      L10n.of(context).settingsNarrateSystemTts;
}
