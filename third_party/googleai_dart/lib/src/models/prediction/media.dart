import '../copy_with_sentinel.dart';

/// A proto encapsulate various types of media.
class Media {
  /// Video as the only one for now. This is mimicking Vertex proto.
  final Video? video;

  /// Creates a [Media].
  const Media({this.video});

  /// Creates a [Media] from JSON.
  factory Media.fromJson(Map<String, dynamic> json) => Media(
    video: json['video'] != null
        ? Video.fromJson(json['video'] as Map<String, dynamic>)
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (video != null) 'video': video!.toJson(),
  };

  /// Creates a copy with replaced values.
  Media copyWith({Object? video = unsetCopyWithValue}) {
    return Media(
      video: video == unsetCopyWithValue ? this.video : video as Video?,
    );
  }
}

/// Representation of a video.
class Video {
  /// Raw bytes (base64 encoded).
  final String? video;

  /// Path to another storage (e.g., GCS URI).
  final String? uri;

  /// Creates a [Video].
  const Video({this.video, this.uri});

  /// Creates a [Video] from JSON.
  factory Video.fromJson(Map<String, dynamic> json) =>
      Video(video: json['video'] as String?, uri: json['uri'] as String?);

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (video != null) 'video': video,
    if (uri != null) 'uri': uri,
  };

  /// Creates a copy with replaced values.
  Video copyWith({
    Object? video = unsetCopyWithValue,
    Object? uri = unsetCopyWithValue,
  }) {
    return Video(
      video: video == unsetCopyWithValue ? this.video : video as String?,
      uri: uri == unsetCopyWithValue ? this.uri : uri as String?,
    );
  }
}
