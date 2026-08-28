import 'dart:convert';

class BookDeviceReadingPosition {
  const BookDeviceReadingPosition({
    required this.bookId,
    required this.deviceId,
    required this.cfi,
    required this.progress,
    this.chapterHref,
    this.chapterTitle,
    required this.updatedAt,
  });

  final int bookId;
  final String deviceId;
  final String cfi;
  final double progress;
  final String? chapterHref;
  final String? chapterTitle;
  final int updatedAt;

  Map<String, Object?> toDb() => {
        'book_id': bookId,
        'device_id': deviceId,
        'cfi': cfi,
        'progress': progress.clamp(0, 1),
        'chapter_href': chapterHref,
        'chapter_title': chapterTitle,
        'updated_at': updatedAt,
      };

  factory BookDeviceReadingPosition.fromDb(Map<String, dynamic> row) =>
      BookDeviceReadingPosition(
        bookId: _int(row['book_id']),
        deviceId: row['device_id']?.toString() ?? '',
        cfi: row['cfi']?.toString() ?? '',
        progress: _double(row['progress']).clamp(0, 1),
        chapterHref: row['chapter_href']?.toString(),
        chapterTitle: row['chapter_title']?.toString(),
        updatedAt: _int(row['updated_at']),
      );
}

class ReadingSyncTombstone {
  const ReadingSyncTombstone({
    required this.entityType,
    required this.entityId,
    required this.bookId,
    required this.deviceId,
    required this.deletedAt,
  });

  final String entityType;
  final String entityId;
  final int bookId;
  final String deviceId;
  final int deletedAt;

  Map<String, Object?> toDb() => {
        'entity_type': entityType,
        'entity_id': entityId,
        'book_id': bookId,
        'device_id': deviceId,
        'deleted_at': deletedAt,
      };
}

/// One device's independently replaceable state for one book. It contains the
/// current rows rather than a database snapshot, so a database download cannot
/// erase another device's Reading Agent branch.
class ReadingAgentBookDelta {
  const ReadingAgentBookDelta({
    required this.bookKey,
    required this.deviceId,
    required this.generatedAt,
    required this.rows,
    this.schemaVersion = 1,
  });

  static const type = 'anx-reading-agent-book-delta';

  final int schemaVersion;
  final String bookKey;
  final String deviceId;
  final int generatedAt;
  final Map<String, List<Map<String, dynamic>>> rows;

  Map<String, dynamic> toJson() => {
        'type': type,
        'schemaVersion': schemaVersion,
        'bookKey': bookKey,
        'deviceId': deviceId,
        'generatedAt': generatedAt,
        'rows': rows,
      };

  String encode() => jsonEncode(toJson());

  factory ReadingAgentBookDelta.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map || decoded['type'] != type) {
      throw const FormatException('Unsupported Reading Agent sync package');
    }
    final rawRows = decoded['rows'];
    if (rawRows is! Map) {
      throw const FormatException('Reading Agent sync package has no rows');
    }
    return ReadingAgentBookDelta(
      schemaVersion: _int(decoded['schemaVersion']),
      bookKey: decoded['bookKey']?.toString() ?? '',
      deviceId: decoded['deviceId']?.toString() ?? '',
      generatedAt: _int(decoded['generatedAt']),
      rows: rawRows.map<String, List<Map<String, dynamic>>>((key, value) {
        final list = value is List ? value : const [];
        return MapEntry(
          key.toString(),
          list
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList(growable: false),
        );
      }),
    );
  }
}

int _int(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

double _double(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
