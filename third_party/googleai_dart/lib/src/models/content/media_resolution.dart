import '../copy_with_sentinel.dart';

/// Media resolution for the input media.
class MediaResolution {
  /// The media resolution level.
  final MediaResolutionLevel? level;

  /// Creates a [MediaResolution].
  const MediaResolution({this.level});

  /// Creates a [MediaResolution] from JSON.
  factory MediaResolution.fromJson(Map<String, dynamic> json) =>
      MediaResolution(
        level: json['level'] != null
            ? MediaResolutionLevel.fromString(json['level'] as String)
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {if (level != null) 'level': level!.value};

  /// Creates a copy with replaced values.
  MediaResolution copyWith({Object? level = unsetCopyWithValue}) {
    return MediaResolution(
      level: level == unsetCopyWithValue
          ? this.level
          : level as MediaResolutionLevel?,
    );
  }

  @override
  String toString() => 'MediaResolution(level: $level)';
}

/// Media resolution level.
enum MediaResolutionLevel {
  /// Media resolution has not been set.
  unspecified('MEDIA_RESOLUTION_UNSPECIFIED'),

  /// Media resolution set to low.
  low('MEDIA_RESOLUTION_LOW'),

  /// Media resolution set to medium.
  medium('MEDIA_RESOLUTION_MEDIUM'),

  /// Media resolution set to high.
  high('MEDIA_RESOLUTION_HIGH'),

  /// Media resolution set to ultra high.
  ultraHigh('MEDIA_RESOLUTION_ULTRA_HIGH');

  const MediaResolutionLevel(this.value);

  /// The string value of the enum.
  final String value;

  /// Creates a [MediaResolutionLevel] from a string value.
  static MediaResolutionLevel fromString(String value) {
    return MediaResolutionLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MediaResolutionLevel.unspecified,
    );
  }
}
