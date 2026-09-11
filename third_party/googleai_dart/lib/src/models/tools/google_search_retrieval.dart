import '../copy_with_sentinel.dart';
import 'dynamic_retrieval_config.dart';

/// Tool to retrieve public web data for grounding, powered by Google.
class GoogleSearchRetrieval {
  /// Specifies the dynamic retrieval configuration for the given source.
  final DynamicRetrievalConfig? dynamicRetrievalConfig;

  /// Creates a [GoogleSearchRetrieval].
  const GoogleSearchRetrieval({this.dynamicRetrievalConfig});

  /// Creates a [GoogleSearchRetrieval] from JSON.
  factory GoogleSearchRetrieval.fromJson(Map<String, dynamic> json) =>
      GoogleSearchRetrieval(
        dynamicRetrievalConfig: json['dynamicRetrievalConfig'] != null
            ? DynamicRetrievalConfig.fromJson(
                json['dynamicRetrievalConfig'] as Map<String, dynamic>,
              )
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (dynamicRetrievalConfig != null)
      'dynamicRetrievalConfig': dynamicRetrievalConfig!.toJson(),
  };

  /// Creates a copy with replaced values.
  GoogleSearchRetrieval copyWith({
    Object? dynamicRetrievalConfig = unsetCopyWithValue,
  }) {
    return GoogleSearchRetrieval(
      dynamicRetrievalConfig: dynamicRetrievalConfig == unsetCopyWithValue
          ? this.dynamicRetrievalConfig
          : dynamicRetrievalConfig as DynamicRetrievalConfig?,
    );
  }

  @override
  String toString() =>
      'GoogleSearchRetrieval(dynamicRetrievalConfig: $dynamicRetrievalConfig)';
}
