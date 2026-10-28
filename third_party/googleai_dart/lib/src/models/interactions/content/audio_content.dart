part of 'content.dart';

/// An audio content block.
class AudioContent extends InteractionContent {
  @override
  String get type => 'audio';

  /// Base64-encoded audio data.
  final String? data;

  /// URI of the audio.
  final String? uri;

  /// The MIME type of the audio.
  final String? mimeType;

  /// Creates an [AudioContent] instance.
  const AudioContent({this.data, this.uri, this.mimeType});

  /// Creates an [AudioContent] from JSON.
  factory AudioContent.fromJson(Map<String, dynamic> json) => AudioContent(
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

  /// Creates a copy with replaced values.
  AudioContent copyWith({
    Object? data = unsetCopyWithValue,
    Object? uri = unsetCopyWithValue,
    Object? mimeType = unsetCopyWithValue,
  }) {
    return AudioContent(
      data: data == unsetCopyWithValue ? this.data : data as String?,
      uri: uri == unsetCopyWithValue ? this.uri : uri as String?,
      mimeType: mimeType == unsetCopyWithValue
          ? this.mimeType
          : mimeType as String?,
    );
  }
}
