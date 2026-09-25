import '../copy_with_sentinel.dart';

/// A citation source.
class CitationSource {
  /// Start index of the citation.
  final int? startIndex;

  /// End index of the citation.
  final int? endIndex;

  /// URI of the source.
  final String? uri;

  /// License of the source.
  final String? license;

  /// Title of the source.
  final String? title;

  /// Publication date.
  final DateTime? publicationDate;

  /// Creates a [CitationSource].
  const CitationSource({
    this.startIndex,
    this.endIndex,
    this.uri,
    this.license,
    this.title,
    this.publicationDate,
  });

  /// Creates a [CitationSource] from JSON.
  factory CitationSource.fromJson(Map<String, dynamic> json) => CitationSource(
    startIndex: json['startIndex'] as int?,
    endIndex: json['endIndex'] as int?,
    uri: json['uri'] as String?,
    license: json['license'] as String?,
    title: json['title'] as String?,
    publicationDate: json['publicationDate'] != null
        ? DateTime.parse(json['publicationDate'] as String)
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (startIndex != null) 'startIndex': startIndex,
    if (endIndex != null) 'endIndex': endIndex,
    if (uri != null) 'uri': uri,
    if (license != null) 'license': license,
    if (title != null) 'title': title,
    if (publicationDate != null)
      'publicationDate': publicationDate!.toIso8601String(),
  };

  /// Creates a copy with replaced values.
  CitationSource copyWith({
    Object? startIndex = unsetCopyWithValue,
    Object? endIndex = unsetCopyWithValue,
    Object? uri = unsetCopyWithValue,
    Object? license = unsetCopyWithValue,
    Object? title = unsetCopyWithValue,
    Object? publicationDate = unsetCopyWithValue,
  }) {
    return CitationSource(
      startIndex: startIndex == unsetCopyWithValue
          ? this.startIndex
          : startIndex as int?,
      endIndex: endIndex == unsetCopyWithValue
          ? this.endIndex
          : endIndex as int?,
      uri: uri == unsetCopyWithValue ? this.uri : uri as String?,
      license: license == unsetCopyWithValue
          ? this.license
          : license as String?,
      title: title == unsetCopyWithValue ? this.title : title as String?,
      publicationDate: publicationDate == unsetCopyWithValue
          ? this.publicationDate
          : publicationDate as DateTime?,
    );
  }
}

/// Citation sources for generated content.
class CitationMetadata {
  /// List of citation sources.
  final List<CitationSource>? citationSources;

  /// Creates a [CitationMetadata].
  const CitationMetadata({this.citationSources});

  /// Creates a [CitationMetadata] from JSON.
  factory CitationMetadata.fromJson(Map<String, dynamic> json) =>
      CitationMetadata(
        citationSources: json['citationSources'] != null
            ? (json['citationSources'] as List)
                  .map(
                    (e) => CitationSource.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (citationSources != null)
      'citationSources': citationSources!.map((e) => e.toJson()).toList(),
  };

  /// Creates a copy with replaced values.
  CitationMetadata copyWith({Object? citationSources = unsetCopyWithValue}) {
    return CitationMetadata(
      citationSources: citationSources == unsetCopyWithValue
          ? this.citationSources
          : citationSources as List<CitationSource>?,
    );
  }
}
