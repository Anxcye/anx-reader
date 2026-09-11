import '../copy_with_sentinel.dart';
import 'tuned_model.dart';

/// Response from listing tuned models.
class ListTunedModelsResponse {
  /// The list of tuned models.
  final List<TunedModel> tunedModels;

  /// Token to retrieve the next page of results.
  final String? nextPageToken;

  /// Creates a [ListTunedModelsResponse].
  const ListTunedModelsResponse({
    required this.tunedModels,
    this.nextPageToken,
  });

  /// Creates a [ListTunedModelsResponse] from JSON.
  factory ListTunedModelsResponse.fromJson(Map<String, dynamic> json) =>
      ListTunedModelsResponse(
        tunedModels:
            (json['tunedModels'] as List<dynamic>?)
                ?.map((e) => TunedModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        nextPageToken: json['nextPageToken'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'tunedModels': tunedModels.map((e) => e.toJson()).toList(),
    if (nextPageToken != null) 'nextPageToken': nextPageToken,
  };

  /// Creates a copy with replaced values.
  ListTunedModelsResponse copyWith({
    Object? tunedModels = unsetCopyWithValue,
    Object? nextPageToken = unsetCopyWithValue,
  }) {
    return ListTunedModelsResponse(
      tunedModels: tunedModels == unsetCopyWithValue
          ? this.tunedModels
          : tunedModels! as List<TunedModel>,
      nextPageToken: nextPageToken == unsetCopyWithValue
          ? this.nextPageToken
          : nextPageToken as String?,
    );
  }
}
