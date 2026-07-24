import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  RPS_BATTLE_SHRINK_DELAY_SEC,
  RPS_BATTLE_SHRINK_MAX_PADDING_RATIO,
  RPS_BATTLE_SHRINK_SPEED,
  RPS_BATTLE_SHRINK_WARNING_SEC,
  RpsBattleShrinkSystem
} from '../../../main/ets/games/rpsBattle/RpsBattleShrinkSystem';
import { RpsBattleShrinkState } from '../../../main/ets/games/rpsBattle/RpsBattleTypes';

export default function rpsBattleShrinkSystemTest(): void {
  describe('RpsBattleShrinkSystemTest', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
    it('shows warning but does not advance before the shrink delay',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleShrinkSystem();
      system.reset(400, 300);

      system.update(RPS_BATTLE_SHRINK_WARNING_SEC, 1, 400, 300);
      const state = system.snapshot() as RpsBattleShrinkState;

      expect(state.active).assertEqual(true);
      expect(state.padding).assertEqual(0);
      expect(state.bounds.left).assertEqual(0);
      expect(state.bounds.right).assertEqual(400);
    });

    it('advances padding after the shrink delay',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleShrinkSystem();
      system.reset(400, 300);

      system.update(RPS_BATTLE_SHRINK_DELAY_SEC, 1, 400, 300);
      const state = system.snapshot() as RpsBattleShrinkState;

      expect(state.active).assertEqual(true);
      expect(state.padding).assertEqual(RPS_BATTLE_SHRINK_SPEED);
      expect(state.bounds.left).assertEqual(RPS_BATTLE_SHRINK_SPEED);
      expect(state.bounds.top).assertEqual(RPS_BATTLE_SHRINK_SPEED);
    });

    it('caps padding by the tuned short-side ratio',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleShrinkSystem();
      system.reset(400, 300);

      system.update(RPS_BATTLE_SHRINK_DELAY_SEC + 100, 100, 400, 300);
      const state = system.snapshot() as RpsBattleShrinkState;
      const expectedMax = 300 * RPS_BATTLE_SHRINK_MAX_PADDING_RATIO;

      expect(state.padding).assertEqual(expectedMax);
      expect(state.progress).assertEqual(1);
    });

    it('keeps a playable inner area when the board is narrow',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleShrinkSystem();
      system.reset(240, 240);

      system.update(RPS_BATTLE_SHRINK_DELAY_SEC + 100, 100, 240, 240);
      const state = system.snapshot() as RpsBattleShrinkState;

      expect(state.bounds.left < state.bounds.right).assertEqual(true);
      expect(state.bounds.top < state.bounds.bottom).assertEqual(true);
      expect(state.bounds.left <= 240 * 0.38).assertEqual(true);
      expect(state.bounds.right >= 240 * 0.62).assertEqual(true);
    });

    it('recomputes bounds after resize',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleShrinkSystem();
      system.reset(400, 300);
      system.update(RPS_BATTLE_SHRINK_DELAY_SEC, 1, 400, 300);

      system.resize(500, 360);
      const state = system.snapshot() as RpsBattleShrinkState;

      expect(state.bounds.right).assertEqual(500 - RPS_BATTLE_SHRINK_SPEED);
      expect(state.bounds.bottom).assertEqual(360 - RPS_BATTLE_SHRINK_SPEED);
    });
  });
}
