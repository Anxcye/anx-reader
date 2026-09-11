/// Configuration for audio transcription.
///
/// Enable transcription for input (user speech) or output (model speech).
class AudioTranscriptionConfig {
  /// Whether transcription is enabled.
  final bool? enabled;

  /// Creates an [AudioTranscriptionConfig].
  const AudioTranscriptionConfig({this.enabled});

  /// Creates a configuration with transcription enabled.
  factory AudioTranscriptionConfig.enabled() =>
      const AudioTranscriptionConfig(enabled: true);

  /// Creates a configuration with transcription disabled.
  factory AudioTranscriptionConfig.disabled() =>
      const AudioTranscriptionConfig(enabled: false);

  /// Creates from JSON.
  factory AudioTranscriptionConfig.fromJson(Map<String, dynamic> json) {
    return AudioTranscriptionConfig(enabled: json['enabled'] as bool?);
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {if (enabled != null) 'enabled': enabled};

  /// Creates a copy with the given fields replaced.
  AudioTranscriptionConfig copyWith({bool? enabled}) {
    return AudioTranscriptionConfig(enabled: enabled ?? this.enabled);
  }

  @override
  String toString() => 'AudioTranscriptionConfig(enabled: $enabled)';
}
