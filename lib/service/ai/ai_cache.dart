import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/utils/get_path/get_cache_dir.dart';

class AiCache {
  static const String cacheFileName = 'ai_cache.json';

  static Future<Map<String, dynamic>> _readCache() async {
    final cacheDir = await getAnxCacheDir();
    final file = File('${cacheDir.path}/$cacheFileName');

    if (await file.exists()) {
      final content = await file.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    }
    return {};
  }

  static Future<void> setAiCache(int hash, String data, String identifier) async {
    final cacheDir = await getAnxCacheDir();
    final file = File('${cacheDir.path}/$cacheFileName');
    final cache = await _readCache();

    cache[hash.toString()] = {
      'data': data,
      'identifier': identifier,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    };

    await file.writeAsString(json.encode(cache));
  }

  static Future<String?> getAiCache(int hash) async {
    final context = navigatorKey.currentContext!;
    final cache = await _readCache();
    final entry = cache[hash.toString()];
    if (entry != null) {
      String data = entry['data'] as String;
      String identifier = entry['identifier'] as String;
      return '$data\n\n> ${L10n.of(context).ai_cached_by(identifier)}';
    }
    return null;
  }

  static Future<void> cleanOldCache(
      {Duration maxAge = const Duration(days: 7)}) async {
    final cache = await _readCache();
    final now = DateTime.now().millisecondsSinceEpoch;

    cache.removeWhere(
        (_, value) => now - value['timestamp'] > maxAge.inMilliseconds);

    final cacheDir = await getAnxCacheDir();
    final file = File('${cacheDir.path}/$cacheFileName');
    await file.writeAsString(json.encode(cache));
  }

  Future<int> get cacheCount async {
    final cache = await _readCache();
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
