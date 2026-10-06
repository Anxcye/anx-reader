import '../copy_with_sentinel.dart';

/// Metadata for a video file.
class VideoMetadata {
  /// Duration of the video (format: google-duration, e.g., "3.5s").
  final String? videoDuration;

  /// Creates a [VideoMetadata].
  const VideoMetadata({this.videoDuration});

  /// Creates a [VideoMetadata] from JSON.
  factory VideoMetadata.fromJson(Map<String, dynamic> json) =>
      VideoMetadata(videoDuration: json['videoDuration'] as String?);

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (videoDuration != null) 'videoDuration': videoDuration,
  };

  /// Creates a copy with replaced values.
  VideoMetadata copyWith({Object? videoDuration = unsetCopyWithValue}) {
    return VideoMetadata(
      videoDuration: videoDuration == unsetCopyWithValue
          ? this.videoDuration
          : videoDuration as String?,
    );
  }
}
