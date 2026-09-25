import 'speech_config.dart';

/// Generation configuration for Live API sessions.
///
/// Controls response modalities, temperature, and other generation settings.
class LiveGenerationConfig {
  /// Response modalities (e.g., ["AUDIO"], ["TEXT"], ["AUDIO", "TEXT"]).
  ///
  /// Specifies what types of content the model should generate.
  final List<String>? responseModalities;

  /// Speech configuration for audio output.
  final SpeechConfig? speechConfig;

  /// Temperature for generation (0.0 to 2.0).
  ///
  /// Higher values make output more random, lower values more deterministic.
  final double? temperature;

  /// Maximum number of output tokens.
  final int? maxOutputTokens;

  /// Top-p sampling parameter (0.0 to 1.0).
  final double? topP;

  /// Top-k sampling parameter.
  final int? topK;

  /// Creates a [LiveGenerationConfig].
  const LiveGenerationConfig({
    this.responseModalities,
    this.speechConfig,
    this.temperature,
    this.maxOutputTokens,
    this.topP,
    this.topK,
  });

  /// Creates an audio-only configuration.
  factory LiveGenerationConfig.audioOnly({
    SpeechConfig? speechConfig,
    double? temperature,
    int? maxOutputTokens,
  }) {
    return LiveGenerationConfig(
      responseModalities: const ['AUDIO'],
      speechConfig: speechConfig,
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    );
  }

  /// Creates a text-only configuration.
  factory LiveGenerationConfig.textOnly({
    double? temperature,
    int? maxOutputTokens,
  }) {
    return LiveGenerationConfig(
      responseModalities: const ['TEXT'],
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    );
  }

  /// Creates a configuration with both audio and text output.
  factory LiveGenerationConfig.textAndAudio({
    SpeechConfig? speechConfig,
    double? temperature,
    int? maxOutputTokens,
  }) {
    return LiveGenerationConfig(
      responseModalities: const ['AUDIO', 'TEXT'],
      speechConfig: speechConfig,
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    );
  }

  /// Creates from JSON.
  factory LiveGenerationConfig.fromJson(Map<String, dynamic> json) {
    return LiveGenerationConfig(
      responseModalities: json['responseModalities'] != null
          ? (json['responseModalities'] as List<dynamic>).cast<String>()
          : null,
      speechConfig: json['speechConfig'] != null
          ? SpeechConfig.fromJson(json['speechConfig'] as Map<String, dynamic>)
          : null,
      temperature: json['temperature'] != null
          ? (json['temperature'] as num).toDouble()
          : null,
      maxOutputTokens: json['maxOutputTokens'] as int?,
      topP: json['topP'] != null ? (json['topP'] as num).toDouble() : null,
      topK: json['topK'] as int?,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (responseModalities != null) 'responseModalities': responseModalities,
    if (speechConfig != null) 'speechConfig': speechConfig!.toJson(),
    if (temperature != null) 'temperature': temperature,
    if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
    if (topP != null) 'topP': topP,
    if (topK != null) 'topK': topK,
  };

  /// Creates a copy with the given fields replaced.
  LiveGenerationConfig copyWith({
    List<String>? responseModalities,
    SpeechConfig? speechConfig,
    double? temperature,
    int? maxOutputTokens,
    double? topP,
    int? topK,
  }) {
    return LiveGenerationConfig(
      responseModalities: responseModalities ?? this.responseModalities,
      speechConfig: speechConfig ?? this.speechConfig,
      temperature: temperature ?? this.temperature,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
    );
  }

  @override
  String toString() =>
      'LiveGenerationConfig(responseModalities: $responseModalities, '
      'temperature: $temperature)';
}
