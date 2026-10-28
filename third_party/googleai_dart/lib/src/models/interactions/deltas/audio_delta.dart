part of 'deltas.dart';

/// An audio delta update.
class AudioDelta extends InteractionDelta {
  @override
  String get type => 'audio';

  /// Base64-encoded audio data.
  final String? data;

  /// URI of the audio.
  final String? uri;

  /// The MIME type of the audio.
  final String? mimeType;

  /// Creates an [AudioDelta] instance.
  const AudioDelta({this.data, this.uri, this.mimeType});

  /// Creates an [AudioDelta] from JSON.
  factory AudioDelta.fromJson(Map<String, dynamic> json) => AudioDelta(
    data: json['data'] as String?,
    uri: json['uri'] as String?,
    mimeType: json['mime_type'] as String?,
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (data != null) 'data': data,
    if (uri != null) 'uri': uri,
    if (mimeType != null) 'mime_type': mimeType,
  };
}
