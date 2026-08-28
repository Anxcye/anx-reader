import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';

enum ReadingIntervention { none, passiveCapsule }

/// Pure local policy. It can expose a capsule, but it can never authorize a
/// model request, modal, banner, notification, or persistent Agent write.
class ReadingInterventionPolicy {
  const ReadingInterventionPolicy();

  ReadingIntervention decide({
    required ReadingWorldState state,
    required bool controlsVisible,
    required bool dismissedForSession,
    ReadingClosurePolicyDefinition? closurePolicy,
    bool resumeContextAvailable = false,
    bool coverageSetupPending = false,
  }) {
    final checkpointVisible = closurePolicy?.checkpointTriggersCapsule ?? true;
    final hasVisibleState = state.activeGoal != null ||
        state.unresolvedDifficultyCount > 0 ||
        state.pendingProfileCount > 0 ||
        state.lastAgentAction != null ||
        (checkpointVisible && state.pendingCheckpointCount > 0) ||
        resumeContextAvailable ||
        coverageSetupPending;
    if (!controlsVisible || dismissedForSession || !hasVisibleState) {
      return ReadingIntervention.none;
    }
    return ReadingIntervention.passiveCapsule;
  }
}
