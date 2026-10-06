part of 'deltas.dart';

/// A File Search result delta update.
class FileSearchResultDelta extends InteractionDelta {
  @override
  String get type => 'file_search_result';

  /// The results of the File Search.
  final List<FileSearchResult>? result;

  /// Creates a [FileSearchResultDelta] instance.
  const FileSearchResultDelta({this.result});

  /// Creates a [FileSearchResultDelta] from JSON.
  factory FileSearchResultDelta.fromJson(Map<String, dynamic> json) =>
      FileSearchResultDelta(
        result: (json['result'] as List<dynamic>?)
            ?.map((e) => FileSearchResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (result != null) 'result': result!.map((e) => e.toJson()).toList(),
  };
}
