class ReadingTime {
  int? id;
  int bookId;
  String? date;
  int readingTime;
  int round;

  ReadingTime({
    this.id,
    required this.bookId,
    this.date,
    required this.readingTime,
    this.round = 1,
  });

  /// Returns the stored date string as a [DateTime] if it can be parsed.
  ///
  /// Supports both legacy `YYYY-MM-DD` values and upcoming ISO8601
  /// timestamps with time components. When SQLite returns a value using a
  /// space separator (`YYYY-MM-DD HH:MM:SS`), we normalise it to
  /// `YYYY-MM-DDTHH:MM:SS` before parsing.
  DateTime? get startedAt {
    final raw = date;
    if (raw == null || raw.isEmpty) {
      return null;
    }

    DateTime? tryParse(String value) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    return tryParse(raw) ?? tryParse(raw.replaceFirst(' ', 'T'));
  }

  /// Extracts only the calendar day portion (YYYY-MM-DD) when available.
  String? get dateOnly {
    final parsed = startedAt;
    if (parsed != null) {
      return parsed.toIso8601String().substring(0, 10);
    }

    final raw = date;
    if (raw == null || raw.length < 10) {
      return null;
    }
    return raw.substring(0, 10);
  }

  Map<String, dynamic> toMap() {
    return {
      'book_id': bookId,
      'date': date,
      'reading_time': readingTime,
      'round': round,
    };
  }

  factory ReadingTime.fromDb(Map<String, dynamic> map) {
    return ReadingTime(
      id: map['id'] as int?,
      bookId: map['book_id'] as int,
      date: map['date'] as String?,
      readingTime: map['reading_time'] as int? ?? 0,
      round: map['round'] as int? ?? 1,
    );
  }
}
