/// Ensures that callers sharing a sync action join the same in-flight Future.
///
/// This is intentionally transport-agnostic: WebDAV, CloudBase and UI entry
/// points can use one gate without adding another queue or spawning duplicate
/// network/database work.
class SyncRequestGate<T> {
  Future<T>? _active;

  bool get isRunning => _active != null;

  Future<T> run(Future<T> Function() operation) {
    final active = _active;
    if (active != null) return active;

    late final Future<T> guarded;
    guarded = Future<T>.sync(operation).whenComplete(() {
      if (identical(_active, guarded)) _active = null;
    });
    _active = guarded;
    return guarded;
  }
}
