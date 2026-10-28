/// Transcription of audio content.
///
/// Used for both input (user speech) and output (model speech) transcription.
class Transcription {
  /// The transcribed text.
  final String? text;

  /// Creates a [Transcription].
  const Transcription({this.text});

  /// Creates from JSON.
  factory Transcription.fromJson(Map<String, dynamic> json) {
    return Transcription(text: json['text'] as String?);
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {if (text != null) 'text': text};

  @override
  String toString() => 'Transcription(text: $text)';
}
