import 'dart:convert';

abstract final class BookWikiEntryKinds {
  static const overview = 'wiki.overview';
  static const chapter = 'wiki.chapter';
  static const part = 'wiki.part';
  static const concept = 'wiki.concept';
  static const argument = 'wiki.argument';
  static const character = 'wiki.character';
  static const relationship = 'wiki.relationship';
  static const event = 'wiki.event';
  static const theme = 'wiki.theme';
  static const method = 'wiki.method';
  static const question = 'wiki.question';
  static const memory = 'wiki.memory';

  static const supported = <String>{
    overview,
    chapter,
    part,
    concept,
    argument,
    character,
    relationship,
    event,
    theme,
    method,
    question,
    memory,
  };
}

enum BookWikiGenerationScope { readBoundary, fullBook }

extension BookWikiGenerationScopeId on BookWikiGenerationScope {
  String get id => this == BookWikiGenerationScope.readBoundary
      ? 'read_boundary'
      : 'full_book';

  static BookWikiGenerationScope parse(Object? value) => value == 'full_book'
      ? BookWikiGenerationScope.fullBook
      : BookWikiGenerationScope.readBoundary;
}

enum BookWikiStatus { empty, partial, ready, failed }

enum BookWikiEntryStatus { active, hidden, retracted }

enum BookWikiEntryCreatedBy { user, agent, system }

class BookWiki {
  const BookWiki({
    required this.bookId,
    this.version = 1,
    this.generationScope = BookWikiGenerationScope.readBoundary,
    this.safeKnowledgeBoundary = 0,
    this.coverageStart = 0,
    this.coverageEnd = 0,
    this.status = BookWikiStatus.empty,
    this.lastGeneratedAt,
    required this.updatedAt,
  });

  final int bookId;
  final int version;
  final BookWikiGenerationScope generationScope;
  final double safeKnowledgeBoundary;
  final double coverageStart;
  final double coverageEnd;
  final BookWikiStatus status;
  final int? lastGeneratedAt;
  final int updatedAt;

  Map<String, Object?> toDb() => {
        'book_id': bookId,
        'version': version,
        'generation_scope': generationScope.id,
        'safe_knowledge_boundary': safeKnowledgeBoundary,
        'coverage_start': coverageStart,
        'coverage_end': coverageEnd,
        'status': status.name,
        'last_generated_at': lastGeneratedAt,
        'updated_at': updatedAt,
      };

  factory BookWiki.fromDb(Map<String, dynamic> row) => BookWiki(
        bookId: _int(row['book_id']),
        version: _int(row['version'], 1),
        generationScope: BookWikiGenerationScopeId.parse(
          row['generation_scope'],
        ),
        safeKnowledgeBoundary: _double(row['safe_knowledge_boundary']),
        coverageStart: _double(row['coverage_start']),
        coverageEnd: _double(row['coverage_end']),
        status:
            _enum(BookWikiStatus.values, row['status'], BookWikiStatus.empty),
        lastGeneratedAt: row['last_generated_at'] == null
            ? null
            : _int(row['last_generated_at']),
        updatedAt: _int(row['updated_at']),
      );
}

class BookWikiSourceRef {
  const BookWikiSourceRef({
    required this.id,
    required this.entryId,
    required this.bookId,
    this.artifactId,
    this.chapterHref,
    this.chapterTitle,
    this.cfi,
    this.textSnapshot = '',
    this.sourceProgress = 0,
    required this.createdAt,
  });

  final String id;
  final String entryId;
  final int bookId;
  final String? artifactId;
  final String? chapterHref;
  final String? chapterTitle;
  final String? cfi;
  final String textSnapshot;
  final double sourceProgress;
  final int createdAt;

  Map<String, Object?> toDb() => {
        'id': id,
        'entry_id': entryId,
        'book_id': bookId,
        'artifact_id': artifactId,
        'chapter_href': chapterHref,
        'chapter_title': chapterTitle,
        'cfi': cfi,
        'text_snapshot': textSnapshot,
        'source_progress': sourceProgress,
        'created_at': createdAt,
      };

  factory BookWikiSourceRef.fromDb(Map<String, dynamic> row) =>
      BookWikiSourceRef(
        id: row['id'].toString(),
        entryId: row['entry_id'].toString(),
        bookId: _int(row['book_id']),
        artifactId: row['artifact_id']?.toString(),
        chapterHref: row['chapter_href']?.toString(),
        chapterTitle: row['chapter_title']?.toString(),
        cfi: row['cfi']?.toString(),
        textSnapshot: row['text_snapshot']?.toString() ?? '',
        sourceProgress: _double(row['source_progress']),
        createdAt: _int(row['created_at']),
      );
}

class BookWikiEntry {
  const BookWikiEntry({
    required this.id,
    required this.bookId,
    required this.kind,
    required this.title,
    this.summary = '',
    this.contentMarkdown = '',
    this.parentId,
    this.sortKey = '',
    this.sourceArtifactIds = const [],
    this.visibleFromProgress = 0,
    this.epistemicStatus = 'agentInference',
    this.createdBy = BookWikiEntryCreatedBy.agent,
    this.version = 1,
    this.status = BookWikiEntryStatus.active,
    this.userCorrected = false,
    required this.createdAt,
    required this.updatedAt,
    this.sources = const [],
  });

  final String id;
  final int bookId;
  final String kind;
  final String title;
  final String summary;
  final String contentMarkdown;
  final String? parentId;
  final String sortKey;
  final List<String> sourceArtifactIds;
  final double visibleFromProgress;
  final String epistemicStatus;
  final BookWikiEntryCreatedBy createdBy;
  final int version;
  final BookWikiEntryStatus status;
  final bool userCorrected;
  final int createdAt;
  final int updatedAt;
  final List<BookWikiSourceRef> sources;

  BookWikiEntry copyWith({
    String? summary,
    String? contentMarkdown,
    BookWikiEntryStatus? status,
    bool? userCorrected,
    int? version,
    int? updatedAt,
    List<BookWikiSourceRef>? sources,
  }) =>
      BookWikiEntry(
        id: id,
        bookId: bookId,
        kind: kind,
        title: title,
        summary: summary ?? this.summary,
        contentMarkdown: contentMarkdown ?? this.contentMarkdown,
        parentId: parentId,
        sortKey: sortKey,
        sourceArtifactIds: sourceArtifactIds,
        visibleFromProgress: visibleFromProgress,
        epistemicStatus: epistemicStatus,
        createdBy: createdBy,
        version: version ?? this.version,
        status: status ?? this.status,
        userCorrected: userCorrected ?? this.userCorrected,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        sources: sources ?? this.sources,
      );

  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'kind': kind,
        'title': title,
        'summary': summary,
        'content_markdown': contentMarkdown,
        'parent_id': parentId,
        'sort_key': sortKey,
        'source_artifact_ids_json': jsonEncode(sourceArtifactIds),
        'visible_from_progress': visibleFromProgress,
        'epistemic_status': epistemicStatus,
        'created_by': createdBy.name,
        'version': version,
        'status': status.name,
        'user_corrected': userCorrected ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory BookWikiEntry.fromDb(Map<String, dynamic> row) => BookWikiEntry(
        id: row['id'].toString(),
        bookId: _int(row['book_id']),
        kind: row['kind']?.toString() ?? '',
        title: row['title']?.toString() ?? '',
        summary: row['summary']?.toString() ?? '',
        contentMarkdown: row['content_markdown']?.toString() ?? '',
        parentId: row['parent_id']?.toString(),
        sortKey: row['sort_key']?.toString() ?? '',
        sourceArtifactIds: _strings(row['source_artifact_ids_json']),
        visibleFromProgress: _double(row['visible_from_progress']),
        epistemicStatus:
            row['epistemic_status']?.toString() ?? 'agentInference',
        createdBy: _enum(BookWikiEntryCreatedBy.values, row['created_by'],
            BookWikiEntryCreatedBy.agent),
        version: _int(row['version'], 1),
        status: _enum(BookWikiEntryStatus.values, row['status'],
            BookWikiEntryStatus.active),
        userCorrected: row['user_corrected'] == 1,
        createdAt: _int(row['created_at']),
        updatedAt: _int(row['updated_at']),
      );
}

class BookWikiRevision {
  const BookWikiRevision({
    required this.id,
    required this.entryId,
    required this.bookId,
    required this.baseVersion,
    required this.kind,
    this.correction = '',
    this.beforeSnapshot = const {},
    this.afterSnapshot = const {},
    required this.deviceId,
    required this.createdAt,
  });

  final String id;
  final String entryId;
  final int bookId;
  final int baseVersion;
  final String kind;
  final String correction;
  final Map<String, dynamic> beforeSnapshot;
  final Map<String, dynamic> afterSnapshot;
  final String deviceId;
  final int createdAt;

  Map<String, Object?> toDb() => {
        'id': id,
        'entry_id': entryId,
        'book_id': bookId,
        'base_version': baseVersion,
        'revision_kind': kind,
        'correction': correction,
        'before_snapshot': jsonEncode(beforeSnapshot),
        'after_snapshot': jsonEncode(afterSnapshot),
        'device_id': deviceId,
        'created_at': createdAt,
      };
}

int _int(Object? value, [int fallback = 0]) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;
double _double(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) =>
    values.where((item) => item.name == raw?.toString()).firstOrNull ??
    fallback;
List<String> _strings(Object? raw) {
  if (raw is String && raw.isNotEmpty) {
    final value = jsonDecode(raw);
    if (value is List) return value.map((item) => item.toString()).toList();
  }
  return const [];
}
