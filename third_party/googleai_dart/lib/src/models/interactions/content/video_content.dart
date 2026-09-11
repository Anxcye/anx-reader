part of 'content.dart';

/// A video content block.
class VideoContent extends InteractionContent {
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

  /// Creates a [VideoContent] instance.
  const VideoContent({this.data, this.uri, this.mimeType, this.resolution});

  /// Creates a [VideoContent] from JSON.
  factory VideoContent.fromJson(Map<String, dynamic> json) => VideoContent(
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

  /// Creates a copy with replaced values.
  VideoContent copyWith({
    Object? data = unsetCopyWithValue,
    Object? uri = unsetCopyWithValue,
    Object? mimeType = unsetCopyWithValue,
    Object? resolution = unsetCopyWithValue,
  }) {
    return VideoContent(
      data: data == unsetCopyWithValue ? this.data : data as String?,
      uri: uri == unsetCopyWithValue ? this.uri : uri as String?,
      mimeType: mimeType == unsetCopyWithValue
          ? this.mimeType
          : mimeType as String?,
      resolution: resolution == unsetCopyWithValue
          ? this.resolution
          : resolution as String?,
    );
  }
}
