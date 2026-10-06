import '../copy_with_sentinel.dart';

/// Configuration for speech interaction.
class InteractionSpeechConfig {
  /// The voice of the speaker.
  final String? voice;

  /// The language of the speech.
  final String? language;

  /// The speaker's name (should match the speaker name in the prompt).
  final String? speaker;

  /// Creates an [InteractionSpeechConfig] instance.
  const InteractionSpeechConfig({this.voice, this.language, this.speaker});

  /// Creates an [InteractionSpeechConfig] from JSON.
  factory InteractionSpeechConfig.fromJson(Map<String, dynamic> json) =>
      InteractionSpeechConfig(
        voice: json['voice'] as String?,
        language: json['language'] as String?,
        speaker: json['speaker'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (voice != null) 'voice': voice,
    if (language != null) 'language': language,
    if (speaker != null) 'speaker': speaker,
  };

  /// Creates a copy with replaced values.
  InteractionSpeechConfig copyWith({
    Object? voice = unsetCopyWithValue,
    Object? language = unsetCopyWithValue,
    Object? speaker = unsetCopyWithValue,
  }) {
    return InteractionSpeechConfig(
      voice: voice == unsetCopyWithValue ? this.voice : voice as String?,
      language: language == unsetCopyWithValue
          ? this.language
          : language as String?,
      speaker: speaker == unsetCopyWithValue
          ? this.speaker
          : speaker as String?,
    );
  }
}
