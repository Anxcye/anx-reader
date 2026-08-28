import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/ai_session.dart';
import 'package:anx_reader/utils/get_path/get_cache_dir.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:langchain_core/chat_models.dart';

class AiChatHistoryEntry {
  const AiChatHistoryEntry({
    required this.id,
    required this.serviceId,
    required this.model,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    required this.completed,
    this.title,
    this.bookId,
    this.bookTitle,
    this.chapterTitle,
    this.chapterHref,
    this.readingMode,
    this.analysisDepth,
    this.frameworks = const [],
    this.outputTemplate,
    this.readingGoal,
    this.analysisResult,
    this.contextSnapshot,
    this.agentTraces = const [],
    this.citations = const [],
  });

  final String id;
  final String serviceId;
  final String model;
  final int createdAt;
  final int updatedAt;
  final List<ChatMessage> messages;
  final bool completed;
  final String? title;
  final int? bookId;
  final String? bookTitle;
  final String? chapterTitle;
  final String? chapterHref;
  final String? readingMode;
  final String? analysisDepth;
  final List<String> frameworks;
  final String? outputTemplate;
  final String? readingGoal;
  final Map<String, dynamic>? analysisResult;
  final Map<String, dynamic>? contextSnapshot;
  final List<Map<String, dynamic>> agentTraces;
  final List<Map<String, dynamic>> citations;

  AiChatHistoryEntry copyWith({
    String? serviceId,
    List<ChatMessage>? messages,
    int? updatedAt,
    bool? completed,
    String? model,
    String? title,
    int? bookId,
    String? bookTitle,
    String? chapterTitle,
    String? chapterHref,
    String? readingMode,
    String? analysisDepth,
    List<String>? frameworks,
    String? outputTemplate,
    String? readingGoal,
    Map<String, dynamic>? analysisResult,
    bool clearAnalysisResult = false,
    Map<String, dynamic>? contextSnapshot,
    List<Map<String, dynamic>>? agentTraces,
    List<Map<String, dynamic>>? citations,
  }) {
    return AiChatHistoryEntry(
      id: id,
      serviceId: serviceId ?? this.serviceId,
      model: model ?? this.model,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      completed: completed ?? this.completed,
      title: title ?? this.title,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      chapterHref: chapterHref ?? this.chapterHref,
      readingMode: readingMode ?? this.readingMode,
      analysisDepth: analysisDepth ?? this.analysisDepth,
      frameworks: frameworks ?? this.frameworks,
      outputTemplate: outputTemplate ?? this.outputTemplate,
      readingGoal: readingGoal ?? this.readingGoal,
      analysisResult:
          clearAnalysisResult ? null : analysisResult ?? this.analysisResult,
      contextSnapshot: contextSnapshot ?? this.contextSnapshot,
      agentTraces: agentTraces ?? this.agentTraces,
      citations: citations ?? this.citations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'model': model,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'completed': completed,
      'messages': messages.map((m) => m.toMap()).toList(growable: false),
      if (title != null) 'title': title,
      if (bookId != null) 'bookId': bookId,
      if (bookTitle != null) 'bookTitle': bookTitle,
      if (chapterTitle != null) 'chapterTitle': chapterTitle,
      if (chapterHref != null) 'chapterHref': chapterHref,
      if (readingMode != null) 'readingMode': readingMode,
      if (analysisDepth != null) 'analysisDepth': analysisDepth,
      if (frameworks.isNotEmpty) 'frameworks': frameworks,
      if (outputTemplate != null) 'outputTemplate': outputTemplate,
      if (readingGoal != null) 'readingGoal': readingGoal,
      if (analysisResult != null) 'analysisResult': analysisResult,
      if (contextSnapshot != null) 'contextSnapshot': contextSnapshot,
      if (agentTraces.isNotEmpty) 'agentTraces': agentTraces,
      if (citations.isNotEmpty) 'citations': citations,
    };
  }

  factory AiChatHistoryEntry.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return AiChatHistoryEntry(
      id: json['id']?.toString() ?? '',
      serviceId:
          json['serviceId']?.toString() ?? json['service']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      createdAt: _readInt(json['createdAt']) ?? now,
      updatedAt: _readInt(json['updatedAt']) ?? now,
      completed: json['completed'] == true || json['completed'] == 1,
      messages: _readMessages(json['messages']),
      title: json['title']?.toString(),
      bookId: _readInt(json['bookId']),
      bookTitle: json['bookTitle']?.toString(),
      chapterTitle: json['chapterTitle']?.toString(),
      chapterHref: json['chapterHref']?.toString(),
      readingMode: json['readingMode']?.toString(),
      analysisDepth: json['analysisDepth']?.toString(),
      frameworks: _readStringList(json['frameworks']),
      outputTemplate: json['outputTemplate']?.toString(),
      readingGoal: json['readingGoal']?.toString(),
      analysisResult: _readMap(json['analysisResult']),
      contextSnapshot: _readMap(json['contextSnapshot']),
      agentTraces: _readMapList(json['agentTraces']),
      citations: _readMapList(json['citations']),
    );
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static List<ChatMessage> _readMessages(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) {
      return ChatMessage.fromMap(
        item.map((key, value) => MapEntry(key.toString(), value)),
      );
    }).toList(growable: false);
  }

  static Map<String, dynamic>? _readMap(Object? value) {
    if (value is! Map) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  static List<Map<String, dynamic>> _readMapList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)))
        .toList(growable: false);
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }
}

class AiHistoryStore {
  static const String historyFileName = 'ai_history.json';
  static final Map<String, Future<void>> _migrationFutures = {};

  static Future<List<AiChatHistoryEntry>> readHistory({
    AiSessionDao? sessionDao,
    File? legacyFile,
  }) async {
    final dao = sessionDao ?? aiSessionDao;
    await _ensureLegacyHistoryMigrated(dao, legacyFile);
    final rows = await dao.selectAll();
    return rows.map(_entryFromDb).toList(growable: false);
  }

  static Future<void> upsertEntry(
    AiChatHistoryEntry entry, {
    AiSessionDao? sessionDao,
    File? legacyFile,
    int? maxCount,
  }) async {
    final dao = sessionDao ?? aiSessionDao;
    await _ensureLegacyHistoryMigrated(dao, legacyFile);
    await dao.upsert(
      _entryToDb(entry),
      maxCount: maxCount ?? Prefs().maxAiCacheCount,
    );
  }

  static Future<void> removeEntry(
    String id, {
    AiSessionDao? sessionDao,
    File? legacyFile,
  }) async {
    final dao = sessionDao ?? aiSessionDao;
    await _ensureLegacyHistoryMigrated(dao, legacyFile);
    await dao.remove(id);
  }

  static Future<void> clear({
    AiSessionDao? sessionDao,
    File? legacyFile,
  }) async {
    final dao = sessionDao ?? aiSessionDao;
    await _ensureLegacyHistoryMigrated(dao, legacyFile);
    await dao.clear();
  }

  static Future<void> _ensureLegacyHistoryMigrated(
    AiSessionDao dao,
    File? legacyFile,
  ) async {
    final file = legacyFile ?? await _resolveFile();
    await _migrationFutures.putIfAbsent(
      file.path,
      () => _migrateLegacyHistory(dao, file),
    );
  }

  static Future<void> _migrateLegacyHistory(
    AiSessionDao dao,
    File file,
  ) async {
    if (!await file.exists()) return;

    late final List<AiChatHistoryEntry> entries;
    try {
      final decoded = json.decode(await file.readAsString());
      if (decoded is! List) {
        throw const FormatException('AI history must be a JSON list');
      }
      entries = decoded.map((item) {
        if (item is! Map) {
          throw const FormatException('AI history entry must be an object');
        }
        final entry = AiChatHistoryEntry.fromJson(
          item.map((key, value) => MapEntry(key.toString(), value)),
        );
        if (entry.id.isEmpty) {
          throw const FormatException('AI history entry id is missing');
        }
        return entry;
      }).toList(growable: false);
    } catch (error) {
      AnxLog.warning('AI history: legacy migration skipped: $error');
      return;
    }

    await dao.insertAllIfAbsent(entries.map(_entryToDb).toList());

    final backup = File('${file.path}.backup');
    try {
      if (await backup.exists()) {
        await file.delete();
      } else {
        await file.rename(backup.path);
      }
    } catch (error) {
      AnxLog.warning('AI history: failed to retain migration backup: $error');
    }
  }

  static Map<String, Object?> _entryToDb(AiChatHistoryEntry entry) {
    return {
      'id': entry.id,
      'title': entry.title,
      'service': entry.serviceId,
      'model': entry.model,
      'bookId': entry.bookId,
      'bookTitle': entry.bookTitle,
      'chapterTitle': entry.chapterTitle,
      'chapterHref': entry.chapterHref,
      'readingMode': entry.readingMode,
      'analysisDepth': entry.analysisDepth,
      'frameworks': json.encode(entry.frameworks),
      'outputTemplate': entry.outputTemplate,
      'readingGoal': entry.readingGoal,
      'analysisResult': entry.analysisResult == null
          ? null
          : json.encode(entry.analysisResult),
      'contextSnapshot': entry.contextSnapshot == null
          ? null
          : json.encode(entry.contextSnapshot),
      'agentTraces': json.encode(entry.agentTraces),
      'citations': json.encode(entry.citations),
      'messages': json.encode(
        entry.messages
            .map((message) => message.toMap())
            .toList(growable: false),
      ),
      'completed': entry.completed ? 1 : 0,
      'createdAt': entry.createdAt,
      'updatedAt': entry.updatedAt,
    };
  }

  static AiChatHistoryEntry _entryFromDb(Map<String, Object?> row) {
    Object? decodeJsonColumn(String column, Object? fallback) {
      final value = row[column];
      if (value is! String || value.isEmpty) return fallback;
      return json.decode(value);
    }

    return AiChatHistoryEntry.fromJson({
      ...row,
      'serviceId': row['service'],
      'contextSnapshot': decodeJsonColumn('contextSnapshot', null),
      'frameworks': decodeJsonColumn('frameworks', const []),
      'analysisResult': decodeJsonColumn('analysisResult', null),
      'agentTraces': decodeJsonColumn('agentTraces', const []),
      'citations': decodeJsonColumn('citations', const []),
      'messages': decodeJsonColumn('messages', const []),
    });
  }

  static Future<File> _resolveFile() async {
    final cacheDir = await getAnxCacheDir();
    return File('${cacheDir.path}/$historyFileName');
  }
}
