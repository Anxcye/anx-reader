/// Configuration for proactive audio responses.
///
/// Allows the model to proactively generate audio without explicit prompts.
class ProactivityConfig {
  /// Whether proactive audio is enabled.
  ///
  /// When enabled, the model may generate audio responses proactively.
  final bool? proactiveAudio;

  /// Creates a [ProactivityConfig].
  const ProactivityConfig({this.proactiveAudio});

  /// Creates a configuration with proactive audio enabled.
  factory ProactivityConfig.enabled() =>
      const ProactivityConfig(proactiveAudio: true);

  /// Creates a configuration with proactive audio disabled.
  factory ProactivityConfig.disabled() =>
      const ProactivityConfig(proactiveAudio: false);

  /// Creates from JSON.
  factory ProactivityConfig.fromJson(Map<String, dynamic> json) {
    return ProactivityConfig(proactiveAudio: json['proactiveAudio'] as bool?);
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (proactiveAudio != null) 'proactiveAudio': proactiveAudio,
  };

  /// Creates a copy with the given fields replaced.
  ProactivityConfig copyWith({bool? proactiveAudio}) {
    return ProactivityConfig(
      proactiveAudio: proactiveAudio ?? this.proactiveAudio,
    );
  }

  @override
  String toString() => 'ProactivityConfig(proactiveAudio: $proactiveAudio)';
}
