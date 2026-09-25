import '../allowed_tools.dart';

part 'code_execution_tool.dart';
part 'computer_use_tool.dart';
part 'file_search_tool.dart';
part 'function_tool.dart';
part 'google_search_tool.dart';
part 'mcp_server_tool.dart';
part 'url_context_tool.dart';

/// A tool that can be used by the model.
///
/// This is a sealed class with subtypes for different tool types.
sealed class InteractionTool {
  /// The type discriminator for this tool.
  String get type;

  const InteractionTool();

  /// Creates an [InteractionTool] from JSON.
  factory InteractionTool.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'function' => FunctionTool.fromJson(json),
      'google_search' => GoogleSearchTool.fromJson(json),
      'code_execution' => CodeExecutionTool.fromJson(json),
      'url_context' => UrlContextTool.fromJson(json),
      'computer_use' => ComputerUseTool.fromJson(json),
      'mcp_server' => McpServerTool.fromJson(json),
      'file_search' => FileSearchTool.fromJson(json),
      _ => throw ArgumentError('Unknown tool type: $type'),
    };
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson();
}
