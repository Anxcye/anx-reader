part of 'tools.dart';

/// A tool that allows the model to interact with the computer.
class ComputerUseTool extends InteractionTool {
  @override
  String get type => 'computer_use';

  /// The environment being operated.
  ///
  /// Currently only 'browser' is supported.
  final String? environment;

  /// The list of predefined functions that are excluded from the model call.
  final List<String>? excludedPredefinedFunctions;

  /// Creates a [ComputerUseTool] instance.
  const ComputerUseTool({this.environment, this.excludedPredefinedFunctions});

  /// Creates a [ComputerUseTool] from JSON.
  factory ComputerUseTool.fromJson(Map<String, dynamic> json) =>
      ComputerUseTool(
        environment: json['environment'] as String?,
        excludedPredefinedFunctions:
            (json['excludedPredefinedFunctions'] as List<dynamic>?)
                ?.cast<String>(),
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (environment != null) 'environment': environment,
    if (excludedPredefinedFunctions != null)
      'excludedPredefinedFunctions': excludedPredefinedFunctions,
  };
}
