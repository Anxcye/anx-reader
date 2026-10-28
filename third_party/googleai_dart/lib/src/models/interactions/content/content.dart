import '../../copy_with_sentinel.dart';

part 'annotation.dart';
part 'audio_content.dart';
part 'code_execution_call_content.dart';
part 'code_execution_result_content.dart';
part 'document_content.dart';
part 'file_search_result_content.dart';
part 'function_call_content.dart';
part 'function_result_content.dart';
part 'google_search_call_content.dart';
part 'google_search_result_content.dart';
part 'image_content.dart';
part 'mcp_server_tool_call_content.dart';
part 'mcp_server_tool_result_content.dart';
part 'text_content.dart';
part 'thought_content.dart';
part 'url_context_call_content.dart';
part 'url_context_result_content.dart';
part 'video_content.dart';

/// The content of an interaction response.
///
/// This is a sealed class with 17 subtypes representing different content
/// types in the Interactions API.
sealed class InteractionContent {
  /// The type discriminator for this content.
  String get type;

  const InteractionContent();

  /// Creates an [InteractionContent] from JSON.
  factory InteractionContent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'text' => TextContent.fromJson(json),
      'image' => ImageContent.fromJson(json),
      'audio' => AudioContent.fromJson(json),
      'document' => DocumentContent.fromJson(json),
      'video' => VideoContent.fromJson(json),
      'thought' => ThoughtContent.fromJson(json),
      'function_call' => FunctionCallContent.fromJson(json),
      'function_result' => FunctionResultContent.fromJson(json),
      'code_execution_call' => CodeExecutionCallContent.fromJson(json),
      'code_execution_result' => CodeExecutionResultContent.fromJson(json),
      'url_context_call' => UrlContextCallContent.fromJson(json),
      'url_context_result' => UrlContextResultContent.fromJson(json),
      'google_search_call' => GoogleSearchCallContent.fromJson(json),
      'google_search_result' => GoogleSearchResultContent.fromJson(json),
      'mcp_server_tool_call' => McpServerToolCallContent.fromJson(json),
      'mcp_server_tool_result' => McpServerToolResultContent.fromJson(json),
      'file_search_result' => FileSearchResultContent.fromJson(json),
      _ => throw ArgumentError('Unknown content type: $type'),
    };
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson();
}
