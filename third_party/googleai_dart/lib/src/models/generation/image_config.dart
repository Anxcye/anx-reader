import '../copy_with_sentinel.dart';

/// Config for image generation features.
class ImageConfig {
  /// The aspect ratio of the image to generate.
  ///
  /// Supported aspect ratios: 1:1, 2:3, 3:2, 3:4, 4:3, 9:16, 16:9, 21:9.
  /// If not specified, the model will choose a default aspect ratio based
  /// on any reference images provided.
  final String? aspectRatio;

  /// Specifies the size of generated images.
  ///
  /// Supported values are `1K`, `2K`, `4K`.
  /// If not specified, the model will use default value `1K`.
  final String? imageSize;

  /// Creates an [ImageConfig].
  const ImageConfig({this.aspectRatio, this.imageSize});

  /// Creates an [ImageConfig] from JSON.
  factory ImageConfig.fromJson(Map<String, dynamic> json) => ImageConfig(
    aspectRatio: json['aspectRatio'] as String?,
    imageSize: json['imageSize'] as String?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (aspectRatio != null) 'aspectRatio': aspectRatio,
    if (imageSize != null) 'imageSize': imageSize,
  };

  /// Creates a copy with replaced values.
  ImageConfig copyWith({
    Object? aspectRatio = unsetCopyWithValue,
    Object? imageSize = unsetCopyWithValue,
  }) {
    return ImageConfig(
      aspectRatio: aspectRatio == unsetCopyWithValue
          ? this.aspectRatio
          : aspectRatio as String?,
      imageSize: imageSize == unsetCopyWithValue
          ? this.imageSize
          : imageSize as String?,
    );
  }

  @override
  String toString() =>
      'ImageConfig(aspectRatio: $aspectRatio, imageSize: $imageSize)';
}
