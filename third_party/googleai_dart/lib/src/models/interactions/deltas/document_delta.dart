part of 'deltas.dart';

/// A document delta update.
class DocumentDelta extends InteractionDelta {
  @override
  String get type => 'document';

  /// Base64-encoded document data.
  final String? data;

  /// URI of the document.
  final String? uri;

  /// The MIME type of the document.
  final String? mimeType;

  /// Creates a [DocumentDelta] instance.
  const DocumentDelta({this.data, this.uri, this.mimeType});

  /// Creates a [DocumentDelta] from JSON.
  factory DocumentDelta.fromJson(Map<String, dynamic> json) => DocumentDelta(
    data: json['data'] as String?,
    uri: json['uri'] as String?,
    mimeType: json['mime_type'] as String?,
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (data != null) 'data': data,
    if (uri != null) 'uri': uri,
    if (mimeType != null) 'mime_type': mimeType,
  };
}
