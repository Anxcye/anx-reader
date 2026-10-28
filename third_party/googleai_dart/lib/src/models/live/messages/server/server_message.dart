import '../../../content/content.dart';
import '../../../metadata/grounding_metadata.dart';
import '../../../metadata/usage_metadata.dart';
import '../../../tools/function_call.dart';
import '../../config/transcription.dart';

/// Base class for server-to-client WebSocket messages.
///
/// Each message type has a specific wrapper key in the JSON:
/// - `setupComplete` for [BidiGenerateContentSetupComplete]
/// - `serverContent` for [BidiGenerateContentServerContent]
/// - `toolCall` for [BidiGenerateContentToolCall]
/// - `toolCallCancellation` for [BidiGenerateContentToolCallCancellation]
/// - `goAway` for [GoAway]
/// - `sessionResumptionUpdate` for [SessionResumptionUpdate]
sealed class BidiGenerateContentServerMessage {
  /// Creates a message.
  const BidiGenerateContentServerMessage();

  /// Creates a message from JSON.
  ///
  /// Dispatches to the appropriate subclass based on the JSON key.
  factory BidiGenerateContentServerMessage.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('setupComplete')) {
      return BidiGenerateContentSetupComplete.fromJson(
        json['setupComplete'] as Map<String, dynamic>,
      );
    }
    if (json.containsKey('serverContent')) {
      return BidiGenerateContentServerContent.fromJson(
        json['serverContent'] as Map<String, dynamic>,
      );
    }
    if (json.containsKey('toolCall')) {
      return BidiGenerateContentToolCall.fromJson(
        json['toolCall'] as Map<String, dynamic>,
      );
    }
    if (json.containsKey('toolCallCancellation')) {
      return BidiGenerateContentToolCallCancellation.fromJson(
        json['toolCallCancellation'] as Map<String, dynamic>,
      );
    }
    if (json.containsKey('goAway')) {
      return GoAway.fromJson(json['goAway'] as Map<String, dynamic>);
    }
    if (json.containsKey('sessionResumptionUpdate')) {
      return SessionResumptionUpdate.fromJson(
        json['sessionResumptionUpdate'] as Map<String, dynamic>,
      );
    }
    // Return unknown message type instead of throwing to handle
    // future API additions gracefully
    return UnknownServerMessage(json);
  }

  /// Converts to JSON with the message type wrapper key.
  Map<String, dynamic> toJson();
}

/// Session setup complete message.
///
/// Sent by the server after receiving [BidiGenerateContentSetup] and
/// successfully initializing the session.
class BidiGenerateContentSetupComplete
    extends BidiGenerateContentServerMessage {
  /// The session ID.
  final String? sessionId;

  /// Creates a [BidiGenerateContentSetupComplete].
  const BidiGenerateContentSetupComplete({this.sessionId});

  /// Creates from JSON.
  factory BidiGenerateContentSetupComplete.fromJson(Map<String, dynamic> json) {
    return BidiGenerateContentSetupComplete(
      sessionId: json['sessionId'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'setupComplete': {if (sessionId != null) 'sessionId': sessionId},
  };

  @override
  String toString() =>
      'BidiGenerateContentSetupComplete(sessionId: $sessionId)';
}

/// Server content message containing model output.
///
/// This is the main response message containing the model's generated content.
class BidiGenerateContentServerContent
    extends BidiGenerateContentServerMessage {
  /// The model's generated content for this turn.
  final Content? modelTurn;

  /// Whether the model's turn is complete.
  ///
  /// When `true`, the model has finished generating for this turn.
  final bool? turnComplete;

  /// Whether generation is fully complete.
  ///
  /// When `true`, no more content will be generated for this request.
  final bool? generationComplete;

  /// Whether the model was interrupted.
  ///
  /// `true` if user activity interrupted the model's output.
  final bool? interrupted;

  /// Transcription of the user's input audio.
  ///
  /// Only present if `inputAudioTranscription` was enabled in setup.
  final Transcription? inputTranscription;

  /// Transcription of the model's output audio.
  ///
  /// Only present if `outputAudioTranscription` was enabled in setup.
  final Transcription? outputTranscription;

  /// Grounding metadata for the response.
  final GroundingMetadata? groundingMetadata;

  /// Token usage metadata.
  final UsageMetadata? usageMetadata;

  /// Creates a [BidiGenerateContentServerContent].
  const BidiGenerateContentServerContent({
    this.modelTurn,
    this.turnComplete,
    this.generationComplete,
    this.interrupted,
    this.inputTranscription,
    this.outputTranscription,
    this.groundingMetadata,
    this.usageMetadata,
  });

  /// Creates from JSON.
  factory BidiGenerateContentServerContent.fromJson(Map<String, dynamic> json) {
    return BidiGenerateContentServerContent(
      modelTurn: json['modelTurn'] != null
          ? Content.fromJson(json['modelTurn'] as Map<String, dynamic>)
          : null,
      turnComplete: json['turnComplete'] as bool?,
      generationComplete: json['generationComplete'] as bool?,
      interrupted: json['interrupted'] as bool?,
      inputTranscription: json['inputTranscription'] != null
          ? Transcription.fromJson(
              json['inputTranscription'] as Map<String, dynamic>,
            )
          : null,
      outputTranscription: json['outputTranscription'] != null
          ? Transcription.fromJson(
              json['outputTranscription'] as Map<String, dynamic>,
            )
          : null,
      groundingMetadata: json['groundingMetadata'] != null
          ? GroundingMetadata.fromJson(
              json['groundingMetadata'] as Map<String, dynamic>,
            )
          : null,
      usageMetadata: json['usageMetadata'] != null
          ? UsageMetadata.fromJson(
              json['usageMetadata'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'serverContent': {
      if (modelTurn != null) 'modelTurn': modelTurn!.toJson(),
      if (turnComplete != null) 'turnComplete': turnComplete,
      if (generationComplete != null) 'generationComplete': generationComplete,
      if (interrupted != null) 'interrupted': interrupted,
      if (inputTranscription != null)
        'inputTranscription': inputTranscription!.toJson(),
      if (outputTranscription != null)
        'outputTranscription': outputTranscription!.toJson(),
      if (groundingMetadata != null)
        'groundingMetadata': groundingMetadata!.toJson(),
      if (usageMetadata != null) 'usageMetadata': usageMetadata!.toJson(),
    },
  };

  @override
  String toString() =>
      'BidiGenerateContentServerContent(turnComplete: $turnComplete, '
      'generationComplete: $generationComplete, interrupted: $interrupted)';
}

/// Tool call request message.
///
/// Sent when the model wants to execute one or more tools.
/// Respond with [BidiGenerateContentToolResponse].
class BidiGenerateContentToolCall extends BidiGenerateContentServerMessage {
  /// The function calls to execute.
  final List<FunctionCall> functionCalls;

  /// Creates a [BidiGenerateContentToolCall].
  const BidiGenerateContentToolCall({required this.functionCalls});

  /// Creates from JSON.
  factory BidiGenerateContentToolCall.fromJson(Map<String, dynamic> json) {
    return BidiGenerateContentToolCall(
      functionCalls: (json['functionCalls'] as List<dynamic>)
          .map((e) => FunctionCall.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'toolCall': {
      'functionCalls': functionCalls.map((e) => e.toJson()).toList(),
    },
  };

  @override
  String toString() =>
      'BidiGenerateContentToolCall(functionCalls: ${functionCalls.length})';
}

/// Tool call cancellation message.
///
/// Sent when the model no longer needs the results of pending tool calls,
/// typically due to user interruption.
class BidiGenerateContentToolCallCancellation
    extends BidiGenerateContentServerMessage {
  /// The IDs of tool calls to cancel.
  final List<String> ids;

  /// Creates a [BidiGenerateContentToolCallCancellation].
  const BidiGenerateContentToolCallCancellation({required this.ids});

  /// Creates from JSON.
  factory BidiGenerateContentToolCallCancellation.fromJson(
    Map<String, dynamic> json,
  ) {
    return BidiGenerateContentToolCallCancellation(
      ids: (json['ids'] as List<dynamic>).cast<String>(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'toolCallCancellation': {'ids': ids},
  };

  @override
  String toString() => 'BidiGenerateContentToolCallCancellation(ids: $ids)';
}

/// Go away message indicating session is ending.
///
/// Sent by the server before the session ends, giving the client
/// time to save state or reconnect with a resumption token.
class GoAway extends BidiGenerateContentServerMessage {
  /// Time remaining before the session ends.
  ///
  /// Format: ISO 8601 duration (e.g., "PT30S" for 30 seconds).
  final String? timeLeft;

  /// Creates a [GoAway].
  const GoAway({this.timeLeft});

  /// Creates from JSON.
  factory GoAway.fromJson(Map<String, dynamic> json) {
    return GoAway(timeLeft: json['timeLeft'] as String?);
  }

  @override
  Map<String, dynamic> toJson() => {
    'goAway': {if (timeLeft != null) 'timeLeft': timeLeft},
  };

  @override
  String toString() => 'GoAway(timeLeft: $timeLeft)';
}

/// Session resumption update message.
///
/// Contains a token that can be used to resume the session later.
class SessionResumptionUpdate extends BidiGenerateContentServerMessage {
  /// The new resumption handle/token.
  ///
  /// Store this and include it in [SessionResumptionConfig.handle] when
  /// reconnecting to resume the session.
  final String? newHandle;

  /// Whether the session can be resumed.
  final bool? resumable;

  /// Creates a [SessionResumptionUpdate].
  const SessionResumptionUpdate({this.newHandle, this.resumable});

  /// Creates from JSON.
  factory SessionResumptionUpdate.fromJson(Map<String, dynamic> json) {
    return SessionResumptionUpdate(
      newHandle: json['newHandle'] as String?,
      resumable: json['resumable'] as bool?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'sessionResumptionUpdate': {
      if (newHandle != null) 'newHandle': newHandle,
      if (resumable != null) 'resumable': resumable,
    },
  };

  @override
  String toString() =>
      'SessionResumptionUpdate(newHandle: ${newHandle != null ? "..." : null}, '
      'resumable: $resumable)';
}

/// Unknown server message type.
///
/// This is returned when the server sends a message type that this client
/// version doesn't recognize. This allows graceful handling of future API
/// additions without crashing.
///
/// Applications can check for this type and handle it appropriately:
/// ```dart
/// final message = BidiGenerateContentServerMessage.fromJson(json);
/// if (message is UnknownServerMessage) {
///   // Log or ignore unrecognized message type
///   print('Unknown message: ${message.rawJson.keys}');
/// }
/// ```
class UnknownServerMessage extends BidiGenerateContentServerMessage {
  /// The raw JSON of the unrecognized message.
  final Map<String, dynamic> rawJson;

  /// Creates an [UnknownServerMessage].
  const UnknownServerMessage(this.rawJson);

  @override
  Map<String, dynamic> toJson() => rawJson;

  @override
  String toString() => 'UnknownServerMessage(keys: ${rawJson.keys})';
}
