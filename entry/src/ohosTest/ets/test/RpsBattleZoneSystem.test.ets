import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import { RpsBattleZoneSystem } from '../../../main/ets/games/rpsBattle/RpsBattleZoneSystem';
import {
  RpsBattleControlZone,
  RpsBattleEntity,
  RpsBattleFaction
} from '../../../main/ets/games/rpsBattle/RpsBattleTypes';
import { rpsBattleBuildResult, rpsBattleCreateOptions } from '../../../main/ets/games/rpsBattle/RpsBattleRules';

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

    it('awards score only to the unique pressure leader',
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
      expect(Math.round(zone.scores.rock * 10)).assertEqual(56);
      expect(zone.scores.scissors).assertEqual(0);
      expect(zone.scores.paper).assertEqual(0);
    });

    it('retains each faction score after a counter-capture',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleZoneSystem();
      system.reset(400, 300);

      system.update([
        createEntity(1, 'rock', 200, 150),
        createEntity(2, 'rock', 206, 150)
      ], 1);
      system.update([
        createEntity(3, 'paper', 200, 150),
        createEntity(4, 'paper', 206, 150),
        createEntity(5, 'paper', 194, 150)
      ], 1);
      const zone = system.snapshot() as RpsBattleControlZone;

      expect(Math.round(zone.scores.rock * 10)).assertEqual(56);
      expect(Math.round(zone.scores.paper * 10)).assertEqual(84);
      expect(zone.owner).assertEqual('paper');
      expect(system.timeWinner()).assertEqual('paper');
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
      expect(zone.scores.rock).assertEqual(0);
      expect(zone.scores.scissors).assertEqual(0);
      expect(zone.scores.paper).assertEqual(0);
      expect(system.timeWinner()).assertEqual('');
    });

    it('ends at the first faction that reaches the score limit',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleZoneSystem();
      system.reset(400, 300);

      system.update([createEntity(1, 'scissors', 200, 150)], 40);

      const zone = system.snapshot() as RpsBattleControlZone;
      expect(zone.scores.scissors).assertEqual(100);
      expect(system.finishWinner()).assertEqual('scissors');
    });

    it('uses zone scores rather than living count for a timed zone result',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const result = rpsBattleBuildResult(
        rpsBattleCreateOptions(
          { rock: 12, scissors: 2, paper: 1 },
          60,
          'paper',
          'zones'
        ),
        { rock: 12, scissors: 2, paper: 1 },
        60,
        8,
        'time',
        'scissors',
        true
      );

      expect(result.finishReason).assertEqual('time');
      expect(result.winner).assertEqual('scissors');
      expect(result.supportWon).assertEqual(false);
    });

    it('returns a draw when timed zone scores are tied',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const result = rpsBattleBuildResult(
        rpsBattleCreateOptions(
          { rock: 12, scissors: 2, paper: 1 },
          60,
          'paper',
          'zones'
        ),
        { rock: 12, scissors: 2, paper: 1 },
        60,
        8,
        'time',
        '',
        true
      );

      expect(result.finishReason).assertEqual('draw');
      expect(result.winner).assertEqual('');
    });
  });
}
