import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';

class FictionCharacterRecall {
  const FictionCharacterRecall({
    required this.name,
    required this.summary,
    this.relationships = const [],
    this.aliases = const [],
    required this.source,
    required this.epistemicStatus,
  });

  final String name;
  final String summary;
  final List<String> relationships;
  final List<String> aliases;
  final ReadingArtifact source;
  final ReadingArtifactEpistemicStatus epistemicStatus;
}

class FictionResumeContext {
  const FictionResumeContext({
    this.lastScene,
    this.activeCharacters = const [],
    this.openMysteries = const [],
  });

  final String? lastScene;
  final List<String> activeCharacters;
  final List<ReadingArtifact> openMysteries;

  bool get isEmpty =>
      lastScene == null && activeCharacters.isEmpty && openMysteries.isEmpty;
}

/// Local-first fiction projections. Every query applies the reader's current
/// progress before matching names or building a resume, so future artifacts
/// cannot leak into an earlier reading position.
class FictionReadingService {
  FictionReadingService({ReadingAgentRepository? repository})
      : _repository = repository ?? readingAgentRepository;

  final ReadingAgentRepository _repository;

  Future<FictionCharacterRecall?> recallCharacter({
    required int bookId,
    required String query,
    required double currentProgress,
  }) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return null;
    final characters = await _repository.artifacts(
      bookId,
      kind: ReadingArtifactKinds.character,
      status: ReadingArtifactStatus.active,
      visibleAtProgress: currentProgress,
    );
    for (final artifact in characters) {
      final name = artifact.payload['name']?.toString() ?? '';
      final aliases = _strings(artifact.payload['aliases']);
      final searchable = [name, ...aliases].map((item) => item.toLowerCase());
      if (!searchable.any((item) =>
          item == needle || item.contains(needle) || needle.contains(item))) {
        continue;
      }
      return FictionCharacterRecall(
        name: name,
        summary: artifact.payload['summary']?.toString() ?? '',
        relationships: _strings(artifact.payload['relationships']),
        aliases: aliases,
        source: artifact,
        epistemicStatus: artifact.epistemicStatus,
      );
    }
    return null;
  }

  Future<List<ReadingArtifact>> mysteryLedger({
    required int bookId,
    required double currentProgress,
    bool includeResolved = true,
  }) async {
    final items = await _repository.artifacts(
      bookId,
      kind: ReadingArtifactKinds.mystery,
      visibleAtProgress: currentProgress,
    );
    return includeResolved
        ? items
        : items
            .where((item) => item.status == ReadingArtifactStatus.active)
            .toList(growable: false);
  }

  Future<FictionResumeContext> resumeContext({
    required int bookId,
    required double currentProgress,
  }) async {
    final artifacts = await _repository.artifacts(
      bookId,
      status: ReadingArtifactStatus.active,
      visibleAtProgress: currentProgress,
    );
    String? lastScene;
    final characters = <String>[];
    final mysteries = <ReadingArtifact>[];
    for (final artifact in artifacts) {
      if (lastScene == null &&
          (artifact.kind == ReadingArtifactKinds.scene ||
              artifact.kind == ReadingArtifactKinds.resumeContext)) {
        lastScene = artifact.payload['summary']?.toString();
      }
      if (artifact.kind == ReadingArtifactKinds.character &&
          characters.length < 4) {
        final name = artifact.payload['name']?.toString().trim();
        if (name?.isNotEmpty == true && !characters.contains(name)) {
          characters.add(name!);
        }
      }
      if (artifact.kind == ReadingArtifactKinds.mystery &&
          mysteries.length < 5) {
        mysteries.add(artifact);
      }
    }
    return FictionResumeContext(
      lastScene: lastScene,
      activeCharacters: characters,
      openMysteries: mysteries,
    );
  }
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

final fictionReadingService = FictionReadingService();
