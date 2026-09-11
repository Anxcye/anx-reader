import '../copy_with_sentinel.dart';
import 'corpus.dart';

/// Response from ListCorpora containing a paginated list of Corpora.
///
/// Results are sorted by ascending corpus.create_time.
class ListCorporaResponse {
  /// Creates a new [ListCorporaResponse] instance.
  const ListCorporaResponse({this.corpora, this.nextPageToken});

  /// The returned corpora.
  final List<Corpus>? corpora;

  /// Token for retrieving the next page.
  ///
  /// If omitted, no more pages exist.
  final String? nextPageToken;

  /// Creates a [ListCorporaResponse] from JSON.
  factory ListCorporaResponse.fromJson(Map<String, dynamic> json) {
    return ListCorporaResponse(
      corpora: json['corpora'] != null
          ? (json['corpora'] as List)
                .map((e) => Corpus.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      nextPageToken: json['nextPageToken'] as String?,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      if (corpora != null) 'corpora': corpora!.map((e) => e.toJson()).toList(),
      if (nextPageToken != null) 'nextPageToken': nextPageToken,
    };
  }

  /// Creates a copy with replaced values.
  ListCorporaResponse copyWith({
    Object? corpora = unsetCopyWithValue,
    Object? nextPageToken = unsetCopyWithValue,
  }) {
    return ListCorporaResponse(
      corpora: corpora == unsetCopyWithValue
          ? this.corpora
          : corpora as List<Corpus>?,
      nextPageToken: nextPageToken == unsetCopyWithValue
          ? this.nextPageToken
          : nextPageToken as String?,
    );
  }

  @override
  String toString() =>
      'ListCorporaResponse('
      'corpora: $corpora, '
      'nextPageToken: $nextPageToken)';
}
