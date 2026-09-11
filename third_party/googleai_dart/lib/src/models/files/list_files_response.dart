import '../copy_with_sentinel.dart';
import 'file.dart';

/// Response from listing files.
class ListFilesResponse {
  /// The list of files.
  final List<File> files;

  /// Token to retrieve the next page of results.
  final String? nextPageToken;

  /// Creates a [ListFilesResponse].
  const ListFilesResponse({required this.files, this.nextPageToken});

  /// Creates a [ListFilesResponse] from JSON.
  factory ListFilesResponse.fromJson(Map<String, dynamic> json) =>
      ListFilesResponse(
        files:
            (json['files'] as List<dynamic>?)
                ?.map((e) => File.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        nextPageToken: json['nextPageToken'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'files': files.map((e) => e.toJson()).toList(),
    if (nextPageToken != null) 'nextPageToken': nextPageToken,
  };

  /// Creates a copy with replaced values.
  ListFilesResponse copyWith({
    Object? files = unsetCopyWithValue,
    Object? nextPageToken = unsetCopyWithValue,
  }) {
    return ListFilesResponse(
      files: files == unsetCopyWithValue ? this.files : files! as List<File>,
      nextPageToken: nextPageToken == unsetCopyWithValue
          ? this.nextPageToken
          : nextPageToken as String?,
    );
  }
}
