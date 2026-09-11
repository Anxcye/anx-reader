part of 'deltas.dart';

/// A Google Search call delta update.
class GoogleSearchCallDelta extends InteractionDelta {
  @override
  String get type => 'google_search_call';

  /// A unique ID for this specific tool call.
  final String? id;

  /// Web search queries.
  final List<String>? queries;

  /// Creates a [GoogleSearchCallDelta] instance.
  const GoogleSearchCallDelta({this.id, this.queries});

  /// Creates a [GoogleSearchCallDelta] from JSON.
  factory GoogleSearchCallDelta.fromJson(Map<String, dynamic> json) {
    final arguments = json['arguments'] as Map<String, dynamic>?;
    return GoogleSearchCallDelta(
      id: json['id'] as String?,
      queries: (arguments?['queries'] as List<dynamic>?)?.cast<String>(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (id != null) 'id': id,
    if (queries != null) 'arguments': {'queries': queries},
  };
}
