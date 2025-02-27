import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/utils/get_path/get_cache_dir.dart';

class AiCache {
  static const String cacheFileName = 'ai_cache.json';

  static Future<Map<String, dynamic>> readCache() async {
    final cacheDir = await getAnxCacheDir();
    final file = File('${cacheDir.path}/$cacheFileName');

    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        return json.decode(content) as Map<String, dynamic>;
      } catch (e) {
        file.delete();
        return {};
      }
    }
    return {};
  }

  static Future<void> setAiCache(
    int hash,
    String data,
    String identifier,
  ) async {

    final cacheDir = await getAnxCacheDir();
    final file = File('${cacheDir.path}/$cacheFileName');
    final cache = await readCache();

    cache[hash.toString()] = {
      'data': data,
      'identifier': identifier,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    };

    await file.writeAsString(json.encode(cache));
    await cleanCache();
  }

  static Future<String?> getAiCache(int hash) async {
    final context = navigatorKey.currentContext!;
    final cache = await readCache();
    final entry = cache[hash.toString()];
    if (entry != null) {
      String data = entry['data'] as String;
      String identifier = entry['identifier'] as String;
      return '$data\n\n> ${L10n.of(context).ai_cached_by(identifier)}';
    }
    return null;
  }

  static Future<void> cleanCache() async {
    final maxCount = Prefs().maxAiCacheCount;
    var cache = await readCache();
    if (cache.length > maxCount) {

      final keys = cache.keys.toList();
      keys.sort((a, b) => cache[a]['timestamp'] - cache[b]['timestamp']);
      final keysToRemove = keys.sublist(0, cache.length - maxCount);
      cache.removeWhere((key, _) => keysToRemove.contains(key));

      final cacheDir = await getAnxCacheDir();
      final file = File('${cacheDir.path}/$cacheFileName');
      await file.writeAsString(json.encode(cache), mode: FileMode.writeOnly);
    }
  }

  static Future<int> get cacheCount async {
    final cache = await readCache();
    return cache.length;
  }

  static Future<void> clearCache() async {
    final cacheDir = await getAnxCacheDir();
    final file = File('${cacheDir.path}/$cacheFileName');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
