import 'package:anx_reader/service/ai/reading_agent_runtime.dart';
import 'package:anx_reader/service/ai/reading_intervention_policy.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('policy only exposes a passive capsule when state is present', () {
    const policy = ReadingInterventionPolicy();
    expect(
        policy.decide(
          state: const ReadingWorldState(unresolvedDifficultyCount: 1),
          controlsVisible: true,
          dismissedForSession: false,
        ),
        ReadingIntervention.passiveCapsule);
    expect(
        policy.decide(
          state: const ReadingWorldState(unresolvedDifficultyCount: 1),
          controlsVisible: false,
          dismissedForSession: false,
        ),
        ReadingIntervention.none);
    expect(
        policy.decide(
          state: const ReadingWorldState(pendingCheckpointCount: 1),
          controlsVisible: true,
          dismissedForSession: true,
        ),
        ReadingIntervention.none);
  });

  test('fiction checkpoint alone never surfaces the capsule', () {
    const policy = ReadingInterventionPolicy();
    expect(
      policy.decide(
        state: const ReadingWorldState(pendingCheckpointCount: 2),
        controlsVisible: true,
        dismissedForSession: false,
        closurePolicy: ReadingClosurePolicyRegistry.fictionImmersion,
      ),
      ReadingIntervention.none,
    );
    expect(
      policy.decide(
        state: const ReadingWorldState(
          pendingCheckpointCount: 2,
          unresolvedDifficultyCount: 1,
        ),
        controlsVisible: true,
        dismissedForSession: false,
        closurePolicy: ReadingClosurePolicyRegistry.fictionImmersion,
      ),
      ReadingIntervention.passiveCapsule,
    );
  });

  test('resume context is exposed only as a passive capsule', () {
    const policy = ReadingInterventionPolicy();
    expect(
      policy.decide(
        state: const ReadingWorldState(),
        controlsVisible: true,
        dismissedForSession: false,
        closurePolicy: ReadingClosurePolicyRegistry.fictionImmersion,
        resumeContextAvailable: true,
      ),
      ReadingIntervention.passiveCapsule,
    );
    expect(
      policy.decide(
        state: const ReadingWorldState(),
        controlsVisible: false,
        dismissedForSession: false,
        closurePolicy: ReadingClosurePolicyRegistry.fictionImmersion,
        resumeContextAvailable: true,
      ),
      ReadingIntervention.none,
    );
  });

  test('mid-book setup is exposed only as a passive capsule', () {
    const policy = ReadingInterventionPolicy();
    expect(
      policy.decide(
        state: const ReadingWorldState(),
        controlsVisible: true,
        dismissedForSession: false,
        coverageSetupPending: true,
      ),
      ReadingIntervention.passiveCapsule,
    );
    expect(
      policy.decide(
        state: const ReadingWorldState(),
        controlsVisible: false,
        dismissedForSession: false,
        coverageSetupPending: true,
      ),
      ReadingIntervention.none,
    );
  });
}
