import '../copy_with_sentinel.dart';
import 'predict_long_running_generated_video_response.dart';

/// Response message for PredictLongRunning operation.
class PredictLongRunningResponse {
  /// The response of the video generation prediction.
  final PredictLongRunningGeneratedVideoResponse? generateVideoResponse;

  /// Creates a [PredictLongRunningResponse].
  const PredictLongRunningResponse({this.generateVideoResponse});

  /// Creates a [PredictLongRunningResponse] from JSON.
  factory PredictLongRunningResponse.fromJson(Map<String, dynamic> json) =>
      PredictLongRunningResponse(
        generateVideoResponse: json['generateVideoResponse'] != null
            ? PredictLongRunningGeneratedVideoResponse.fromJson(
                json['generateVideoResponse'] as Map<String, dynamic>,
              )
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (generateVideoResponse != null)
      'generateVideoResponse': generateVideoResponse!.toJson(),
  };

  /// Creates a copy with replaced values.
  PredictLongRunningResponse copyWith({
    Object? generateVideoResponse = unsetCopyWithValue,
  }) {
    return PredictLongRunningResponse(
      generateVideoResponse: generateVideoResponse == unsetCopyWithValue
          ? this.generateVideoResponse
          : generateVideoResponse as PredictLongRunningGeneratedVideoResponse?,
    );
  }
}
