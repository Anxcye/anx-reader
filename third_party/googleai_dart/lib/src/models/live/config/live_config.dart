import '../../content/content.dart';
import '../../tools/tool.dart';
import 'audio_transcription_config.dart';
import 'context_window_compression_config.dart';
import 'live_generation_config.dart';
import 'proactivity_config.dart';
import 'realtime_input_config.dart';
import 'session_resumption_config.dart';
import 'speech_config.dart';

/// Main configuration for Live API sessions.
///
/// Contains all settings for a live streaming session including generation,
/// voice activity detection, tools, and transcription.
class LiveConfig {
  /// Generation configuration (modalities, temperature, etc.).
  final LiveGenerationConfig? generationConfig;

  /// System instruction for the model.
  final Content? systemInstruction;

  /// Available tools for function calling.
  final List<Tool>? tools;

  /// Real-time input configuration (VAD, interruption handling).
  final RealtimeInputConfig? realtimeInputConfig;

  /// Session resumption configuration.
  final SessionResumptionConfig? sessionResumption;

  /// Context window compression configuration.
  final ContextWindowCompressionConfig? contextWindowCompression;

  /// Input audio transcription configuration.
  final AudioTranscriptionConfig? inputAudioTranscription;

  /// Output audio transcription configuration.
  final AudioTranscriptionConfig? outputAudioTranscription;

  /// Proactive audio configuration.
  final ProactivityConfig? proactivity;

  /// Creates a [LiveConfig].
  const LiveConfig({
    this.generationConfig,
    this.systemInstruction,
    this.tools,
    this.realtimeInputConfig,
    this.sessionResumption,
    this.contextWindowCompression,
    this.inputAudioTranscription,
    this.outputAudioTranscription,
    this.proactivity,
  });

  /// Creates a basic audio configuration.
  factory LiveConfig.audio({
    String? voiceName,
    int? silenceDurationMs,
    Content? systemInstruction,
    List<Tool>? tools,
  }) {
    return LiveConfig(
      generationConfig: LiveGenerationConfig.audioOnly(
        speechConfig: voiceName != null
            ? SpeechConfig.withVoice(voiceName)
            : null,
      ),
      systemInstruction: systemInstruction,
      tools: tools,
      realtimeInputConfig: silenceDurationMs != null
          ? RealtimeInputConfig.withVAD(silenceDurationMs: silenceDurationMs)
          : null,
    );
  }

  /// Creates a text and audio configuration.
  factory LiveConfig.textAndAudio({
    String? voiceName,
    int? silenceDurationMs,
    Content? systemInstruction,
    List<Tool>? tools,
    bool enableTranscription = false,
  }) {
    return LiveConfig(
      generationConfig: LiveGenerationConfig.textAndAudio(
        speechConfig: voiceName != null
            ? SpeechConfig.withVoice(voiceName)
            : null,
      ),
      systemInstruction: systemInstruction,
      tools: tools,
      realtimeInputConfig: silenceDurationMs != null
          ? RealtimeInputConfig.withVAD(silenceDurationMs: silenceDurationMs)
          : null,
      inputAudioTranscription: enableTranscription
          ? AudioTranscriptionConfig.enabled()
          : null,
      outputAudioTranscription: enableTranscription
          ? AudioTranscriptionConfig.enabled()
          : null,
    );
  }

  /// Creates from JSON.
  factory LiveConfig.fromJson(Map<String, dynamic> json) {
    return LiveConfig(
      generationConfig: json['generationConfig'] != null
          ? LiveGenerationConfig.fromJson(
              json['generationConfig'] as Map<String, dynamic>,
            )
          : null,
      systemInstruction: json['systemInstruction'] != null
          ? Content.fromJson(json['systemInstruction'] as Map<String, dynamic>)
          : null,
      tools: json['tools'] != null
          ? (json['tools'] as List<dynamic>)
                .map((e) => Tool.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      realtimeInputConfig: json['realtimeInputConfig'] != null
          ? RealtimeInputConfig.fromJson(
              json['realtimeInputConfig'] as Map<String, dynamic>,
            )
          : null,
      sessionResumption: json['sessionResumption'] != null
          ? SessionResumptionConfig.fromJson(
              json['sessionResumption'] as Map<String, dynamic>,
            )
          : null,
      contextWindowCompression: json['contextWindowCompression'] != null
          ? ContextWindowCompressionConfig.fromJson(
              json['contextWindowCompression'] as Map<String, dynamic>,
            )
          : null,
      inputAudioTranscription: json['inputAudioTranscription'] != null
          ? AudioTranscriptionConfig.fromJson(
              json['inputAudioTranscription'] as Map<String, dynamic>,
            )
          : null,
      outputAudioTranscription: json['outputAudioTranscription'] != null
          ? AudioTranscriptionConfig.fromJson(
              json['outputAudioTranscription'] as Map<String, dynamic>,
            )
          : null,
      proactivity: json['proactivity'] != null
          ? ProactivityConfig.fromJson(
              json['proactivity'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (generationConfig != null)
      'generationConfig': generationConfig!.toJson(),
    if (systemInstruction != null)
      'systemInstruction': systemInstruction!.toJson(),
    if (tools != null) 'tools': tools!.map((e) => e.toJson()).toList(),
    if (realtimeInputConfig != null)
      'realtimeInputConfig': realtimeInputConfig!.toJson(),
    if (sessionResumption != null)
      'sessionResumption': sessionResumption!.toJson(),
    if (contextWindowCompression != null)
      'contextWindowCompression': contextWindowCompression!.toJson(),
    if (inputAudioTranscription != null)
      'inputAudioTranscription': inputAudioTranscription!.toJson(),
    if (outputAudioTranscription != null)
      'outputAudioTranscription': outputAudioTranscription!.toJson(),
    if (proactivity != null) 'proactivity': proactivity!.toJson(),
  };

  /// Creates a copy with the given fields replaced.
  LiveConfig copyWith({
    LiveGenerationConfig? generationConfig,
    Content? systemInstruction,
    List<Tool>? tools,
    RealtimeInputConfig? realtimeInputConfig,
    SessionResumptionConfig? sessionResumption,
    ContextWindowCompressionConfig? contextWindowCompression,
    AudioTranscriptionConfig? inputAudioTranscription,
    AudioTranscriptionConfig? outputAudioTranscription,
    ProactivityConfig? proactivity,
  }) {
    return LiveConfig(
      generationConfig: generationConfig ?? this.generationConfig,
      systemInstruction: systemInstruction ?? this.systemInstruction,
      tools: tools ?? this.tools,
      realtimeInputConfig: realtimeInputConfig ?? this.realtimeInputConfig,
      sessionResumption: sessionResumption ?? this.sessionResumption,
      contextWindowCompression:
          contextWindowCompression ?? this.contextWindowCompression,
      inputAudioTranscription:
          inputAudioTranscription ?? this.inputAudioTranscription,
      outputAudioTranscription:
          outputAudioTranscription ?? this.outputAudioTranscription,
      proactivity: proactivity ?? this.proactivity,
    );
  }

  @override
  String toString() => 'LiveConfig(generationConfig: $generationConfig)';
}
