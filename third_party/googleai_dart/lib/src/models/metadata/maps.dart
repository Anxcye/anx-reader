import '../copy_with_sentinel.dart';
import 'place_answer_sources.dart';

/// A grounding chunk from Google Maps.
///
/// A Maps chunk corresponds to a single place.
class Maps {
  /// URI reference of the place.
  final String? uri;

  /// Title of the place.
  final String? title;

  /// Text description of the place answer.
  final String? text;

  /// This ID of the place, in `places/{place_id}` format.
  ///
  /// A user can use this ID to look up that place.
  final String? placeId;

  /// Sources that provide answers about the features of a given place
  /// in Google Maps.
  final PlaceAnswerSources? placeAnswerSources;

  /// Creates a [Maps].
  const Maps({
    this.uri,
    this.title,
    this.text,
    this.placeId,
    this.placeAnswerSources,
  });

  /// Creates a [Maps] from JSON.
  factory Maps.fromJson(Map<String, dynamic> json) => Maps(
    uri: json['uri'] as String?,
    title: json['title'] as String?,
    text: json['text'] as String?,
    placeId: json['placeId'] as String?,
    placeAnswerSources: json['placeAnswerSources'] != null
        ? PlaceAnswerSources.fromJson(
            json['placeAnswerSources'] as Map<String, dynamic>,
          )
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (uri != null) 'uri': uri,
    if (title != null) 'title': title,
    if (text != null) 'text': text,
    if (placeId != null) 'placeId': placeId,
    if (placeAnswerSources != null)
      'placeAnswerSources': placeAnswerSources!.toJson(),
  };

  /// Creates a copy with replaced values.
  Maps copyWith({
    Object? uri = unsetCopyWithValue,
    Object? title = unsetCopyWithValue,
    Object? text = unsetCopyWithValue,
    Object? placeId = unsetCopyWithValue,
    Object? placeAnswerSources = unsetCopyWithValue,
  }) {
    return Maps(
      uri: uri == unsetCopyWithValue ? this.uri : uri as String?,
      title: title == unsetCopyWithValue ? this.title : title as String?,
      text: text == unsetCopyWithValue ? this.text : text as String?,
      placeId: placeId == unsetCopyWithValue
          ? this.placeId
          : placeId as String?,
      placeAnswerSources: placeAnswerSources == unsetCopyWithValue
          ? this.placeAnswerSources
          : placeAnswerSources as PlaceAnswerSources?,
    );
  }

  @override
  String toString() =>
      'Maps(uri: $uri, title: $title, text: $text, placeId: $placeId, placeAnswerSources: $placeAnswerSources)';
}
