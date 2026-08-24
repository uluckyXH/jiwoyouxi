import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  RPS_BATTLE_GOD_HAND_CHARGES,
  RPS_BATTLE_GOD_HAND_COOLDOWN_SEC,
  RpsBattleGodHandSystem
} from '../../../main/ets/games/rpsBattle/RpsBattleGodHandSystem';
import { RpsBattleEntity, RpsBattleGodHandState } from '../../../main/ets/games/rpsBattle/RpsBattleTypes';

function createEntity(id: number, x: number, y: number): RpsBattleEntity {
  return {
    id: id,
    faction: 'rock',
    x: x,
    y: y,
    vx: 0,
    vy: 0,
    radius: 14,
    shield: 0,
    speedBoostUntilSec: 0,
    traitorRageUntilSec: 0,
    convertedAt: 0
  };
}

export default function rpsBattleGodHandSystemTest(): void {
  describe('RpsBattleGodHandSystemTest', () => {
    it('applies a push pulse and enforces its cooldown', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleGodHandSystem();
      const entity = createEntity(1, 150, 100);
      system.reset(true);

      expect((system.snapshot() as RpsBattleGodHandState).chargesRemaining).assertEqual(RPS_BATTLE_GOD_HAND_CHARGES);
      expect(system.requestPulse(100, 100, 'push', 0)).assertEqual(true);
      expect(system.update([entity], 0.1, 0.1)).assertEqual(1);
      expect(entity.vx > 0).assertEqual(true);
      expect(system.requestPulse(100, 100, 'push', 0.2)).assertEqual(false);
    });

    it('applies a pull pulse after cooldown and consumes another charge', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleGodHandSystem();
      const entity = createEntity(2, 150, 100);
      system.reset(true);
      expect(system.requestPulse(100, 100, 'push', 0)).assertEqual(true);

      entity.vx = 0;
      expect(system.requestPulse(100, 100, 'pull', RPS_BATTLE_GOD_HAND_COOLDOWN_SEC)).assertEqual(true);
      expect(system.update([entity], RPS_BATTLE_GOD_HAND_COOLDOWN_SEC + 0.1, 0.1)).assertEqual(1);
      expect(entity.vx < 0).assertEqual(true);
      const state = system.snapshot() as RpsBattleGodHandState;
      expect(state.mode).assertEqual('pull');
      expect(state.chargesRemaining).assertEqual(RPS_BATTLE_GOD_HAND_CHARGES - 2);
    });

    it('ignores disabled matches and entities outside the pulse radius', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleGodHandSystem();
      const farEntity = createEntity(3, 400, 100);
      system.reset(false);

      expect(system.requestPulse(100, 100, 'push', 0)).assertEqual(false);
      expect(system.snapshot()).assertEqual(null);

      system.reset(true);
      expect(system.requestPulse(100, 100, 'push', 0)).assertEqual(true);
      expect(system.update([farEntity], 0.1, 0.1)).assertEqual(0);
      expect(farEntity.vx).assertEqual(0);
    });

    it('clears an active field when paused without restoring charges or bypassing cooldown', TestType.FUNCTION |
      Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleGodHandSystem();
      system.reset(true);
      expect(system.requestPulse(100, 100, 'push', 0)).assertEqual(true);

      system.clearTransient();
      const state = system.snapshot() as RpsBattleGodHandState;
      expect(state.pulseStartedAtSec).assertEqual(-1);
      expect(state.pulseEndsAtSec).assertEqual(-1);
      expect(state.cooldownEndsAtSec).assertEqual(RPS_BATTLE_GOD_HAND_COOLDOWN_SEC);
      expect(state.chargesRemaining).assertEqual(RPS_BATTLE_GOD_HAND_CHARGES - 1);
    });
  });
}
