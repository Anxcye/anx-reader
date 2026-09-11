import '../copy_with_sentinel.dart';
import 'streamable_http_transport.dart';

/// A MCPServer is a server that can be called by the model to perform actions.
///
/// It is a server that implements the MCP protocol.
class McpServer {
  /// The name of the MCPServer.
  final String? name;

  /// A transport that can stream HTTP requests and responses.
  final StreamableHttpTransport? streamableHttpTransport;

  /// Creates a [McpServer].
  const McpServer({this.name, this.streamableHttpTransport});

  /// Creates a [McpServer] from JSON.
  factory McpServer.fromJson(Map<String, dynamic> json) => McpServer(
    name: json['name'] as String?,
    streamableHttpTransport: json['streamableHttpTransport'] != null
        ? StreamableHttpTransport.fromJson(
            json['streamableHttpTransport'] as Map<String, dynamic>,
          )
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (streamableHttpTransport != null)
      'streamableHttpTransport': streamableHttpTransport!.toJson(),
  };

  /// Creates a copy with replaced values.
  McpServer copyWith({
    Object? name = unsetCopyWithValue,
    Object? streamableHttpTransport = unsetCopyWithValue,
  }) {
    return McpServer(
      name: name == unsetCopyWithValue ? this.name : name as String?,
      streamableHttpTransport: streamableHttpTransport == unsetCopyWithValue
          ? this.streamableHttpTransport
          : streamableHttpTransport as StreamableHttpTransport?,
    );
  }

  @override
  String toString() =>
      'McpServer(name: $name, streamableHttpTransport: $streamableHttpTransport)';
}
