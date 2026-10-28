part of 'events.dart';

/// An event indicating that content output has stopped.
class ContentStopEvent extends InteractionEvent {
  @override
  String get eventType => 'content.stop';

  /// The index of this content in the outputs array.
  final int? index;

  /// Creates a [ContentStopEvent] instance.
  const ContentStopEvent({this.index, super.eventId});

  /// Creates a [ContentStopEvent] from JSON.
  factory ContentStopEvent.fromJson(Map<String, dynamic> json) =>
      ContentStopEvent(
        index: json['index'] as int?,
        eventId: json['event_id'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'event_type': eventType,
    if (index != null) 'index': index,
    if (eventId != null) 'event_id': eventId,
  };
}
