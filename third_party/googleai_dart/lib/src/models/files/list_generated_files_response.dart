import '../copy_with_sentinel.dart';
import 'generated_file.dart';

/// Response for `ListGeneratedFiles`.
class ListGeneratedFilesResponse {
  /// The list of GeneratedFiles.
  final List<GeneratedFile> generatedFiles;

  /// A token that can be sent as a page_token into a subsequent
  /// ListGeneratedFiles call.
  final String? nextPageToken;

  /// Creates a [ListGeneratedFilesResponse].
  const ListGeneratedFilesResponse({
    required this.generatedFiles,
    this.nextPageToken,
  });

  /// Creates a [ListGeneratedFilesResponse] from JSON.
  factory ListGeneratedFilesResponse.fromJson(Map<String, dynamic> json) =>
      ListGeneratedFilesResponse(
        generatedFiles:
            (json['generatedFiles'] as List<dynamic>?)
                ?.map((e) => GeneratedFile.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        nextPageToken: json['nextPageToken'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'generatedFiles': generatedFiles.map((e) => e.toJson()).toList(),
    if (nextPageToken != null) 'nextPageToken': nextPageToken,
  };

  /// Creates a copy with replaced values.
  ListGeneratedFilesResponse copyWith({
    Object? generatedFiles = unsetCopyWithValue,
    Object? nextPageToken = unsetCopyWithValue,
  }) {
    return ListGeneratedFilesResponse(
      generatedFiles: generatedFiles == unsetCopyWithValue
          ? this.generatedFiles
          : generatedFiles! as List<GeneratedFile>,
      nextPageToken: nextPageToken == unsetCopyWithValue
          ? this.nextPageToken
          : nextPageToken as String?,
    );
  }
}
