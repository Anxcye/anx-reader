part of 'deltas.dart';

/// A video delta update.
class VideoDelta extends InteractionDelta {
  @override
  String get type => 'video';

  /// Base64-encoded video data.
  final String? data;

  /// URI of the video.
  final String? uri;

  /// The MIME type of the video.
  final String? mimeType;

  /// The resolution of the media.
  final String? resolution;

  /// Creates a [VideoDelta] instance.
  const VideoDelta({this.data, this.uri, this.mimeType, this.resolution});

  /// Creates a [VideoDelta] from JSON.
  factory VideoDelta.fromJson(Map<String, dynamic> json) => VideoDelta(
    data: json['data'] as String?,
    uri: json['uri'] as String?,
    mimeType: json['mime_type'] as String?,
    resolution: json['resolution'] as String?,
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (data != null) 'data': data,
    if (uri != null) 'uri': uri,
    if (mimeType != null) 'mime_type': mimeType,
    if (resolution != null) 'resolution': resolution,
  };
}
