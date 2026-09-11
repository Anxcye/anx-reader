part of 'events.dart';

/// An event indicating that an error has occurred.
class ErrorEvent extends InteractionEvent {
  @override
  String get eventType => 'error';

  /// The error that occurred.
  final InteractionError? error;

  /// Creates an [ErrorEvent] instance.
  const ErrorEvent({this.error, super.eventId});

  /// Creates an [ErrorEvent] from JSON.
  factory ErrorEvent.fromJson(Map<String, dynamic> json) => ErrorEvent(
    error: json['error'] != null
        ? InteractionError.fromJson(json['error'] as Map<String, dynamic>)
        : null,
    eventId: json['event_id'] as String?,
  );

  @override
  Map<String, dynamic> toJson() => {
    'event_type': eventType,
    if (error != null) 'error': error!.toJson(),
    if (eventId != null) 'event_id': eventId,
  };
}
