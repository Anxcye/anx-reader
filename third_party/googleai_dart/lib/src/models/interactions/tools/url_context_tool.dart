part of 'tools.dart';

/// A tool that allows the model to fetch URL context.
class UrlContextTool extends InteractionTool {
  @override
  String get type => 'url_context';

  /// Creates a [UrlContextTool] instance.
  const UrlContextTool();

  /// Creates a [UrlContextTool] from JSON.
  factory UrlContextTool.fromJson(Map<String, dynamic> _) =>
      const UrlContextTool();

  @override
  Map<String, dynamic> toJson() => {'type': type};
}
