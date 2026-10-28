part of 'tools.dart';

/// A tool that allows the model to execute code.
class CodeExecutionTool extends InteractionTool {
  @override
  String get type => 'code_execution';

  /// Creates a [CodeExecutionTool] instance.
  const CodeExecutionTool();

  /// Creates a [CodeExecutionTool] from JSON.
  factory CodeExecutionTool.fromJson(Map<String, dynamic> _) =>
      const CodeExecutionTool();

  @override
  Map<String, dynamic> toJson() => {'type': type};
}
