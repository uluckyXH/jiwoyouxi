import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  RPS_BATTLE_POWER_UP_FIRST_DELAY_SEC,
  RPS_BATTLE_POWER_UP_MAX_ACTIVE,
  RpsBattlePowerUpSystem
} from '../../../main/ets/games/rpsBattle/RpsBattlePowerUpSystem';
import {
  RpsBattleEntity,
  RpsBattlePowerUpPickup,
  RpsBattlePowerUpState
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

export default function rpsBattlePowerUpSystemTest(): void {
  describe('RpsBattlePowerUpSystemTest', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
    it('spawns the first power up after the tuned fast delay', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattlePowerUpSystem();
      system.reset(0);
      system.updateSpawnAndExpire(true, RPS_BATTLE_POWER_UP_FIRST_DELAY_SEC - 0.1, 360, 520,
        randomSequence([0, 0.5, 0.5, 0.5]));
      expect(system.snapshot()).assertEqual(null);

      system.updateSpawnAndExpire(true, RPS_BATTLE_POWER_UP_FIRST_DELAY_SEC, 360, 520,
        randomSequence([0, 0.5, 0.5, 0.5]));
      const state = system.snapshot() as RpsBattlePowerUpState;
      expect(state.items.length).assertEqual(1);
      expect(state.items[0].kind).assertEqual('speed');
      expect(state.spawnedCount).assertEqual(1);
    });

    it('keeps at most the tuned active power up limit', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattlePowerUpSystem();
      system.reset(0);
      for (let i = 0; i < 8; i += 1) {
        system.updateSpawnAndExpire(true, 5 + i * 12, 360, 520, randomSequence([0.2, 0.5, 0.5, 0.5]));
      }
      const state = system.snapshot() as RpsBattlePowerUpState;
      expect(Math.min(state.items.length, RPS_BATTLE_POWER_UP_MAX_ACTIVE)).assertEqual(state.items.length);
    });

    it('cycles power up kinds so shield and split are visible during play', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattlePowerUpSystem();
      system.reset(0);
      system.updateSpawnAndExpire(true, 3, 360, 520, randomSequence([0.5, 0.5, 0.5, 0.5]));
      system.updateSpawnAndExpire(true, 7.5, 360, 520, randomSequence([0.5, 0.5, 0.5, 0.5]));
      system.updateSpawnAndExpire(true, 12, 360, 520, randomSequence([0.5, 0.5, 0.5, 0.5]));
      const state = system.snapshot() as RpsBattlePowerUpState;
      expect(state.items[0].kind).assertEqual('speed');
      expect(state.items[1].kind).assertEqual('shield');
      expect(state.items[2].kind).assertEqual('split');
    });

    it('removes an item after pickup and records team pickup intent', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattlePowerUpSystem();
      system.reset(0);
      system.updateSpawnAndExpire(true, 5, 360, 520, randomSequence([0.4, 0, 0, 0.5]));
      const before = system.snapshot() as RpsBattlePowerUpState;
      const item = before.items[0];
      const entities: RpsBattleEntity[] = [createEntity(7, item.x, item.y)];
      const pickups: RpsBattlePowerUpPickup[] = system.collect(entities, 5.1, true);
      const after = system.snapshot() as RpsBattlePowerUpState;

      expect(pickups.length).assertEqual(1);
      expect(pickups[0].collectorId).assertEqual(7);
      expect(pickups[0].isTeam).assertEqual(true);
      expect(after.items.length).assertEqual(0);
      expect(after.pickedCount).assertEqual(1);
      expect(after.teamEffectCount).assertEqual(1);
    });

    it('clears all items when the mechanism is disabled', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattlePowerUpSystem();
      system.reset(0);
      system.updateSpawnAndExpire(true, 5, 360, 520, randomSequence([0.8, 0.5, 0.5, 0.5]));
      expect((system.snapshot() as RpsBattlePowerUpState).items.length).assertEqual(1);

      system.updateSpawnAndExpire(false, 5.2, 360, 520, randomSequence([0.5]));
      expect(system.snapshot()).assertEqual(null);
    });
  });
}
