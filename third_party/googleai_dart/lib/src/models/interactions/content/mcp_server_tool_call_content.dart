part of 'content.dart';

/// An MCP Server tool call content block.
class McpServerToolCallContent extends InteractionContent {
  @override
  String get type => 'mcp_server_tool_call';

  /// A unique ID for this specific tool call.
  final String id;

  /// The name of the tool which was called.
  final String name;

  /// The name of the used MCP server.
  final String serverName;

  /// The JSON object of arguments for the function.
  final Map<String, dynamic> arguments;

  /// Creates a [McpServerToolCallContent] instance.
  const McpServerToolCallContent({
    required this.id,
    required this.name,
    required this.serverName,
    required this.arguments,
  });

  /// Creates a [McpServerToolCallContent] from JSON.
  factory McpServerToolCallContent.fromJson(Map<String, dynamic> json) =>
      McpServerToolCallContent(
        id: json['id'] as String,
        name: json['name'] as String,
        serverName: json['server_name'] as String,
        arguments: json['arguments'] as Map<String, dynamic>,
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'name': name,
    'server_name': serverName,
    'arguments': arguments,
  };

  /// Creates a copy with replaced values.
  McpServerToolCallContent copyWith({
    Object? id = unsetCopyWithValue,
    Object? name = unsetCopyWithValue,
    Object? serverName = unsetCopyWithValue,
    Object? arguments = unsetCopyWithValue,
  }) {
    return McpServerToolCallContent(
      id: id == unsetCopyWithValue ? this.id : id! as String,
      name: name == unsetCopyWithValue ? this.name : name! as String,
      serverName: serverName == unsetCopyWithValue
          ? this.serverName
          : serverName! as String,
      arguments: arguments == unsetCopyWithValue
          ? this.arguments
          : arguments! as Map<String, dynamic>,
    );
  }
}
