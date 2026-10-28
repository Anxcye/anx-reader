import '../batch/status.dart';
import '../copy_with_sentinel.dart';
import 'file_source.dart';
import 'file_state.dart';
import 'video_metadata.dart';

/// Represents an uploaded file.
class File {
  /// The resource name in format `files/{file}`.
  final String name;

  /// Display name for the file.
  final String? displayName;

  /// MIME type of the file.
  final String mimeType;

  /// Size of the file in bytes (stored as string to handle large files).
  final String? sizeBytes;

  /// Creation timestamp.
  final DateTime createTime;

  /// Last update timestamp.
  final DateTime updateTime;

  /// Expiration timestamp.
  final DateTime expirationTime;

  /// SHA256 hash of the file.
  final String? sha256Hash;

  /// URI for accessing the file.
  final String uri;

  /// Download URI for the file.
  final String? downloadUri;

  /// Current state of the file.
  final FileState state;

  /// Source of the file (uploaded, generated, or registered).
  final FileSource? source;

  /// Error status if file processing failed.
  final Status? error;

  /// Video metadata if the file is a video.
  final VideoMetadata? videoMetadata;

  /// Creates a [File].
  const File({
    required this.name,
    required this.mimeType,
    required this.createTime,
    required this.updateTime,
    required this.expirationTime,
    required this.uri,
    required this.state,
    this.sizeBytes,
    this.displayName,
    this.sha256Hash,
    this.downloadUri,
    this.source,
    this.error,
    this.videoMetadata,
  });

  /// Creates a [File] from JSON.
  factory File.fromJson(Map<String, dynamic> json) => File(
    name: json['name'] as String,
    displayName: json['displayName'] as String?,
    mimeType: json['mimeType'] as String,
    sizeBytes: json['sizeBytes'] as String?,
    createTime: DateTime.parse(json['createTime'] as String),
    updateTime: DateTime.parse(json['updateTime'] as String),
    expirationTime: DateTime.parse(json['expirationTime'] as String),
    sha256Hash: json['sha256Hash'] as String?,
    uri: json['uri'] as String,
    downloadUri: json['downloadUri'] as String?,
    state: fileStateFromString(json['state'] as String?),
    source: json['source'] != null
        ? fileSourceFromString(json['source'] as String?)
        : null,
    error: json['error'] != null
        ? Status.fromJson(json['error'] as Map<String, dynamic>)
        : null,
    videoMetadata: json['videoMetadata'] != null
        ? VideoMetadata.fromJson(json['videoMetadata'] as Map<String, dynamic>)
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'name': name,
    if (displayName != null) 'displayName': displayName,
    'mimeType': mimeType,
    if (sizeBytes != null) 'sizeBytes': sizeBytes,
    'createTime': createTime.toIso8601String(),
    'updateTime': updateTime.toIso8601String(),
    'expirationTime': expirationTime.toIso8601String(),
    if (sha256Hash != null) 'sha256Hash': sha256Hash,
    'uri': uri,
    if (downloadUri != null) 'downloadUri': downloadUri,
    'state': fileStateToString(state),
    if (source != null) 'source': fileSourceToString(source!),
    if (error != null) 'error': error!.toJson(),
    if (videoMetadata != null) 'videoMetadata': videoMetadata!.toJson(),
  };

  /// Creates a copy with replaced values.
  File copyWith({
    Object? name = unsetCopyWithValue,
    Object? displayName = unsetCopyWithValue,
    Object? mimeType = unsetCopyWithValue,
    Object? sizeBytes = unsetCopyWithValue,
    Object? createTime = unsetCopyWithValue,
    Object? updateTime = unsetCopyWithValue,
    Object? expirationTime = unsetCopyWithValue,
    Object? sha256Hash = unsetCopyWithValue,
    Object? uri = unsetCopyWithValue,
    Object? downloadUri = unsetCopyWithValue,
    Object? state = unsetCopyWithValue,
    Object? source = unsetCopyWithValue,
    Object? error = unsetCopyWithValue,
    Object? videoMetadata = unsetCopyWithValue,
  }) {
    return File(
      name: name == unsetCopyWithValue ? this.name : name! as String,
      displayName: displayName == unsetCopyWithValue
          ? this.displayName
          : displayName as String?,
      mimeType: mimeType == unsetCopyWithValue
          ? this.mimeType
          : mimeType! as String,
      sizeBytes: sizeBytes == unsetCopyWithValue
          ? this.sizeBytes
          : sizeBytes! as String,
      createTime: createTime == unsetCopyWithValue
          ? this.createTime
          : createTime! as DateTime,
      updateTime: updateTime == unsetCopyWithValue
          ? this.updateTime
          : updateTime! as DateTime,
      expirationTime: expirationTime == unsetCopyWithValue
          ? this.expirationTime
          : expirationTime! as DateTime,
      sha256Hash: sha256Hash == unsetCopyWithValue
          ? this.sha256Hash
          : sha256Hash as String?,
      uri: uri == unsetCopyWithValue ? this.uri : uri! as String,
      downloadUri: downloadUri == unsetCopyWithValue
          ? this.downloadUri
          : downloadUri as String?,
      state: state == unsetCopyWithValue ? this.state : state! as FileState,
      source: source == unsetCopyWithValue
          ? this.source
          : source as FileSource?,
      error: error == unsetCopyWithValue ? this.error : error as Status?,
      videoMetadata: videoMetadata == unsetCopyWithValue
          ? this.videoMetadata
          : videoMetadata as VideoMetadata?,
    );
  }
}
