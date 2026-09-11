import '../copy_with_sentinel.dart';

/// A conversation turn in an interaction.
class Turn {
  /// The originator of this turn. Must be 'user' for input or 'model' for
  /// model output.
  final String? role;

  /// The content of the turn.
  ///
  /// Can be a [String] for simple text content, or a [List<dynamic>] for
  /// multimodal content (containing Content objects).
  final Object? content;

  /// Creates a [Turn] instance.
  const Turn({this.role, this.content});

  /// Creates a [Turn] with text content.
  const Turn.text({required this.role, required String text}) : content = text;

  /// Creates a [Turn] from JSON.
  factory Turn.fromJson(Map<String, dynamic> json) =>
      Turn(role: json['role'] as String?, content: json['content']);

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (role != null) 'role': role,
    if (content != null) 'content': content,
  };

  /// Creates a copy with replaced values.
  Turn copyWith({
    Object? role = unsetCopyWithValue,
    Object? content = unsetCopyWithValue,
  }) {
    return Turn(
      role: role == unsetCopyWithValue ? this.role : role as String?,
      content: content == unsetCopyWithValue ? this.content : content,
    );
  }
}
