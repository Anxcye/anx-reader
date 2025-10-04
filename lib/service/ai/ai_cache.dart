import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/utils/get_path/get_cache_dir.dart';
import 'package:langchain_core/chat_models.dart';

class AiCacheEntry {
  AiCacheEntry({
    required this.data,
    required this.identifier,
    required this.timestamp,
    required this.messages,
  });

  final String data;
  final String identifier;
  final int timestamp;
  final List<ChatMessage> messages;

  String decoratedText() {
    final context = navigatorKey.currentContext!;
    return '$data\n\n> ${L10n.of(context).aiCachedBy(identifier)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'identifier': identifier,
      'timestamp': timestamp,
      'messages': messages.map((m) => m.toMap()).toList(growable: false),
    };
  }

  factory AiCacheEntry.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    final messages = <ChatMessage>[];
    if (rawMessages is List) {
      for (final item in rawMessages) {
        if (item is Map<String, dynamic>) {
          messages.add(ChatMessage.fromMap(item));
        } else if (item is Map) {
          messages.add(ChatMessage.fromMap(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ));
        }
      }
    }

    return AiCacheEntry(
      data: json['data']?.toString() ?? '',
      identifier: json['identifier']?.toString() ?? '',
      timestamp: json['timestamp'] is int
          ? json['timestamp'] as int
          : DateTime.now().millisecondsSinceEpoch,
      messages: messages,
    );
  }
}

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
    List<ChatMessage> conversation,
  ) async {
    final cacheDir = await getAnxCacheDir();
    final file = File('${cacheDir.path}/$cacheFileName');
    final cache = await readCache();

    final entry = AiCacheEntry(
      data: data,
      identifier: identifier,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      messages: conversation,
    );

    cache[hash.toString()] = entry.toJson();

    await file.writeAsString(json.encode(cache));
    await cleanCache();
  }

  static Future<AiCacheEntry?> getAiCache(int hash) async {
    final cache = await readCache();
    final entry = cache[hash.toString()];
    if (entry != null) {
      if (entry is Map<String, dynamic>) {
        return AiCacheEntry.fromJson(entry);
      }
      if (entry is Map) {
        return AiCacheEntry.fromJson(
          entry.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    }
    return null;
  }

  static Future<void> cleanCache() async {
    final maxCount = Prefs().maxAiCacheCount;
    var cache = await readCache();
    if (cache.length > maxCount) {
      final keys = cache.keys.toList();
      keys.sort((a, b) {
        final aMap = cache[a];
        final bMap = cache[b];
        final aTimestamp = aMap is Map && aMap['timestamp'] is int
            ? aMap['timestamp'] as int
            : 0;
        final bTimestamp = bMap is Map && bMap['timestamp'] is int
            ? bMap['timestamp'] as int
            : 0;
        return aTimestamp - bTimestamp;
      });
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
