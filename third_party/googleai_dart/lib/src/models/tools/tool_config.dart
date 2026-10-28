import '../copy_with_sentinel.dart';
import '../metadata/retrieval_config.dart';
import 'function_calling_config.dart';

/// The Tool configuration containing parameters for specifying Tool use
/// in the request.
class ToolConfig {
  /// Function calling config.
  final FunctionCallingConfig? functionCallingConfig;

  /// Retrieval config for tools like Google Search or FileSearch.
  final RetrievalConfig? retrievalConfig;

  /// Creates a [ToolConfig].
  const ToolConfig({this.functionCallingConfig, this.retrievalConfig});

  /// Creates a [ToolConfig] from JSON.
  factory ToolConfig.fromJson(Map<String, dynamic> json) => ToolConfig(
    functionCallingConfig: json['functionCallingConfig'] != null
        ? FunctionCallingConfig.fromJson(
            json['functionCallingConfig'] as Map<String, dynamic>,
          )
        : null,
    retrievalConfig: json['retrievalConfig'] != null
        ? RetrievalConfig.fromJson(
            json['retrievalConfig'] as Map<String, dynamic>,
          )
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (functionCallingConfig != null)
      'functionCallingConfig': functionCallingConfig!.toJson(),
    if (retrievalConfig != null) 'retrievalConfig': retrievalConfig!.toJson(),
  };

  /// Creates a copy with replaced values.
  ToolConfig copyWith({
    Object? functionCallingConfig = unsetCopyWithValue,
    Object? retrievalConfig = unsetCopyWithValue,
  }) {
    return ToolConfig(
      functionCallingConfig: functionCallingConfig == unsetCopyWithValue
          ? this.functionCallingConfig
          : functionCallingConfig as FunctionCallingConfig?,
      retrievalConfig: retrievalConfig == unsetCopyWithValue
          ? this.retrievalConfig
          : retrievalConfig as RetrievalConfig?,
    );
  }
}
