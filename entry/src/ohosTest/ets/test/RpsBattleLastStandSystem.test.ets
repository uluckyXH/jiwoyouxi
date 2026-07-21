import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  RPS_BATTLE_LAST_STAND_REINFORCEMENT_COOLDOWN_SEC,
  RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC,
  RPS_BATTLE_LAST_STAND_REVIVE_TRIGGER_COUNT,
  RpsBattleLastStandSystem
} from '../../../main/ets/games/rpsBattle/RpsBattleLastStandSystem';
import {
  RpsBattleEntity,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleLastStandState,
  RpsBattleSpawnRequest
} from '../../../main/ets/games/rpsBattle/RpsBattleTypes';

function randomSequence(values: number[]): () => number {
  let index = 0;
  return (): number => {
    if (index >= values.length) {
      return 0.5;
    }
    const value = values[index];
    index += 1;
    return value;
  };
}

function createEntity(id: number, faction: RpsBattleFaction, x: number, y: number): RpsBattleEntity {
  return {
    id: id,
    faction: faction,
    x: x,
    y: y,
    vx: 0,
    vy: 0,
    radius: 14,
    shield: 0,
    speedBoostUntilSec: 0,
    convertedAt: 0
  };
}

function counts(rock: number, scissors: number, paper: number): RpsBattleFactionCounts {
  return {
    rock: rock,
    scissors: scissors,
    paper: paper
  };
}

export default function rpsBattleLastStandSystemTest(): void {
  describe('RpsBattleLastStandSystemTest', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
    it('creates a revive mark when a faction drops to the tuned trigger count',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleLastStandSystem();
      const previousEntities: RpsBattleEntity[] = [
        createEntity(1, 'rock', 120, 130),
        createEntity(2, 'rock', 124, 134),
        createEntity(3, 'rock', 128, 138),
        createEntity(4, 'rock', 132, 142)
      ];
      const currentEntities: RpsBattleEntity[] = [
        createEntity(1, 'rock', 120, 130),
        createEntity(2, 'rock', 124, 134),
        createEntity(3, 'rock', 128, 138)
      ];
      system.reset(previousEntities, counts(4, 0, 0), 400, 300);

      const requests: RpsBattleSpawnRequest[] = system.update(currentEntities,
        counts(RPS_BATTLE_LAST_STAND_REVIVE_TRIGGER_COUNT, 0, 0), 1, 400, 300, randomSequence([0.1]));
      const state = system.snapshot() as RpsBattleLastStandState;

      expect(requests.length).assertEqual(0);
      expect(state.reviveMarks.length).assertEqual(1);
      expect(state.reviveMarks[0].faction).assertEqual('rock');
      expect(state.reviveMarks[0].dueAtSec).assertEqual(1 + RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC);
      expect(system.hasPendingReviveMarks()).assertEqual(true);
    });

    it('turns the revive mark into a revive request after the tuned fast delay',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleLastStandSystem();
      const previousEntities: RpsBattleEntity[] = [
        createEntity(1, 'scissors', 220, 160),
        createEntity(2, 'scissors', 224, 164),
        createEntity(3, 'scissors', 228, 168),
        createEntity(4, 'scissors', 232, 172)
      ];
      const currentEntities: RpsBattleEntity[] = [
        createEntity(1, 'scissors', 220, 160),
        createEntity(2, 'scissors', 224, 164),
        createEntity(3, 'scissors', 228, 168)
      ];
      system.reset(previousEntities, counts(0, 4, 0), 400, 300);
      system.update(currentEntities, counts(0, RPS_BATTLE_LAST_STAND_REVIVE_TRIGGER_COUNT, 0), 1, 400, 300,
        randomSequence([0.1]));
      system.completeFrame(currentEntities, counts(0, RPS_BATTLE_LAST_STAND_REVIVE_TRIGGER_COUNT, 0));

      const earlyRequests: RpsBattleSpawnRequest[] = system.update(currentEntities,
        counts(0, RPS_BATTLE_LAST_STAND_REVIVE_TRIGGER_COUNT, 0),
        1 + RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC - 0.1, 400, 300, randomSequence([0.1]));
      const dueRequests: RpsBattleSpawnRequest[] = system.update(currentEntities,
        counts(0, RPS_BATTLE_LAST_STAND_REVIVE_TRIGGER_COUNT, 0),
        1 + RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC, 400, 300, randomSequence([0.1]));

      expect(earlyRequests.length).assertEqual(0);
      expect(dueRequests.length).assertEqual(1);
      expect(dueRequests[0].faction).assertEqual('scissors');
      expect(dueRequests[0].eventKind).assertEqual('revive');
      expect(system.hasPendingReviveMarks()).assertEqual(false);
      expect(system.lastFrameReviveCount()).assertEqual(1);
    });

    it('does not create duplicate revive marks while one is already pending',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleLastStandSystem();
      const previousEntities: RpsBattleEntity[] = [
        createEntity(1, 'paper', 240, 180),
        createEntity(2, 'paper', 244, 184),
        createEntity(3, 'paper', 248, 188),
        createEntity(4, 'paper', 252, 192)
      ];
      const currentEntities: RpsBattleEntity[] = [
        createEntity(1, 'paper', 240, 180),
        createEntity(2, 'paper', 244, 184),
        createEntity(3, 'paper', 248, 188)
      ];
      system.reset(previousEntities, counts(0, 0, 4), 400, 300);
      system.update(currentEntities, counts(0, 0, RPS_BATTLE_LAST_STAND_REVIVE_TRIGGER_COUNT), 1, 400, 300,
        randomSequence([0.1]));
      system.completeFrame(currentEntities, counts(0, 0, RPS_BATTLE_LAST_STAND_REVIVE_TRIGGER_COUNT));

      const lowerEntities: RpsBattleEntity[] = [
        createEntity(1, 'paper', 240, 180),
        createEntity(2, 'paper', 244, 184)
      ];
      system.update(lowerEntities, counts(0, 0, 2), 1.5, 400, 300, randomSequence([0.1]));
      const state = system.snapshot() as RpsBattleLastStandState;

      expect(state.reviveMarks.length).assertEqual(1);
    });

    it('can schedule another reinforcement after a wiped faction passes cooldown',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleLastStandSystem();
      system.reset([createEntity(1, 'rock', 220, 160)], counts(1, 0, 0), 400, 300);
      system.update([], counts(0, 0, 0), 1, 400, 300, randomSequence([0.1]));
      system.completeFrame([], counts(0, 0, 0));

      const firstRevive: RpsBattleSpawnRequest[] = system.update([], counts(0, 0, 0),
        1 + RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC, 400, 300, randomSequence([0.1]));
      system.completeFrame([], counts(0, 0, 0));
      const cooldownBlocked: RpsBattleSpawnRequest[] = system.update([], counts(0, 0, 0),
        1 + RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC + 1, 400, 300, randomSequence([0.1]));
      const stateDuringCooldown = system.snapshot() as RpsBattleLastStandState;

      system.completeFrame([], counts(0, 0, 0));
      const cooldownReady: RpsBattleSpawnRequest[] = system.update([], counts(0, 0, 0),
        1 + RPS_BATTLE_LAST_STAND_REVIVE_DELAY_SEC + RPS_BATTLE_LAST_STAND_REINFORCEMENT_COOLDOWN_SEC,
        400, 300, randomSequence([0.1]));
      const stateAfterCooldown = system.snapshot() as RpsBattleLastStandState;

      expect(firstRevive.length).assertEqual(1);
      expect(cooldownBlocked.length).assertEqual(0);
      expect(stateDuringCooldown.reviveMarks.length).assertEqual(0);
      expect(cooldownReady.length).assertEqual(0);
      expect(stateAfterCooldown.reviveMarks.length).assertEqual(1);
      expect(stateAfterCooldown.reviveMarks[0].faction).assertEqual('rock');
    });
  });
}
