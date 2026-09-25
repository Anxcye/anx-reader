import 'dart:convert';

import '../copy_with_sentinel.dart';

/// Inline binary data (e.g., image, audio) encoded as base64.
class Blob {
  /// MIME type (e.g., image/jpeg, audio/mp3).
  final String mimeType;

  /// Base64-encoded binary data.
  final String data;

  /// Creates a [Blob].
  const Blob({required this.mimeType, required this.data});

  /// Creates a [Blob] from JSON.
  factory Blob.fromJson(Map<String, dynamic> json) =>
      Blob(mimeType: json['mimeType'] as String, data: json['data'] as String);

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {'mimeType': mimeType, 'data': data};

  /// Creates a [Blob] from bytes.
  factory Blob.fromBytes(String mimeType, List<int> bytes) =>
      Blob(mimeType: mimeType, data: base64Encode(bytes));

  /// Decodes to bytes.
  List<int> toBytes() => base64Decode(data);

  /// Creates a copy with replaced values.
  Blob copyWith({
    Object? mimeType = unsetCopyWithValue,
    Object? data = unsetCopyWithValue,
  }) {
    return Blob(
      mimeType: mimeType == unsetCopyWithValue
          ? this.mimeType
          : mimeType! as String,
      data: data == unsetCopyWithValue ? this.data : data! as String,
    );
  }
}
