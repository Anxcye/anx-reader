import '../copy_with_sentinel.dart';
import 'lat_lng.dart';

/// Retrieval config.
class RetrievalConfig {
  /// Optional. The location of the user.
  final LatLng? latLng;

  /// Optional. The language code of the user.
  ///
  /// Language code for content. Use language tags defined by
  /// [BCP47](https://www.rfc-editor.org/rfc/bcp/bcp47.txt).
  final String? languageCode;

  /// Creates a [RetrievalConfig].
  const RetrievalConfig({this.latLng, this.languageCode});

  /// Creates a [RetrievalConfig] from JSON.
  factory RetrievalConfig.fromJson(Map<String, dynamic> json) =>
      RetrievalConfig(
        latLng: json['latLng'] != null
            ? LatLng.fromJson(json['latLng'] as Map<String, dynamic>)
            : null,
        languageCode: json['languageCode'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (latLng != null) 'latLng': latLng!.toJson(),
    if (languageCode != null) 'languageCode': languageCode,
  };

  /// Creates a copy with replaced values.
  RetrievalConfig copyWith({
    Object? latLng = unsetCopyWithValue,
    Object? languageCode = unsetCopyWithValue,
  }) {
    return RetrievalConfig(
      latLng: latLng == unsetCopyWithValue ? this.latLng : latLng as LatLng?,
      languageCode: languageCode == unsetCopyWithValue
          ? this.languageCode
          : languageCode as String?,
    );
  }

  @override
  String toString() =>
      'RetrievalConfig(latLng: $latLng, languageCode: $languageCode)';
}
