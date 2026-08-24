import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  RPS_BATTLE_BOUNTY_PULSE_DURATION_SEC,
  RPS_BATTLE_BOUNTY_WARMUP_SEC,
  RpsBattleBountySystem
} from '../../../main/ets/games/rpsBattle/RpsBattleBountySystem';
import { RpsBattleBountyState, RpsBattleFactionCounts } from '../../../main/ets/games/rpsBattle/RpsBattleTypes';

function createCounts(rock: number, scissors: number, paper: number): RpsBattleFactionCounts {
  return {
    rock: rock,
    scissors: scissors,
    paper: paper
  };
}

export default function rpsBattleBountySystemTest(): void {
  describe('RpsBattleBountySystemTest', () => {
    it('waits for the opening window before marking a qualified leader', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleBountySystem();
      const dominantCounts = createCounts(13, 6, 5);
      system.reset(true);

      system.update(dominantCounts, RPS_BATTLE_BOUNTY_WARMUP_SEC - 0.1);
      expect((system.snapshot() as RpsBattleBountyState).active).assertEqual(false);

      system.update(dominantCounts, RPS_BATTLE_BOUNTY_WARMUP_SEC);
      const state = system.snapshot() as RpsBattleBountyState;
      expect(state.active).assertEqual(true);
      expect(state.leader).assertEqual('rock');
      expect(system.shouldHunt('rock')).assertEqual(false);
      expect(system.shouldHunt('scissors')).assertEqual(true);
    });

    it('removes the bounty when the lead no longer meets the threshold', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleBountySystem();
      system.reset(true);
      system.update(createCounts(13, 6, 5), RPS_BATTLE_BOUNTY_WARMUP_SEC);
      expect((system.snapshot() as RpsBattleBountyState).active).assertEqual(true);

      system.update(createCounts(12, 6, 6), RPS_BATTLE_BOUNTY_WARMUP_SEC + 0.5);
      const state = system.snapshot() as RpsBattleBountyState;
      expect(state.active).assertEqual(false);
      expect(state.leader).assertEqual('');
    });

    it('awards only a conversion of the active leader and expires its visual pulse', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleBountySystem();
      const elapsedSec = RPS_BATTLE_BOUNTY_WARMUP_SEC;
      system.reset(true);
      system.update(createCounts(13, 6, 5), elapsedSec);

      expect(system.registerReward('rock', 'scissors', 120, 80, elapsedSec + 0.1)).assertEqual(true);
      expect(system.registerReward('scissors', 'rock', 120, 80, elapsedSec + 0.1)).assertEqual(false);
      const rewarded = system.snapshot() as RpsBattleBountyState;
      expect(rewarded.rewardCount).assertEqual(1);
      expect(rewarded.pulses.length).assertEqual(1);
      expect(rewarded.pulses[0].faction).assertEqual('scissors');

      system.update(createCounts(13, 6, 5), elapsedSec + 0.1 + RPS_BATTLE_BOUNTY_PULSE_DURATION_SEC);
      expect((system.snapshot() as RpsBattleBountyState).pulses.length).assertEqual(0);
    });

    it('does not expose state while disabled', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleBountySystem();
      system.reset(false);
      system.update(createCounts(20, 2, 2), 10);

      expect(system.snapshot()).assertEqual(null);
      expect(system.shouldHunt('scissors')).assertEqual(false);
    });
  });
}
