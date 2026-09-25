import '../copy_with_sentinel.dart';

/// Encapsulates a snippet of a user review that answers a question about
/// the features of a specific place in Google Maps.
class ReviewSnippet {
  /// The ID of the review snippet.
  final String? reviewId;

  /// A link that corresponds to the user review on Google Maps.
  final String? googleMapsUri;

  /// Title of the review.
  final String? title;

  /// Creates a [ReviewSnippet].
  const ReviewSnippet({this.reviewId, this.googleMapsUri, this.title});

  /// Creates a [ReviewSnippet] from JSON.
  factory ReviewSnippet.fromJson(Map<String, dynamic> json) => ReviewSnippet(
    reviewId: json['reviewId'] as String?,
    googleMapsUri: json['googleMapsUri'] as String?,
    title: json['title'] as String?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (reviewId != null) 'reviewId': reviewId,
    if (googleMapsUri != null) 'googleMapsUri': googleMapsUri,
    if (title != null) 'title': title,
  };

  /// Creates a copy with replaced values.
  ReviewSnippet copyWith({
    Object? reviewId = unsetCopyWithValue,
    Object? googleMapsUri = unsetCopyWithValue,
    Object? title = unsetCopyWithValue,
  }) {
    return ReviewSnippet(
      reviewId: reviewId == unsetCopyWithValue
          ? this.reviewId
          : reviewId as String?,
      googleMapsUri: googleMapsUri == unsetCopyWithValue
          ? this.googleMapsUri
          : googleMapsUri as String?,
      title: title == unsetCopyWithValue ? this.title : title as String?,
    );
  }

  @override
  String toString() =>
      'ReviewSnippet(reviewId: $reviewId, googleMapsUri: $googleMapsUri, title: $title)';
}
