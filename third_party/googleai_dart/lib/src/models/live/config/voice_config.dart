/// Configuration for voice selection.
///
/// Specifies which voice to use for audio output.
class VoiceConfig {
  /// Configuration for prebuilt voices.
  final PrebuiltVoiceConfig? prebuiltVoiceConfig;

  /// Creates a [VoiceConfig].
  const VoiceConfig({this.prebuiltVoiceConfig});

  /// Creates a configuration using a prebuilt voice.
  factory VoiceConfig.prebuilt(String voiceName) {
    return VoiceConfig(
      prebuiltVoiceConfig: PrebuiltVoiceConfig(voiceName: voiceName),
    );
  }

  /// Creates from JSON.
  factory VoiceConfig.fromJson(Map<String, dynamic> json) {
    return VoiceConfig(
      prebuiltVoiceConfig: json['prebuiltVoiceConfig'] != null
          ? PrebuiltVoiceConfig.fromJson(
              json['prebuiltVoiceConfig'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (prebuiltVoiceConfig != null)
      'prebuiltVoiceConfig': prebuiltVoiceConfig!.toJson(),
  };

  /// Creates a copy with the given fields replaced.
  VoiceConfig copyWith({PrebuiltVoiceConfig? prebuiltVoiceConfig}) {
    return VoiceConfig(
      prebuiltVoiceConfig: prebuiltVoiceConfig ?? this.prebuiltVoiceConfig,
    );
  }

  @override
  String toString() => 'VoiceConfig(prebuiltVoiceConfig: $prebuiltVoiceConfig)';
}

/// Configuration for prebuilt voices.
class PrebuiltVoiceConfig {
  /// Name of the prebuilt voice.
  ///
  /// Available voices: Puck, Charon, Kore, Fenrir, Aoede, Leda, Orus, Zephyr.
  final String? voiceName;

  /// Creates a [PrebuiltVoiceConfig].
  const PrebuiltVoiceConfig({this.voiceName});

  /// Creates from JSON.
  factory PrebuiltVoiceConfig.fromJson(Map<String, dynamic> json) {
    return PrebuiltVoiceConfig(voiceName: json['voiceName'] as String?);
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (voiceName != null) 'voiceName': voiceName,
  };

  /// Creates a copy with the given fields replaced.
  PrebuiltVoiceConfig copyWith({String? voiceName}) {
    return PrebuiltVoiceConfig(voiceName: voiceName ?? this.voiceName);
  }

  @override
  String toString() => 'PrebuiltVoiceConfig(voiceName: $voiceName)';
}

/// Available prebuilt voices for Live API.
abstract class LiveVoices {
  LiveVoices._();

  /// Puck - A distinctive voice.
  static const String puck = 'Puck';

  /// Charon - A distinctive voice.
  static const String charon = 'Charon';

  /// Kore - A distinctive voice.
  static const String kore = 'Kore';

  /// Fenrir - A distinctive voice.
  static const String fenrir = 'Fenrir';

  /// Aoede - A distinctive voice.
  static const String aoede = 'Aoede';

  /// Leda - A distinctive voice.
  static const String leda = 'Leda';

  /// Orus - A distinctive voice.
  static const String orus = 'Orus';

  /// Zephyr - A distinctive voice.
  static const String zephyr = 'Zephyr';
}
