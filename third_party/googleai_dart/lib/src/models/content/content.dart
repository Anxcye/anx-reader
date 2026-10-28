import '../copy_with_sentinel.dart';
import 'part.dart';

/// Represents a message in a conversation (user or model turn).
class Content {
  /// Producer of content: "user" or "model".
  final String? role;

  /// Multi-part message content.
  final List<Part> parts;

  /// Creates a [Content].
  const Content({required this.parts, this.role});

  /// Creates user-role content from parts.
  ///
  /// Example:
  /// ```dart
  /// final content = Content.user([TextPart('Hello!')]);
  /// ```
  const Content.user(List<Part> parts) : this(parts: parts, role: 'user');

  /// Creates model-role content from parts.
  ///
  /// Example:
  /// ```dart
  /// final content = Content.model([TextPart('Hi there!')]);
  /// ```
  const Content.model(List<Part> parts) : this(parts: parts, role: 'model');

  /// Creates user content from a simple text string.
  ///
  /// This is the most common pattern for simple text prompts.
  ///
  /// Example:
  /// ```dart
  /// final content = Content.text('Explain quantum computing');
  /// ```
  factory Content.text(String text) => Content.user([TextPart(text)]);

  /// Creates user content from multiple parts.
  ///
  /// Accepts strings (auto-wrapped to [TextPart]) or [Part] objects.
  ///
  /// Example:
  /// ```dart
  /// final content = Content.fromParts([
  ///   'Describe this image:',
  ///   Part.base64(imageData, 'image/png'),
  /// ]);
  /// ```
  factory Content.fromParts(List<Object> parts, {String role = 'user'}) {
    return Content(
      role: role,
      parts: parts.map((p) {
        if (p is String) return TextPart(p);
        if (p is Part) return p;
        throw ArgumentError('Expected String or Part, got ${p.runtimeType}');
      }).toList(),
    );
  }

  /// Creates a [Content] from JSON.
  factory Content.fromJson(Map<String, dynamic> json) => Content(
    role: json['role'] as String?,
    parts: ((json['parts'] as List?) ?? [])
        .map((e) => Part.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (role != null) 'role': role,
    'parts': parts.map((e) => e.toJson()).toList(),
  };

  /// Creates a copy with replaced values.
  Content copyWith({
    Object? role = unsetCopyWithValue,
    Object? parts = unsetCopyWithValue,
  }) {
    return Content(
      role: role == unsetCopyWithValue ? this.role : role as String?,
      parts: parts == unsetCopyWithValue ? this.parts : parts! as List<Part>,
    );
  }
}
