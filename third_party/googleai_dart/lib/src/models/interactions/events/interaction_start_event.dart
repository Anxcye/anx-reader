part of 'events.dart';

/// An event indicating that an interaction has started.
class InteractionStartEvent extends InteractionEvent {
  @override
  String get eventType => 'interaction.start';

  /// The interaction that has started.
  final Interaction? interaction;

  /// Creates an [InteractionStartEvent] instance.
  const InteractionStartEvent({this.interaction, super.eventId});

  /// Creates an [InteractionStartEvent] from JSON.
  factory InteractionStartEvent.fromJson(Map<String, dynamic> json) =>
      InteractionStartEvent(
        interaction: json['interaction'] != null
            ? Interaction.fromJson(json['interaction'] as Map<String, dynamic>)
            : null,
        eventId: json['event_id'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'event_type': eventType,
    if (interaction != null) 'interaction': interaction!.toJson(),
    if (eventId != null) 'event_id': eventId,
  };
}
