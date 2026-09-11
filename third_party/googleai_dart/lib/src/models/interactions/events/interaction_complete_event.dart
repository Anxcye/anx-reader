part of 'events.dart';

/// An event indicating that an interaction has completed.
class InteractionCompleteEvent extends InteractionEvent {
  @override
  String get eventType => 'interaction.complete';

  /// The completed interaction.
  final Interaction? interaction;

  /// Creates an [InteractionCompleteEvent] instance.
  const InteractionCompleteEvent({this.interaction, super.eventId});

  /// Creates an [InteractionCompleteEvent] from JSON.
  factory InteractionCompleteEvent.fromJson(Map<String, dynamic> json) =>
      InteractionCompleteEvent(
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
