import 'dart:convert';

enum ReadingNoteAiBatchStatus {
  pending,
  running,
  reviewing,
  completed,
  failed,
  abandoned,
}

enum ReadingNoteAiSuggestionStatus { pending, adopted, ignored, archived }

enum ReadingNoteAiAdoptableField { title, aiBlock, tags, topics }

enum ReadingNoteAiSourceType { readingNote, annotation }

enum ReadingNoteAiScope { inbox, filtered, selected }

class ReadingNoteAiBatch {
  const ReadingNoteAiBatch({
    required this.id,
    required this.bookId,
    required this.scope,
    required this.sourceSnapshot,
    required this.status,
    this.providerId,
    this.model,
    this.usedFallback = false,
    required this.totalCount,
    required this.remainingCount,
    this.error,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int bookId;
  final ReadingNoteAiScope scope;
  final List<String> sourceSnapshot;
  final ReadingNoteAiBatchStatus status;
  final String? providerId;
  final String? model;
  final bool usedFallback;
  final int totalCount;
  final int remainingCount;
  final String? error;
  final int createdAt;
  final int updatedAt;

  ReadingNoteAiBatch copyWith({
    ReadingNoteAiBatchStatus? status,
    String? providerId,
    String? model,
    bool? usedFallback,
    int? remainingCount,
    String? error,
    bool clearError = false,
    int? updatedAt,
  }) =>
      ReadingNoteAiBatch(
        id: id,
        bookId: bookId,
        scope: scope,
        sourceSnapshot: sourceSnapshot,
        status: status ?? this.status,
        providerId: providerId ?? this.providerId,
        model: model ?? this.model,
        usedFallback: usedFallback ?? this.usedFallback,
        totalCount: totalCount,
        remainingCount: remainingCount ?? this.remainingCount,
        error: clearError ? null : error ?? this.error,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'scope': scope.name,
        'source_snapshot': jsonEncode(sourceSnapshot),
        'status': status.name,
        'provider_id': providerId,
        'model': model,
        'used_fallback': usedFallback ? 1 : 0,
        'total_count': totalCount,
        'remaining_count': remainingCount,
        'error': error,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory ReadingNoteAiBatch.fromDb(Map<String, dynamic> row) =>
      ReadingNoteAiBatch(
        id: row['id'].toString(),
        bookId: row['book_id'] as int,
        scope: ReadingNoteAiScope.values.byName(row['scope'].toString()),
        sourceSnapshot: _strings(row['source_snapshot']),
        status:
            ReadingNoteAiBatchStatus.values.byName(row['status'].toString()),
        providerId: row['provider_id']?.toString(),
        model: row['model']?.toString(),
        usedFallback: row['used_fallback'] == 1,
        totalCount: row['total_count'] as int,
        remainingCount: row['remaining_count'] as int,
        error: row['error']?.toString(),
        createdAt: row['created_at'] as int,
        updatedAt: row['updated_at'] as int,
      );
}

class ReadingNoteAiSuggestion {
  const ReadingNoteAiSuggestion({
    required this.id,
    required this.batchId,
    required this.bookId,
    required this.sourceType,
    required this.sourceRef,
    required this.contentHash,
    required this.suggestedTitle,
    required this.suggestedBody,
    required this.suggestedTags,
    required this.existingTopicIds,
    required this.newTopics,
    required this.selectedFields,
    required this.status,
    this.beforeSnapshot,
    this.appliedHash,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String batchId;
  final int bookId;
  final ReadingNoteAiSourceType sourceType;
  final String sourceRef;
  final String contentHash;
  final String suggestedTitle;
  final String suggestedBody;
  final List<String> suggestedTags;
  final List<String> existingTopicIds;
  final List<Map<String, dynamic>> newTopics;
  final Set<ReadingNoteAiAdoptableField> selectedFields;
  final ReadingNoteAiSuggestionStatus status;
  final Map<String, dynamic>? beforeSnapshot;
  final String? appliedHash;
  final int createdAt;
  final int updatedAt;

  ReadingNoteAiSuggestion copyWith({
    Set<ReadingNoteAiAdoptableField>? selectedFields,
    ReadingNoteAiSuggestionStatus? status,
    Map<String, dynamic>? beforeSnapshot,
    String? appliedHash,
    int? updatedAt,
  }) =>
      ReadingNoteAiSuggestion(
        id: id,
        batchId: batchId,
        bookId: bookId,
        sourceType: sourceType,
        sourceRef: sourceRef,
        contentHash: contentHash,
        suggestedTitle: suggestedTitle,
        suggestedBody: suggestedBody,
        suggestedTags: suggestedTags,
        existingTopicIds: existingTopicIds,
        newTopics: newTopics,
        selectedFields: selectedFields ?? this.selectedFields,
        status: status ?? this.status,
        beforeSnapshot: beforeSnapshot ?? this.beforeSnapshot,
        appliedHash: appliedHash ?? this.appliedHash,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toDb() => {
        'id': id,
        'batch_id': batchId,
        'book_id': bookId,
        'source_type': sourceType.name,
        'source_ref': sourceRef,
        'content_hash': contentHash,
        'suggested_title': suggestedTitle,
        'suggested_body': suggestedBody,
        'suggested_tags': jsonEncode(suggestedTags),
        'existing_topic_ids': jsonEncode(existingTopicIds),
        'new_topics': jsonEncode(newTopics),
        'selected_fields':
            jsonEncode(selectedFields.map((field) => field.name).toList()),
        'status': status.name,
        'before_snapshot':
            beforeSnapshot == null ? null : jsonEncode(beforeSnapshot),
        'applied_hash': appliedHash,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory ReadingNoteAiSuggestion.fromDb(Map<String, dynamic> row) =>
      ReadingNoteAiSuggestion(
        id: row['id'].toString(),
        batchId: row['batch_id'].toString(),
        bookId: row['book_id'] as int,
        sourceType: ReadingNoteAiSourceType.values
            .byName(row['source_type'].toString()),
        sourceRef: row['source_ref'].toString(),
        contentHash: row['content_hash'].toString(),
        suggestedTitle: row['suggested_title']?.toString() ?? '',
        suggestedBody: row['suggested_body']?.toString() ?? '',
        suggestedTags: _strings(row['suggested_tags']),
        existingTopicIds: _strings(row['existing_topic_ids']),
        newTopics: _maps(row['new_topics']),
        selectedFields: _strings(row['selected_fields'])
            .map(ReadingNoteAiAdoptableField.values.byName)
            .toSet(),
        status: ReadingNoteAiSuggestionStatus.values
            .byName(row['status'].toString()),
        beforeSnapshot: _mapOrNull(row['before_snapshot']),
        appliedHash: row['applied_hash']?.toString(),
        createdAt: row['created_at'] as int,
        updatedAt: row['updated_at'] as int,
      );
}

List<String> _strings(Object? raw) {
  if (raw is! String || raw.isEmpty) return const [];
  final value = jsonDecode(raw);
  return value is List
      ? value.map((item) => item.toString()).toList(growable: false)
      : const [];
}

List<Map<String, dynamic>> _maps(Object? raw) {
  if (raw is! String || raw.isEmpty) return const [];
  final value = jsonDecode(raw);
  return value is List
      ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
      : const [];
}

Map<String, dynamic>? _mapOrNull(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  final value = jsonDecode(raw);
  return value is Map ? Map<String, dynamic>.from(value) : null;
}
