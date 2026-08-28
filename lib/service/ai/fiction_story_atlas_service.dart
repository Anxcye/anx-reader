import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';

/// A page-independent projection of fiction Artifacts. The database remains
/// the source of truth; this service only applies the reader's current spoiler
/// boundary and normalizes legacy payloads for the visual surfaces.
class FictionStoryAtlas {
  const FictionStoryAtlas({
    required this.characters,
    required this.relationships,
    required this.timeline,
    required this.visibleProgress,
    required this.coverageStart,
    required this.coverageEnd,
    this.lastOrganizedProgress,
    this.lastIngestedAt,
    this.workId,
    this.arcId,
  });

  final List<FictionCharacterNode> characters;
  final List<FictionRelationshipEdge> relationships;
  final List<FictionTimelineEvent> timeline;
  final double visibleProgress;
  final double? coverageStart;
  final double? coverageEnd;
  final double? lastOrganizedProgress;
  final int? lastIngestedAt;

  /// Independent work inside a collection EPUB, when available.
  final String? workId;

  /// The case/arc scope used to build this projection, when available.
  final String? arcId;

  bool get isEmpty => characters.isEmpty && timeline.isEmpty;
}

class FictionCharacterNode {
  const FictionCharacterNode({
    required this.id,
    required this.name,
    required this.summary,
    required this.aliases,
    required this.source,
    this.namingSystem = 'unknown',
    this.courtesyNames = const [],
    this.artNames = const [],
    this.titles = const [],
    this.givenName,
    this.familyName,
  });

  final String id;
  final String name;
  final String summary;
  final List<String> aliases;
  final ReadingArtifact source;
  final String namingSystem;
  final List<String> courtesyNames;
  final List<String> artNames;
  final List<String> titles;
  final String? givenName;
  final String? familyName;

  /// Prefer the given-name character for Chinese names; western names use
  /// their conventional first-letter initial.
  String get initial {
    final value = name.trim();
    if (value.isEmpty) return '?';
    final han = RegExp(r'[\u3400-\u9fff\uf900-\ufaff]')
        .allMatches(value)
        .map((match) => match.group(0)!)
        .toList(growable: false);
    return han.isNotEmpty ? han.last : value[0].toUpperCase();
  }

  String get narrativeLayer => FictionNarrativeLayerIds.normalize(
        source.payload['narrativeLayer'] ??
            (source.payload['entityId'] == 'narrator.primary'
                ? FictionNarrativeLayerIds.outer
                : null),
      );
}

class FictionRelationshipEdge {
  const FictionRelationshipEdge({
    required this.from,
    required this.to,
    required this.relation,
    required this.summary,
    required this.state,
    required this.history,
    required this.source,
  });

  final String from;
  final String to;
  final String relation;
  final String summary;
  final String state;
  final List<ReadingArtifact> history;
  final ReadingArtifact source;

  bool get isChanged => state == 'changed' || state == 'ended';
  String get relationType =>
      FictionRelationTypeIds.normalize(source.payload['relationType']);
}

class FictionTimelineEvent {
  const FictionTimelineEvent({
    required this.id,
    required this.title,
    required this.summary,
    required this.kind,
    required this.participants,
    required this.storyTimeLabel,
    required this.source,
  });

  final String id;
  final String title;
  final String summary;
  final String kind;
  final List<String> participants;
  final String? storyTimeLabel;
  final ReadingArtifact source;

  bool get isMajor => source.payload['importance']?.toString() == 'major';
  bool get isMystery => kind == ReadingArtifactKinds.mystery;
  bool get isClue => kind == ReadingArtifactKinds.clue;
  bool get isRelationship => kind == ReadingArtifactKinds.relationship;
  String get track => FictionEventTrackIds.normalize(source.payload['track']);
  String get stage => FictionEventStageIds.normalize(source.payload['stage']);
}

enum FictionTimelineDensity { compact, standard, complete }

class FictionTimelineChapter {
  const FictionTimelineChapter({
    required this.id,
    required this.title,
    required this.startProgress,
    required this.events,
  });

  final String id;
  final String title;
  final double startProgress;
  final List<FictionTimelineEvent> events;

  int get majorEventCount => events.where((event) => event.isMajor).length;
}

class FictionStoryStage {
  const FictionStoryStage({
    required this.index,
    required this.startProgress,
    required this.endProgress,
    required this.chapterIds,
    required this.eventCount,
  });

  final int index;
  final double startProgress;
  final double endProgress;
  final List<String> chapterIds;
  final int eventCount;

  String get label => '阶段 $index';
}

class FictionMysteryThread {
  const FictionMysteryThread({required this.mystery, required this.events});

  final FictionTimelineEvent mystery;
  final List<FictionTimelineEvent> events;
}

class FictionStoryAtlasService {
  const FictionStoryAtlasService({ReadingAgentRepository? repository})
      : _repository = repository;

  final ReadingAgentRepository? _repository;

  Future<FictionStoryAtlas> load({
    required int bookId,
    required double visibleAtProgress,
    String? workId,
    String? arcId,
  }) async {
    final artifacts = await (_repository ?? readingAgentRepository).artifacts(
      bookId,
      status: ReadingArtifactStatus.active,
      visibleAtProgress: visibleAtProgress,
    );
    return fromArtifacts(
      artifacts,
      visibleAtProgress: visibleAtProgress,
      workId: workId,
      arcId: arcId,
    );
  }

  /// Finds the latest case scope encountered at the reader's position. This
  /// is deliberately derived from source progress (not ingestion time), so a
  /// synced artifact cannot switch the reader to a future case.
  String? currentArcId(
    Iterable<ReadingArtifact> artifacts,
    double visibleAtProgress,
  ) {
    final scoped = artifacts
        .where((item) =>
            item.isVisibleAtProgress(visibleAtProgress) &&
            item.sourceProgress <= visibleAtProgress + 0.000001)
        .map((item) {
          final value = item.payload['arcId']?.toString().trim() ?? '';
          return (progress: item.sourceProgress, arcId: value);
        })
        .where((item) => item.arcId.isNotEmpty)
        .toList()
      ..sort((a, b) => a.progress.compareTo(b.progress));
    return scoped.isEmpty ? null : scoped.last.arcId;
  }

  String? currentWorkId(
    Iterable<ReadingArtifact> artifacts,
    double visibleAtProgress,
  ) {
    final scoped = artifacts
        .where((item) => item.sourceProgress <= visibleAtProgress)
        .map((item) => (
              progress: item.sourceProgress,
              workId: item.payload['workId']?.toString().trim() ?? '',
            ))
        .where((item) => item.workId.isNotEmpty)
        .toList()
      ..sort((a, b) => a.progress.compareTo(b.progress));
    return scoped.isEmpty ? null : scoped.last.workId;
  }

  /// Produces the chapter-level projection used by long timelines. Filtering
  /// happens before grouping so the page can render one bounded chapter page
  /// without building every event widget in the book.
  List<FictionTimelineChapter> timelineChapters(
    Iterable<FictionTimelineEvent> input, {
    FictionTimelineDensity density = FictionTimelineDensity.compact,
    Set<String> kinds = const {},
    String? participant,
  }) {
    final normalizedParticipant = participant?.trim();
    final filtered = input.where((event) {
      if (!_includedAtDensity(event, density)) return false;
      if (kinds.isNotEmpty && !kinds.contains(event.kind)) return false;
      if (normalizedParticipant != null &&
          normalizedParticipant.isNotEmpty &&
          !event.participants.contains(normalizedParticipant)) {
        return false;
      }
      return true;
    });
    final grouped = <String, List<FictionTimelineEvent>>{};
    final titles = <String, String>{};
    for (final event in filtered) {
      final href = event.source.chapterHref?.trim() ?? '';
      final title = event.source.chapterTitle?.trim() ?? '';
      final key = href.isNotEmpty
          ? href
          : title.isNotEmpty
              ? 'title:$title'
              : 'progress:${(event.source.sourceProgress * 1000).floor()}';
      grouped.putIfAbsent(key, () => []).add(event);
      titles[key] = title.isEmpty ? '未知章节' : title;
    }
    return grouped.entries.map((entry) {
      final events = entry.value
        ..sort((a, b) => _artifactOrder(a.source, b.source));
      return FictionTimelineChapter(
        id: entry.key,
        title: titles[entry.key]!,
        startProgress: events.first.source.sourceProgress,
        events: List.unmodifiable(events),
      );
    }).toList(growable: false)
      ..sort((a, b) => a.startProgress.compareTo(b.startProgress));
  }

  List<FictionStoryStage> storyStages(
    List<FictionTimelineChapter> chapters, {
    int maxStages = 5,
  }) {
    if (chapters.isEmpty) return const [];
    final stageCount = maxStages.clamp(1, chapters.length);
    final perStage = (chapters.length / stageCount).ceil();
    final stages = <FictionStoryStage>[];
    for (var offset = 0; offset < chapters.length; offset += perStage) {
      final slice =
          chapters.skip(offset).take(perStage).toList(growable: false);
      stages.add(FictionStoryStage(
        index: stages.length + 1,
        startProgress: slice.first.startProgress,
        endProgress: slice.last.events.last.source.sourceProgress,
        chapterIds: List.unmodifiable(slice.map((chapter) => chapter.id)),
        eventCount:
            slice.fold(0, (sum, chapter) => sum + chapter.events.length),
      ));
    }
    return List.unmodifiable(stages);
  }

  List<FictionMysteryThread> mysteryThreads(
      Iterable<FictionTimelineEvent> events) {
    final all = events.toList(growable: false);
    final clues = all.where((event) => event.isClue).toList(growable: false);
    return all.where((event) => event.isMystery).map((mystery) {
      final keys = {
        mystery.id,
        mystery.title.trim().toLowerCase(),
        mystery.source.payload['question']?.toString().trim().toLowerCase() ??
            '',
      }..remove('');
      final related = clues.where((clue) {
        final payload = clue.source.payload;
        final refs = <String>{
          payload['mysteryId']?.toString() ?? '',
          payload['relatedMysteryId']?.toString() ?? '',
          payload['mystery']?.toString() ?? '',
          payload['relatedMystery']?.toString() ?? '',
          if (payload['mysteryIds'] is List)
            ...(payload['mysteryIds'] as List).map((value) => value.toString()),
        }.map((value) => value.trim().toLowerCase()).toSet();
        return refs.any(keys.contains);
      }).toList()
        ..sort((a, b) => _artifactOrder(a.source, b.source));
      return FictionMysteryThread(
        mystery: mystery,
        events: List.unmodifiable([mystery, ...related]),
      );
    }).toList(growable: false);
  }

  List<FictionTimelineEvent> relationshipTimeline(FictionStoryAtlas atlas) {
    final names = {
      for (final character in atlas.characters) character.id: character.name
    };
    final result = <FictionTimelineEvent>[];
    for (final edge in atlas.relationships) {
      for (final artifact in edge.history) {
        final from = names[edge.from] ?? edge.from;
        final to = names[edge.to] ?? edge.to;
        final relation = _text(artifact.payload['relation'], fallback: '关系变化');
        result.add(FictionTimelineEvent(
          id: 'relationship:${artifact.id}',
          title: '$from与$to：$relation',
          summary: _text(artifact.payload['summary']),
          kind: ReadingArtifactKinds.relationship,
          participants: [from, to],
          storyTimeLabel: null,
          source: artifact,
        ));
      }
    }
    result.sort((a, b) => _artifactOrder(a.source, b.source));
    return List.unmodifiable(result);
  }

  bool _includedAtDensity(
    FictionTimelineEvent event,
    FictionTimelineDensity density,
  ) =>
      switch (density) {
        FictionTimelineDensity.compact =>
          event.isMajor || event.isMystery || event.isClue,
        FictionTimelineDensity.standard =>
          event.kind != ReadingArtifactKinds.scene,
        FictionTimelineDensity.complete => true,
      };

  FictionStoryAtlas fromArtifacts(
    Iterable<ReadingArtifact> input, {
    required double visibleAtProgress,
    String? workId,
    String? arcId,
  }) {
    final visibleArtifacts = input
        .where((item) =>
            item.isVisibleAtProgress(visibleAtProgress) &&
            item.status == ReadingArtifactStatus.active)
        .toList(growable: false);
    final effectiveWorkId =
        workId ?? currentWorkId(visibleArtifacts, visibleAtProgress);
    final workArtifacts = _filterByWork(visibleArtifacts, effectiveWorkId);
    final effectiveArcId =
        arcId ?? currentArcId(workArtifacts, visibleAtProgress);
    final artifacts = _filterByArc(workArtifacts, effectiveArcId);
    final characterIndex = _buildCharacterIndex(artifacts);
    final characters = <String, FictionCharacterNode>{
      for (final character in characterIndex.characters)
        character.id: character,
    };
    final unresolvedCharacters = <String, String>{};

    final relationshipArtifacts = artifacts
        .where((item) => item.kind == ReadingArtifactKinds.relationship)
        .toList()
      ..sort(_artifactOrder);
    final grouped = <String, List<ReadingArtifact>>{};
    final endpoints = <String, ({String from, String to})>{};
    for (final artifact in relationshipArtifacts) {
      final artifactArc = artifact.payload['arcId']?.toString().trim() ?? '';
      if (effectiveArcId != null &&
          artifactArc.isNotEmpty &&
          artifactArc != effectiveArcId) {
        // A relationship from another case is only useful when it explicitly
        // connects two already-known book-wide characters. Do not create an
        // unresolved node here: that would leak the other case into the
        // focused graph.
        final knownFrom =
            characterIndex.resolve(_text(artifact.payload['from']));
        final knownTo = characterIndex.resolve(_text(artifact.payload['to']));
        if (knownFrom == null || knownTo == null) continue;
        final hasMainEndpoint = _isMainCharacter(characters[knownFrom]) ||
            _isMainCharacter(characters[knownTo]);
        if (!hasMainEndpoint) continue;
      }
      final from = _resolveRelationshipEndpoint(
        _text(artifact.payload['from']),
        characterIndex,
        characters,
        unresolvedCharacters,
        artifact,
      );
      final to = _resolveRelationshipEndpoint(
        _text(artifact.payload['to']),
        characterIndex,
        characters,
        unresolvedCharacters,
        artifact,
      );
      // A one-character Chinese reference is normally a model-generated
      // abbreviation. If it is ambiguous or unknown, hiding this edge is
      // safer than rendering a duplicate character such as "第五伦" + "伦".
      if (from == null || to == null || from == to) continue;
      endpoints[artifact.id] = (from: from, to: to);
      final key = [from, to]..sort();
      grouped.putIfAbsent(key.join('|'), () => []).add(artifact);
    }
    final relationships = <FictionRelationshipEdge>[];
    for (final history in grouped.values) {
      history.sort(_artifactOrder);
      final latest = history.last;
      final endpoint = endpoints[latest.id]!;
      relationships.add(FictionRelationshipEdge(
        from: endpoint.from,
        to: endpoint.to,
        relation: _text(latest.payload['relation'], fallback: '其他'),
        summary: _text(latest.payload['summary']),
        state: _text(latest.payload['state'], fallback: 'active'),
        history: List.unmodifiable(history),
        source: latest,
      ));
    }

    // Older or partially valid extraction batches may reference a named
    // person from an event without emitting a matching character Artifact.
    // Keep those source-backed names visible in the atlas instead of silently
    // dropping them from the graph. Opaque IDs and ambiguous one-character
    // Chinese references are deliberately ignored.
    for (final artifact in artifacts.where((item) => const {
          ReadingArtifactKinds.event,
          ReadingArtifactKinds.scene,
          ReadingArtifactKinds.clue,
          ReadingArtifactKinds.mystery,
        }.contains(item.kind))) {
      for (final participant in _list(artifact.payload['participants'])) {
        _ensureReferencedCharacter(
          participant,
          characterIndex,
          characters,
          unresolvedCharacters,
          artifact,
        );
      }
    }

    final timelineKinds = {
      ReadingArtifactKinds.event,
      ReadingArtifactKinds.scene,
      ReadingArtifactKinds.clue,
      ReadingArtifactKinds.mystery,
    };
    final timeline = artifacts
        .where((item) => timelineKinds.contains(item.kind))
        .map((artifact) => _timelineEvent(
              artifact,
              characterIndex,
              characters,
            ))
        .toList()
      ..sort((a, b) => _artifactOrder(a.source, b.source));
    final ingested = artifacts.map((item) => item.ingestedAt).toList();
    final progress = artifacts.map((item) => item.sourceProgress).toList();
    final organizedProgress = artifacts
        .where((item) =>
            item.ingestionMode == ReadingArtifactIngestionMode.backfill)
        .map((item) => item.sourceProgress)
        .toList();
    return FictionStoryAtlas(
      characters: List.unmodifiable(characters.values),
      relationships: List.unmodifiable(relationships),
      timeline: List.unmodifiable(timeline),
      visibleProgress: visibleAtProgress.clamp(0, 1).toDouble(),
      coverageStart: progress.isEmpty ? null : progress.reduce(_min),
      coverageEnd: progress.isEmpty ? null : progress.reduce(_max),
      lastOrganizedProgress:
          organizedProgress.isEmpty ? null : organizedProgress.reduce(_max),
      lastIngestedAt: ingested.isEmpty ? null : ingested.reduce(_maxInt),
      workId: effectiveWorkId,
      arcId: effectiveArcId,
    );
  }

  List<ReadingArtifact> _filterByWork(
    List<ReadingArtifact> artifacts,
    String? workId,
  ) {
    if (workId == null || workId.isEmpty) return artifacts;
    return artifacts.where((artifact) {
      final artifactWork = artifact.payload['workId']?.toString().trim() ?? '';
      // Legacy artifacts remain visible for compatibility. Once a work scope
      // exists, artifacts explicitly assigned to another work never cross it.
      return artifactWork.isEmpty || artifactWork == workId;
    }).toList(growable: false);
  }

  List<ReadingArtifact> _filterByArc(
    List<ReadingArtifact> artifacts,
    String? arcId,
  ) {
    if (arcId == null || arcId.isEmpty) return artifacts;
    return artifacts.where((artifact) {
      final payloadArc = artifact.payload['arcId']?.toString().trim() ?? '';
      // Legacy/global artifacts have no scope and remain available. Scoped
      // artifacts from another case are hidden from both graph and timeline.
      if (payloadArc.isEmpty || payloadArc == arcId) return true;
      // Main cast metadata is book-wide and should remain visible while the
      // reader is inside a case. A global scope is an explicit opt-in for the
      // same behavior; all other scoped artifacts belong to another arc.
      if (artifact.kind == ReadingArtifactKinds.character) {
        final role = artifact.payload['role']?.toString().trim().toLowerCase();
        final scope =
            artifact.payload['scope']?.toString().trim().toLowerCase();
        return scope == 'global' ||
            role == 'main_character' ||
            role == 'main' ||
            role == 'protagonist' ||
            role == '主角';
      }
      // Relationships are checked against the current/main cast while the
      // projection is assembled; keeping them here lets that pass inspect
      // endpoint identity without exposing unrelated case events.
      return artifact.kind == ReadingArtifactKinds.relationship;
    }).toList(growable: false);
  }

  bool _isMainCharacter(FictionCharacterNode? character) {
    if (character == null) return false;
    final role =
        character.source.payload['role']?.toString().trim().toLowerCase();
    final scope =
        character.source.payload['scope']?.toString().trim().toLowerCase();
    return scope == 'global' ||
        role == 'main_character' ||
        role == 'main' ||
        role == 'protagonist' ||
        role == '主角';
  }

  FictionTimelineEvent _timelineEvent(
    ReadingArtifact artifact,
    _CharacterIdentityIndex characterIndex,
    Map<String, FictionCharacterNode> characters,
  ) {
    final payload = artifact.payload;
    final title = _text(
      payload['title'],
      fallback: artifact.kind == ReadingArtifactKinds.scene
          ? '场景'
          : artifact.kind == ReadingArtifactKinds.mystery
              ? '未解悬念'
              : artifact.kind == ReadingArtifactKinds.clue
                  ? '线索'
                  : '故事事件',
    );
    final participants = _list(payload['participants']).map((value) {
      final id = characterIndex.resolve(value);
      return id == null ? value : characters[id]?.name ?? value;
    }).toList(growable: false);
    return FictionTimelineEvent(
      id: artifact.id,
      title: title,
      summary: _text(
        payload['summary'],
        fallback: _text(payload['question']),
      ),
      kind: artifact.kind,
      participants: participants,
      storyTimeLabel: _nullableText(payload['storyTimeLabel']),
      source: artifact,
    );
  }

  FictionCharacterNode _placeholder(
          String id, String name, ReadingArtifact source) =>
      FictionCharacterNode(
        id: id,
        name: name,
        summary: '',
        aliases: const [],
        source: source,
      );

  String? _resolveRelationshipEndpoint(
    String value,
    _CharacterIdentityIndex index,
    Map<String, FictionCharacterNode> characters,
    Map<String, String> unresolved,
    ReadingArtifact source,
  ) {
    final known = index.resolve(value);
    if (known != null) return known;
    final name = _cleanReference(value);
    if (name.isEmpty ||
        index.containsReference(name) ||
        _isLikelyShortChineseReference(name)) {
      return null;
    }
    final key = _normalize(name);
    final existing = unresolved[key];
    if (existing != null) return existing;
    var id = 'unresolved:$key';
    var suffix = 2;
    while (characters.containsKey(id)) {
      id = 'unresolved:$key:$suffix';
      suffix++;
    }
    unresolved[key] = id;
    characters[id] = _placeholder(id, name, source);
    return id;
  }

  String? _ensureReferencedCharacter(
    String value,
    _CharacterIdentityIndex index,
    Map<String, FictionCharacterNode> characters,
    Map<String, String> unresolved,
    ReadingArtifact source,
  ) {
    final known = index.resolve(value);
    if (known != null) return known;
    final name = _cleanReference(value);
    if (!_isRenderableCharacterReference(name)) return null;
    final key = _normalize(name);
    final existing = unresolved[key];
    if (existing != null) return existing;
    final id = 'unresolved:$key';
    if (characters.containsKey(id)) return id;
    unresolved[key] = id;
    characters[id] = _placeholder(id, name, source);
    return id;
  }

  bool _isRenderableCharacterReference(String value) {
    if (value.isEmpty || value.length > 80) return false;
    if (_isLikelyShortChineseReference(value)) return false;
    final normalized = _normalize(value);
    const genericReferences = {
      '他们',
      '她们',
      '众人',
      '某人',
      '男人',
      '女人',
      '老人',
      '孩子',
      '主角',
      'protagonist',
      'narrator',
      'unknown',
    };
    if (genericReferences.contains(normalized)) return false;
    if (RegExp(r'^(character|person|char|role)[_:#-]?\d+$',
            caseSensitive: false)
        .hasMatch(normalized)) {
      return false;
    }
    if (normalized.contains('_') || normalized.contains('://')) return false;
    return RegExp(
      r"^[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaffA-Za-zÀ-ÖØ-öø-ÿ'’·•. -]+$",
    ).hasMatch(value);
  }

  _CharacterIdentityIndex _buildCharacterIndex(
      List<ReadingArtifact> artifacts) {
    final records = artifacts
        .where((item) => item.kind == ReadingArtifactKinds.character)
        .map((artifact) {
          final payload = artifact.payload;
          final name = _cleanReference(_text(payload['name']));
          if (name.isEmpty) return null;
          final namingSystem = _namingSystem(payload, name);
          final parsedAliases = _parseIdentityAliases(
            _list(payload['aliases'])
                .map(_cleanReference)
                .where((value) => value.isNotEmpty)
                .toList(growable: false),
          );
          return _CharacterRecord(
            name: name,
            entityId: _normalizeNarratorEntityId(
              _cleanReference(_text(payload['entityId'])),
            ),
            summary: _text(payload['summary']),
            namingSystem: namingSystem,
            courtesyNames: List.unmodifiable({
              ..._values(
                payload,
                const ['courtesyName', 'courtesyNames', 'styleName', 'zi', '字'],
              ),
              ...parsedAliases.courtesyNames,
            }),
            artNames: List.unmodifiable({
              ..._values(
                payload,
                const ['artName', 'artNames', 'hao', '号'],
              ),
              ...parsedAliases.artNames,
            }),
            titles: List.unmodifiable({
              ..._values(
                payload,
                const ['title', 'titles', 'honorifics', '称谓'],
              ),
              ...parsedAliases.titles,
            }),
            givenName: _nullableCleanText(payload['givenName']),
            familyName: _nullableCleanText(payload['familyName']),
            aliases: parsedAliases.aliases,
            source: artifact,
          );
        })
        .whereType<_CharacterRecord>()
        .toList()
      ..sort((a, b) => _artifactOrder(a.source, b.source));
    if (records.isEmpty) {
      return _CharacterIdentityIndex(
        characters: const [],
        fullNames: const {},
        entityIds: const {},
        aliases: const {},
        normalize: _normalize,
        clean: _cleanReference,
      );
    }

    final parents = List<int>.generate(records.length, (index) => index);
    int find(int value) {
      var root = value;
      while (parents[root] != root) {
        root = parents[root];
      }
      while (parents[value] != value) {
        final next = parents[value];
        parents[value] = root;
        value = next;
      }
      return root;
    }

    void union(int left, int right) {
      final leftRoot = find(left);
      final rightRoot = find(right);
      if (leftRoot != rightRoot) parents[rightRoot] = leftRoot;
    }

    final nameOwners = <String, int>{};
    final idOwners = <String, List<int>>{};
    for (var index = 0; index < records.length; index++) {
      final record = records[index];
      final nameKey = _normalize(record.name);
      final nameOwner = nameOwners[nameKey];
      if (nameOwner != null) union(index, nameOwner);
      nameOwners.putIfAbsent(nameKey, () => index);
      if (record.entityId.isNotEmpty) {
        final idKey = _normalize(record.entityId);
        final owners = idOwners[idKey] ?? const <int>[];
        for (final owner in owners) {
          if (_compatibleIdentity(record, records[owner])) {
            union(index, owner);
          }
        }
        idOwners.putIfAbsent(idKey, () => <int>[]).add(index);
      }
    }

    // Explicit culture-aware identity fields are stronger than a generic
    // alias: Chinese 字/号 and Western aliases can bridge separate extraction
    // passes, but only when both the alias owner and matching name are unique.
    final identityAliasOwners = <String, Set<int>>{};
    for (var index = 0; index < records.length; index++) {
      for (final alias in records[index].mergeableIdentityAliases) {
        identityAliasOwners
            .putIfAbsent(_normalize(alias), () => <int>{})
            .add(find(index));
      }
    }
    for (final entry in identityAliasOwners.entries) {
      final aliasRoots = entry.value.map(find).toSet();
      final nameOwner = nameOwners[entry.key];
      if (aliasRoots.length == 1 && nameOwner != null) {
        union(aliasRoots.single, find(nameOwner));
      }
    }

    // Older extraction results sometimes promoted a one-character reference
    // to a standalone person ("伦"), while a later pass emitted the full
    // name ("第五伦"). Merge only when that suffix identifies exactly one
    // longer-name cluster. If both "第五伦" and "周伦" exist, keep "伦"
    // unresolved rather than guessing.
    final shortNameRecords = <String, Set<int>>{};
    final suffixCandidates = <String, Set<int>>{};
    for (var index = 0; index < records.length; index++) {
      final record = records[index];
      final runes = record.name.runes.toList(growable: false);
      if (runes.length == 1 && _isLikelyShortChineseReference(record.name)) {
        shortNameRecords
            .putIfAbsent(_normalize(record.name), () => <int>{})
            .add(find(index));
      } else if (runes.length > 1) {
        final suffix = String.fromCharCode(runes.last);
        suffixCandidates
            .putIfAbsent(_normalize(suffix), () => <int>{})
            .add(find(index));
      }
    }
    for (final entry in shortNameRecords.entries) {
      final shortRoots = entry.value.map(find).toSet();
      final longRoots =
          (suffixCandidates[entry.key] ?? const <int>{}).map(find).toSet();
      if (shortRoots.length == 1 && longRoots.length == 1) {
        union(shortRoots.single, longRoots.single);
      }
    }

    final westernShortRecords = <String, Set<int>>{};
    final westernPartCandidates = <String, Set<int>>{};
    for (var index = 0; index < records.length; index++) {
      final record = records[index];
      if (record.namingSystem != 'western') continue;
      final parts = _westernNameParts(record.name);
      if (parts.length == 1) {
        westernShortRecords
            .putIfAbsent(parts.single, () => <int>{})
            .add(find(index));
      } else if (parts.length > 1) {
        for (final part in {parts.first, parts.last}) {
          westernPartCandidates
              .putIfAbsent(part, () => <int>{})
              .add(find(index));
        }
      }
    }
    for (final entry in westernShortRecords.entries) {
      final shortRoots = entry.value.map(find).toSet();
      final longRoots =
          (westernPartCandidates[entry.key] ?? const <int>{}).map(find).toSet();
      if (shortRoots.length == 1 && longRoots.length == 1) {
        union(shortRoots.single, longRoots.single);
      }
    }

    final grouped = <int, List<_CharacterRecord>>{};
    for (var index = 0; index < records.length; index++) {
      grouped.putIfAbsent(find(index), () => []).add(records[index]);
    }
    final characters = <FictionCharacterNode>[];
    final fullNames = <String, String>{};
    final entityIds = <String, Set<String>>{};
    final aliases = <String, Set<String>>{};
    for (final group in grouped.values) {
      group.sort((a, b) => _artifactOrder(a.source, b.source));
      final preferred = _preferredRecord(group);
      // The model-provided entityId is an input alias, not the ViewModel's
      // identity. Deriving the canonical ID from the normalized full name
      // keeps it stable when separate chapter batches invent different IDs.
      final canonicalId =
          'character:${Uri.encodeComponent(_normalize(preferred.name))}';
      final displayAliases = <String>{};
      final courtesyNames = <String>{};
      final artNames = <String>{};
      final titles = <String>{};
      for (final record in group) {
        fullNames[_normalize(record.name)] = canonicalId;
        if (record.entityId.isNotEmpty) {
          entityIds
              .putIfAbsent(_normalize(record.entityId), () => <String>{})
              .add(canonicalId);
        }
        if (_normalize(record.name) != _normalize(preferred.name)) {
          displayAliases.add(record.name);
        }
        displayAliases.addAll(record.aliases);
        courtesyNames.addAll(record.courtesyNames);
        artNames.addAll(record.artNames);
        titles.addAll(record.titles);
      }
      displayAliases.removeWhere(
        (value) =>
            _normalize(value) == _normalize(preferred.name) ||
            courtesyNames
                .any((item) => _normalize(item) == _normalize(value)) ||
            artNames.any((item) => _normalize(item) == _normalize(value)) ||
            titles.any((item) => _normalize(item) == _normalize(value)),
      );
      final summaryRecord = group.firstWhere(
        (record) => record.summary.isNotEmpty,
        orElse: () => preferred,
      );
      characters.add(FictionCharacterNode(
        id: canonicalId,
        name: preferred.name,
        summary: summaryRecord.summary,
        aliases: List.unmodifiable(displayAliases),
        source: preferred.source,
        namingSystem: preferred.namingSystem,
        courtesyNames: List.unmodifiable(courtesyNames),
        artNames: List.unmodifiable(artNames),
        titles: List.unmodifiable(titles),
        givenName: _firstNonNull(group.map((record) => record.givenName)),
        familyName: _firstNonNull(group.map((record) => record.familyName)),
      ));
      for (final alias in {
        ...displayAliases,
        ...courtesyNames,
        ...artNames,
        ...titles,
      }) {
        aliases
            .putIfAbsent(_normalize(alias), () => <String>{})
            .add(canonicalId);
      }
    }
    _addUniqueShortNameAliases(characters, fullNames, entityIds, aliases);
    _addUniqueWesternNameAliases(characters, fullNames, entityIds, aliases);
    return _CharacterIdentityIndex(
      characters: List.unmodifiable(characters),
      fullNames: Map.unmodifiable(fullNames),
      entityIds: Map.unmodifiable({
        for (final entry in entityIds.entries)
          entry.key: Set.unmodifiable(entry.value),
      }),
      aliases: Map.unmodifiable({
        for (final entry in aliases.entries)
          entry.key: Set.unmodifiable(entry.value),
      }),
      normalize: _normalize,
      clean: _cleanReference,
    );
  }

  String _normalizeNarratorEntityId(String value) =>
      value == 'narrator.primary' ? 'narrator.outer' : value;

  int _characterRecordPreference(
      _CharacterRecord left, _CharacterRecord right) {
    final length = _normalize(right.name)
        .runes
        .length
        .compareTo(_normalize(left.name).runes.length);
    if (length != 0) return length;
    final source = _artifactOrder(left.source, right.source);
    if (source != 0) return source;
    return left.name.compareTo(right.name);
  }

  _CharacterRecord _preferredRecord(List<_CharacterRecord> group) {
    final alternateNames = <String>{
      for (final record in group) ...record.courtesyNames.map(_normalize),
      for (final record in group) ...record.artNames.map(_normalize),
      for (final record in group) ...record.titles.map(_normalize),
    };
    final formal = group
        .where((record) => !alternateNames.contains(_normalize(record.name)))
        .toList(growable: false);
    final candidates = formal.isEmpty ? group : formal;
    return candidates.reduce((left, right) =>
        _characterRecordPreference(left, right) <= 0 ? left : right);
  }

  bool _compatibleIdentity(_CharacterRecord left, _CharacterRecord right) {
    final leftName = _normalize(left.name);
    final rightName = _normalize(right.name);
    if (leftName == rightName) return true;
    if (left.identityAliases.any((alias) => _normalize(alias) == rightName) ||
        right.identityAliases.any((alias) => _normalize(alias) == leftName)) {
      return true;
    }
    return (leftName.length < rightName.length &&
            rightName.endsWith(leftName)) ||
        (rightName.length < leftName.length && leftName.endsWith(rightName));
  }

  String? _firstNonNull(Iterable<String?> values) {
    for (final value in values) {
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  List<String> _westernNameParts(String value) {
    const honorifics = {
      'mr',
      'mrs',
      'miss',
      'ms',
      'dr',
      'sir',
      'lady',
      'lord',
      'professor',
      'captain',
      'colonel',
      'reverend',
    };
    final parts = _normalize(value)
        .split(RegExp(r'[\s·•]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length > 1 && honorifics.contains(parts.first)) {
      parts.removeAt(0);
    }
    return parts;
  }

  String _cleanReference(String value) {
    var result =
        value.replaceAll('\u3000', ' ').trim().replaceAll(RegExp(r'\s+'), ' ');
    const pairs = {
      '"': '"',
      "'": "'",
      '“': '”',
      '‘': '’',
      '「': '」',
      '『': '』',
    };
    while (result.length >= 2 &&
        pairs[result.substring(0, 1)] == result.substring(result.length - 1)) {
      result = result.substring(1, result.length - 1).trim();
    }
    final withoutSpaces = result.replaceAll(' ', '');
    return withoutSpaces.isNotEmpty &&
            RegExp(r'^[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]+$')
                .hasMatch(withoutSpaces)
        ? withoutSpaces
        : result;
  }

  String _namingSystem(Map<String, dynamic> payload, String name) {
    final declared = _text(payload['namingSystem']).toLowerCase();
    if (declared == 'chinese' || declared == 'western') return declared;
    return _isChineseText(name) ? 'chinese' : 'western';
  }

  String? _nullableCleanText(Object? value) {
    final result = _cleanReference(_text(value));
    return result.isEmpty ? null : result;
  }

  List<String> _values(Map<String, dynamic> payload, List<String> keys) {
    final result = <String>{};
    for (final key in keys) {
      final value = payload[key];
      if (value is List) {
        result.addAll(value.map((item) => _cleanReference(item.toString())));
      } else {
        final text = _cleanReference(_text(value));
        if (text.isNotEmpty) result.add(text);
      }
    }
    result.remove('');
    return List.unmodifiable(result);
  }

  ({
    List<String> aliases,
    List<String> courtesyNames,
    List<String> artNames,
    List<String> titles,
  }) _parseIdentityAliases(List<String> values) {
    final aliases = <String>[];
    final courtesyNames = <String>[];
    final artNames = <String>[];
    final titles = <String>[];
    for (final value in values) {
      final match = RegExp(r'^(字|号|称谓|尊称|官职)[：:\s]*(.+)$').firstMatch(value);
      if (match == null) {
        aliases.add(value);
        continue;
      }
      final kind = match.group(1);
      final name = _cleanReference(match.group(2) ?? '');
      if (name.isEmpty) continue;
      if (kind == '字') {
        courtesyNames.add(name);
      } else if (kind == '号') {
        artNames.add(name);
      } else {
        titles.add(name);
      }
    }
    return (
      aliases: List.unmodifiable(aliases),
      courtesyNames: List.unmodifiable(courtesyNames),
      artNames: List.unmodifiable(artNames),
      titles: List.unmodifiable(titles),
    );
  }

  bool _isChineseText(String value) {
    final compact = value.replaceAll(' ', '');
    return compact.isNotEmpty &&
        RegExp(r'^[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]+$')
            .hasMatch(compact);
  }

  String _normalize(String value) {
    var cleaned = _cleanReference(value)
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‘', "'");
    final withoutSpaces = cleaned.replaceAll(' ', '');
    if (_isChineseText(withoutSpaces)) return withoutSpaces;
    cleaned = cleaned
        .replaceAll('.', '')
        .replaceAll(RegExp(r'\s*-\s*'), '-')
        .replaceAll(RegExp(r'\s+'), ' ');
    final comma = cleaned.split(',');
    if (comma.length == 2 && comma.every((part) => part.trim().isNotEmpty)) {
      cleaned = '${comma[1].trim()} ${comma[0].trim()}';
    }
    return cleaned;
  }

  bool _isLikelyShortChineseReference(String value) =>
      value.runes.length == 1 &&
      RegExp(r'^[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]$').hasMatch(value);

  void _addUniqueShortNameAliases(
    List<FictionCharacterNode> characters,
    Map<String, String> fullNames,
    Map<String, Set<String>> entityIds,
    Map<String, Set<String>> aliases,
  ) {
    final candidates = <String, Set<String>>{};
    for (final character in characters) {
      final name = character.name.trim();
      if (name.runes.length < 2) continue;
      final last = String.fromCharCode(name.runes.last);
      candidates
          .putIfAbsent(_normalize(last), () => <String>{})
          .add(character.id);
    }
    for (final entry in candidates.entries) {
      if (entry.value.length == 1 &&
          !fullNames.containsKey(entry.key) &&
          !entityIds.containsKey(entry.key)) {
        aliases
            .putIfAbsent(entry.key, () => <String>{})
            .add(entry.value.single);
      }
    }
  }

  void _addUniqueWesternNameAliases(
    List<FictionCharacterNode> characters,
    Map<String, String> fullNames,
    Map<String, Set<String>> entityIds,
    Map<String, Set<String>> aliases,
  ) {
    final candidates = <String, Set<String>>{};
    for (final character in characters) {
      if (character.namingSystem != 'western') continue;
      final parts = _westernNameParts(character.name);
      if (parts.length < 2) continue;
      for (final part in {parts.first, parts.last}) {
        candidates.putIfAbsent(part, () => <String>{}).add(character.id);
      }
    }
    for (final entry in candidates.entries) {
      if (!fullNames.containsKey(entry.key) &&
          !entityIds.containsKey(entry.key)) {
        aliases.putIfAbsent(entry.key, () => <String>{}).addAll(entry.value);
      }
    }
  }

  String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String? _nullableText(Object? value) {
    final text = _text(value);
    return text.isEmpty ? null : text;
  }

  List<String> _list(Object? value) => value is List
      ? value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList()
      : const [];

  int _artifactOrder(ReadingArtifact a, ReadingArtifact b) {
    final progress = a.sourceProgress.compareTo(b.sourceProgress);
    if (progress != 0) return progress;
    final href = (a.chapterHref ?? '').compareTo(b.chapterHref ?? '');
    if (href != 0) return href;
    final cfi = (a.sourceStartCfi ?? a.discoveredAtCfi ?? '')
        .compareTo(b.sourceStartCfi ?? b.discoveredAtCfi ?? '');
    if (cfi != 0) return cfi;
    final created = a.createdAt.compareTo(b.createdAt);
    if (created != 0) return created;
    return a.id.compareTo(b.id);
  }

  double _min(double a, double b) => a < b ? a : b;
  double _max(double a, double b) => a > b ? a : b;
  int _maxInt(int a, int b) => a > b ? a : b;
}

const fictionStoryAtlasService = FictionStoryAtlasService();

class _CharacterRecord {
  const _CharacterRecord({
    required this.name,
    required this.entityId,
    required this.summary,
    required this.aliases,
    required this.namingSystem,
    required this.courtesyNames,
    required this.artNames,
    required this.titles,
    required this.givenName,
    required this.familyName,
    required this.source,
  });

  final String name;
  final String entityId;
  final String summary;
  final List<String> aliases;
  final String namingSystem;
  final List<String> courtesyNames;
  final List<String> artNames;
  final List<String> titles;
  final String? givenName;
  final String? familyName;
  final ReadingArtifact source;

  Iterable<String> get identityAliases sync* {
    yield* aliases;
    yield* courtesyNames;
    yield* artNames;
    yield* titles;
    if (givenName != null) yield givenName!;
    if (familyName != null) yield familyName!;
  }

  Iterable<String> get mergeableIdentityAliases sync* {
    yield* courtesyNames;
    yield* artNames;
    // Western aliases commonly represent a title form, given name, surname,
    // nickname, or translated spelling of the same person.
    if (namingSystem == 'western') yield* aliases;
  }
}

class _CharacterIdentityIndex {
  const _CharacterIdentityIndex({
    required this.characters,
    required this.fullNames,
    required this.entityIds,
    required this.aliases,
    required String Function(String) normalize,
    required String Function(String) clean,
  })  : _normalize = normalize,
        _clean = clean;

  final List<FictionCharacterNode> characters;
  final Map<String, String> fullNames;
  final Map<String, Set<String>> entityIds;
  final Map<String, Set<String>> aliases;
  final String Function(String) _normalize;
  final String Function(String) _clean;

  String? resolve(String raw) {
    final value = _clean(raw);
    if (value.isEmpty) return null;
    final key = _normalize(value);
    // A full name always wins over model-generated IDs and aliases. Model IDs
    // are accepted only when they identify exactly one canonical person.
    final byName = fullNames[key];
    if (byName != null) return byName;
    final byId = entityIds[key];
    if (byId?.length == 1) return byId!.single;
    final candidates = aliases[key];
    return candidates?.length == 1 ? candidates!.single : null;
  }

  bool containsReference(String raw) {
    final value = _clean(raw);
    if (value.isEmpty) return false;
    final key = _normalize(value);
    return fullNames.containsKey(key) ||
        entityIds.containsKey(key) ||
        aliases.containsKey(key);
  }
}
