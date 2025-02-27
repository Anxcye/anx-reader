import 'package:anx_reader/service/ai/ai_cache.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_cache_count.g.dart';

@riverpod
class AiCacheCount extends _$AiCacheCount {
  @override
  Future<int> build() async {
    return _getCacheCount();
  }

  Future<int> _getCacheCount() async {
    return AiCache.cacheCount;
  }

  Future<void> clearCache() async {
    await AiCache.clearCache();
    state = const AsyncValue.data(0);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _getCacheCount());
  }
}
