import 'dart:convert';

import '../../../content/blob.dart';
import '../../../content/content.dart';
import '../../../tools/function_response.dart';
import '../../../tools/tool.dart';
import '../../config/audio_transcription_config.dart';
import '../../config/context_window_compression_config.dart';
import '../../config/live_generation_config.dart';
import '../../config/proactivity_config.dart';
import '../../config/realtime_input_config.dart';
import '../../config/session_resumption_config.dart';

/// Base class for client-to-server WebSocket messages.
///
/// Each message type has a specific wrapper key in the JSON:
/// - `setup` for [BidiGenerateContentSetup]
/// - `clientContent` for [BidiGenerateContentClientContent]
/// - `realtimeInput` for [BidiGenerateContentRealtimeInput]
/// - `toolResponse` for [BidiGenerateContentToolResponse]
sealed class BidiGenerateContentClientMessage {
  /// Creates a message.
  const BidiGenerateContentClientMessage();

  /// Creates a message from JSON.
  ///
  /// Dispatches to the appropriate subclass based on the JSON key.
  factory BidiGenerateContentClientMessage.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('setup')) {
      return BidiGenerateContentSetup.fromJson(
        json['setup'] as Map<String, dynamic>,
      );
    }
    if (json.containsKey('clientContent')) {
      return BidiGenerateContentClientContent.fromJson(
        json['clientContent'] as Map<String, dynamic>,
      );
    }
    if (json.containsKey('realtimeInput')) {
      return BidiGenerateContentRealtimeInput.fromJson(
        json['realtimeInput'] as Map<String, dynamic>,
      );
    }
    if (json.containsKey('toolResponse')) {
      return BidiGenerateContentToolResponse.fromJson(
        json['toolResponse'] as Map<String, dynamic>,
      );
    }
    // Return unknown message type instead of throwing to handle
    // future API additions gracefully
    return UnknownClientMessage(json);
  }

  /// Converts to JSON with the message type wrapper key.
  Map<String, dynamic> toJson();
}

/// Initial session setup message.
///
/// Must be the first message sent after WebSocket connection is established.
class BidiGenerateContentSetup extends BidiGenerateContentClientMessage {
  /// Required. The model resource name.
  ///
  /// Format: `models/{model}` or just `{model}`.
  final String model;

  /// Optional. Generation configuration.
  final LiveGenerationConfig? generationConfig;

  /// Optional. System instruction.
  final Content? systemInstruction;

  /// Optional. Available tools.
  final List<Tool>? tools;

  /// Optional. Real-time input configuration (VAD, activity handling).
  final RealtimeInputConfig? realtimeInputConfig;

  /// Optional. Session resumption configuration.
  final SessionResumptionConfig? sessionResumption;

  /// Optional. Context window compression configuration.
  final ContextWindowCompressionConfig? contextWindowCompression;

  /// Optional. Enable input audio transcription.
  final AudioTranscriptionConfig? inputAudioTranscription;

  /// Optional. Enable output audio transcription.
  final AudioTranscriptionConfig? outputAudioTranscription;

  /// Optional. Proactive audio configuration.
  final ProactivityConfig? proactivity;

  /// Creates a [BidiGenerateContentSetup].
  const BidiGenerateContentSetup({
    required this.model,
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

  /// Creates from JSON (inner object, not wrapped).
  factory BidiGenerateContentSetup.fromJson(Map<String, dynamic> json) {
    return BidiGenerateContentSetup(
      model: json['model'] as String,
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

  @override
  Map<String, dynamic> toJson() => {
    'setup': {
      'model': model,
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
    },
  };

  @override
  String toString() => 'BidiGenerateContentSetup(model: $model)';
}

/// Client content message for sending conversation context.
///
/// Use this to send previous conversation turns or user context.
class BidiGenerateContentClientContent
    extends BidiGenerateContentClientMessage {
  /// The conversation turns to send.
  final List<Content> turns;

  /// Whether this turn is complete.
  ///
  /// If `true`, the model may start generating a response.
  final bool? turnComplete;

  /// Creates a [BidiGenerateContentClientContent].
  const BidiGenerateContentClientContent({
    required this.turns,
    this.turnComplete,
  });

  /// Creates from JSON.
  factory BidiGenerateContentClientContent.fromJson(Map<String, dynamic> json) {
    return BidiGenerateContentClientContent(
      turns: (json['turns'] as List<dynamic>)
          .map((e) => Content.fromJson(e as Map<String, dynamic>))
          .toList(),
      turnComplete: json['turnComplete'] as bool?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'clientContent': {
      'turns': turns.map((e) => e.toJson()).toList(),
      if (turnComplete != null) 'turnComplete': turnComplete,
    },
  };

  @override
  String toString() =>
      'BidiGenerateContentClientContent(turns: ${turns.length}, turnComplete: $turnComplete)';
}

/// Real-time input message for streaming audio, video, or text.
///
/// Use this to send real-time input during a live session.
class BidiGenerateContentRealtimeInput
    extends BidiGenerateContentClientMessage {
  /// Audio data (16kHz, 16-bit signed little-endian mono PCM).
  final Blob? audio;

  /// Video frame data.
  final Blob? video;

  /// Text input.
  final String? text;

  /// Signal that user activity has started (manual VAD).
  final bool? activityStart;

  /// Signal that user activity has ended (manual VAD).
  final bool? activityEnd;

  /// Signal that the audio stream has ended.
  final bool? audioStreamEnd;

  /// Creates a [BidiGenerateContentRealtimeInput].
  const BidiGenerateContentRealtimeInput({
    this.audio,
    this.video,
    this.text,
    this.activityStart,
    this.activityEnd,
    this.audioStreamEnd,
  });

  /// Creates an audio input message.
  factory BidiGenerateContentRealtimeInput.audio(List<int> pcmBytes) {
    return BidiGenerateContentRealtimeInput(
      audio: Blob(
        mimeType: 'audio/pcm;rate=16000',
        data: base64Encode(pcmBytes),
      ),
    );
  }

  /// Creates a text input message.
  factory BidiGenerateContentRealtimeInput.textInput(String text) {
    return BidiGenerateContentRealtimeInput(text: text);
  }

  /// Creates an activity start signal (manual VAD).
  factory BidiGenerateContentRealtimeInput.startActivity() {
    return const BidiGenerateContentRealtimeInput(activityStart: true);
  }

  /// Creates an activity end signal (manual VAD).
  factory BidiGenerateContentRealtimeInput.endActivity() {
    return const BidiGenerateContentRealtimeInput(activityEnd: true);
  }

  /// Creates from JSON.
  factory BidiGenerateContentRealtimeInput.fromJson(Map<String, dynamic> json) {
    return BidiGenerateContentRealtimeInput(
      audio: json['audio'] != null
          ? Blob.fromJson(json['audio'] as Map<String, dynamic>)
          : null,
      video: json['video'] != null
          ? Blob.fromJson(json['video'] as Map<String, dynamic>)
          : null,
      text: json['text'] as String?,
      // Activity signals can be either boolean or empty objects
      activityStart: _parseActivitySignal(
        json['activityStart'] ?? json['activity_start'],
      ),
      activityEnd: _parseActivitySignal(
        json['activityEnd'] ?? json['activity_end'],
      ),
      audioStreamEnd: _parseActivitySignal(
        json['audioStreamEnd'] ?? json['audio_stream_end'],
      ),
    );
  }

  /// Parses an activity signal that can be a boolean or an empty object.
  static bool? _parseActivitySignal(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is Map) return true; // Empty object means signal is active
    return null;
  }

  @override
  Map<String, dynamic> toJson() => {
    'realtimeInput': {
      if (audio != null) 'audio': audio!.toJson(),
      if (video != null) 'video': video!.toJson(),
      if (text != null) 'text': text,
      // Activity signals are empty objects, not boolean values
      if (activityStart ?? false) 'activityStart': <String, dynamic>{},
      if (activityEnd ?? false) 'activityEnd': <String, dynamic>{},
      if (audioStreamEnd ?? false) 'audioStreamEnd': <String, dynamic>{},
    },
  };

  @override
  String toString() {
    final parts = <String>[];
    if (audio != null) parts.add('audio');
    if (video != null) parts.add('video');
    if (text != null) parts.add('text: $text');
    if (activityStart ?? false) parts.add('activityStart');
    if (activityEnd ?? false) parts.add('activityEnd');
    if (audioStreamEnd ?? false) parts.add('audioStreamEnd');
    return 'BidiGenerateContentRealtimeInput(${parts.join(', ')})';
  }
}

/// Tool response message.
///
/// Send this after receiving a [BidiGenerateContentToolCall] with the
/// results of executing the requested tools.
class BidiGenerateContentToolResponse extends BidiGenerateContentClientMessage {
  /// The function responses.
  final List<FunctionResponse> functionResponses;

  /// Creates a [BidiGenerateContentToolResponse].
  const BidiGenerateContentToolResponse({required this.functionResponses});

  /// Creates from JSON.
  factory BidiGenerateContentToolResponse.fromJson(Map<String, dynamic> json) {
    return BidiGenerateContentToolResponse(
      functionResponses: (json['functionResponses'] as List<dynamic>)
          .map((e) => FunctionResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'toolResponse': {
      'functionResponses': functionResponses.map((e) => e.toJson()).toList(),
    },
  };

  @override
  String toString() =>
      'BidiGenerateContentToolResponse(functionResponses: ${functionResponses.length})';
}

/// Unknown client message type.
///
/// This is returned when deserializing a message type that this client
/// version doesn't recognize. This allows graceful handling of future API
/// additions without crashing.
///
/// Applications can check for this type and handle it appropriately:
/// ```dart
/// final message = BidiGenerateContentClientMessage.fromJson(json);
/// if (message is UnknownClientMessage) {
///   // Log or ignore unrecognized message type
///   print('Unknown message: ${message.rawJson.keys}');
/// }
/// ```
class UnknownClientMessage extends BidiGenerateContentClientMessage {
  /// The raw JSON of the unrecognized message.
  final Map<String, dynamic> rawJson;

  /// Creates an [UnknownClientMessage].
  const UnknownClientMessage(this.rawJson);

  @override
  Map<String, dynamic> toJson() => rawJson;

  @override
  String toString() => 'UnknownClientMessage(keys: ${rawJson.keys})';
}
