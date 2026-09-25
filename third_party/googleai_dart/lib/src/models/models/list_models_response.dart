import '../copy_with_sentinel.dart';
import 'model.dart';

/// Response from listing models.
class ListModelsResponse {
  /// The list of models.
  final List<Model> models;

  /// Token to retrieve the next page of results.
  final String? nextPageToken;

  /// Creates a [ListModelsResponse].
  const ListModelsResponse({required this.models, this.nextPageToken});

  /// Creates a [ListModelsResponse] from JSON.
  factory ListModelsResponse.fromJson(Map<String, dynamic> json) =>
      ListModelsResponse(
        models:
            (json['models'] as List<dynamic>?)
                ?.map((e) => Model.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        nextPageToken: json['nextPageToken'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'models': models.map((e) => e.toJson()).toList(),
    if (nextPageToken != null) 'nextPageToken': nextPageToken,
  };

  /// Creates a copy with replaced values.
  ListModelsResponse copyWith({
    Object? models = unsetCopyWithValue,
    Object? nextPageToken = unsetCopyWithValue,
  }) {
    return ListModelsResponse(
      models: models == unsetCopyWithValue
          ? this.models
          : models! as List<Model>,
      nextPageToken: nextPageToken == unsetCopyWithValue
          ? this.nextPageToken
          : nextPageToken as String?,
    );
  }
}
