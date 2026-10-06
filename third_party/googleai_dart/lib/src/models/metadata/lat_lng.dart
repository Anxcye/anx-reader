import '../copy_with_sentinel.dart';

/// An object that represents a latitude/longitude pair.
///
/// This is expressed as a pair of doubles to represent degrees latitude
/// and degrees longitude. Unless specified otherwise, this object must
/// conform to the WGS84 standard. Values must be within normalized ranges.
class LatLng {
  /// The latitude in degrees. It must be in the range [-90.0, +90.0].
  final double? latitude;

  /// The longitude in degrees. It must be in the range [-180.0, +180.0].
  final double? longitude;

  /// Creates a [LatLng].
  const LatLng({this.latitude, this.longitude});

  /// Creates a [LatLng] from JSON.
  factory LatLng.fromJson(Map<String, dynamic> json) => LatLng(
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  /// Creates a copy with replaced values.
  LatLng copyWith({
    Object? latitude = unsetCopyWithValue,
    Object? longitude = unsetCopyWithValue,
  }) {
    return LatLng(
      latitude: latitude == unsetCopyWithValue
          ? this.latitude
          : latitude as double?,
      longitude: longitude == unsetCopyWithValue
          ? this.longitude
          : longitude as double?,
    );
  }

  @override
  String toString() => 'LatLng(latitude: $latitude, longitude: $longitude)';
}
