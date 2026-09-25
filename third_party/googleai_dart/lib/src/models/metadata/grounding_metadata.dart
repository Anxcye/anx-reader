import '../copy_with_sentinel.dart';
import 'grounding_chunk.dart';
import 'grounding_support.dart';
import 'retrieval_metadata.dart';
import 'search_entry_point.dart';

/// Metadata returned to client when grounding is enabled.
class GroundingMetadata {
  /// Optional. Google search entry for the following-up web searches.
  final SearchEntryPoint? searchEntryPoint;

  /// List of supporting references retrieved from specified grounding source.
  final List<GroundingChunk>? groundingChunks;

  /// List of grounding support.
  final List<GroundingSupport>? groundingSupports;

  /// Metadata related to retrieval in the grounding flow.
  final RetrievalMetadata? retrievalMetadata;

  /// Web search queries for the following-up web search.
  final List<String>? webSearchQueries;

  /// Optional. Resource name of the Google Maps widget context token that can
  /// be used with the PlacesContextElement widget in order to render
  /// contextual data.
  ///
  /// Only populated in the case that grounding with Google Maps is enabled.
  final String? googleMapsWidgetContextToken;

  /// Creates a [GroundingMetadata].
  const GroundingMetadata({
    this.searchEntryPoint,
    this.groundingChunks,
    this.groundingSupports,
    this.retrievalMetadata,
    this.webSearchQueries,
    this.googleMapsWidgetContextToken,
  });

  /// Creates a [GroundingMetadata] from JSON.
  factory GroundingMetadata.fromJson(Map<String, dynamic> json) =>
      GroundingMetadata(
        searchEntryPoint: json['searchEntryPoint'] != null
            ? SearchEntryPoint.fromJson(
                json['searchEntryPoint'] as Map<String, dynamic>,
              )
            : null,
        groundingChunks: (json['groundingChunks'] as List?)
            ?.map((e) => GroundingChunk.fromJson(e as Map<String, dynamic>))
            .toList(),
        groundingSupports: (json['groundingSupports'] as List?)
            ?.map((e) => GroundingSupport.fromJson(e as Map<String, dynamic>))
            .toList(),
        retrievalMetadata: json['retrievalMetadata'] != null
            ? RetrievalMetadata.fromJson(
                json['retrievalMetadata'] as Map<String, dynamic>,
              )
            : null,
        webSearchQueries: (json['webSearchQueries'] as List?)
            ?.map((e) => e as String)
            .toList(),
        googleMapsWidgetContextToken:
            json['googleMapsWidgetContextToken'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (searchEntryPoint != null)
      'searchEntryPoint': searchEntryPoint!.toJson(),
    if (groundingChunks != null)
      'groundingChunks': groundingChunks!.map((e) => e.toJson()).toList(),
    if (groundingSupports != null)
      'groundingSupports': groundingSupports!.map((e) => e.toJson()).toList(),
    if (retrievalMetadata != null)
      'retrievalMetadata': retrievalMetadata!.toJson(),
    if (webSearchQueries != null) 'webSearchQueries': webSearchQueries,
    if (googleMapsWidgetContextToken != null)
      'googleMapsWidgetContextToken': googleMapsWidgetContextToken,
  };

  /// Creates a copy with replaced values.
  GroundingMetadata copyWith({
    Object? searchEntryPoint = unsetCopyWithValue,
    Object? groundingChunks = unsetCopyWithValue,
    Object? groundingSupports = unsetCopyWithValue,
    Object? retrievalMetadata = unsetCopyWithValue,
    Object? webSearchQueries = unsetCopyWithValue,
    Object? googleMapsWidgetContextToken = unsetCopyWithValue,
  }) {
    return GroundingMetadata(
      searchEntryPoint: searchEntryPoint == unsetCopyWithValue
          ? this.searchEntryPoint
          : searchEntryPoint as SearchEntryPoint?,
      groundingChunks: groundingChunks == unsetCopyWithValue
          ? this.groundingChunks
          : groundingChunks as List<GroundingChunk>?,
      groundingSupports: groundingSupports == unsetCopyWithValue
          ? this.groundingSupports
          : groundingSupports as List<GroundingSupport>?,
      retrievalMetadata: retrievalMetadata == unsetCopyWithValue
          ? this.retrievalMetadata
          : retrievalMetadata as RetrievalMetadata?,
      webSearchQueries: webSearchQueries == unsetCopyWithValue
          ? this.webSearchQueries
          : webSearchQueries as List<String>?,
      googleMapsWidgetContextToken:
          googleMapsWidgetContextToken == unsetCopyWithValue
          ? this.googleMapsWidgetContextToken
          : googleMapsWidgetContextToken as String?,
    );
  }

  @override
  String toString() =>
      'GroundingMetadata(searchEntryPoint: $searchEntryPoint, groundingChunks: $groundingChunks, groundingSupports: $groundingSupports, retrievalMetadata: $retrievalMetadata, webSearchQueries: $webSearchQueries, googleMapsWidgetContextToken: $googleMapsWidgetContextToken)';
}
