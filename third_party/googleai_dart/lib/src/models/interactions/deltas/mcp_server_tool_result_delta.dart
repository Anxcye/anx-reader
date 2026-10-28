part of 'deltas.dart';

/// An MCP Server tool result delta update.
class McpServerToolResultDelta extends InteractionDelta {
  @override
  String get type => 'mcp_server_tool_result';

  /// The name of the tool.
  final String? name;

  /// The name of the MCP server.
  final String? serverName;

  /// The result of the tool call.
  final Object? result;

  /// Creates a [McpServerToolResultDelta] instance.
  const McpServerToolResultDelta({this.name, this.serverName, this.result});

  /// Creates a [McpServerToolResultDelta] from JSON.
  factory McpServerToolResultDelta.fromJson(Map<String, dynamic> json) =>
      McpServerToolResultDelta(
        name: json['name'] as String?,
        serverName: json['server_name'] as String?,
        result: json['result'],
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (name != null) 'name': name,
    if (serverName != null) 'server_name': serverName,
    if (result != null) 'result': result,
  };
}
