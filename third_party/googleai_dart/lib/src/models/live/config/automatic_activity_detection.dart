import '../enums/end_sensitivity.dart';
import '../enums/start_sensitivity.dart';

/// Configuration for automatic voice activity detection (VAD).
///
/// Controls how the system detects when the user starts and stops speaking.
class AutomaticActivityDetection {
  /// Whether automatic detection is disabled.
  ///
  /// When `true`, manual activity signals must be used instead.
  final bool? disabled;

  /// Sensitivity for detecting speech start.
  final StartSensitivity? startOfSpeechSensitivity;

  /// Sensitivity for detecting speech end.
  final EndSensitivity? endOfSpeechSensitivity;

  /// Padding before detected speech in milliseconds.
  ///
  /// Audio before the detected speech start is included.
  final int? prefixPaddingMs;

  /// Silence duration to trigger end of speech in milliseconds.
  ///
  /// How long to wait after speech stops before ending the turn.
  final int? silenceDurationMs;

  /// Creates an [AutomaticActivityDetection].
  const AutomaticActivityDetection({
    this.disabled,
    this.startOfSpeechSensitivity,
    this.endOfSpeechSensitivity,
    this.prefixPaddingMs,
    this.silenceDurationMs,
  });

  /// Creates a configuration with automatic VAD enabled.
  factory AutomaticActivityDetection.enabled({
    StartSensitivity? startSensitivity,
    EndSensitivity? endSensitivity,
    int? prefixPaddingMs,
    int? silenceDurationMs,
  }) {
    return AutomaticActivityDetection(
      disabled: false,
      startOfSpeechSensitivity: startSensitivity,
      endOfSpeechSensitivity: endSensitivity,
      prefixPaddingMs: prefixPaddingMs,
      silenceDurationMs: silenceDurationMs,
    );
  }

  /// Creates a configuration with automatic VAD disabled (manual mode).
  factory AutomaticActivityDetection.manual() =>
      const AutomaticActivityDetection(disabled: true);

  /// Creates from JSON.
  factory AutomaticActivityDetection.fromJson(Map<String, dynamic> json) {
    return AutomaticActivityDetection(
      disabled: json['disabled'] as bool?,
      startOfSpeechSensitivity: json['startOfSpeechSensitivity'] != null
          ? StartSensitivity.fromJson(
              json['startOfSpeechSensitivity'] as String,
            )
          : null,
      endOfSpeechSensitivity: json['endOfSpeechSensitivity'] != null
          ? EndSensitivity.fromJson(json['endOfSpeechSensitivity'] as String)
          : null,
      prefixPaddingMs: json['prefixPaddingMs'] as int?,
      silenceDurationMs: json['silenceDurationMs'] as int?,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (disabled != null) 'disabled': disabled,
    if (startOfSpeechSensitivity != null)
      'startOfSpeechSensitivity': startOfSpeechSensitivity!.toJson(),
    if (endOfSpeechSensitivity != null)
      'endOfSpeechSensitivity': endOfSpeechSensitivity!.toJson(),
    if (prefixPaddingMs != null) 'prefixPaddingMs': prefixPaddingMs,
    if (silenceDurationMs != null) 'silenceDurationMs': silenceDurationMs,
  };

  /// Creates a copy with the given fields replaced.
  AutomaticActivityDetection copyWith({
    bool? disabled,
    StartSensitivity? startOfSpeechSensitivity,
    EndSensitivity? endOfSpeechSensitivity,
    int? prefixPaddingMs,
    int? silenceDurationMs,
  }) {
    return AutomaticActivityDetection(
      disabled: disabled ?? this.disabled,
      startOfSpeechSensitivity:
          startOfSpeechSensitivity ?? this.startOfSpeechSensitivity,
      endOfSpeechSensitivity:
          endOfSpeechSensitivity ?? this.endOfSpeechSensitivity,
      prefixPaddingMs: prefixPaddingMs ?? this.prefixPaddingMs,
      silenceDurationMs: silenceDurationMs ?? this.silenceDurationMs,
    );
  }

  @override
  String toString() =>
      'AutomaticActivityDetection(disabled: $disabled, '
      'silenceDurationMs: $silenceDurationMs)';
}
