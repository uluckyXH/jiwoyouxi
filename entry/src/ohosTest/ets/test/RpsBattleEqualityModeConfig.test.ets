import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  rpsBattleDefaultMechanicSelection,
  rpsBattleResolveModeRulesByKey,
  rpsBattleToggleMechanicSelection
} from '../../../main/ets/games/rpsBattle/RpsBattleModeConfig';

export default function rpsBattleEqualityModeConfigTest(): void {
  describe('RpsBattleEqualityModeConfigTest', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
    it('enables snap and obstacles by default while retaining deathmatch', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const selection = rpsBattleDefaultMechanicSelection('equality');
      const rules = rpsBattleResolveModeRulesByKey('equality', selection);

      expect(selection.snap).assertEqual(true);
      expect(selection.obstacles).assertEqual(true);
      expect(rules.hasDeathmatch).assertEqual(true);
      expect(rules.hasSnap).assertEqual(true);
      expect(rules.hasObstacles).assertEqual(true);
    });

    it('allows either enhanced equality mechanism to be turned off before a match', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const defaults = rpsBattleDefaultMechanicSelection('equality');
      const snapOff = rpsBattleToggleMechanicSelection('equality', defaults, 'snap');
      const bothOff = rpsBattleToggleMechanicSelection('equality', snapOff, 'obstacles');
      const rules = rpsBattleResolveModeRulesByKey('equality', bothOff);

      expect(snapOff.snap).assertEqual(false);
      expect(snapOff.obstacles).assertEqual(true);
      expect(rules.hasSnap).assertEqual(false);
      expect(rules.hasObstacles).assertEqual(false);
      expect(rules.hasDeathmatch).assertEqual(true);
    });
  });
}
