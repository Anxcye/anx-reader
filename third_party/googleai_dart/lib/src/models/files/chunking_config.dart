import '../copy_with_sentinel.dart';
import 'white_space_config.dart';

/// Parameters for telling the service how to chunk the file.
class ChunkingConfig {
  /// White space chunking configuration.
  final WhiteSpaceConfig? whiteSpaceConfig;

  /// Creates a [ChunkingConfig].
  const ChunkingConfig({this.whiteSpaceConfig});

  /// Creates a [ChunkingConfig] from JSON.
  factory ChunkingConfig.fromJson(Map<String, dynamic> json) => ChunkingConfig(
    whiteSpaceConfig: json['whiteSpaceConfig'] != null
        ? WhiteSpaceConfig.fromJson(
            json['whiteSpaceConfig'] as Map<String, dynamic>,
          )
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (whiteSpaceConfig != null)
      'whiteSpaceConfig': whiteSpaceConfig!.toJson(),
  };

  /// Creates a copy with replaced values.
  ChunkingConfig copyWith({Object? whiteSpaceConfig = unsetCopyWithValue}) {
    return ChunkingConfig(
      whiteSpaceConfig: whiteSpaceConfig == unsetCopyWithValue
          ? this.whiteSpaceConfig
          : whiteSpaceConfig as WhiteSpaceConfig?,
    );
  }

  @override
  String toString() => 'ChunkingConfig(whiteSpaceConfig: $whiteSpaceConfig)';
}
