part of 'tools.dart';

/// A tool that allows the model to search Google.
class GoogleSearchTool extends InteractionTool {
  @override
  String get type => 'google_search';

  /// Creates a [GoogleSearchTool] instance.
  const GoogleSearchTool();

  /// Creates a [GoogleSearchTool] from JSON.
  factory GoogleSearchTool.fromJson(Map<String, dynamic> _) =>
      const GoogleSearchTool();

  @override
  Map<String, dynamic> toJson() => {'type': type};
}
