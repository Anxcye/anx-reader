import '../content/content.dart';

part 'audio_delta.dart';
part 'code_execution_call_delta.dart';
part 'code_execution_result_delta.dart';
part 'document_delta.dart';
part 'file_search_result_delta.dart';
part 'function_call_delta.dart';
part 'function_result_delta.dart';
part 'google_search_call_delta.dart';
part 'google_search_result_delta.dart';
part 'image_delta.dart';
part 'mcp_server_tool_call_delta.dart';
part 'mcp_server_tool_result_delta.dart';
part 'text_delta.dart';
part 'thought_signature_delta.dart';
part 'thought_summary_delta.dart';
part 'url_context_call_delta.dart';
part 'url_context_result_delta.dart';
part 'video_delta.dart';

/// A delta update for interaction content.
///
/// This is a sealed class with subtypes for different content delta types.
sealed class InteractionDelta {
  /// The type discriminator for this delta.
  String get type;

  const InteractionDelta();

  /// Creates an [InteractionDelta] from JSON.
  factory InteractionDelta.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'text' => TextDelta.fromJson(json),
      'image' => ImageDelta.fromJson(json),
      'audio' => AudioDelta.fromJson(json),
      'document' => DocumentDelta.fromJson(json),
      'video' => VideoDelta.fromJson(json),
      'thought_summary' => ThoughtSummaryDelta.fromJson(json),
      'thought_signature' => ThoughtSignatureDelta.fromJson(json),
      'function_call' => FunctionCallDelta.fromJson(json),
      'function_result' => FunctionResultDelta.fromJson(json),
      'code_execution_call' => CodeExecutionCallDelta.fromJson(json),
      'code_execution_result' => CodeExecutionResultDelta.fromJson(json),
      'url_context_call' => UrlContextCallDelta.fromJson(json),
      'url_context_result' => UrlContextResultDelta.fromJson(json),
      'google_search_call' => GoogleSearchCallDelta.fromJson(json),
      'google_search_result' => GoogleSearchResultDelta.fromJson(json),
      'mcp_server_tool_call' => McpServerToolCallDelta.fromJson(json),
      'mcp_server_tool_result' => McpServerToolResultDelta.fromJson(json),
      'file_search_result' => FileSearchResultDelta.fromJson(json),
      _ => throw ArgumentError('Unknown delta type: $type'),
    };
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson();
}
