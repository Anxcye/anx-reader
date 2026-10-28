import '../copy_with_sentinel.dart';
import 'maps.dart';
import 'retrieved_context.dart';
import 'web.dart';

/// Grounding chunk.
class GroundingChunk {
  /// Grounding chunk from the web.
  final Web? web;

  /// Optional. Grounding chunk from context retrieved by the file search tool.
  final RetrievedContext? retrievedContext;

  /// Optional. Grounding chunk from Google Maps.
  final Maps? maps;

  /// Creates a [GroundingChunk].
  const GroundingChunk({this.web, this.retrievedContext, this.maps});

  /// Creates a [GroundingChunk] from JSON.
  factory GroundingChunk.fromJson(Map<String, dynamic> json) => GroundingChunk(
    web: json['web'] != null
        ? Web.fromJson(json['web'] as Map<String, dynamic>)
        : null,
    retrievedContext: json['retrievedContext'] != null
        ? RetrievedContext.fromJson(
            json['retrievedContext'] as Map<String, dynamic>,
          )
        : null,
    maps: json['maps'] != null
        ? Maps.fromJson(json['maps'] as Map<String, dynamic>)
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (web != null) 'web': web!.toJson(),
    if (retrievedContext != null)
      'retrievedContext': retrievedContext!.toJson(),
    if (maps != null) 'maps': maps!.toJson(),
  };

  /// Creates a copy with replaced values.
  GroundingChunk copyWith({
    Object? web = unsetCopyWithValue,
    Object? retrievedContext = unsetCopyWithValue,
    Object? maps = unsetCopyWithValue,
  }) {
    return GroundingChunk(
      web: web == unsetCopyWithValue ? this.web : web as Web?,
      retrievedContext: retrievedContext == unsetCopyWithValue
          ? this.retrievedContext
          : retrievedContext as RetrievedContext?,
      maps: maps == unsetCopyWithValue ? this.maps : maps as Maps?,
    );
  }

  @override
  String toString() =>
      'GroundingChunk(web: $web, retrievedContext: $retrievedContext, maps: $maps)';
}
