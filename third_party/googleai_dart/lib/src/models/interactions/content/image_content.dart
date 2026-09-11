part of 'content.dart';

/// An image content block.
class ImageContent extends InteractionContent {
  @override
  String get type => 'image';

  /// Base64-encoded image data.
  final String? data;

  /// URI of the image.
  final String? uri;

  /// The MIME type of the image.
  final String? mimeType;

  /// The resolution of the media.
  final String? resolution;

  /// Creates an [ImageContent] instance.
  const ImageContent({this.data, this.uri, this.mimeType, this.resolution});

  /// Creates an [ImageContent] from JSON.
  factory ImageContent.fromJson(Map<String, dynamic> json) => ImageContent(
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
  ImageContent copyWith({
    Object? data = unsetCopyWithValue,
    Object? uri = unsetCopyWithValue,
    Object? mimeType = unsetCopyWithValue,
    Object? resolution = unsetCopyWithValue,
  }) {
    return ImageContent(
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
