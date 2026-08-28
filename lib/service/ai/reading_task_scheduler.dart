import 'dart:async';

import 'package:anx_reader/dao/reading_task.dart';
import 'package:anx_reader/models/reading_task.dart';

typedef ReadingTaskExecutor<T> = Future<T> Function(
  ReadingTaskExecutionContext context,
);

class ReadingTaskExecutionContext {
  ReadingTaskExecutionContext._(this._scheduler, this.taskId, this._control);

  final ReadingTaskScheduler _scheduler;
  final String taskId;
  final _TaskControl _control;

  ReadingTask get task => _scheduler.task(taskId)!;
  bool get isPauseRequested => _control.pauseRequested;
  bool get isCancelRequested => _control.cancelRequested;

  /// Cooperative boundary used between model calls, chapter loads and writes.
  /// It never interrupts a transaction or an in-flight provider response.
  void safePoint() {
    if (_control.cancelRequested) throw const ReadingTaskCancelled();
    if (_control.pauseRequested) throw const ReadingTaskPaused();
  }

  Future<void> update({
    double? progress,
    Map<String, dynamic>? checkpoint,
  }) async {
    safePoint();
    await _scheduler._updateProgress(
      taskId,
      progress: progress,
      checkpoint: checkpoint,
    );
  }
}

class ReadingTaskPaused implements Exception {
  const ReadingTaskPaused();
}

class ReadingTaskCancelled implements Exception {
  const ReadingTaskCancelled();
}

class ReadingTaskScheduler {
  ReadingTaskScheduler({
    ReadingTaskStore? store,
    int Function()? now,
  })  : _store = store,
        _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final ReadingTaskStore? _store;
  final int Function() _now;
  final Map<String, _ScheduledTask> _entries = {};
  final Map<String, ReadingTaskExecutor<dynamic>> _registeredExecutors = {};
  final StreamController<List<ReadingTask>> _changes =
      StreamController<List<ReadingTask>>.broadcast(sync: true);
  String? _runningId;
  bool _restored = false;
  bool _pumping = false;

  Stream<List<ReadingTask>> get changes => _changes.stream;
  List<ReadingTask> get tasks {
    final values = _entries.values.map((entry) => entry.task).toList();
    values.sort(_compareTasks);
    return List.unmodifiable(values);
  }

  ReadingTask? task(String id) => _entries[id]?.task;

  /// Restores durable work without silently restarting it. Work that was
  /// queued or running before process death becomes paused and must be resumed
  /// explicitly after its executor is registered again.
  Future<List<ReadingTask>> restore() async {
    if (_restored || _store == null) return tasks;
    for (var task in await _store.loadRecoverable()) {
      if (task.status == ReadingTaskStatus.queued ||
          task.status == ReadingTaskStatus.running) {
        task = task.transition(ReadingTaskStatus.paused, now: _now());
        await _store.save(task);
      }
      _entries[task.id] = _ScheduledTask(task);
    }
    _restored = true;
    _emit();
    return tasks;
  }

  void registerExecutor<T>(String type, ReadingTaskExecutor<T> executor) {
    _registeredExecutors[type] = executor;
    for (final entry in _entries.values.where((e) => e.task.type == type)) {
      entry.executor ??= executor;
    }
  }

  Future<T> submit<T>(
    ReadingTask task,
    ReadingTaskExecutor<T> executor,
  ) async {
    await restore();
    if (_entries.containsKey(task.id)) {
      throw StateError('Reading task already exists: ${task.id}');
    }
    if (task.status != ReadingTaskStatus.queued) {
      throw StateError('New reading task must be queued');
    }
    final entry = _ScheduledTask<T>(task, executor: executor);
    _entries[task.id] = entry;
    if (task.persistence == ReadingTaskPersistence.durable) {
      await _store?.save(task);
    }
    _emit();
    _requestPreemption(task);
    unawaited(_pump());
    return entry.completer.future;
  }

  Future<void> pause(String id) async {
    final entry = _entries[id];
    if (entry == null || entry.task.isTerminal) return;
    if (!entry.task.canPause) return;
    if (entry.task.status == ReadingTaskStatus.running) {
      entry.autoResumeAfterPreemption = false;
      entry.control.pauseRequested = true;
      return;
    }
    if (entry.task.status == ReadingTaskStatus.queued) {
      await _transition(entry, ReadingTaskStatus.paused);
      unawaited(_pump());
    }
  }

  Future<void> pauseAll({bool durableOnly = false}) async {
    for (final entry in _entries.values.toList(growable: false)) {
      if (durableOnly &&
          entry.task.persistence != ReadingTaskPersistence.durable) {
        continue;
      }
      await pause(entry.task.id);
    }
  }

  Future<void> resume(String id) async {
    final entry = _entries[id];
    if (entry == null || entry.task.status != ReadingTaskStatus.paused) return;
    entry.executor ??= _registeredExecutors[entry.task.type];
    if (entry.executor == null) {
      throw StateError('No executor registered for ${entry.task.type}');
    }
    entry.control = _TaskControl();
    await _transition(entry, ReadingTaskStatus.queued);
    _requestPreemption(entry.task);
    unawaited(_pump());
  }

  Future<T> resumeWith<T>(
    String id,
    ReadingTaskExecutor<T> executor,
  ) async {
    final entry = _entries[id];
    if (entry == null || entry.task.status != ReadingTaskStatus.paused) {
      throw StateError('Reading task is not paused: $id');
    }
    entry.executor = executor;
    await resume(id);
    return entry.completer.future.then((value) => value as T);
  }

  Future<void> retry(String id) async {
    final entry = _entries[id];
    if (entry == null || entry.task.status != ReadingTaskStatus.failed) return;
    entry.executor ??= _registeredExecutors[entry.task.type];
    if (entry.executor == null) {
      throw StateError('No executor registered for ${entry.task.type}');
    }
    entry.control = _TaskControl();
    await _transition(entry, ReadingTaskStatus.queued);
    unawaited(_pump());
  }

  Future<void> cancel(String id) async {
    final entry = _entries[id];
    if (entry == null || entry.task.isTerminal) return;
    if (entry.task.status == ReadingTaskStatus.running) {
      entry.autoResumeAfterPreemption = false;
      entry.control.cancelRequested = true;
      return;
    }
    await _transition(entry, ReadingTaskStatus.cancelled);
    if (!entry.completer.isCompleted) {
      entry.completer.completeError(const ReadingTaskCancelled());
    }
    unawaited(_pump());
  }

  Future<void> _pump() async {
    if (_pumping || _runningId != null) return;
    _pumping = true;
    try {
      final candidates = _entries.values
          .where((entry) =>
              entry.task.status == ReadingTaskStatus.queued &&
              entry.executor != null)
          .toList()
        ..sort((a, b) => _compareTasks(a.task, b.task));
      if (candidates.isEmpty) return;
      final entry = candidates.first;
      _runningId = entry.task.id;
      entry.control = _TaskControl();
      await _transition(entry, ReadingTaskStatus.running);
      unawaited(_execute(entry));
    } finally {
      _pumping = false;
    }
  }

  Future<void> _execute(_ScheduledTask entry) async {
    try {
      final result = await entry.executor!(
        ReadingTaskExecutionContext._(this, entry.task.id, entry.control),
      );
      entry.control.cancelRequested
          ? throw const ReadingTaskCancelled()
          : entry.control.pauseRequested
              ? throw const ReadingTaskPaused()
              : null;
      await _transition(entry, ReadingTaskStatus.completed);
      if (!entry.completer.isCompleted) entry.completer.complete(result);
    } on ReadingTaskPaused {
      await _transition(entry, ReadingTaskStatus.paused);
      if (entry.autoResumeAfterPreemption) {
        entry.autoResumeAfterPreemption = false;
        entry.control = _TaskControl();
        await _transition(entry, ReadingTaskStatus.queued);
      }
    } on ReadingTaskCancelled {
      await _transition(entry, ReadingTaskStatus.cancelled);
      if (!entry.completer.isCompleted) {
        entry.completer.completeError(const ReadingTaskCancelled());
      }
    } catch (error, stack) {
      await _transition(
        entry,
        ReadingTaskStatus.failed,
        error: error.toString(),
      );
      if (!entry.completer.isCompleted) {
        entry.completer.completeError(error, stack);
      }
    } finally {
      if (_runningId == entry.task.id) _runningId = null;
      unawaited(_pump());
    }
  }

  void _requestPreemption(ReadingTask incoming) {
    final running = _runningId == null ? null : _entries[_runningId];
    if (running == null || !running.task.canPause) return;
    if (incoming.priority.weight <= running.task.priority.weight) return;
    running.autoResumeAfterPreemption = true;
    running.control.pauseRequested = true;
  }

  Future<void> _updateProgress(
    String id, {
    double? progress,
    Map<String, dynamic>? checkpoint,
  }) async {
    final entry = _entries[id];
    if (entry == null || entry.task.status != ReadingTaskStatus.running) return;
    entry.task = entry.task.copyWith(
      progress: progress,
      checkpoint: checkpoint,
      updatedAt: _now(),
    );
    await _persist(entry.task);
    _emit();
  }

  Future<void> _transition(
    _ScheduledTask entry,
    ReadingTaskStatus status, {
    String? error,
  }) async {
    entry.task = entry.task.transition(status, now: _now(), error: error);
    await _persist(entry.task);
    _emit();
  }

  Future<void> _persist(ReadingTask task) async {
    if (task.persistence == ReadingTaskPersistence.durable) {
      await _store?.save(task);
    }
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(tasks);
  }

  int _compareTasks(ReadingTask a, ReadingTask b) {
    final priority = b.priority.weight.compareTo(a.priority.weight);
    if (priority != 0) return priority;
    return a.createdAt.compareTo(b.createdAt);
  }

  Future<void> dispose() async {
    for (final entry in _entries.values) {
      if (entry.task.status == ReadingTaskStatus.running &&
          entry.task.canPause) {
        entry.control.pauseRequested = true;
      }
    }
    await _changes.close();
  }
}

class _ScheduledTask<T> {
  _ScheduledTask(this.task, {this.executor});

  ReadingTask task;
  ReadingTaskExecutor<T>? executor;
  final Completer<T> completer = Completer<T>();
  _TaskControl control = _TaskControl();
  bool autoResumeAfterPreemption = false;
}

class _TaskControl {
  bool pauseRequested = false;
  bool cancelRequested = false;
}

final readingTaskScheduler = ReadingTaskScheduler(store: readingTaskDao);
