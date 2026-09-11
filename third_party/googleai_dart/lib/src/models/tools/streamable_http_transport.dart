import '../copy_with_sentinel.dart';

/// A transport that can stream HTTP requests and responses.
class StreamableHttpTransport {
  /// The full URL for the MCPServer endpoint.
  ///
  /// Example: "https://api.example.com/mcp"
  final String? url;

  /// Optional: Fields for authentication headers, timeouts, etc., if needed.
  final Map<String, String>? headers;

  /// HTTP timeout for regular operations.
  final String? timeout;

  /// Timeout for SSE read operations.
  final String? sseReadTimeout;

  /// Whether to close the client session when the transport closes.
  final bool? terminateOnClose;

  /// Creates a [StreamableHttpTransport].
  const StreamableHttpTransport({
    this.url,
    this.headers,
    this.timeout,
    this.sseReadTimeout,
    this.terminateOnClose,
  });

  /// Creates a [StreamableHttpTransport] from JSON.
  factory StreamableHttpTransport.fromJson(Map<String, dynamic> json) =>
      StreamableHttpTransport(
        url: json['url'] as String?,
        headers: (json['headers'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v as String),
        ),
        timeout: json['timeout'] as String?,
        sseReadTimeout: json['sseReadTimeout'] as String?,
        terminateOnClose: json['terminateOnClose'] as bool?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (url != null) 'url': url,
    if (headers != null) 'headers': headers,
    if (timeout != null) 'timeout': timeout,
    if (sseReadTimeout != null) 'sseReadTimeout': sseReadTimeout,
    if (terminateOnClose != null) 'terminateOnClose': terminateOnClose,
  };

  /// Creates a copy with replaced values.
  StreamableHttpTransport copyWith({
    Object? url = unsetCopyWithValue,
    Object? headers = unsetCopyWithValue,
    Object? timeout = unsetCopyWithValue,
    Object? sseReadTimeout = unsetCopyWithValue,
    Object? terminateOnClose = unsetCopyWithValue,
  }) {
    return StreamableHttpTransport(
      url: url == unsetCopyWithValue ? this.url : url as String?,
      headers: headers == unsetCopyWithValue
          ? this.headers
          : headers as Map<String, String>?,
      timeout: timeout == unsetCopyWithValue
          ? this.timeout
          : timeout as String?,
      sseReadTimeout: sseReadTimeout == unsetCopyWithValue
          ? this.sseReadTimeout
          : sseReadTimeout as String?,
      terminateOnClose: terminateOnClose == unsetCopyWithValue
          ? this.terminateOnClose
          : terminateOnClose as bool?,
    );
  }

  @override
  String toString() =>
      'StreamableHttpTransport(url: $url, headers: $headers, timeout: $timeout, sseReadTimeout: $sseReadTimeout, terminateOnClose: $terminateOnClose)';
}
