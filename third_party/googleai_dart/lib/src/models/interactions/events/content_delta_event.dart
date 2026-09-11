part of 'events.dart';

/// An event containing a delta update for content.
class ContentDeltaEvent extends InteractionEvent {
  @override
  String get eventType => 'content.delta';

  /// The index of this content in the outputs array.
  final int? index;

  /// The delta update for the content.
  final InteractionDelta? delta;

  /// Creates a [ContentDeltaEvent] instance.
  const ContentDeltaEvent({this.index, this.delta, super.eventId});

  /// Creates a [ContentDeltaEvent] from JSON.
  factory ContentDeltaEvent.fromJson(Map<String, dynamic> json) =>
      ContentDeltaEvent(
        index: json['index'] as int?,
        delta: json['delta'] != null
            ? InteractionDelta.fromJson(json['delta'] as Map<String, dynamic>)
            : null,
        eventId: json['event_id'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'event_type': eventType,
    if (index != null) 'index': index,
    if (delta != null) 'delta': delta!.toJson(),
    if (eventId != null) 'event_id': eventId,
  };
}
