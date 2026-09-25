part of 'tools.dart';

/// A tool that allows the model to call an MCP (Model Context Protocol) server.
class McpServerTool extends InteractionTool {
  @override
  String get type => 'mcp_server';

  /// The name of the MCP server.
  final String? name;

  /// The full URL for the MCP server endpoint.
  final String? url;

  /// Optional authentication headers.
  final Map<String, String>? headers;

  /// The allowed tools from this MCP server.
  final List<AllowedTools>? allowedTools;

  /// Creates a [McpServerTool] instance.
  const McpServerTool({this.name, this.url, this.headers, this.allowedTools});

  /// Creates a [McpServerTool] from JSON.
  factory McpServerTool.fromJson(Map<String, dynamic> json) => McpServerTool(
    name: json['name'] as String?,
    url: json['url'] as String?,
    headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
    allowedTools: (json['allowed_tools'] as List<dynamic>?)
        ?.map((e) => AllowedTools.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (name != null) 'name': name,
    if (url != null) 'url': url,
    if (headers != null) 'headers': headers,
    if (allowedTools != null)
      'allowed_tools': allowedTools!.map((e) => e.toJson()).toList(),
  };
}
