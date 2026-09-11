part of 'deltas.dart';

/// A URL context call delta update.
class UrlContextCallDelta extends InteractionDelta {
  @override
  String get type => 'url_context_call';

  /// A unique ID for this specific tool call.
  final String? id;

  /// The URLs to fetch.
  final List<String>? urls;

  /// Creates a [UrlContextCallDelta] instance.
  const UrlContextCallDelta({this.id, this.urls});

  /// Creates a [UrlContextCallDelta] from JSON.
  factory UrlContextCallDelta.fromJson(Map<String, dynamic> json) {
    final arguments = json['arguments'] as Map<String, dynamic>?;
    return UrlContextCallDelta(
      id: json['id'] as String?,
      urls: (arguments?['urls'] as List<dynamic>?)?.cast<String>(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (id != null) 'id': id,
    if (urls != null) 'arguments': {'urls': urls},
  };
}
