import 'dart:convert';

enum ReadingGoalStatus { active, completed, abandoned }

enum ReaderProfileStatus { candidate, confirmed, rejected }

enum AgentActionStatus { applied, undone, conflict }

enum AgentActionType { goal, profile, note, difficulty, memory, artifact, wiki }

enum ReadingCheckpointStatus { pending, completed, skipped }

enum BookReadingProfileMatchSource {
  metadata,
  localClassifier,
  user,
  legacyPreference,
}

/// Stable, namespaced facets used to specialize a book profile without
/// coupling persisted data to a Dart enum. Facets are intentionally additive:
/// the primary closure can remain `fiction.immersion` while suspense books
/// opt into case-aware processing and scoped projections.
abstract final class ReadingProfileFacetIds {
  static const suspense = 'fiction.suspense';
  static const processingVolumeCaseScene = 'processing.volume_case_scene';
  static const entitiesSuspense = 'entities.character_case_clue_evidence';
  static const timelineNarrativeOrder = 'timeline.narrative_order';
  static const relationshipsDurableOnly = 'relationships.durable_only';
  static const timelineCaseDefault = 'timeline.default.case';
  static const timelineFamilyDefault = 'timeline.default.family';
  static const timelineHistoricalDefault = 'timeline.default.historical';
  static const timelineCharacterDefault = 'timeline.default.character';
  static const timelineWorldbuildingDefault = 'timeline.default.worldbuilding';
  static const scienceFiction = 'fiction.science_fiction';
  static const entitiesWorldbuilding = 'entities.worldbuilding';
}

/// Persisted story taxonomy. These are deliberately strings (rather than
/// enums) so new clients can add values without changing the database schema.
abstract final class FictionEventTrackIds {
  static const caseInvestigation = 'story.case';
  static const family = 'story.family';
  static const historical = 'story.historical';
  static const character = 'story.character';
  static const relationship = 'story.relationship';
  static const mystery = 'story.mystery';
  static const social = 'story.social';
  static const worldbuilding = 'story.worldbuilding';
  static const general = 'story.general';

  static String normalize(Object? value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return switch (raw) {
      'case' ||
      '案件' ||
      '案情' ||
      'investigation' ||
      caseInvestigation =>
        caseInvestigation,
      'family' || '家庭' || '家族' || family => family,
      'historical' || 'history' || '历史' || historical => historical,
      'character' || '人物' || '成长' || character => character,
      'relationship' || '关系' || relationship => relationship,
      'mystery' || '悬念' || mystery => mystery,
      'social' || '社会' || social => social,
      'worldbuilding' ||
      '世界观' ||
      '科幻' ||
      '文明' ||
      worldbuilding =>
        worldbuilding,
      'main' || 'story.main' || '主线' => general,
      'general' || '' || general => general,
      _ => general,
    };
  }
}

abstract final class FictionEventStageIds {
  static const opening = 'stage.opening';
  static const incident = 'stage.incident';
  static const investigation = 'stage.investigation';
  static const autopsy = 'stage.autopsy';
  static const development = 'stage.development';
  static const conflict = 'stage.conflict';
  static const revelation = 'stage.revelation';
  static const climax = 'stage.climax';
  static const resolution = 'stage.resolution';
  static const turningPoint = 'stage.turning_point';
  static const background = 'stage.background';
  static const other = 'stage.other';

  static String normalize(Object? value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return switch (raw) {
      '开端' || 'opening' || opening => opening,
      '案发' || 'incident' || incident => incident,
      '勘查' || '调查' || '侦查' || 'investigation' || investigation => investigation,
      '尸检' || 'autopsy' || autopsy => autopsy,
      '发展' || 'development' || development => development,
      'rising_action' ||
      'rising action' ||
      'stage.rising_action' =>
        development,
      '冲突' || 'conflict' || conflict => conflict,
      '揭示' || 'revelation' || revelation => revelation,
      '高潮' || 'climax' || climax => climax,
      '结案' || '结论' || 'resolution' || resolution => resolution,
      '转折' ||
      'turning_point' ||
      'turning point' ||
      turningPoint =>
        turningPoint,
      '背景' || 'background' || background => background,
      _ => other,
    };
  }
}

abstract final class FictionRelationTypeIds {
  static const mentor = 'relation.mentor';
  static const partner = 'relation.partner';
  static const schoolmate = 'relation.schoolmate';
  static const colleague = 'relation.colleague';
  static const comrade = 'relation.comrade';
  static const family = 'relation.family';
  static const spouse = 'relation.spouse';
  static const romantic = 'relation.romantic';
  static const parentChild = 'relation.parent_child';
  static const ally = 'relation.ally';
  static const rival = 'relation.rival';
  static const other = 'relation.other';

  static String normalize(Object? value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return switch (raw) {
      'mentor' || '师徒' || '导师' || '老师' || mentor => mentor,
      'partner' || '搭档' || '队友' || partner => partner,
      'schoolmate' || '同桌' || '同学' || schoolmate => schoolmate,
      'colleague' || '同事' || '同僚' || colleague => colleague,
      'comrade' || '战友' || comrade => comrade,
      'spouse' || '夫妻' || '配偶' || spouse => spouse,
      'romantic' || '恋人' || '恋爱' || '情侣' || romantic => romantic,
      'parent_child' || '亲子' || parentChild => parentChild,
      'family' || '家人' || '亲属' || family => family,
      'ally' || '盟友' || '朋友' || ally => ally,
      'rival' || '敌对' || '对手' || rival => rival,
      _ => other,
    };
  }
}

/// Stable entity taxonomy used by extraction validation. Story Atlas still
/// renders people, but science-fiction extraction needs to distinguish an
/// intelligent non-human character from a civilization, technology or idea.
abstract final class FictionEntityTypeIds {
  static const person = 'entity.person';
  static const intelligentNonhuman = 'entity.intelligent_nonhuman';
  static const organization = 'entity.organization';
  static const concept = 'entity.concept';
  static const technology = 'entity.technology';
  static const species = 'entity.species';
  static const place = 'entity.place';

  static String normalize(Object? value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return switch (raw) {
      'person' || person => person,
      'intelligent_nonhuman' ||
      'intelligent nonhuman' ||
      intelligentNonhuman =>
        intelligentNonhuman,
      'organization' || organization => organization,
      'concept' || concept => concept,
      'technology' || technology => technology,
      'species' || species => species,
      'place' || place => place,
      _ => person,
    };
  }
}

abstract final class FictionNarrativeLayerIds {
  static const outer = 'narrative.outer';
  static const inner = 'narrative.inner';
  static const none = 'narrative.none';

  static String normalize(Object? value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return switch (raw) {
      'outer' || '外层' || '框架' || outer => outer,
      'inner' || '内层' || '人物叙述' || inner => inner,
      _ => none,
    };
  }
}

/// Per-book reading experience selection. This row lives in the synchronized
/// database; [primaryModuleId] is a stable registry id rather than a Dart enum.
class BookReadingProfile {
  const BookReadingProfile({
    required this.bookId,
    required this.primaryModuleId,
    this.facets = const [],
    this.confidence = 0,
    this.pinned = false,
    this.matchSource = BookReadingProfileMatchSource.metadata,
    this.schemaVersion = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  final int bookId;
  final String primaryModuleId;
  final List<String> facets;
  final double confidence;
  final bool pinned;
  final BookReadingProfileMatchSource matchSource;
  final int schemaVersion;
  final int createdAt;
  final int updatedAt;

  bool hasFacet(String facet) => facets.contains(facet);

  /// Whether this book should use the suspense/case-oriented story pipeline.
  bool get isSuspense => hasFacet(ReadingProfileFacetIds.suspense);

  String get processingStrategy => hasFacet(
        ReadingProfileFacetIds.processingVolumeCaseScene,
      )
          ? ReadingProfileFacetIds.processingVolumeCaseScene
          : 'processing.chapter_scene';

  String get timelineStrategy => hasFacet(
        ReadingProfileFacetIds.timelineNarrativeOrder,
      )
          ? ReadingProfileFacetIds.timelineNarrativeOrder
          : 'timeline.narrative_order';

  String get relationshipStrategy => hasFacet(
        ReadingProfileFacetIds.relationshipsDurableOnly,
      )
          ? ReadingProfileFacetIds.relationshipsDurableOnly
          : 'relationships.default';

  String get defaultStoryTrack {
    if (hasFacet(ReadingProfileFacetIds.timelineCaseDefault) || isSuspense) {
      return FictionEventTrackIds.caseInvestigation;
    }
    if (hasFacet(ReadingProfileFacetIds.timelineFamilyDefault) ||
        hasFacet('family') ||
        hasFacet('realist')) {
      return FictionEventTrackIds.family;
    }
    if (hasFacet(ReadingProfileFacetIds.timelineHistoricalDefault) ||
        hasFacet('historical')) {
      return FictionEventTrackIds.historical;
    }
    if (hasFacet(ReadingProfileFacetIds.timelineWorldbuildingDefault) ||
        hasFacet(ReadingProfileFacetIds.scienceFiction)) {
      return FictionEventTrackIds.worldbuilding;
    }
    return FictionEventTrackIds.character;
  }

  BookReadingProfile copyWith({
    String? primaryModuleId,
    List<String>? facets,
    double? confidence,
    bool? pinned,
    BookReadingProfileMatchSource? matchSource,
    int? schemaVersion,
    int? updatedAt,
  }) =>
      BookReadingProfile(
        bookId: bookId,
        primaryModuleId: primaryModuleId ?? this.primaryModuleId,
        facets: facets ?? this.facets,
        confidence: confidence ?? this.confidence,
        pinned: pinned ?? this.pinned,
        matchSource: matchSource ?? this.matchSource,
        schemaVersion: schemaVersion ?? this.schemaVersion,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toDb() => {
        'book_id': bookId,
        'primary_module_id': primaryModuleId,
        'facets_json': jsonEncode(facets),
        'confidence': confidence.clamp(0, 1),
        'pinned': pinned ? 1 : 0,
        'match_source': matchSource.name,
        'schema_version': schemaVersion,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory BookReadingProfile.fromDb(Map<String, dynamic> row) =>
      BookReadingProfile(
        bookId: _asInt(row['book_id']),
        primaryModuleId: row['primary_module_id']?.toString() ?? '',
        facets: _stringList(row['facets_json']),
        confidence: _asDouble(row['confidence']),
        pinned: _asInt(row['pinned']) == 1,
        matchSource: _enumByName(
          BookReadingProfileMatchSource.values,
          row['match_source'],
          BookReadingProfileMatchSource.metadata,
        ),
        schemaVersion: _asInt(row['schema_version']),
        createdAt: _asInt(row['created_at']),
        updatedAt: _asInt(row['updated_at']),
      );
}

enum ReadingArtifactEpistemicStatus {
  textFact,
  userReflection,
  agentInference,
  externalFact,
}

enum ReadingArtifactStatus { active, resolved, retracted }

enum ReadingArtifactIngestionMode { live, backfill, imported, synced }

enum ReadingCoverageSetupStatus { pending, fromHere, backfilled, imported }

/// Per-book spoiler and archive coverage state. The current reading position
/// deliberately does not live here; it remains part of ReadingWorldState.
class BookReadingCoverage {
  const BookReadingCoverage({
    required this.bookId,
    required this.safeKnowledgeBoundary,
    required this.artifactCoverageStart,
    required this.artifactCoverageEnd,
    required this.setupStatus,
    required this.initializedAtProgress,
    required this.createdAt,
    required this.updatedAt,
  });

  final int bookId;
  final double safeKnowledgeBoundary;
  final double artifactCoverageStart;
  final double artifactCoverageEnd;
  final ReadingCoverageSetupStatus setupStatus;
  final double initializedAtProgress;
  final int createdAt;
  final int updatedAt;

  bool get setupPending => setupStatus == ReadingCoverageSetupStatus.pending;

  BookReadingCoverage copyWith({
    double? safeKnowledgeBoundary,
    double? artifactCoverageStart,
    double? artifactCoverageEnd,
    ReadingCoverageSetupStatus? setupStatus,
    int? updatedAt,
  }) =>
      BookReadingCoverage(
        bookId: bookId,
        safeKnowledgeBoundary:
            safeKnowledgeBoundary ?? this.safeKnowledgeBoundary,
        artifactCoverageStart:
            artifactCoverageStart ?? this.artifactCoverageStart,
        artifactCoverageEnd: artifactCoverageEnd ?? this.artifactCoverageEnd,
        setupStatus: setupStatus ?? this.setupStatus,
        initializedAtProgress: initializedAtProgress,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toDb() => {
        'book_id': bookId,
        'safe_knowledge_boundary': safeKnowledgeBoundary.clamp(0, 1),
        'artifact_coverage_start': artifactCoverageStart.clamp(0, 1),
        'artifact_coverage_end': artifactCoverageEnd.clamp(0, 1),
        'setup_status': setupStatus.name,
        'initialized_at_progress': initializedAtProgress.clamp(0, 1),
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory BookReadingCoverage.fromDb(Map<String, dynamic> row) =>
      BookReadingCoverage(
        bookId: _asInt(row['book_id']),
        safeKnowledgeBoundary: _asDouble(row['safe_knowledge_boundary']),
        artifactCoverageStart: _asDouble(row['artifact_coverage_start']),
        artifactCoverageEnd: _asDouble(row['artifact_coverage_end']),
        setupStatus: _enumByName(
          ReadingCoverageSetupStatus.values,
          row['setup_status'],
          ReadingCoverageSetupStatus.fromHere,
        ),
        initializedAtProgress: _asDouble(row['initialized_at_progress']),
        createdAt: _asInt(row['created_at']),
        updatedAt: _asInt(row['updated_at']),
      );
}

abstract final class ReadingArtifactKinds {
  static const character = 'fiction.character';
  static const relationship = 'fiction.relationship';
  static const event = 'fiction.event';
  static const mystery = 'fiction.mystery';
  static const clue = 'fiction.clue';
  static const scene = 'fiction.scene';
  static const resumeContext = 'fiction.resume_context';
  static const backfillCheckpoint = 'fiction.backfill_checkpoint';
}

/// Versioned, source-traceable outcome used by genre modules.
///
/// [visibleFromProgress] is the enforceable spoiler boundary. [sourceProgress]
/// records where the event occurred, while [ingestedAt] records when it entered
/// the system. Keeping these separate makes backfill safe.
class ReadingArtifact {
  const ReadingArtifact({
    required this.id,
    required this.bookId,
    required this.moduleId,
    required this.kind,
    this.schemaVersion = 1,
    this.payload = const {},
    this.epistemicStatus = ReadingArtifactEpistemicStatus.textFact,
    this.status = ReadingArtifactStatus.active,
    this.sourceStartCfi,
    this.sourceEndCfi,
    this.sourceTextSnapshot = '',
    this.chapterHref,
    this.chapterTitle,
    this.discoveredAtCfi,
    this.sourceProgress = 0,
    this.visibleFromProgress = 0,
    required this.ingestedAt,
    this.ingestionMode = ReadingArtifactIngestionMode.live,
    this.sessionId,
    this.createdBy = 'user',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int bookId;
  final String moduleId;
  final String kind;
  final int schemaVersion;
  final Map<String, dynamic> payload;
  final ReadingArtifactEpistemicStatus epistemicStatus;
  final ReadingArtifactStatus status;
  final String? sourceStartCfi;
  final String? sourceEndCfi;
  final String sourceTextSnapshot;
  final String? chapterHref;
  final String? chapterTitle;
  final String? discoveredAtCfi;
  final double sourceProgress;
  final double visibleFromProgress;
  final int ingestedAt;
  final ReadingArtifactIngestionMode ingestionMode;
  final String? sessionId;
  final String createdBy;
  final int createdAt;
  final int updatedAt;

  bool isVisibleAtProgress(double progress) =>
      visibleFromProgress <= progress.clamp(0, 1) + 0.000001;

  ReadingArtifact copyWith({
    Map<String, dynamic>? payload,
    ReadingArtifactEpistemicStatus? epistemicStatus,
    ReadingArtifactStatus? status,
    String? sourceStartCfi,
    String? sourceEndCfi,
    String? sourceTextSnapshot,
    String? chapterHref,
    String? chapterTitle,
    String? discoveredAtCfi,
    double? sourceProgress,
    double? visibleFromProgress,
    int? ingestedAt,
    ReadingArtifactIngestionMode? ingestionMode,
    String? sessionId,
    String? createdBy,
    int? updatedAt,
  }) =>
      ReadingArtifact(
        id: id,
        bookId: bookId,
        moduleId: moduleId,
        kind: kind,
        schemaVersion: schemaVersion,
        payload: payload ?? this.payload,
        epistemicStatus: epistemicStatus ?? this.epistemicStatus,
        status: status ?? this.status,
        sourceStartCfi: sourceStartCfi ?? this.sourceStartCfi,
        sourceEndCfi: sourceEndCfi ?? this.sourceEndCfi,
        sourceTextSnapshot: sourceTextSnapshot ?? this.sourceTextSnapshot,
        chapterHref: chapterHref ?? this.chapterHref,
        chapterTitle: chapterTitle ?? this.chapterTitle,
        discoveredAtCfi: discoveredAtCfi ?? this.discoveredAtCfi,
        sourceProgress: sourceProgress ?? this.sourceProgress,
        visibleFromProgress: visibleFromProgress ?? this.visibleFromProgress,
        ingestedAt: ingestedAt ?? this.ingestedAt,
        ingestionMode: ingestionMode ?? this.ingestionMode,
        sessionId: sessionId ?? this.sessionId,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'module_id': moduleId,
        'artifact_kind': kind,
        'schema_version': schemaVersion,
        'payload_json': jsonEncode(payload),
        'epistemic_status': epistemicStatus.name,
        'status': status.name,
        'source_start_cfi': sourceStartCfi,
        'source_end_cfi': sourceEndCfi,
        'source_text_snapshot': sourceTextSnapshot,
        'chapter_href': chapterHref,
        'chapter_title': chapterTitle,
        'discovered_at_cfi': discoveredAtCfi,
        'source_progress': sourceProgress.clamp(0, 1),
        'visible_from_progress': visibleFromProgress.clamp(0, 1),
        'ingested_at': ingestedAt,
        'ingestion_mode': ingestionMode.name,
        'session_id': sessionId,
        'created_by': createdBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory ReadingArtifact.fromDb(Map<String, dynamic> row) => ReadingArtifact(
        id: row['id']?.toString() ?? '',
        bookId: _asInt(row['book_id']),
        moduleId: row['module_id']?.toString() ?? '',
        kind: row['artifact_kind']?.toString() ?? '',
        schemaVersion: _asInt(row['schema_version']),
        payload: _map(row['payload_json']),
        epistemicStatus: _enumByName(
          ReadingArtifactEpistemicStatus.values,
          row['epistemic_status'],
          ReadingArtifactEpistemicStatus.textFact,
        ),
        status: _enumByName(
          ReadingArtifactStatus.values,
          row['status'],
          ReadingArtifactStatus.active,
        ),
        sourceStartCfi: row['source_start_cfi']?.toString(),
        sourceEndCfi: row['source_end_cfi']?.toString(),
        sourceTextSnapshot: row['source_text_snapshot']?.toString() ?? '',
        chapterHref: row['chapter_href']?.toString(),
        chapterTitle: row['chapter_title']?.toString(),
        discoveredAtCfi: row['discovered_at_cfi']?.toString(),
        sourceProgress: _asDouble(row['source_progress']),
        visibleFromProgress: _asDouble(row['visible_from_progress']),
        ingestedAt: _asInt(row['ingested_at']),
        ingestionMode: _enumByName(
          ReadingArtifactIngestionMode.values,
          row['ingestion_mode'],
          ReadingArtifactIngestionMode.live,
        ),
        sessionId: row['session_id']?.toString(),
        createdBy: row['created_by']?.toString() ?? 'user',
        createdAt: _asInt(row['created_at']),
        updatedAt: _asInt(row['updated_at']),
      );
}

class ReadingChapterCheckpoint {
  const ReadingChapterCheckpoint({
    required this.id,
    required this.bookId,
    required this.chapterHref,
    required this.chapterTitle,
    this.progress = 0,
    this.status = ReadingCheckpointStatus.pending,
    this.reflection = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int bookId;
  final String chapterHref;
  final String chapterTitle;
  final double progress;
  final ReadingCheckpointStatus status;
  final String reflection;
  final int createdAt;
  final int updatedAt;

  ReadingChapterCheckpoint copyWith({
    double? progress,
    ReadingCheckpointStatus? status,
    String? reflection,
    int? updatedAt,
  }) =>
      ReadingChapterCheckpoint(
        id: id,
        bookId: bookId,
        chapterHref: chapterHref,
        chapterTitle: chapterTitle,
        progress: progress ?? this.progress,
        status: status ?? this.status,
        reflection: reflection ?? this.reflection,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'chapter_href': chapterHref,
        'chapter_title': chapterTitle,
        'progress': progress,
        'status': status.name,
        'reflection': reflection,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory ReadingChapterCheckpoint.fromDb(Map<String, dynamic> row) =>
      ReadingChapterCheckpoint(
        id: row['id'].toString(),
        bookId: _asInt(row['book_id']),
        chapterHref: row['chapter_href']?.toString() ?? '',
        chapterTitle: row['chapter_title']?.toString() ?? '',
        progress: _asDouble(row['progress']),
        status: _enumByName(ReadingCheckpointStatus.values, row['status'],
            ReadingCheckpointStatus.pending),
        reflection: row['reflection']?.toString() ?? '',
        createdAt: _asInt(row['created_at']),
        updatedAt: _asInt(row['updated_at']),
      );
}

enum MasteryLevel { unknown, emerging, familiar, mastered }

class MasteryState {
  const MasteryState(
      {required this.id,
      required this.bookId,
      this.chapterHref,
      required this.topic,
      this.level = MasteryLevel.unknown,
      this.score = 0,
      this.nextReviewAt,
      required this.updatedAt});
  final String id;
  final int bookId;
  final String? chapterHref;
  final String topic;
  final MasteryLevel level;
  final double score;
  final int? nextReviewAt;
  final int updatedAt;
  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'chapter_href': chapterHref,
        'topic': topic,
        'level': level.name,
        'score': score,
        'next_review_at': nextReviewAt,
        'updated_at': updatedAt
      };
  factory MasteryState.fromDb(Map<String, dynamic> row) => MasteryState(
      id: row['id'].toString(),
      bookId: _asInt(row['book_id']),
      chapterHref: row['chapter_href']?.toString(),
      topic: row['topic']?.toString() ?? '',
      level:
          _enumByName(MasteryLevel.values, row['level'], MasteryLevel.unknown),
      score: _asDouble(row['score']),
      nextReviewAt:
          row['next_review_at'] == null ? null : _asInt(row['next_review_at']),
      updatedAt: _asInt(row['updated_at']));
}

class KnowledgeCard {
  const KnowledgeCard(
      {required this.id,
      required this.bookId,
      required this.front,
      required this.back,
      this.chapterHref,
      this.dueAt,
      this.intervalDays = 1,
      this.repetitions = 0,
      this.status = 'active',
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final int bookId;
  final String front;
  final String back;
  final String? chapterHref;
  final int? dueAt;
  final int intervalDays;
  final int repetitions;
  final String status;
  final int createdAt;
  final int updatedAt;
  KnowledgeCard copyWith(
          {int? dueAt,
          int? intervalDays,
          int? repetitions,
          String? status,
          int? updatedAt}) =>
      KnowledgeCard(
          id: id,
          bookId: bookId,
          front: front,
          back: back,
          chapterHref: chapterHref,
          dueAt: dueAt ?? this.dueAt,
          intervalDays: intervalDays ?? this.intervalDays,
          repetitions: repetitions ?? this.repetitions,
          status: status ?? this.status,
          createdAt: createdAt,
          updatedAt: updatedAt ?? this.updatedAt);
  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'front': front,
        'back': back,
        'chapter_href': chapterHref,
        'due_at': dueAt,
        'interval_days': intervalDays,
        'repetitions': repetitions,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt
      };
  factory KnowledgeCard.fromDb(Map<String, dynamic> row) => KnowledgeCard(
      id: row['id'].toString(),
      bookId: _asInt(row['book_id']),
      front: row['front']?.toString() ?? '',
      back: row['back']?.toString() ?? '',
      chapterHref: row['chapter_href']?.toString(),
      dueAt: row['due_at'] == null ? null : _asInt(row['due_at']),
      intervalDays: _asInt(row['interval_days']),
      repetitions: _asInt(row['repetitions']),
      status: row['status']?.toString() ?? 'active',
      createdAt: _asInt(row['created_at']),
      updatedAt: _asInt(row['updated_at']));
}

class ReadingMemoryDocument {
  const ReadingMemoryDocument(
      {required this.id,
      required this.bookId,
      required this.title,
      required this.markdown,
      this.sourceRefs = const [],
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final int bookId;
  final String title;
  final String markdown;
  final List<String> sourceRefs;
  final int createdAt;
  final int updatedAt;
  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'title': title,
        'markdown': markdown,
        'source_refs_json': jsonEncode(sourceRefs),
        'created_at': createdAt,
        'updated_at': updatedAt
      };
  factory ReadingMemoryDocument.fromDb(Map<String, dynamic> row) =>
      ReadingMemoryDocument(
          id: row['id'].toString(),
          bookId: _asInt(row['book_id']),
          title: row['title']?.toString() ?? '',
          markdown: row['markdown']?.toString() ?? '',
          sourceRefs: _stringList(row['source_refs_json']),
          createdAt: _asInt(row['created_at']),
          updatedAt: _asInt(row['updated_at']));
}

/// A durable reading outcome. Interpretation-based criteria are deliberately
/// represented as user-confirmed booleans; only [progress] is automatic.
class ReadingGoal {
  const ReadingGoal({
    required this.id,
    required this.bookId,
    required this.title,
    this.range = const {},
    this.timeBudgetMinutes,
    this.criteria = const [],
    this.progress = 0,
    this.status = ReadingGoalStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int bookId;
  final String title;
  final Map<String, dynamic> range;
  final int? timeBudgetMinutes;
  final List<Map<String, dynamic>> criteria;
  final double progress;
  final ReadingGoalStatus status;
  final int createdAt;
  final int updatedAt;

  ReadingGoal copyWith({
    String? title,
    Map<String, dynamic>? range,
    int? timeBudgetMinutes,
    bool clearTimeBudget = false,
    List<Map<String, dynamic>>? criteria,
    double? progress,
    ReadingGoalStatus? status,
    int? updatedAt,
  }) =>
      ReadingGoal(
        id: id,
        bookId: bookId,
        title: title ?? this.title,
        range: range ?? this.range,
        timeBudgetMinutes: clearTimeBudget
            ? null
            : timeBudgetMinutes ?? this.timeBudgetMinutes,
        criteria: criteria ?? this.criteria,
        progress: progress ?? this.progress,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'title': title,
        'range_json': jsonEncode(range),
        'time_budget_minutes': timeBudgetMinutes,
        'criteria_json': jsonEncode(criteria),
        'progress': progress,
        'status': status.name,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory ReadingGoal.fromDb(Map<String, dynamic> row) => ReadingGoal(
        id: row['id'].toString(),
        bookId: _asInt(row['book_id']),
        title: row['title']?.toString() ?? '',
        range: _map(row['range_json']),
        timeBudgetMinutes: row['time_budget_minutes'] == null
            ? null
            : _asInt(row['time_budget_minutes']),
        criteria: _mapList(row['criteria_json']),
        progress: _asDouble(row['progress']),
        status: _enumByName(
          ReadingGoalStatus.values,
          row['status'],
          ReadingGoalStatus.active,
        ),
        createdAt: _asInt(row['created_at']),
        updatedAt: _asInt(row['updated_at']),
      );
}

class ReaderProfileItem {
  const ReaderProfileItem({
    required this.key,
    this.value = const {},
    this.status = ReaderProfileStatus.candidate,
    this.confidence = 0,
    this.evidenceSessionIds = const [],
    this.rejectedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  final String key;
  final Map<String, dynamic> value;
  final ReaderProfileStatus status;
  final double confidence;
  final List<String> evidenceSessionIds;
  int get evidenceCount => evidenceSessionIds.length;
  final int? rejectedUntil;
  final int createdAt;
  final int updatedAt;

  ReaderProfileItem copyWith({
    Map<String, dynamic>? value,
    ReaderProfileStatus? status,
    double? confidence,
    List<String>? evidenceSessionIds,
    int? rejectedUntil,
    bool clearRejectedUntil = false,
    int? updatedAt,
  }) =>
      ReaderProfileItem(
        key: key,
        value: value ?? this.value,
        status: status ?? this.status,
        confidence: confidence ?? this.confidence,
        evidenceSessionIds: evidenceSessionIds ?? this.evidenceSessionIds,
        rejectedUntil:
            clearRejectedUntil ? null : rejectedUntil ?? this.rejectedUntil,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toDb() => {
        'profile_key': key,
        'value_json': jsonEncode(value),
        'status': status.name,
        'confidence': confidence,
        'evidence_count': evidenceCount,
        'evidence_sessions_json': jsonEncode(evidenceSessionIds),
        'rejected_until': rejectedUntil,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory ReaderProfileItem.fromDb(Map<String, dynamic> row) =>
      ReaderProfileItem(
        key: row['profile_key'].toString(),
        value: _map(row['value_json']),
        status: _enumByName(
          ReaderProfileStatus.values,
          row['status'],
          ReaderProfileStatus.candidate,
        ),
        confidence: _asDouble(row['confidence']),
        evidenceSessionIds: _stringList(row['evidence_sessions_json']),
        rejectedUntil: row['rejected_until'] == null
            ? null
            : _asInt(row['rejected_until']),
        createdAt: _asInt(row['created_at']),
        updatedAt: _asInt(row['updated_at']),
      );
}

class AgentAction {
  const AgentAction({
    required this.id,
    required this.type,
    required this.targetId,
    this.bookId,
    required this.beforeSnapshot,
    required this.afterSnapshot,
    required this.afterHash,
    this.status = AgentActionStatus.applied,
    required this.sessionId,
    required this.createdAt,
    required this.expiresAt,
    this.undoneAt,
  });

  final String id;
  final AgentActionType type;
  final String targetId;
  final int? bookId;
  final Map<String, dynamic>? beforeSnapshot;
  final Map<String, dynamic>? afterSnapshot;
  final String afterHash;
  final AgentActionStatus status;
  final String sessionId;
  final int createdAt;
  final int expiresAt;
  final int? undoneAt;

  Map<String, Object?> toDb() => {
        'id': id,
        'action_type': type.name,
        'target_id': targetId,
        'book_id': bookId,
        'before_snapshot':
            beforeSnapshot == null ? null : jsonEncode(beforeSnapshot),
        'after_snapshot':
            afterSnapshot == null ? null : jsonEncode(afterSnapshot),
        'after_hash': afterHash,
        'status': status.name,
        'session_id': sessionId,
        'created_at': createdAt,
        'expires_at': expiresAt,
        'undone_at': undoneAt,
      };

  factory AgentAction.fromDb(Map<String, dynamic> row) => AgentAction(
        id: row['id'].toString(),
        type: _enumByName(
            AgentActionType.values, row['action_type'], AgentActionType.goal),
        targetId: row['target_id'].toString(),
        bookId: row['book_id'] == null ? null : _asInt(row['book_id']),
        beforeSnapshot: row['before_snapshot'] == null
            ? null
            : _map(row['before_snapshot']),
        afterSnapshot:
            row['after_snapshot'] == null ? null : _map(row['after_snapshot']),
        afterHash: row['after_hash']?.toString() ?? '',
        status: _enumByName(
          AgentActionStatus.values,
          row['status'],
          AgentActionStatus.applied,
        ),
        sessionId: row['session_id']?.toString() ?? '',
        createdAt: _asInt(row['created_at']),
        expiresAt: _asInt(row['expires_at']),
        undoneAt: row['undone_at'] == null ? null : _asInt(row['undone_at']),
      );
}

enum UndoResult { undone, alreadyUndone, expired, conflict, missing }

class AgentMutation<T> {
  const AgentMutation({required this.value, required this.action});
  final T value;
  final AgentAction action;
}

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) =>
    values.where((value) => value.name == raw?.toString()).firstOrNull ??
    fallback;

int _asInt(Object? value) => value is int
    ? value
    : value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;

double _asDouble(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

Map<String, dynamic> _map(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is! String || value.isEmpty) return const {};
  final decoded = jsonDecode(value);
  return decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
}

List<Map<String, dynamic>> _mapList(Object? value) {
  final decoded = value is String ? jsonDecode(value) : value;
  return decoded is List
      ? decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
      : const [];
}

List<String> _stringList(Object? value) {
  final decoded = value is String ? jsonDecode(value) : value;
  return decoded is List
      ? decoded.map((item) => item.toString()).toList(growable: false)
      : const [];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
