import 'dart:async';

import 'package:anx_reader/dao/reading_task.dart';
import 'package:anx_reader/models/reading_task.dart';
import 'package:anx_reader/service/ai/reading_task_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReadingTask rejects invalid state transitions', () {
    final task = _task('state');
    expect(
      () => task.transition(ReadingTaskStatus.completed, now: 2),
      throwsStateError,
    );
  });

  test('higher priority task cooperatively preempts and resumes lower work',
      () async {
    final scheduler = ReadingTaskScheduler(now: _clock());
    addTearDown(scheduler.dispose);
    final firstStarted = Completer<void>();
    final reachSafePoint = Completer<void>();
    final order = <String>[];

    final lowFuture = scheduler.submit<String>(
      _task('low', priority: ReadingTaskPriority.background),
      (context) async {
        if (context.task.attempts == 1) {
          firstStarted.complete();
          await reachSafePoint.future;
          context.safePoint();
        }
        order.add('low');
        return 'low-result';
      },
    );
    await firstStarted.future;
    final highFuture = scheduler.submit<String>(
      _task('high', priority: ReadingTaskPriority.userInitiated),
      (_) async {
        order.add('high');
        return 'high-result';
      },
    );
    reachSafePoint.complete();

    expect(await highFuture, 'high-result');
    expect(await lowFuture, 'low-result');
    expect(order, ['high', 'low']);
    expect(scheduler.task('low')!.attempts, 2);
  });

  test('pause and resume keep the original completion future', () async {
    final scheduler = ReadingTaskScheduler(now: _clock());
    addTearDown(scheduler.dispose);
    final started = Completer<void>();
    final reachSafePoint = Completer<void>();

    final future = scheduler.submit<String>(_task('pause'), (context) async {
      if (context.task.attempts == 1) {
        started.complete();
        await reachSafePoint.future;
        context.safePoint();
      }
      return 'resumed';
    });
    await started.future;
    await scheduler.pause('pause');
    reachSafePoint.complete();
    await _waitForStatus(scheduler, 'pause', ReadingTaskStatus.paused);

    await scheduler.resume('pause');

    expect(await future, 'resumed');
    expect(scheduler.task('pause')!.status, ReadingTaskStatus.completed);
  });

  test('cancel is cooperative and terminal', () async {
    final scheduler = ReadingTaskScheduler(now: _clock());
    addTearDown(scheduler.dispose);
    final started = Completer<void>();
    final reachSafePoint = Completer<void>();
    final future = scheduler.submit<void>(_task('cancel'), (context) async {
      started.complete();
      await reachSafePoint.future;
      context.safePoint();
    });
    final expectation =
        expectLater(future, throwsA(isA<ReadingTaskCancelled>()));
    await started.future;

    await scheduler.cancel('cancel');
    reachSafePoint.complete();

    await expectation;
    expect(scheduler.task('cancel')!.status, ReadingTaskStatus.cancelled);
  });

  test('durable running task restores paused and resumes after registration',
      () async {
    final store = _MemoryTaskStore();
    final running = _task(
      'durable',
      persistence: ReadingTaskPersistence.durable,
    ).transition(ReadingTaskStatus.running, now: 2);
    await store.save(running.copyWith(
      progress: .4,
      checkpoint: const {'chapter': 4},
    ));
    final scheduler = ReadingTaskScheduler(store: store, now: _clock());
    addTearDown(scheduler.dispose);

    await scheduler.restore();

    expect(scheduler.task('durable')!.status, ReadingTaskStatus.paused);
    expect(scheduler.task('durable')!.checkpoint, {'chapter': 4});
    scheduler.registerExecutor<String>('test', (context) async {
      expect(context.task.checkpoint, {'chapter': 4});
      await context.update(progress: 1, checkpoint: const {'chapter': 10});
      return 'done';
    });
    await scheduler.resume('durable');
    await _waitForStatus(scheduler, 'durable', ReadingTaskStatus.completed);

    expect(store.values['durable']!.progress, 1);
    expect(store.values['durable']!.checkpoint, {'chapter': 10});
  });
}

ReadingTask _task(
  String id, {
  ReadingTaskPriority priority = ReadingTaskPriority.normal,
  ReadingTaskPersistence persistence = ReadingTaskPersistence.ephemeral,
}) =>
    ReadingTask(
      id: id,
      type: 'test',
      priority: priority,
      persistence: persistence,
      status: ReadingTaskStatus.queued,
      createdAt: 1,
      updatedAt: 1,
    );

int Function() _clock() {
  var value = 10;
  return () => value++;
}

Future<void> _waitForStatus(
  ReadingTaskScheduler scheduler,
  String id,
  ReadingTaskStatus status,
) async {
  for (var i = 0; i < 100; i++) {
    if (scheduler.task(id)?.status == status) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Task $id did not reach $status; was ${scheduler.task(id)?.status}');
}

class _MemoryTaskStore implements ReadingTaskStore {
  final Map<String, ReadingTask> values = {};

  @override
  Future<void> deleteTask(String id) async => values.remove(id);

  @override
  Future<List<ReadingTask>> loadRecoverable() async =>
      values.values.where((task) => !task.isTerminal).toList(growable: false);

  @override
  Future<void> save(ReadingTask task) async => values[task.id] = task;
}
