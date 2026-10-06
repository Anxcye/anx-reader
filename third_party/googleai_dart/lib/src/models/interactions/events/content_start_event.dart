part of 'events.dart';

/// An event indicating that content output has started.
class ContentStartEvent extends InteractionEvent {
  @override
  String get eventType => 'content.start';

  /// The index of this content in the outputs array.
  final int? index;

  /// The content that is starting (may be partial).
  final InteractionContent? content;

  /// Creates a [ContentStartEvent] instance.
  const ContentStartEvent({this.index, this.content, super.eventId});

  /// Creates a [ContentStartEvent] from JSON.
  factory ContentStartEvent.fromJson(Map<String, dynamic> json) =>
      ContentStartEvent(
        index: json['index'] as int?,
        content: json['content'] != null
            ? InteractionContent.fromJson(
                json['content'] as Map<String, dynamic>,
              )
            : null,
        eventId: json['event_id'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'event_type': eventType,
    if (index != null) 'index': index,
    if (content != null) 'content': content!.toJson(),
    if (eventId != null) 'event_id': eventId,
  };
}
