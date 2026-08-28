import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/models/reading_agent_sync.dart';
import 'package:anx_reader/service/sync/reading_agent_sync_transport.dart';
import 'package:anx_reader/service/sync/sync_client_base.dart';
import 'package:sqflite/sqflite.dart';

/// Merges Reading Agent records independently of the legacy whole-database
/// sync. Every device writes a separate file, so concurrent readers never
/// overwrite another device's branch.
class ReadingAgentSyncService {
  ReadingAgentSyncService({required this.deviceId});

  final String deviceId;

  static const _bookTables = <String>[
    'tb_book_device_positions',
    'tb_book_reading_profiles',
    'tb_book_reading_coverage',
    'tb_reading_goals',
    'tb_reading_checkpoints',
    'tb_reading_mastery',
    'tb_knowledge_cards',
    'tb_reading_memory_documents',
    'tb_reading_artifacts',
    'tb_reading_difficulties',
    'tb_book_wikis',
    'tb_book_wiki_entries',
    'tb_book_wiki_entry_sources',
    'tb_book_wiki_revisions',
    'tb_reading_sync_tombstones',
  ];

  static const _idColumns = <String, String>{
    'tb_book_wikis': 'book_id',
    'tb_reading_goals': 'id',
    'tb_reading_checkpoints': 'id',
    'tb_reading_mastery': 'id',
    'tb_knowledge_cards': 'id',
    'tb_reading_memory_documents': 'id',
    'tb_reading_artifacts': 'id',
    'tb_reading_difficulties': 'id',
    'tb_book_wiki_entries': 'id',
    'tb_book_wiki_entry_sources': 'id',
    'tb_book_wiki_revisions': 'id',
  };

  static const _entityTables = <String, String>{
    'goal': 'tb_reading_goals',
    'checkpoint': 'tb_reading_checkpoints',
    'mastery': 'tb_reading_mastery',
    'knowledgeCard': 'tb_knowledge_cards',
    'memory': 'tb_reading_memory_documents',
    'artifact': 'tb_reading_artifacts',
    'difficulty': 'tb_reading_difficulties',
    'wikiEntry': 'tb_book_wiki_entries',
    'wikiSource': 'tb_book_wiki_entry_sources',
    'wikiRevision': 'tb_book_wiki_revisions',
  };

  Future<List<ReadingAgentBookDelta>> capture({Database? database}) async {
    final db = database ?? await DBHelper().database;
    final books = await db.query(
      'tb_books',
      columns: ['id', 'file_md5'],
      where: 'is_deleted = 0',
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    final packages = <ReadingAgentBookDelta>[];
    for (final book in books) {
      final bookId = _asInt(book['id']);
      final rows = <String, List<Map<String, dynamic>>>{};
      for (final table in _bookTables) {
        rows[table] = await db.query(
          table,
          where: 'book_id = ?',
          whereArgs: [bookId],
        );
      }
      packages.add(ReadingAgentBookDelta(
        bookKey: bookKey(bookId, book['file_md5']?.toString()),
        deviceId: deviceId,
        generatedAt: now,
        rows: rows,
      ));
    }
    return packages;
  }

  /// Combines packages with the current database. Invalid or unknown books are
  /// ignored. The returned position belongs to this installation only; the
  /// global farthest position remains a derived value.
  Future<Map<int, BookDeviceReadingPosition>> merge(
    Iterable<ReadingAgentBookDelta> packages, {
    Database? database,
  }) async {
    final db = database ?? await DBHelper().database;
    final localBooks = await db.query('tb_books', columns: ['id', 'file_md5']);
    final byKey = <String, int>{};
    for (final book in localBooks) {
      final id = _asInt(book['id']);
      byKey[bookKey(id, book['file_md5']?.toString())] = id;
      byKey['id-$id'] = id;
    }

    await db.transaction((txn) async {
      for (final package in packages) {
        if (package.schemaVersion != 1 || package.bookKey.isEmpty) continue;
        final bookId = byKey[package.bookKey];
        if (bookId == null) continue;
        await _mergePackage(txn, bookId, package);
      }
      await _resolveActiveGoals(txn);
      await _advanceCoverageToGlobalFarthest(txn);
    });

    final result = <int, BookDeviceReadingPosition>{};
    for (final bookId in byKey.values.toSet()) {
      final rows = await db.query(
        'tb_book_device_positions',
        where: 'book_id = ? AND device_id = ?',
        whereArgs: [bookId, deviceId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        result[bookId] = BookDeviceReadingPosition.fromDb(rows.first);
      }
    }
    return result;
  }

  Future<void> _mergePackage(
    Transaction txn,
    int bookId,
    ReadingAgentBookDelta package,
  ) async {
    final tombstones = package.rows['tb_reading_sync_tombstones'] ?? const [];
    for (final raw in tombstones) {
      final row = _withBookId(raw, bookId);
      await txn.insert('tb_reading_sync_tombstones', row,
          conflictAlgorithm: ConflictAlgorithm.replace);
      final table = _entityTables[row['entity_type']];
      if (table != null) {
        final existing = await txn.query(table,
            columns: ['updated_at'],
            where: 'id = ? AND book_id = ?',
            whereArgs: [row['entity_id'], bookId],
            limit: 1);
        if (existing.isNotEmpty &&
            _asInt(existing.first['updated_at']) <= _asInt(row['deleted_at'])) {
          await txn.delete(table,
              where: 'id = ? AND book_id = ?',
              whereArgs: [row['entity_id'], bookId]);
        }
      }
    }

    for (final entry in package.rows.entries) {
      final table = entry.key;
      if (!_bookTables.contains(table) ||
          table == 'tb_reading_sync_tombstones') {
        continue;
      }
      for (final raw in entry.value) {
        final row = _withBookId(raw, bookId);
        if (await _deletedAfter(txn, table, row, bookId)) continue;
        if (table == 'tb_book_device_positions') {
          await _mergePosition(txn, row);
        } else if (table == 'tb_book_reading_coverage') {
          await _mergeCoverage(txn, row);
        } else if (table == 'tb_book_reading_profiles') {
          await _mergeBookProfile(txn, row);
        } else if (table == 'tb_reading_artifacts') {
          await _mergeArtifact(txn, row);
        } else if (table == 'tb_reading_goals') {
          await _mergeGoal(txn, row);
        } else if (table == 'tb_reading_checkpoints') {
          await _mergeCheckpoint(txn, row);
        } else if (table == 'tb_book_wiki_entries') {
          await _mergeWikiEntry(txn, row);
        } else if (table == 'tb_book_wiki_entry_sources' ||
            table == 'tb_book_wiki_revisions') {
          await txn.insert(table, row,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        } else {
          await _mergeLww(txn, table, row);
        }
      }
    }
  }

  Future<bool> _deletedAfter(Transaction txn, String table,
      Map<String, dynamic> row, int bookId) async {
    final idColumn = _idColumns[table];
    if (idColumn == null) return false;
    final entityType = _entityTables.entries
        .where((entry) => entry.value == table)
        .map((entry) => entry.key)
        .firstOrNull;
    if (entityType == null) return false;
    final deleted = await txn.rawQuery(
      'SELECT MAX(deleted_at) AS deleted_at FROM tb_reading_sync_tombstones '
      'WHERE entity_type = ? AND entity_id = ? AND book_id = ?',
      [entityType, row[idColumn], bookId],
    );
    return _asInt(deleted.first['deleted_at']) >= _asInt(row['updated_at']);
  }

  Future<void> _mergePosition(
      Transaction txn, Map<String, dynamic> incoming) async {
    final existing = await txn.query('tb_book_device_positions',
        where: 'book_id = ? AND device_id = ?',
        whereArgs: [incoming['book_id'], incoming['device_id']],
        limit: 1);
    if (existing.isEmpty ||
        _asInt(incoming['updated_at']) > _asInt(existing.first['updated_at'])) {
      await txn.insert('tb_book_device_positions', incoming,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _mergeCoverage(
      Transaction txn, Map<String, dynamic> incoming) async {
    final rows = await txn.query('tb_book_reading_coverage',
        where: 'book_id = ?', whereArgs: [incoming['book_id']], limit: 1);
    if (rows.isEmpty) {
      await txn.insert('tb_book_reading_coverage', incoming);
      return;
    }
    final current = rows.first;
    final start = [
      _asDouble(current['artifact_coverage_start']),
      _asDouble(incoming['artifact_coverage_start'])
    ]
        .where((value) => value > 0)
        .fold<double>(0, (min, value) => min == 0 || value < min ? value : min);
    final status = _coverageRank(incoming['setup_status']) >
            _coverageRank(current['setup_status'])
        ? incoming['setup_status']
        : current['setup_status'];
    await txn.update(
      'tb_book_reading_coverage',
      {
        ...Map<String, Object?>.from(current),
        'safe_knowledge_boundary': _maxDouble(
            current['safe_knowledge_boundary'],
            incoming['safe_knowledge_boundary']),
        'artifact_coverage_start': start,
        'artifact_coverage_end': _maxDouble(current['artifact_coverage_end'],
            incoming['artifact_coverage_end']),
        'setup_status': status,
        'initialized_at_progress': _minDouble(
            current['initialized_at_progress'],
            incoming['initialized_at_progress']),
        'updated_at': _maxInt(current['updated_at'], incoming['updated_at']),
      },
      where: 'book_id = ?',
      whereArgs: [incoming['book_id']],
    );
  }

  Future<void> _mergeBookProfile(
      Transaction txn, Map<String, dynamic> incoming) async {
    final rows = await txn.query('tb_book_reading_profiles',
        where: 'book_id = ?', whereArgs: [incoming['book_id']], limit: 1);
    if (rows.isEmpty) {
      await txn.insert('tb_book_reading_profiles', incoming);
      return;
    }
    final current = rows.first;
    final incomingPinned = _asInt(incoming['pinned']) == 1;
    final currentPinned = _asInt(current['pinned']) == 1;
    if ((incomingPinned && !currentPinned) ||
        (incomingPinned == currentPinned &&
            _asInt(incoming['updated_at']) > _asInt(current['updated_at']))) {
      await txn.insert('tb_book_reading_profiles', incoming,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _mergeArtifact(
      Transaction txn, Map<String, dynamic> incoming) async {
    final rows = await txn.query('tb_reading_artifacts',
        where: 'id = ?', whereArgs: [incoming['id']], limit: 1);
    if (rows.isEmpty) {
      incoming['ingestion_mode'] = incoming['ingestion_mode'] ?? 'synced';
      await txn.insert('tb_reading_artifacts', incoming);
      return;
    }
    final current = rows.first;
    final incomingAt = _asInt(incoming['updated_at']);
    final currentAt = _asInt(current['updated_at']);
    if (incomingAt > currentAt) {
      incoming['visible_from_progress'] = _maxDouble(
          current['visible_from_progress'], incoming['visible_from_progress']);
      await txn.insert('tb_reading_artifacts', incoming,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else if (incomingAt == currentAt) {
      final merged = Map<String, Object?>.from(current);
      merged['visible_from_progress'] = _maxDouble(
          current['visible_from_progress'], incoming['visible_from_progress']);
      if (_artifactStatusRank(incoming['status']) >
          _artifactStatusRank(current['status'])) {
        merged['status'] = incoming['status'];
      }
      await txn.insert('tb_reading_artifacts', merged,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _mergeGoal(
      Transaction txn, Map<String, dynamic> incoming) async {
    final rows = await txn.query('tb_reading_goals',
        where: 'id = ?', whereArgs: [incoming['id']], limit: 1);
    if (rows.isNotEmpty) {
      final current = rows.first;
      final currentAt = _asInt(current['updated_at']);
      final incomingAt = _asInt(incoming['updated_at']);
      if (currentAt > incomingAt ||
          (currentAt == incomingAt &&
              _goalStatusRank(current['status']) >=
                  _goalStatusRank(incoming['status']))) {
        return;
      }
    }
    if (incoming['status'] == 'active') {
      final active = await txn.query('tb_reading_goals',
          where: "book_id = ? AND status = 'active' AND id != ?",
          whereArgs: [incoming['book_id'], incoming['id']],
          orderBy: 'updated_at DESC',
          limit: 1);
      if (active.isNotEmpty &&
          _asInt(active.first['updated_at']) > _asInt(incoming['updated_at'])) {
        incoming['status'] = 'abandoned';
      } else {
        await txn.update('tb_reading_goals',
            {'status': 'abandoned', 'updated_at': incoming['updated_at']},
            where: "book_id = ? AND status = 'active' AND id != ?",
            whereArgs: [incoming['book_id'], incoming['id']]);
      }
    }
    await txn.insert('tb_reading_goals', incoming,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _mergeCheckpoint(
      Transaction txn, Map<String, dynamic> incoming) async {
    final rows = await txn.query('tb_reading_checkpoints',
        where: 'id = ? OR (book_id = ? AND chapter_href = ?)',
        whereArgs: [
          incoming['id'],
          incoming['book_id'],
          incoming['chapter_href']
        ],
        orderBy: 'updated_at DESC',
        limit: 1);
    if (rows.isEmpty) {
      await txn.insert('tb_reading_checkpoints', incoming);
      return;
    }
    final current = rows.first;
    final newer =
        _asInt(incoming['updated_at']) > _asInt(current['updated_at']);
    final sameTimeMoreComplete =
        _asInt(incoming['updated_at']) == _asInt(current['updated_at']) &&
            _checkpointRank(incoming['status']) >
                _checkpointRank(current['status']);
    if (newer || sameTimeMoreComplete) {
      incoming['id'] = current['id'];
      await txn.insert('tb_reading_checkpoints', incoming,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _mergeLww(
      Transaction txn, String table, Map<String, dynamic> incoming) async {
    final idColumn = _idColumns[table]!;
    final rows = await txn.query(table,
        where: '$idColumn = ?', whereArgs: [incoming[idColumn]], limit: 1);
    if (rows.isEmpty ||
        _asInt(incoming['updated_at']) > _asInt(rows.first['updated_at'])) {
      await txn.insert(table, incoming,
          conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }
    if (rows.isNotEmpty &&
        _asInt(incoming['updated_at']) == _asInt(rows.first['updated_at'])) {
      final current = rows.first;
      final statusColumn = table == 'tb_reading_mastery' ? 'level' : 'status';
      if (_terminalStatusRank(incoming[statusColumn]) >
          _terminalStatusRank(current[statusColumn])) {
        await txn.insert(table, incoming,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Future<void> _mergeWikiEntry(
      Transaction txn, Map<String, dynamic> incoming) async {
    final rows = await txn.query('tb_book_wiki_entries',
        where: 'id = ?', whereArgs: [incoming['id']], limit: 1);
    if (rows.isEmpty) {
      await txn.insert('tb_book_wiki_entries', incoming);
      return;
    }
    final current = rows.first;
    final incomingCorrected = _asInt(incoming['user_corrected']) == 1;
    final currentCorrected = _asInt(current['user_corrected']) == 1;
    final shouldReplace = incomingCorrected && !currentCorrected ||
        incomingCorrected == currentCorrected &&
            (_asInt(incoming['version']) > _asInt(current['version']) ||
                _asInt(incoming['version']) == _asInt(current['version']) &&
                    _asInt(incoming['updated_at']) >
                        _asInt(current['updated_at']));
    if (shouldReplace) {
      await txn.insert('tb_book_wiki_entries', incoming,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _resolveActiveGoals(Transaction txn) async {
    final duplicates = await txn.rawQuery(
      "SELECT book_id FROM tb_reading_goals WHERE status = 'active' "
      'GROUP BY book_id HAVING COUNT(*) > 1',
    );
    for (final row in duplicates) {
      final goals = await txn.query('tb_reading_goals',
          columns: ['id'],
          where: "book_id = ? AND status = 'active'",
          whereArgs: [row['book_id']],
          orderBy: 'updated_at DESC, id DESC');
      for (final goal in goals.skip(1)) {
        await txn.update('tb_reading_goals', {'status': 'abandoned'},
            where: 'id = ?', whereArgs: [goal['id']]);
      }
    }
  }

  Future<void> _advanceCoverageToGlobalFarthest(Transaction txn) async {
    final rows = await txn.rawQuery('''
      SELECT c.book_id, c.safe_knowledge_boundary, MAX(p.progress) AS farthest
      FROM tb_book_reading_coverage c
      JOIN tb_book_device_positions p ON p.book_id = c.book_id
      GROUP BY c.book_id
    ''');
    for (final row in rows) {
      final farthest = _asDouble(row['farthest']);
      if (farthest > _asDouble(row['safe_knowledge_boundary'])) {
        await txn.update(
          'tb_book_reading_coverage',
          {
            'safe_knowledge_boundary': farthest.clamp(0, 1),
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'book_id = ?',
          whereArgs: [row['book_id']],
        );
      }
    }
  }

  /// Downloads all device files, merges them together with the pre-database-
  /// sync capture, restores this device's own position, then uploads this
  /// device's newly merged packages.
  Future<void> synchronize(
    SyncClientBase client, {
    required List<ReadingAgentBookDelta> localBeforeDatabaseSync,
  }) =>
      synchronizeWithTransport(
        WebDavReadingAgentSyncTransport(client: client, deviceId: deviceId),
        localBeforeDatabaseSync: localBeforeDatabaseSync,
      );

  Future<void> synchronizeWithTransport(
    ReadingAgentSyncTransport transport, {
    List<ReadingAgentBookDelta>? localBeforeDatabaseSync,
  }) async {
    final local = localBeforeDatabaseSync ?? await capture();
    await transport.ping();
    final remote = await transport.downloadPackages(
      local.map((package) => package.bookKey),
    );
    final localPositions = await merge([...local, ...remote]);
    await _restoreLocalBookPositions(localPositions);
    final mergedPackages = await capture();
    await transport.uploadPackages(mergedPackages);
  }

  Future<void> _restoreLocalBookPositions(
      Map<int, BookDeviceReadingPosition> positions) async {
    final db = await DBHelper().database;
    await db.transaction((txn) async {
      for (final entry in positions.entries) {
        await txn.update(
          'tb_books',
          {
            'last_read_position': entry.value.cfi,
            'reading_percentage': entry.value.progress,
          },
          where: 'id = ?',
          whereArgs: [entry.key],
        );
      }
    });
  }

  static String bookKey(int bookId, String? md5) {
    final normalized = md5?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty ? 'id-$bookId' : normalized;
  }

  static Map<String, dynamic> _withBookId(
          Map<String, dynamic> row, int bookId) =>
      {...row, 'book_id': bookId};
}

int _asInt(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
double _asDouble(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
int _maxInt(Object? a, Object? b) =>
    _asInt(a) > _asInt(b) ? _asInt(a) : _asInt(b);
double _maxDouble(Object? a, Object? b) =>
    _asDouble(a) > _asDouble(b) ? _asDouble(a) : _asDouble(b);
double _minDouble(Object? a, Object? b) =>
    _asDouble(a) < _asDouble(b) ? _asDouble(a) : _asDouble(b);
int _coverageRank(Object? status) =>
    const {
      'pending': 0,
      'fromHere': 1,
      'imported': 2,
      'backfilled': 3
    }[status] ??
    0;
int _artifactStatusRank(Object? status) =>
    const {'active': 0, 'resolved': 1, 'retracted': 2}[status] ?? 0;
int _checkpointRank(Object? status) =>
    const {'pending': 0, 'skipped': 1, 'completed': 2}[status] ?? 0;
int _terminalStatusRank(Object? status) =>
    const {
      'active': 0,
      'unresolved': 0,
      'unknown': 0,
      'pending': 0,
      'suspended': 1,
      'resolved': 2,
      'skipped': 2,
      'completed': 3,
      'mastered': 3,
      'retracted': 4,
    }[status] ??
    0;
int _goalStatusRank(Object? status) =>
    const {'active': 0, 'abandoned': 1, 'completed': 2}[status] ?? 0;
