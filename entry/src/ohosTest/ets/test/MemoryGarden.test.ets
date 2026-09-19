import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import { MemoryEngine } from '../../../main/ets/gamesNext/memoryGarden/MemoryEngine';
import { MemoryMode, memoryPairCount, memoryMatched } from '../../../main/ets/gamesNext/memoryGarden/MemoryModel';
import { memoryLayout, memoryViewport, memoryUsesCreases, MemoryInsets } from '../../../main/ets/gamesNext/memoryGarden/MemoryLayout';

function memoryMate(engine: MemoryEngine, first: number): number {
  return engine.round.cards.findIndex((id: number, i: number) => i !== first && id === engine.round.cards[first]);
}
function memorySolve(engine: MemoryEngine): void {
  while (engine.round.phase !== 'complete') {
    engine.settle();
    const first = engine.round.matched.findIndex((matched: boolean) => !matched);
    engine.flip(first);
    engine.flip(memoryMate(engine, first));
  }
}
export default function memoryGardenTest(): void {
  describe('MemoryGarden', () => {
    const kind = TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0;
    it('all modes deal exactly two of each picture and permit a lossless save', kind, () => {
      const modes: MemoryMode[] = ['journey', 'easy', 'normal', 'focus'];
      modes.forEach((mode: MemoryMode) => {
        const engine = new MemoryEngine(mode, 42);
        expect(engine.round.cards.length).assertEqual(engine.round.pairs * 2);
        engine.round.cards.forEach((id: number) => {
          expect(engine.round.cards.filter((other: number) => id === other).length).assertEqual(2);
        });
        expect(engine.restore(engine.serialize())).assertEqual(true);
      });
    });
    it('journey increases every two tables and stays capped at twelve pairs', kind, () => {
      const expected: number[] = [6, 6, 8, 8, 10, 10, 12, 12, 12, 12];
      const engine = new MemoryEngine();
      expected.forEach((pairs: number, i: number) => {
        expect(engine.round.number).assertEqual(i + 1);
        expect(engine.round.pairs).assertEqual(pairs);
        memorySolve(engine);
        expect(engine.next()).assertEqual(false);
        engine.round.reported = true;
        expect(engine.next()).assertEqual(true);
      });
      expect(memoryPairCount('journey', 9999)).assertEqual(12);
    });
    it('same-card taps and invalid slots never count as an attempt', kind, () => {
      const engine = new MemoryEngine();
      expect(engine.flip(0).accepted).assertEqual(true);
      const before = engine.serialize();
      [-1, 24, 0.5, Number.NaN, 0].forEach((index: number) => {
        expect(engine.flip(index).accepted).assertEqual(false);
        expect(engine.serialize()).assertEqual(before);
      });
      expect(engine.round.attempts).assertEqual(0);
    });
    it('a mismatch exposes two cards, rejects the third and preserves their positions', kind, () => {
      const engine = new MemoryEngine();
      const order = engine.round.cards.join(',');
      const second = engine.round.cards.findIndex((id: number) => id !== engine.round.cards[0]);
      engine.flip(0); engine.flip(second);
      expect(engine.round.phase).assertEqual('mismatch');
      expect(engine.round.attempts).assertEqual(1);
      const before = engine.serialize();
      for (let i = 0; i < engine.round.cards.length; i += 1) { expect(engine.flip(i).accepted).assertEqual(false); }
      expect(engine.serialize()).assertEqual(before);
      expect(engine.settle()).assertEqual(true);
      expect(engine.settle()).assertEqual(false);
      expect(engine.round.first).assertEqual(-1);
      expect(engine.round.cards.join(',')).assertEqual(order);
    });
    it('matching and completion commit once independently of animation callbacks', kind, () => {
      const engine = new MemoryEngine('easy', 5);
      memorySolve(engine);
      expect(engine.profile.totalPairs).assertEqual(6);
      expect(engine.profile.totalTables).assertEqual(1);
      expect(engine.profile.best6).assertEqual(6);
      expect(engine.profile.bestStreak).assertEqual(6);
      expect(engine.round.attempts).assertEqual(6);
      expect(memoryMatched(engine.round)).assertEqual(6);
      const before = engine.serialize();
      expect(engine.flip(0).accepted).assertEqual(false);
      expect(engine.settle()).assertEqual(false);
      expect(engine.next()).assertEqual(false);
      expect(engine.serialize()).assertEqual(before);
    });
    it('mismatch clears the streak without losing matched pairs', kind, () => {
      const engine = new MemoryEngine();
      engine.flip(0); engine.flip(memoryMate(engine, 0)); engine.settle();
      const first = engine.round.matched.findIndex((matched: boolean) => !matched);
      const second = engine.round.cards.findIndex((id: number, i: number) => !engine.round.matched[i] && id !== engine.round.cards[first]);
      engine.flip(first); engine.flip(second);
      expect(engine.round.streak).assertEqual(0);
      expect(engine.profile.bestStreak).assertEqual(1);
      expect(engine.profile.totalPairs).assertEqual(1);
    });
    it('reload preserves first card and a pending mismatch without counting again', kind, () => {
      const engine = new MemoryEngine(); engine.flip(0);
      const restored = new MemoryEngine();
      expect(restored.restore(engine.serialize())).assertEqual(true);
      expect(restored.round.first).assertEqual(0);
      const second = restored.round.cards.findIndex((id: number) => id !== restored.round.cards[0]);
      restored.flip(second);
      expect(engine.restore(restored.serialize())).assertEqual(true);
      expect(engine.round.second).assertEqual(second);
      engine.settle();
      expect(engine.round.attempts).assertEqual(1);
      expect(engine.profile.totalPairs).assertEqual(0);
    });
    it('restart keeps lifetime records and cannot complete an unfinished table', kind, () => {
      const engine = new MemoryEngine(); memorySolve(engine);
      engine.restart('focus');
      expect(engine.round.number).assertEqual(1);
      expect(engine.round.pairs).assertEqual(12);
      expect(engine.profile.totalPairs).assertEqual(6);
      expect(engine.profile.totalTables).assertEqual(1);
      expect(engine.bestAttempts()).assertEqual(0);
      engine.flip(0); engine.restart('easy');
      expect(engine.profile.totalTables).assertEqual(1);
      expect(engine.bestAttempts()).assertEqual(6);
    });
    it('corrupt data is rejected atomically', kind, () => {
      const engine = new MemoryEngine(); engine.flip(0);
      const before = engine.serialize();
      ['null', '{}', 'broken', '{"version":2}'].forEach((raw: string) => {
        expect(engine.restore(raw)).assertEqual(false);
        expect(engine.serialize()).assertEqual(before);
      });
      const saved = engine.snapshot(); saved.round.cards[0] = 99;
      expect(engine.restore(JSON.stringify(saved))).assertEqual(false);
      expect(engine.serialize()).assertEqual(before);
    });
    it('phone and tablet retain four columns with larger tablet targets', kind, () => {
      const insets: MemoryInsets = { top: 24, bottom: 24, left: 0, right: 0 };
      [6, 8, 10, 12].forEach((pairs: number) => {
        const phone = memoryLayout(390, 844, insets, [], pairs);
        const tablet = memoryLayout(1280, 900, insets, [], pairs);
        expect(phone.card >= 49).assertEqual(true);
        expect(tablet.card > phone.card).assertEqual(true);
        expect(tablet.wide).assertEqual(true);
        expect(tablet.board.x + tablet.board.width <= tablet.stats.x).assertEqual(true);
      });
    });
    it('half fold and two hinges choose usable panes, fully expanded ignores creases', kind, () => {
      const safe: MemoryInsets = { top: 20, bottom: 20, left: 0, right: 0 };
      expect(memoryViewport(800, 1200, safe, [{ x: 0, y: 590, width: 800, height: 20 }]).height).assertEqual(570);
      expect(memoryViewport(1200, 800, safe, [
        { x: 390, y: 0, width: 20, height: 800 }, { x: 790, y: 0, width: 20, height: 800 }
      ]).width).assertEqual(390);
      expect(memoryUsesCreases(23)).assertEqual(true);
      expect(memoryUsesCreases(1)).assertEqual(false);
      expect(memoryUsesCreases(2)).assertEqual(false);
    });
    it('narrow half screen allows scrolling without shrinking touch targets', kind, () => {
      const layout = memoryLayout(200, 260, { top: 20, bottom: 20, left: 0, right: 0 }, [], 12);
      expect(layout.contentWidth > layout.width).assertEqual(true);
      expect(layout.contentHeight > layout.body).assertEqual(true);
      expect(layout.card >= 49).assertEqual(true);
    });
  });
}
