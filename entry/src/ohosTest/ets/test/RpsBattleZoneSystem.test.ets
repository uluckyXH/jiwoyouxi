import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import { RpsBattleZoneSystem } from '../../../main/ets/games/rpsBattle/RpsBattleZoneSystem';
import {
  RpsBattleControlZone,
  RpsBattleEntity,
  RpsBattleFaction
} from '../../../main/ets/games/rpsBattle/RpsBattleTypes';

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
    traitorRageUntilSec: 0,
    convertedAt: 0
  };
}

export default function rpsBattleZoneSystemTest(): void {
  describe('RpsBattleZoneSystemTest', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
    it('counts pressure inside the center zone',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleZoneSystem();
      system.reset(400, 300);

      const insideCount = system.update([
        createEntity(1, 'rock', 200, 150),
        createEntity(2, 'rock', 206, 150),
        createEntity(3, 'scissors', 20, 20)
      ], 1);
      const zone = system.snapshot() as RpsBattleControlZone;

      expect(insideCount).assertEqual(2);
      expect(zone.pressure.rock).assertEqual(2);
      expect(zone.pressure.scissors).assertEqual(0);
      expect(zone.pressure.paper).assertEqual(0);
    });

    it('scores only when one faction uniquely leads pressure',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleZoneSystem();
      system.reset(400, 300);

      system.update([
        createEntity(1, 'rock', 200, 150),
        createEntity(2, 'rock', 206, 150),
        createEntity(3, 'paper', 300, 240)
      ], 1);
      const zone = system.snapshot() as RpsBattleControlZone;

      expect(zone.owner).assertEqual('rock');
      expect(zone.capturingFaction).assertEqual('rock');
      expect(Math.round(zone.score * 10)).assertEqual(56);
    });

    it('does not score while the zone is contested',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleZoneSystem();
      system.reset(400, 300);

      system.update([
        createEntity(1, 'rock', 200, 150),
        createEntity(2, 'scissors', 206, 150)
      ], 1);
      const zone = system.snapshot() as RpsBattleControlZone;

      expect(zone.owner).assertEqual('');
      expect(zone.capturingFaction).assertEqual('');
      expect(zone.score).assertEqual(0);
    });
  });
}
