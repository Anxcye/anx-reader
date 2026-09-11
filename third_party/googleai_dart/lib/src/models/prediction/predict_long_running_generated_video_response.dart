import '../copy_with_sentinel.dart';
import 'media.dart';

/// Veo response containing generated video samples.
class PredictLongRunningGeneratedVideoResponse {
  /// The generated samples.
  final List<Media>? generatedSamples;

  /// Returns if any videos were filtered due to RAI policies.
  final int? raiMediaFilteredCount;

  /// Returns RAI failure reasons if any.
  final List<String>? raiMediaFilteredReasons;

  /// Creates a [PredictLongRunningGeneratedVideoResponse].
  const PredictLongRunningGeneratedVideoResponse({
    this.generatedSamples,
    this.raiMediaFilteredCount,
    this.raiMediaFilteredReasons,
  });

  /// Creates a [PredictLongRunningGeneratedVideoResponse] from JSON.
  factory PredictLongRunningGeneratedVideoResponse.fromJson(
    Map<String, dynamic> json,
  ) => PredictLongRunningGeneratedVideoResponse(
    generatedSamples: (json['generatedSamples'] as List<dynamic>?)
        ?.map((e) => Media.fromJson(e as Map<String, dynamic>))
        .toList(),
    raiMediaFilteredCount: json['raiMediaFilteredCount'] as int?,
    raiMediaFilteredReasons: (json['raiMediaFilteredReasons'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (generatedSamples != null)
      'generatedSamples': generatedSamples!.map((e) => e.toJson()).toList(),
    if (raiMediaFilteredCount != null)
      'raiMediaFilteredCount': raiMediaFilteredCount,
    if (raiMediaFilteredReasons != null)
      'raiMediaFilteredReasons': raiMediaFilteredReasons,
  };

  /// Creates a copy with replaced values.
  PredictLongRunningGeneratedVideoResponse copyWith({
    Object? generatedSamples = unsetCopyWithValue,
    Object? raiMediaFilteredCount = unsetCopyWithValue,
    Object? raiMediaFilteredReasons = unsetCopyWithValue,
  }) {
    return PredictLongRunningGeneratedVideoResponse(
      generatedSamples: generatedSamples == unsetCopyWithValue
          ? this.generatedSamples
          : generatedSamples as List<Media>?,
      raiMediaFilteredCount: raiMediaFilteredCount == unsetCopyWithValue
          ? this.raiMediaFilteredCount
          : raiMediaFilteredCount as int?,
      raiMediaFilteredReasons: raiMediaFilteredReasons == unsetCopyWithValue
          ? this.raiMediaFilteredReasons
          : raiMediaFilteredReasons as List<String>?,
    );
  }
}
