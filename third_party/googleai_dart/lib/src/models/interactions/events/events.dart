import '../content/content.dart';
import '../deltas/deltas.dart';
import '../interaction.dart';
import '../interaction_status.dart';

part 'content_delta_event.dart';
part 'content_start_event.dart';
part 'content_stop_event.dart';
part 'error_event.dart';
part 'interaction_complete_event.dart';
part 'interaction_error.dart';
part 'interaction_start_event.dart';
part 'interaction_status_update_event.dart';

/// An event from the Interactions API streaming response.
///
/// This is a sealed class with subtypes for different event types.
sealed class InteractionEvent {
  /// The event type discriminator.
  String get eventType;

  /// The event ID token to resume the stream from this event.
  final String? eventId;

  const InteractionEvent({this.eventId});

  /// Creates an [InteractionEvent] from JSON.
  factory InteractionEvent.fromJson(Map<String, dynamic> json) {
    final eventType = json['event_type'] as String?;
    return switch (eventType) {
      'interaction.start' => InteractionStartEvent.fromJson(json),
      'interaction.complete' => InteractionCompleteEvent.fromJson(json),
      'interaction.status_update' => InteractionStatusUpdateEvent.fromJson(
        json,
      ),
      'content.start' => ContentStartEvent.fromJson(json),
      'content.delta' => ContentDeltaEvent.fromJson(json),
      'content.stop' => ContentStopEvent.fromJson(json),
      'error' => ErrorEvent.fromJson(json),
      _ => throw ArgumentError('Unknown event type: $eventType'),
    };
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson();
}
