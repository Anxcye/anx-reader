import '../copy_with_sentinel.dart';

/// Function calling mode.
enum FunctionCallingMode {
  /// Unspecified function calling mode. This value should not be used.
  unspecified,

  /// Default model behavior, model decides to predict either a function call
  /// or a natural language response.
  auto,

  /// Model is constrained to always predicting a function call only.
  /// If "allowed_function_names" are set, the predicted function call will be
  /// limited to any one of "allowed_function_names", else the predicted
  /// function call will be any one of the provided "function_declarations".
  any,

  /// Model will not predict any function call. Model behavior is same as when
  /// not passing any function declarations.
  none,

  /// Model decides to predict either a function call or a natural language
  /// response, but will validate function calls with constrained decoding.
  /// If "allowed_function_names" are set, the predicted function call will be
  /// limited to any one of "allowed_function_names", else the predicted
  /// function call will be any one of the provided "function_declarations".
  validated,
}

/// Converts a string to a [FunctionCallingMode].
FunctionCallingMode functionCallingModeFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'AUTO' => FunctionCallingMode.auto,
    'ANY' => FunctionCallingMode.any,
    'NONE' => FunctionCallingMode.none,
    'VALIDATED' => FunctionCallingMode.validated,
    _ => FunctionCallingMode.unspecified,
  };
}

/// Converts a [FunctionCallingMode] to a string.
String functionCallingModeToString(FunctionCallingMode mode) {
  return switch (mode) {
    FunctionCallingMode.auto => 'AUTO',
    FunctionCallingMode.any => 'ANY',
    FunctionCallingMode.none => 'NONE',
    FunctionCallingMode.validated => 'VALIDATED',
    FunctionCallingMode.unspecified => 'MODE_UNSPECIFIED',
  };
}

/// Configuration for specifying function calling behavior.
class FunctionCallingConfig {
  /// Specifies the mode in which function calling should execute.
  ///
  /// If unspecified, the default value will be set to AUTO.
  final FunctionCallingMode? mode;

  /// A set of function names that, when provided, limits the functions
  /// the model will call.
  ///
  /// This should only be set when the Mode is ANY or VALIDATED.
  /// Function names should match FunctionDeclaration.name.
  /// When set, model will predict a function call from only allowed function names.
  final List<String>? allowedFunctionNames;

  /// Creates a [FunctionCallingConfig].
  const FunctionCallingConfig({this.mode, this.allowedFunctionNames});

  /// Creates a [FunctionCallingConfig] from JSON.
  factory FunctionCallingConfig.fromJson(Map<String, dynamic> json) =>
      FunctionCallingConfig(
        mode: json['mode'] != null
            ? functionCallingModeFromString(json['mode'] as String)
            : null,
        allowedFunctionNames: (json['allowedFunctionNames'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (mode != null) 'mode': functionCallingModeToString(mode!),
    if (allowedFunctionNames != null)
      'allowedFunctionNames': allowedFunctionNames,
  };

  /// Creates a copy with replaced values.
  FunctionCallingConfig copyWith({
    Object? mode = unsetCopyWithValue,
    Object? allowedFunctionNames = unsetCopyWithValue,
  }) {
    return FunctionCallingConfig(
      mode: mode == unsetCopyWithValue
          ? this.mode
          : mode as FunctionCallingMode?,
      allowedFunctionNames: allowedFunctionNames == unsetCopyWithValue
          ? this.allowedFunctionNames
          : allowedFunctionNames as List<String>?,
    );
  }
}
