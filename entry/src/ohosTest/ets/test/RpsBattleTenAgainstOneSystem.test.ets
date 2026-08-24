import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  RPS_BATTLE_TEN_AGAINST_ONE_ELIGIBLE_SEC,
  RPS_BATTLE_TEN_AGAINST_ONE_INTRO_SEC,
  RPS_BATTLE_TEN_AGAINST_ONE_RAGE_SEC,
  RPS_BATTLE_TEN_AGAINST_ONE_SPEED_MULTIPLIER,
  RpsBattleTenAgainstOneSystem
} from '../../../main/ets/games/rpsBattle/RpsBattleTenAgainstOneSystem';
import {
  RpsBattleEntity,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleTenAgainstOneState
} from '../../../main/ets/games/rpsBattle/RpsBattleTypes';

function createCounts(rock: number, scissors: number, paper: number): RpsBattleFactionCounts {
  return {
    rock: rock,
    scissors: scissors,
    paper: paper
  };
}

function createEntity(id: number, faction: RpsBattleFaction): RpsBattleEntity {
  return {
    id: id,
    faction: faction,
    x: 100,
    y: 100,
    vx: 0,
    vy: 0,
    radius: 14,
    shield: 0,
    speedBoostUntilSec: 0,
    traitorRageUntilSec: 0,
    convertedAt: 0
  };
}

export default function rpsBattleTenAgainstOneSystemTest(): void {
  describe('RpsBattleTenAgainstOneSystemTest', () => {
    it('requires a sustained ten-to-one matchup, then freezes for the intro', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleTenAgainstOneSystem();
      const counts = createCounts(1, 0, 10);
      system.reset(true);

      system.update(counts, 0, 30);
      system.update(counts, RPS_BATTLE_TEN_AGAINST_ONE_ELIGIBLE_SEC - 0.1, 30);
      expect((system.snapshot() as RpsBattleTenAgainstOneState).phase).assertEqual('waiting');

      const triggerAtSec = RPS_BATTLE_TEN_AGAINST_ONE_ELIGIBLE_SEC + 0.2;
      system.update(counts, triggerAtSec, 30);
      const intro = system.snapshot() as RpsBattleTenAgainstOneState;
      expect(intro.phase).assertEqual('intro');
      expect(intro.underdog).assertEqual('rock');
      expect(intro.majority).assertEqual('paper');
      expect(system.isSimulationFrozen()).assertEqual(true);
    });

    it('lets the underdog remove the matching majority during rage', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleTenAgainstOneSystem();
      const counts = createCounts(1, 0, 10);
      const triggerAtSec = RPS_BATTLE_TEN_AGAINST_ONE_ELIGIBLE_SEC + 0.2;
      system.reset(true);
      system.update(counts, 0, 30);
      system.update(counts, triggerAtSec, 30);
      system.update(counts, triggerAtSec + RPS_BATTLE_TEN_AGAINST_ONE_INTRO_SEC, 30);

      expect((system.snapshot() as RpsBattleTenAgainstOneState).phase).assertEqual('rage');
      expect(system.speedMultiplier('rock')).assertEqual(RPS_BATTLE_TEN_AGAINST_ONE_SPEED_MULTIPLIER);
      const eliminated = system.resolveCollision(createEntity(1, 'rock'), createEntity(2, 'paper'));
      expect(eliminated === null).assertEqual(false);
      if (eliminated !== null) {
        expect(eliminated.id).assertEqual(2);
      }

      system.update(counts, triggerAtSec + RPS_BATTLE_TEN_AGAINST_ONE_INTRO_SEC +
        RPS_BATTLE_TEN_AGAINST_ONE_RAGE_SEC, 30);
      const completed = system.snapshot() as RpsBattleTenAgainstOneState;
      expect(completed.phase).assertEqual('completed');
      expect(completed.triggerCount).assertEqual(1);
    });

    it('does not start when the remaining match time cannot contain the event', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleTenAgainstOneSystem();
      const counts = createCounts(1, 0, 10);
      system.reset(true);

      system.update(counts, 18, 30);
      system.update(counts, 19.1, 30);
      const state = system.snapshot() as RpsBattleTenAgainstOneState;
      expect(state.phase).assertEqual('waiting');
      expect(state.triggerCount).assertEqual(0);
    });

    it('does not expose state while disabled', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleTenAgainstOneSystem();
      system.reset(false);
      system.update(createCounts(1, 0, 10), 3, 30);

      expect(system.snapshot()).assertEqual(null);
      expect(system.speedMultiplier('rock')).assertEqual(1);
    });
  });
}
