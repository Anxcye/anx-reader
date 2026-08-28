import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:anx_reader/service/ai/reading_coach_repository.dart';

class ReadingOutcomesSnapshot {
  const ReadingOutcomesSnapshot({
    this.goals = const [],
    this.pendingCheckpoints = const [],
    this.masteryStates = const [],
    this.difficulties = const [],
    this.knowledgeCards = const [],
    this.memories = const [],
    this.artifacts = const [],
    required this.loadedAt,
  });

  final List<ReadingGoal> goals;
  final List<ReadingChapterCheckpoint> pendingCheckpoints;
  final List<MasteryState> masteryStates;
  final List<ReadingDifficulty> difficulties;
  final List<KnowledgeCard> knowledgeCards;
  final List<ReadingMemoryDocument> memories;
  final List<ReadingArtifact> artifacts;
  final DateTime loadedAt;

  ReadingGoal? get activeGoal => goals
      .where((goal) => goal.status == ReadingGoalStatus.active)
      .firstOrNull;

  List<ReadingDifficulty> get unresolvedDifficulties => difficulties
      .where((item) => item.status == ReadingDifficultyStatus.unresolved)
      .toList(growable: false);

  List<KnowledgeCard> get activeCards => knowledgeCards
      .where((card) => card.status == 'active')
      .toList(growable: false);

  List<KnowledgeCard> get dueCards {
    final now = loadedAt.millisecondsSinceEpoch;
    return activeCards
        .where((card) => card.dueAt != null && card.dueAt! <= now)
        .toList(growable: false)
      ..sort((left, right) => left.dueAt!.compareTo(right.dueAt!));
  }

  double get masteryProgress {
    if (masteryStates.isEmpty) return 0;
    final total = masteryStates.fold<double>(
      0,
      (sum, state) => sum + state.score.clamp(0, 1),
    );
    return total / masteryStates.length;
  }

  bool get isEmpty =>
      goals.isEmpty &&
      pendingCheckpoints.isEmpty &&
      masteryStates.isEmpty &&
      unresolvedDifficulties.isEmpty &&
      activeCards.isEmpty &&
      memories.isEmpty &&
      artifacts.isEmpty;
}

class ReadingOutcomesService {
  ReadingOutcomesService({
    ReadingAgentRepository? agentRepository,
    ReadingCoachRepository? coachRepository,
  })  : _agentRepository = agentRepository ?? readingAgentRepository,
        _coachRepository = coachRepository ?? ReadingCoachRepository();

  final ReadingAgentRepository _agentRepository;
  final ReadingCoachRepository _coachRepository;

  Future<ReadingOutcomesSnapshot> load(int bookId) async {
    final results = await Future.wait<dynamic>([
      _agentRepository.goals(bookId),
      _agentRepository.pendingCheckpoints(bookId),
      _agentRepository.masteryStates(bookId),
      _coachRepository.loadDifficulties(bookId),
      _agentRepository.knowledgeCards(bookId),
      _agentRepository.memoryDocuments(bookId),
      _agentRepository.artifacts(bookId),
    ]);
    return ReadingOutcomesSnapshot(
      goals: results[0] as List<ReadingGoal>,
      pendingCheckpoints: results[1] as List<ReadingChapterCheckpoint>,
      masteryStates: results[2] as List<MasteryState>,
      difficulties: results[3] as List<ReadingDifficulty>,
      knowledgeCards: results[4] as List<KnowledgeCard>,
      memories: results[5] as List<ReadingMemoryDocument>,
      artifacts: results[6] as List<ReadingArtifact>,
      loadedAt: DateTime.now(),
    );
  }
}

final readingOutcomesService = ReadingOutcomesService();
