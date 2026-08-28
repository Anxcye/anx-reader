import 'package:anx_reader/dao/base_dao.dart';
import 'package:anx_reader/models/reading_agent_sync.dart';
import 'package:sqflite/sqflite.dart';

class ReadingAgentSyncDao extends BaseDao {
  ReadingAgentSyncDao({super.databaseProvider});

  Future<void> savePosition(BookDeviceReadingPosition position) => insert(
        'tb_book_device_positions',
        position.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<BookDeviceReadingPosition?> position(int bookId, String deviceId) =>
      querySingle(
        'tb_book_device_positions',
        mapper: BookDeviceReadingPosition.fromDb,
        where: 'book_id = ? AND device_id = ?',
        whereArgs: [bookId, deviceId],
      );

  Future<List<BookDeviceReadingPosition>> positions(int bookId) => queryList(
        'tb_book_device_positions',
        mapper: BookDeviceReadingPosition.fromDb,
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'updated_at DESC',
      );

  Future<double> globalFarthestProgress(int bookId) async {
    final row = await rawQuerySingle(
      'SELECT MAX(progress) AS progress FROM tb_book_device_positions WHERE book_id = ?',
      arguments: [bookId],
      mapper: (value) => value,
    );
    return ((row?['progress'] as num?)?.toDouble() ?? 0).clamp(0, 1);
  }

  /// Returns the furthest position recorded by another installation. A
  /// position is only a candidate for navigation when it also has a CFI; a
  /// progress number alone cannot safely restore a reader location.
  Future<BookDeviceReadingPosition?> farthestOtherPosition(
    int bookId,
    String deviceId,
  ) async {
    final positions = await queryList(
      'tb_book_device_positions',
      mapper: BookDeviceReadingPosition.fromDb,
      where: 'book_id = ? AND device_id != ? AND TRIM(cfi) != ?',
      whereArgs: [bookId, deviceId, ''],
      orderBy: 'progress DESC, updated_at DESC',
    );
    return positions.isEmpty ? null : positions.first;
  }
}

final readingAgentSyncDao = ReadingAgentSyncDao();
