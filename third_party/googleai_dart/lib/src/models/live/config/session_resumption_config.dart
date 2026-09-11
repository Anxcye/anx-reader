/// Configuration for session resumption.
///
/// Allows resuming a previous session using a stored handle.
/// When included in the setup message (even without a handle),
/// the server will provide resumption tokens via [SessionResumptionUpdate].
class SessionResumptionConfig {
  /// Handle from a previous session.
  ///
  /// Use the `newHandle` from [SessionResumptionUpdate] to resume.
  /// If not present, a new session is created but resumption is enabled.
  final String? handle;

  /// Whether to use transparent resumption behavior.
  ///
  /// When `true`, session resumption happens transparently without
  /// requiring explicit handling of resumption tokens.
  final bool? transparent;

  /// Creates a [SessionResumptionConfig].
  const SessionResumptionConfig({this.handle, this.transparent});

  /// Creates a configuration for resuming with a handle.
  factory SessionResumptionConfig.resume(String handle, {bool? transparent}) =>
      SessionResumptionConfig(handle: handle, transparent: transparent);

  /// Creates a configuration to enable session resumption.
  ///
  /// When this is included in the setup (without a handle),
  /// the server will provide resumption tokens that can be used
  /// to resume the session later.
  const SessionResumptionConfig.enabled({this.transparent}) : handle = null;

  /// Creates from JSON.
  factory SessionResumptionConfig.fromJson(Map<String, dynamic> json) {
    return SessionResumptionConfig(
      handle: json['handle'] as String?,
      transparent: json['transparent'] as bool?,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (handle != null) 'handle': handle,
    if (transparent != null) 'transparent': transparent,
  };

  /// Creates a copy with the given fields replaced.
  SessionResumptionConfig copyWith({String? handle, bool? transparent}) {
    return SessionResumptionConfig(
      handle: handle ?? this.handle,
      transparent: transparent ?? this.transparent,
    );
  }

  @override
  String toString() =>
      'SessionResumptionConfig(handle: ${handle != null ? "..." : null}, transparent: $transparent)';
}
