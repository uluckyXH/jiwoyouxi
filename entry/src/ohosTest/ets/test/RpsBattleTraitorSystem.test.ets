import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  RPS_BATTLE_TRAITOR_CLEAR_PROTECTION_SEC,
  RPS_BATTLE_TRAITOR_DELAY_SEC,
  RPS_BATTLE_TRAITOR_EARLY_MAX_SEC,
  RPS_BATTLE_TRAITOR_EARLY_MIN_SEC,
  RPS_BATTLE_TRAITOR_FIRST_AT_SEC,
  RPS_BATTLE_TRAITOR_INTERVAL_SEC,
  RPS_BATTLE_TRAITOR_RESCUE_DELAY_SEC,
  RpsBattleTraitorSystem
} from '../../../main/ets/games/rpsBattle/RpsBattleTraitorSystem';
import {
  RpsBattleEntity,
  RpsBattleFaction,
  RpsBattleFactionCounts,
  RpsBattleTraitorConversion,
  RpsBattleTraitorState
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

function createEntity(id: number, faction: RpsBattleFaction): RpsBattleEntity {
  return {
    id: id,
    faction: faction,
    x: 100 + id,
    y: 120 + id,
    vx: 0,
    vy: 0,
    radius: 14,
    shield: 0,
    speedBoostUntilSec: 0,
    traitorRageUntilSec: 0,
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

export default function rpsBattleTraitorSystemTest(): void {
  describe('RpsBattleTraitorSystemTest', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
    it('does not create marks before the opening window',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleTraitorSystem();
      system.reset();
      const entities: RpsBattleEntity[] = [
        createEntity(1, 'rock'),
        createEntity(2, 'scissors'),
        createEntity(3, 'paper')
      ];

      const conversions = system.update(entities, counts(1, 1, 1),
        RPS_BATTLE_TRAITOR_EARLY_MIN_SEC - 0.1, randomSequence([0.1]));

      expect(conversions.length).assertEqual(0);
      expect(system.hasPendingMarks()).assertEqual(false);
      expect(system.lastFrameMarkCount()).assertEqual(0);
    });

    it('creates one opening traitor mark in the first short mobile window',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleTraitorSystem();
      system.reset();
      const entities: RpsBattleEntity[] = [
        createEntity(1, 'rock'),
        createEntity(2, 'scissors'),
        createEntity(3, 'paper')
      ];

      system.update(entities, counts(1, 1, 1), RPS_BATTLE_TRAITOR_FIRST_AT_SEC,
        randomSequence([0.2, 0.0, 0.0, 0.7]));
      const state = system.snapshot() as RpsBattleTraitorState;

      expect(state.marks.length).assertEqual(1);
      expect(state.marks[0].fromFaction).assertEqual('rock');
      expect(state.marks[0].toFaction).assertEqual('scissors');
      expect(state.marks[0].triggerAtSec).assertEqual(RPS_BATTLE_TRAITOR_FIRST_AT_SEC +
        RPS_BATTLE_TRAITOR_DELAY_SEC);
      expect(system.lastFrameMarkCount()).assertEqual(1);
    });

    it('turns a due mark into a traitor conversion request',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleTraitorSystem();
      system.reset();
      const entities: RpsBattleEntity[] = [
        createEntity(1, 'rock'),
        createEntity(2, 'scissors'),
        createEntity(3, 'paper')
      ];
      system.update(entities, counts(1, 1, 1), RPS_BATTLE_TRAITOR_FIRST_AT_SEC,
        randomSequence([0.2, 0.0, 0.0, 0.7]));

      const earlyConversions: RpsBattleTraitorConversion[] = system.update(entities, counts(1, 1, 1),
        RPS_BATTLE_TRAITOR_FIRST_AT_SEC + RPS_BATTLE_TRAITOR_DELAY_SEC - 0.1, randomSequence([0.5]));
      const dueConversions: RpsBattleTraitorConversion[] = system.update(entities, counts(1, 1, 1),
        RPS_BATTLE_TRAITOR_FIRST_AT_SEC + RPS_BATTLE_TRAITOR_DELAY_SEC, randomSequence([0.5]));

      expect(earlyConversions.length).assertEqual(0);
      expect(dueConversions.length).assertEqual(1);
      expect(dueConversions[0].entityId).assertEqual(1);
      expect(dueConversions[0].toFaction).assertEqual('scissors');
      expect(system.lastFrameConversionCount()).assertEqual(1);
    });

    it('uses the opening traitor only once in the early window',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleTraitorSystem();
      system.reset();
      const entities: RpsBattleEntity[] = [
        createEntity(1, 'rock'),
        createEntity(2, 'scissors')
      ];
      const elapsed = (RPS_BATTLE_TRAITOR_EARLY_MIN_SEC + RPS_BATTLE_TRAITOR_EARLY_MAX_SEC) * 0.5;

      system.update(entities, counts(1, 1, 0), elapsed, randomSequence([0.0, 0.0, 0.8]));
      const firstState = system.snapshot() as RpsBattleTraitorState;
      system.update(entities, counts(1, 1, 0), elapsed + 0.5, randomSequence([0.0, 0.0, 0.8]));
      const secondState = system.snapshot() as RpsBattleTraitorState;

      expect(firstState.marks.length).assertEqual(1);
      expect(secondState.marks.length).assertEqual(1);
    });

    it('waits for the regular cooldown between trigger windows',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleTraitorSystem();
      system.reset();
      const entities: RpsBattleEntity[] = [
        createEntity(1, 'rock'),
        createEntity(2, 'rock'),
        createEntity(3, 'scissors'),
        createEntity(4, 'paper')
      ];
      system.update(entities, counts(2, 1, 1), RPS_BATTLE_TRAITOR_FIRST_AT_SEC,
        randomSequence([0.2, 0.0, 0.0, 0.7]));

      system.update(entities, counts(2, 1, 1), RPS_BATTLE_TRAITOR_FIRST_AT_SEC + 1,
        randomSequence([0.2, 0.4, 0.0, 0.7]));
      const blockedState = system.snapshot() as RpsBattleTraitorState;
      system.update(entities, counts(2, 1, 1),
        RPS_BATTLE_TRAITOR_FIRST_AT_SEC + RPS_BATTLE_TRAITOR_INTERVAL_SEC, randomSequence([0.2, 0.4, 0.0, 0.7]));
      const readyState = system.snapshot() as RpsBattleTraitorState;

      expect(blockedState.marks.length).assertEqual(1);
      expect(readyState.marks.length).assertEqual(1);
      expect(readyState.convertedCount).assertEqual(1);
    });

    it('queues a clear rescue traitor during the early protection window',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleTraitorSystem();
      system.reset();
      const entities: RpsBattleEntity[] = [
        createEntity(1, 'rock'),
        createEntity(2, 'rock'),
        createEntity(3, 'rock')
      ];

      const queued = system.tryQueueClearRescue(entities, counts(3, 0, 0), 5, randomSequence([0.0]));
      const state = system.snapshot() as RpsBattleTraitorState;

      expect(queued).assertEqual(true);
      expect(system.clearRescueUsageCount()).assertEqual(1);
      expect(state.marks.length).assertEqual(1);
      expect(state.marks[0].fromFaction).assertEqual('rock');
      expect(state.marks[0].toFaction).assertEqual('paper');
      expect(state.marks[0].triggerAtSec).assertEqual(5 + RPS_BATTLE_TRAITOR_RESCUE_DELAY_SEC);
    });

    it('does not queue a clear rescue after the protection window',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const system = new RpsBattleTraitorSystem();
      system.reset();
      const entities: RpsBattleEntity[] = [
        createEntity(1, 'rock'),
        createEntity(2, 'rock')
      ];

      const queued = system.tryQueueClearRescue(entities, counts(2, 0, 0),
        RPS_BATTLE_TRAITOR_CLEAR_PROTECTION_SEC + 0.1, randomSequence([0.0]));

      expect(queued).assertEqual(false);
      expect(system.hasPendingMarks()).assertEqual(false);
    });
  });
}
