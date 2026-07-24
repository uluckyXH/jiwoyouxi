import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  RPS_BATTLE_SNAP_RESOLVED_DURATION_SEC,
  RPS_BATTLE_SNAP_WARNING_DURATION_SEC,
  RPS_BATTLE_SNAP_WARNING_MIN_SEC,
  RpsBattleSnapSystem
} from '../../../main/ets/games/rpsBattle/RpsBattleSnapSystem';
import {
  RpsBattleEntity,
  RpsBattleFaction,
  RpsBattleSnapState
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

function createFactionEntities(startId: number, count: number, faction: RpsBattleFaction): RpsBattleEntity[] {
  const entities: RpsBattleEntity[] = [];
  for (let i = 0; i < count; i += 1) {
    entities.push({
      id: startId + i,
      faction: faction,
      x: 80 + i * 12,
      y: 120 + i * 8,
      vx: 0,
      vy: 0,
      radius: 14,
      shield: 0,
      speedBoostUntilSec: 0,
      traitorRageUntilSec: 0,
      convertedAt: 0
    });
  }
  return entities;
}

export default function rpsBattleSnapSystemTest(): void {
  describe('RpsBattleSnapSystemTest', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
    it('enters the mobile warning window before resolving one random half-clear', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleSnapSystem();
      const rock = createFactionEntities(1, 5, 'rock');
      const scissors = createFactionEntities(11, 4, 'scissors');
      const paper = createFactionEntities(21, 1, 'paper');
      system.reset(randomSequence([0]));

      system.update(rock, scissors, paper, RPS_BATTLE_SNAP_WARNING_MIN_SEC - 0.1, randomSequence([0]));
      expect((system.snapshot() as RpsBattleSnapState).phase).assertEqual('waiting');

      system.update(rock, scissors, paper, RPS_BATTLE_SNAP_WARNING_MIN_SEC, randomSequence([0]));
      const warning = system.snapshot() as RpsBattleSnapState;
      expect(warning.phase).assertEqual('warning');
      expect(warning.resolveAtSec).assertEqual(RPS_BATTLE_SNAP_WARNING_MIN_SEC +
        RPS_BATTLE_SNAP_WARNING_DURATION_SEC);

      const removedIds = system.update(rock, scissors, paper, warning.resolveAtSec, randomSequence([0, 0, 0]));
      const resolved = system.snapshot() as RpsBattleSnapState;
      expect(removedIds.length).assertEqual(4);
      expect(resolved.phase).assertEqual('resolved');
      expect(resolved.removed.rock).assertEqual(2);
      expect(resolved.removed.scissors).assertEqual(2);
      expect(resolved.removed.paper).assertEqual(0);
      expect(resolved.totalRemoved).assertEqual(4);
    });

    it('does not remove the final unit from a faction and never resolves twice', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleSnapSystem();
      const rock = createFactionEntities(1, 1, 'rock');
      const scissors = createFactionEntities(11, 2, 'scissors');
      const paper = createFactionEntities(21, 5, 'paper');
      system.reset(randomSequence([0]));
      const resolvedAt = RPS_BATTLE_SNAP_WARNING_MIN_SEC + RPS_BATTLE_SNAP_WARNING_DURATION_SEC;

      const first = system.update(rock, scissors, paper, resolvedAt, randomSequence([0, 0, 0]));
      const state = system.snapshot() as RpsBattleSnapState;
      const second = system.update(rock, scissors, paper,
        resolvedAt + RPS_BATTLE_SNAP_RESOLVED_DURATION_SEC + 1, randomSequence([0]));

      expect(first.length).assertEqual(3);
      expect(state.removed.rock).assertEqual(0);
      expect(state.removed.scissors).assertEqual(1);
      expect(state.removed.paper).assertEqual(2);
      expect(second.length).assertEqual(0);
      expect((system.snapshot() as RpsBattleSnapState).phase).assertEqual('completed');
    });

    it('samples removal ids without duplicates inside each faction', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleSnapSystem();
      const rock = createFactionEntities(1, 4, 'rock');
      const scissors = createFactionEntities(11, 0, 'scissors');
      const paper = createFactionEntities(21, 0, 'paper');
      system.reset(randomSequence([0]));
      const removedIds = system.update(rock, scissors, paper,
        RPS_BATTLE_SNAP_WARNING_MIN_SEC + RPS_BATTLE_SNAP_WARNING_DURATION_SEC, randomSequence([0, 0]));

      expect(removedIds.length).assertEqual(2);
      expect(removedIds[0] === removedIds[1]).assertEqual(false);
    });

    it('clears its state when the mechanic is disabled by the engine', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleSnapSystem();
      system.reset(randomSequence([0.5]));
      expect(system.snapshot() === null).assertEqual(false);
      system.clear();
      expect(system.snapshot()).assertEqual(null);
    });
  });
}
