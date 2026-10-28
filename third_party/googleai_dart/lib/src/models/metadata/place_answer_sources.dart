import '../copy_with_sentinel.dart';
import 'review_snippet.dart';

/// Collection of sources that provide answers about the features of a given
/// place in Google Maps.
///
/// Each PlaceAnswerSources message corresponds to a specific place in Google
/// Maps. The Google Maps tool used these sources in order to answer questions
/// about features of the place (e.g: "does Bar Foo have Wifi" or "is Foo Bar
/// wheelchair accessible?").
///
/// Currently only review snippets are supported as sources.
class PlaceAnswerSources {
  /// Snippets of reviews that are used to generate answers about the
  /// features of a given place in Google Maps.
  final List<ReviewSnippet>? reviewSnippets;

  /// Creates a [PlaceAnswerSources].
  const PlaceAnswerSources({this.reviewSnippets});

  /// Creates a [PlaceAnswerSources] from JSON.
  factory PlaceAnswerSources.fromJson(Map<String, dynamic> json) =>
      PlaceAnswerSources(
        reviewSnippets: (json['reviewSnippets'] as List?)
            ?.map((e) => ReviewSnippet.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (reviewSnippets != null)
      'reviewSnippets': reviewSnippets!.map((e) => e.toJson()).toList(),
  };

  /// Creates a copy with replaced values.
  PlaceAnswerSources copyWith({Object? reviewSnippets = unsetCopyWithValue}) {
    return PlaceAnswerSources(
      reviewSnippets: reviewSnippets == unsetCopyWithValue
          ? this.reviewSnippets
          : reviewSnippets as List<ReviewSnippet>?,
    );
  }

  @override
  String toString() => 'PlaceAnswerSources(reviewSnippets: $reviewSnippets)';
}
