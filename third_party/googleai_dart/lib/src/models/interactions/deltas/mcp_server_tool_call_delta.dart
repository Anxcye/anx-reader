part of 'deltas.dart';

/// An MCP Server tool call delta update.
class McpServerToolCallDelta extends InteractionDelta {
  @override
  String get type => 'mcp_server_tool_call';

  /// A unique ID for this specific tool call.
  final String? id;

  /// The name of the tool.
  final String? name;

  /// The name of the MCP server.
  final String? serverName;

  /// The arguments for the tool call.
  final Map<String, dynamic>? arguments;

  /// Creates a [McpServerToolCallDelta] instance.
  const McpServerToolCallDelta({
    this.id,
    this.name,
    this.serverName,
    this.arguments,
  });

  /// Creates a [McpServerToolCallDelta] from JSON.
  factory McpServerToolCallDelta.fromJson(Map<String, dynamic> json) =>
      McpServerToolCallDelta(
        id: json['id'] as String?,
        name: json['name'] as String?,
        serverName: json['server_name'] as String?,
        arguments: json['arguments'] as Map<String, dynamic>?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (id != null) 'id': id,
    if (name != null) 'name': name,
    if (serverName != null) 'server_name': serverName,
    if (arguments != null) 'arguments': arguments,
  };
}
