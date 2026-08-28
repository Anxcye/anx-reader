import 'dart:convert';

enum ReadingTaskStatus {
  queued,
  running,
  paused,
  completed,
  failed,
  cancelled,
}

enum ReadingTaskPriority {
  background(0),
  normal(100),
  userInitiated(200),
  critical(300);

  const ReadingTaskPriority(this.weight);
  final int weight;
}

enum ReadingTaskPersistence { ephemeral, durable }

class ReadingTask {
  const ReadingTask({
    required this.id,
    required this.type,
    required this.priority,
    required this.persistence,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.bookId,
    this.payload = const {},
    this.checkpoint = const {},
    this.progress = 0,
    this.canPause = true,
    this.attempts = 0,
    this.startedAt,
    this.finishedAt,
    this.error,
  });

  final String id;
  final String type;
  final int? bookId;
  final ReadingTaskPriority priority;
  final ReadingTaskPersistence persistence;
  final ReadingTaskStatus status;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> checkpoint;
  final double progress;
  final bool canPause;
  final int attempts;
  final int createdAt;
  final int updatedAt;
  final int? startedAt;
  final int? finishedAt;
  final String? error;

  bool get isTerminal => const {
        ReadingTaskStatus.completed,
        ReadingTaskStatus.failed,
        ReadingTaskStatus.cancelled,
      }.contains(status);

  bool canTransitionTo(ReadingTaskStatus next) => switch (status) {
        ReadingTaskStatus.queued => const {
            ReadingTaskStatus.running,
            ReadingTaskStatus.paused,
            ReadingTaskStatus.cancelled,
          }.contains(next),
        ReadingTaskStatus.running => const {
            ReadingTaskStatus.paused,
            ReadingTaskStatus.completed,
            ReadingTaskStatus.failed,
            ReadingTaskStatus.cancelled,
          }.contains(next),
        ReadingTaskStatus.paused => const {
            ReadingTaskStatus.queued,
            ReadingTaskStatus.cancelled,
          }.contains(next),
        ReadingTaskStatus.failed => next == ReadingTaskStatus.queued,
        ReadingTaskStatus.completed || ReadingTaskStatus.cancelled => false,
      };

  ReadingTask transition(
    ReadingTaskStatus next, {
    required int now,
    String? error,
  }) {
    if (!canTransitionTo(next)) {
      throw StateError('Invalid reading task transition: $status -> $next');
    }
    return copyWith(
      status: next,
      updatedAt: now,
      startedAt: next == ReadingTaskStatus.running ? now : startedAt,
      finishedAt: const {
        ReadingTaskStatus.completed,
        ReadingTaskStatus.failed,
        ReadingTaskStatus.cancelled,
      }.contains(next)
          ? now
          : finishedAt,
      attempts: next == ReadingTaskStatus.running ? attempts + 1 : attempts,
      error: error,
      clearError: error == null && next == ReadingTaskStatus.queued,
      clearFinishedAt: next == ReadingTaskStatus.queued,
    );
  }

  ReadingTask copyWith({
    ReadingTaskStatus? status,
    Map<String, dynamic>? checkpoint,
    double? progress,
    int? attempts,
    int? updatedAt,
    int? startedAt,
    int? finishedAt,
    String? error,
    bool clearError = false,
    bool clearFinishedAt = false,
  }) =>
      ReadingTask(
        id: id,
        type: type,
        bookId: bookId,
        priority: priority,
        persistence: persistence,
        status: status ?? this.status,
        payload: payload,
        checkpoint: Map.unmodifiable(checkpoint ?? this.checkpoint),
        progress: (progress ?? this.progress).clamp(0, 1).toDouble(),
        canPause: canPause,
        attempts: attempts ?? this.attempts,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        startedAt: startedAt ?? this.startedAt,
        finishedAt: clearFinishedAt ? null : finishedAt ?? this.finishedAt,
        error: clearError ? null : error ?? this.error,
      );

  Map<String, Object?> toDb() => {
        'id': id,
        'task_type': type,
        'book_id': bookId,
        'priority': priority.name,
        'persistence': persistence.name,
        'status': status.name,
        'payload_json': jsonEncode(payload),
        'checkpoint_json': jsonEncode(checkpoint),
        'progress': progress,
        'can_pause': canPause ? 1 : 0,
        'attempts': attempts,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'started_at': startedAt,
        'finished_at': finishedAt,
        'error': error,
      };

  factory ReadingTask.fromDb(Map<String, Object?> row) => ReadingTask(
        id: row['id']! as String,
        type: row['task_type']! as String,
        bookId: row['book_id'] as int?,
        priority: ReadingTaskPriority.values.byName(
          row['priority']! as String,
        ),
        persistence: ReadingTaskPersistence.values.byName(
          row['persistence']! as String,
        ),
        status: ReadingTaskStatus.values.byName(row['status']! as String),
        payload: _decodeMap(row['payload_json']),
        checkpoint: _decodeMap(row['checkpoint_json']),
        progress: (row['progress'] as num?)?.toDouble() ?? 0,
        canPause: row['can_pause'] == 1,
        attempts: row['attempts'] as int? ?? 0,
        createdAt: row['created_at']! as int,
        updatedAt: row['updated_at']! as int,
        startedAt: row['started_at'] as int?,
        finishedAt: row['finished_at'] as int?,
        error: row['error'] as String?,
      );
}

Map<String, dynamic> _decodeMap(Object? raw) {
  if (raw is! String || raw.isEmpty) return const {};
  final decoded = jsonDecode(raw);
  return decoded is Map<String, dynamic> ? decoded : const {};
}
