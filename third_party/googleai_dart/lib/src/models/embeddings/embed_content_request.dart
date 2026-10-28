import '../content/content.dart';
import '../copy_with_sentinel.dart';
import 'task_type.dart';

/// Request to embed content.
class EmbedContentRequest {
  /// The content to embed.
  final Content content;

  /// Optional task type hint.
  final TaskType? taskType;

  /// Optional title (only valid with taskType RETRIEVAL_DOCUMENT).
  final String? title;

  /// Optional reduced dimension for the output embedding.
  ///
  /// If set, excessive values in the output embedding are truncated from the end.
  /// Supported by newer models since 2024 only. You cannot set this value if
  /// using the earlier model (models/gemini-embedding-001).
  final int? outputDimensionality;

  /// Creates an [EmbedContentRequest].
  const EmbedContentRequest({
    required this.content,
    this.taskType,
    this.title,
    this.outputDimensionality,
  });

  /// Creates an [EmbedContentRequest] from JSON.
  factory EmbedContentRequest.fromJson(Map<String, dynamic> json) =>
      EmbedContentRequest(
        content: Content.fromJson(json['content'] as Map<String, dynamic>),
        taskType: json['taskType'] != null
            ? taskTypeFromString(json['taskType'] as String?)
            : null,
        title: json['title'] as String?,
        outputDimensionality: json['outputDimensionality'] as int?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'content': content.toJson(),
    if (taskType != null) 'taskType': taskTypeToString(taskType!),
    if (title != null) 'title': title,
    if (outputDimensionality != null)
      'outputDimensionality': outputDimensionality,
  };

  /// Creates a copy with replaced values.
  EmbedContentRequest copyWith({
    Object? content = unsetCopyWithValue,
    Object? taskType = unsetCopyWithValue,
    Object? title = unsetCopyWithValue,
    Object? outputDimensionality = unsetCopyWithValue,
  }) {
    return EmbedContentRequest(
      content: content == unsetCopyWithValue
          ? this.content
          : content! as Content,
      taskType: taskType == unsetCopyWithValue
          ? this.taskType
          : taskType as TaskType?,
      title: title == unsetCopyWithValue ? this.title : title as String?,
      outputDimensionality: outputDimensionality == unsetCopyWithValue
          ? this.outputDimensionality
          : outputDimensionality as int?,
    );
  }
}
