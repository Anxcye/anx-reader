import 'voice_config.dart';

/// Configuration for speech synthesis.
///
/// Controls voice selection and language for audio output.
class SpeechConfig {
  /// Voice configuration.
  final VoiceConfig? voiceConfig;

  /// Language code for speech synthesis (e.g., "en-US").
  final String? languageCode;

  /// Creates a [SpeechConfig].
  const SpeechConfig({this.voiceConfig, this.languageCode});

  /// Creates a configuration with a prebuilt voice.
  factory SpeechConfig.withVoice(String voiceName, {String? languageCode}) {
    return SpeechConfig(
      voiceConfig: VoiceConfig.prebuilt(voiceName),
      languageCode: languageCode,
    );
  }

  /// Creates from JSON.
  factory SpeechConfig.fromJson(Map<String, dynamic> json) {
    return SpeechConfig(
      voiceConfig: json['voiceConfig'] != null
          ? VoiceConfig.fromJson(json['voiceConfig'] as Map<String, dynamic>)
          : null,
      languageCode: json['languageCode'] as String?,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (voiceConfig != null) 'voiceConfig': voiceConfig!.toJson(),
    if (languageCode != null) 'languageCode': languageCode,
  };

  /// Creates a copy with the given fields replaced.
  SpeechConfig copyWith({VoiceConfig? voiceConfig, String? languageCode}) {
    return SpeechConfig(
      voiceConfig: voiceConfig ?? this.voiceConfig,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  String toString() =>
      'SpeechConfig(voiceConfig: $voiceConfig, languageCode: $languageCode)';
}
