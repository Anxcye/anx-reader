part of 'content.dart';

/// A document content block.
class DocumentContent extends InteractionContent {
  @override
  String get type => 'document';

  /// Base64-encoded document data.
  final String? data;

  /// URI of the document.
  final String? uri;

  /// The MIME type of the document.
  final String? mimeType;

  /// Creates a [DocumentContent] instance.
  const DocumentContent({this.data, this.uri, this.mimeType});

  /// Creates a [DocumentContent] from JSON.
  factory DocumentContent.fromJson(Map<String, dynamic> json) =>
      DocumentContent(
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

  /// Creates a copy with replaced values.
  DocumentContent copyWith({
    Object? data = unsetCopyWithValue,
    Object? uri = unsetCopyWithValue,
    Object? mimeType = unsetCopyWithValue,
  }) {
    return DocumentContent(
      data: data == unsetCopyWithValue ? this.data : data as String?,
      uri: uri == unsetCopyWithValue ? this.uri : uri as String?,
      mimeType: mimeType == unsetCopyWithValue
          ? this.mimeType
          : mimeType as String?,
    );
  }
}
