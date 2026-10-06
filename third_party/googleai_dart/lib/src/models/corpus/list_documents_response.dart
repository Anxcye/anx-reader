import '../copy_with_sentinel.dart';
import 'document.dart';

/// Response from ListDocuments containing a paginated list of Documents.
///
/// Results are sorted by ascending document.create_time.
class ListDocumentsResponse {
  /// Creates a new [ListDocumentsResponse] instance.
  const ListDocumentsResponse({this.documents, this.nextPageToken});

  /// The returned Documents.
  final List<Document>? documents;

  /// Token for retrieving the next page.
  ///
  /// If omitted, no more pages exist.
  final String? nextPageToken;

  /// Creates a [ListDocumentsResponse] from JSON.
  factory ListDocumentsResponse.fromJson(Map<String, dynamic> json) {
    return ListDocumentsResponse(
      documents: json['documents'] != null
          ? (json['documents'] as List)
                .map((e) => Document.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      nextPageToken: json['nextPageToken'] as String?,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      if (documents != null)
        'documents': documents!.map((e) => e.toJson()).toList(),
      if (nextPageToken != null) 'nextPageToken': nextPageToken,
    };
  }

  /// Creates a copy with replaced values.
  ListDocumentsResponse copyWith({
    Object? documents = unsetCopyWithValue,
    Object? nextPageToken = unsetCopyWithValue,
  }) {
    return ListDocumentsResponse(
      documents: documents == unsetCopyWithValue
          ? this.documents
          : documents as List<Document>?,
      nextPageToken: nextPageToken == unsetCopyWithValue
          ? this.nextPageToken
          : nextPageToken as String?,
    );
  }

  @override
  String toString() =>
      'ListDocumentsResponse('
      'documents: $documents, '
      'nextPageToken: $nextPageToken)';
}
