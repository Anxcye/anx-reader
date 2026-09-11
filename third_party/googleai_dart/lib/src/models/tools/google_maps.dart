import '../copy_with_sentinel.dart';

/// The GoogleMaps Tool that provides geospatial context for the user's query.
class GoogleMaps {
  /// Optional. Whether to return a widget context token in the
  /// GroundingMetadata of the response.
  ///
  /// Developers can use the widget context token to render a Google Maps
  /// widget with geospatial context related to the places that the model
  /// references in the response.
  final bool? enableWidget;

  /// Creates a [GoogleMaps].
  const GoogleMaps({this.enableWidget});

  /// Creates a [GoogleMaps] from JSON.
  factory GoogleMaps.fromJson(Map<String, dynamic> json) =>
      GoogleMaps(enableWidget: json['enableWidget'] as bool?);

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (enableWidget != null) 'enableWidget': enableWidget,
  };

  /// Creates a copy with replaced values.
  GoogleMaps copyWith({Object? enableWidget = unsetCopyWithValue}) {
    return GoogleMaps(
      enableWidget: enableWidget == unsetCopyWithValue
          ? this.enableWidget
          : enableWidget as bool?,
    );
  }

  @override
  String toString() => 'GoogleMaps(enableWidget: $enableWidget)';
}
