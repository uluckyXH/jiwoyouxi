import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import { MarketEngine } from '../../../main/ets/gamesNext/fruitMarket/MarketEngine';
import { MarketInsets, marketLayout } from '../../../main/ets/gamesNext/fruitMarket/MarketLayout';
import { MarketBody, MARKET_FRUITS, MARKET_STEP, marketMergeScore } from '../../../main/ets/gamesNext/fruitMarket/MarketModel';
import { achievementPrimaryFavoriteCount } from '../../../main/ets/shell/AchievementRegistry';
import { favoriteAchievementEventAfterPersist } from '../../../main/ets/shell/AchievementFavoriteEvent';
import { denseFruitMarket } from './fixtures/FruitMarketDense';

function fruit(id: number, level: number, x: number, y: number): MarketBody {
  return { id: id, level: level, x: x, y: y, vx: 0, vy: 0, angle: 0, born: 0, unlock: 0 };
}

function runSeconds(engine: MarketEngine, seconds: number, fps: number = 60): void {
  for (let i = 0; i < Math.round(seconds * fps); i += 1) engine.advance(1 / fps);
}

export default function fruitMarketNextTest(): void {
  describe('FruitMarketNext', () => {
    it('preserves opening fruits, cooldown and final bonus', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(42);
      const expected = [0, 0, 1, 2, 2, 3];
      for (let i = 0; i < expected.length; i += 1) {
        expect(engine.round.current).assertEqual(expected[i]);
        expect(engine.drop()).assertTrue();
        expect(engine.drop()).assertFalse();
        runSeconds(engine, 0.5);
      }
      expect(marketMergeScore(0)).assertEqual(1);
      expect(marketMergeScore(9)).assertEqual(110);
      expect(marketMergeScore(10)).assertEqual(0);
    });

    it('merges a contact once and never merges the final fruit', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(7);
      engine.round.bodies = [fruit(1, 0, 150, 250), fruit(2, 0, 172, 250), fruit(3, 0, 161, 267)];
      engine.round.nextId = 4;
      engine.advance(MARKET_STEP);
      expect(engine.round.score).assertEqual(1);
      expect(engine.round.bodies.length).assertEqual(2);
      expect(engine.events.length).assertEqual(1);
      const final = new MarketEngine(8);
      final.round.bodies = [fruit(1, 9, 130, 390), fruit(2, 9, 240, 390)];
      final.round.nextId = 3;
      final.advance(MARKET_STEP);
      expect(final.round.score).assertEqual(110);
      expect(final.round.highest).assertEqual(10);
      final.round.bodies = [fruit(3, 10, 120, 380), fruit(4, 10, 230, 380)];
      final.round.nextId = 5;
      runSeconds(final, 1);
      expect(final.round.bodies.length).assertEqual(2);
      expect(final.round.score).assertEqual(110);
    });

    it('advances the current and next preview together and preserves them on resume', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(42);
      for (let i = 0; i < 16; i += 1) {
        const current = engine.round.current;
        const next = engine.round.next;
        engine.aimAt(45 + (i % 4) * 75);
        expect(engine.drop()).assertTrue();
        expect(engine.round.bodies[engine.round.bodies.length - 1].level).assertEqual(current);
        expect(engine.round.current).assertEqual(next);
        const queued = engine.round.next;
        expect(engine.drop()).assertFalse();
        expect(engine.round.current).assertEqual(next);
        expect(engine.round.next).assertEqual(queued);
        const resumed = new MarketEngine(99);
        expect(resumed.restore(engine.serialize())).assertTrue();
        expect(resumed.round.current).assertEqual(next);
        expect(resumed.round.next).assertEqual(queued);
        runSeconds(engine, 0.5);
      }
    });

    it('rebuilds the collision sweep after a merge, drop and restored body list', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(71);
      engine.round.bodies = [fruit(1, 0, 170, 450), fruit(2, 0, 190, 450)];
      engine.round.nextId = 3;
      engine.advance(MARKET_STEP);
      expect(engine.round.score).assertEqual(1);
      expect(engine.drop()).assertTrue();
      runSeconds(engine, 1);
      const replacement = new MarketEngine(72);
      replacement.round.bodies = [fruit(1, 4, 140, 450), fruit(2, 4, 180, 450)];
      replacement.round.nextId = 3;
      expect(engine.restore(replacement.serialize())).assertTrue();
      engine.advance(MARKET_STEP);
      expect(engine.round.bodies.length).assertEqual(1);
      expect(engine.round.bodies[0].level).assertEqual(5);
      expect(engine.round.score).assertEqual(5);
    });

    it('separates coincident bodies and keeps fruit inside the crate', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(9);
      engine.round.bodies = [fruit(1, 4, 180, 420), fruit(2, 5, 180, 420)];
      engine.round.nextId = 3;
      runSeconds(engine, 5);
      engine.round.bodies.forEach((body: MarketBody) => {
        const radius = MARKET_FRUITS[body.level].radius;
        expect(Number.isFinite(body.x) && Number.isFinite(body.y)).assertTrue();
        expect(body.x >= 18 + radius - 0.1 && body.x <= 342 - radius + 0.1).assertTrue();
        expect(body.y <= 493 - radius + 0.1).assertTrue();
      });
      const a = engine.round.bodies[0];
      const b = engine.round.bodies[1];
      expect(Math.hypot(a.x - b.x, a.y - b.y) > 65).assertTrue();
    });

    it('uses the same physics at 30, 60 and 120 fps', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engines = [new MarketEngine(10), new MarketEngine(10), new MarketEngine(10)];
      for (let i = 0; i < engines.length; i += 1) {
        engines[i].aimAt(120);
        engines[i].drop();
        runSeconds(engines[i], 2, [30, 60, 120][i]);
      }
      expect(Math.abs(engines[0].round.bodies[0].y - engines[2].round.bodies[0].y) < 0.001).assertTrue();
      expect(Math.abs(engines[1].round.time - engines[2].round.time) < 0.001).assertTrue();
    });

    it('gives overflow a grace period, resets it after clearing, and ends once', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(11);
      engine.round.bodies = [fruit(1, 10, 180, 416), fruit(2, 10, 180, 264), fruit(3, 10, 180, 112)];
      engine.round.nextId = 4;
      runSeconds(engine, 2);
      expect(engine.round.ended).assertFalse();
      expect(engine.round.overflow > 0).assertTrue();
      const saved = engine.serialize();
      engine.round.bodies = [];
      engine.advance(MARKET_STEP);
      expect(engine.round.overflow).assertEqual(0);
      expect(engine.restore(saved)).assertTrue();
      runSeconds(engine, 3);
      expect(engine.round.ended).assertTrue();
      const finishTime = engine.round.time;
      engine.advance(0.05);
      expect(engine.round.time).assertEqual(finishTime);
      expect(engine.drop()).assertFalse();
    });

    it('round trips a live game including random sequence and rejects bad saves', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(15);
      for (let i = 0; i < 8; i += 1) {
        engine.aimAt(80 + (i % 3) * 95); engine.drop(); runSeconds(engine, 0.5);
      }
      const resumed = new MarketEngine(999);
      expect(resumed.restore(engine.serialize())).assertTrue();
      expect(resumed.round.sessionId).assertEqual(engine.round.sessionId);
      for (let i = 0; i < 10; i += 1) {
        engine.drop(); resumed.drop(); runSeconds(engine, 0.5); runSeconds(resumed, 0.5);
        expect(resumed.round.next).assertEqual(engine.round.next);
        expect(resumed.round.score).assertEqual(engine.round.score);
      }
      const unchanged = resumed.serialize();
      expect(resumed.restore('{bad json')).assertFalse();
      expect(resumed.restore('{"version":2}')).assertFalse();
      expect(resumed.serialize()).assertEqual(unchanged);
      engine.round.current = 99;
      expect(resumed.restore(engine.serialize())).assertFalse();
    });

    it('caps a suspended-frame gap instead of ending a paused game', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(16);
      engine.drop();
      engine.advance(60);
      expect(engine.round.time <= 0.051).assertTrue();
      expect(engine.round.ended).assertFalse();
      engine.aimAt(-1000); expect(engine.round.aim).assertEqual(31);
      engine.aimAt(1000); expect(engine.round.aim).assertEqual(329);
    });

    it('bounds repeated slow callbacks and recovers without a physics backlog', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(81);
      engine.drop();
      for (let i = 0; i < 60; i += 1) {
        engine.advance(1 / 15);
        expect(engine.lastSteps <= 2).assertTrue();
      }
      expect(Math.abs(engine.round.time - 2) < 0.001).assertTrue();
      const before = engine.round.time;
      engine.advance(1 / 60);
      expect(engine.lastSteps).assertEqual(1);
      expect(Math.abs(engine.round.time - before - MARKET_STEP) < 0.001).assertTrue();
    });

    it('sleeps a settled pile, advances its clock, then wakes and merges on a new drop', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(82);
      engine.round.bodies = [fruit(1, 0, 70, 480), fruit(2, 2, 180, 472), fruit(3, 4, 280, 462)];
      engine.round.nextId = 4;
      runSeconds(engine, 2);
      expect(engine.sleeping).assertTrue();
      const before = engine.round.time;
      const resting = JSON.stringify(engine.round.bodies);
      runSeconds(engine, 1);
      expect(engine.lastPairChecks).assertEqual(0);
      expect(JSON.stringify(engine.round.bodies)).assertEqual(resting);
      expect(Math.abs(engine.round.time - before - 1) < 0.001).assertTrue();
      engine.aimAt(70);
      expect(engine.drop()).assertTrue();
      expect(engine.sleeping).assertFalse();
      runSeconds(engine, 2);
      expect(engine.round.score).assertEqual(1);
      expect(engine.round.merges).assertEqual(1);
      const resumed = new MarketEngine(83);
      expect(resumed.restore(engine.serialize())).assertTrue();
      expect(resumed.sleeping).assertFalse();
    });

    it('keeps merging locks and overflow timers alive while settling', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(84);
      engine.round.bodies = [fruit(1, 0, 150, 480), fruit(2, 0, 172, 480)];
      engine.round.bodies[0].unlock = 1.2;
      engine.round.bodies[1].unlock = 1.2;
      engine.round.nextId = 3;
      runSeconds(engine, 1);
      expect(engine.sleeping).assertFalse();
      expect(engine.round.score).assertEqual(0);
      runSeconds(engine, 1);
      expect(engine.round.score).assertEqual(1);
      const stack = new MarketEngine(85);
      stack.round.bodies = [fruit(1, 10, 180, 416), fruit(2, 10, 180, 264), fruit(3, 10, 180, 112)];
      stack.round.nextId = 4;
      runSeconds(stack, 2);
      expect(stack.sleeping).assertTrue();
      expect(stack.round.ended).assertFalse();
      runSeconds(stack, 3);
      expect(stack.round.ended).assertTrue();
    });

    it('keeps fast falling small fruit above the supporting fruit', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(86);
      engine.round.bodies = [fruit(1, 1, 180, 476), fruit(2, 0, 180, 400)];
      engine.round.bodies[1].vy = 620;
      engine.round.nextId = 3;
      runSeconds(engine, 2);
      const base = engine.round.bodies[0];
      const top = engine.round.bodies[1];
      expect(top.y < base.y).assertTrue();
      expect(Math.hypot(base.x - top.x, base.y - top.y) >= 29.5).assertTrue();
      expect(base.y <= 476 && top.y <= 480).assertTrue();
    });

    it('keeps multi-drop contacts and merge scores consistent at 30, 60 and 120 fps', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engines = [new MarketEngine(87), new MarketEngine(87), new MarketEngine(87)];
      for (let i = 0; i < engines.length; i += 1) {
        const engine = engines[i];
        const fps = [30, 60, 120][i];
        for (let frame = 0; frame < fps * 12; frame += 1) {
          if (frame % (fps / 2) === 0) {
            engine.aimAt(70 + ((frame / (fps / 2)) % 3) * 95);
            engine.drop();
          }
          engine.advance(1 / fps);
        }
      }
      expect(engines[0].round.merges > 0).assertTrue();
      for (let i = 1; i < engines.length; i += 1) {
        expect(engines[i].round.score).assertEqual(engines[0].round.score);
        expect(engines[i].round.next).assertEqual(engines[0].round.next);
        expect(JSON.stringify(engines[i].round.bodies)).assertEqual(JSON.stringify(engines[0].round.bodies));
      }
    });

    it('leaves an unrelated resting stack asleep during a drop and impact', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(91);
      engine.round.bodies = [fruit(1, 0, 60, 480), fruit(2, 1, 60, 450),
        fruit(3, 2, 280, 472), fruit(4, 3, 280, 425)];
      engine.round.nextId = 5;
      runSeconds(engine, 3);
      expect(engine.sleepingBodies).assertEqual(4);
      const rightBottom = JSON.stringify(engine.round.bodies[2]);
      const rightTop = JSON.stringify(engine.round.bodies[3]);
      engine.aimAt(60);
      engine.drop();
      runSeconds(engine, 0.1);
      expect(engine.sleepingBodies).assertEqual(4);
      expect(engine.sleeping).assertFalse();
      runSeconds(engine, 3);
      expect(JSON.stringify(engine.round.bodies.find((b: MarketBody): boolean => b.id === 3))).assertEqual(rightBottom);
      expect(JSON.stringify(engine.round.bodies.find((b: MarketBody): boolean => b.id === 4))).assertEqual(rightTop);
    });

    it('wakes a resting fruit when its support merges and permits the next merge', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(92);
      engine.round.bodies = [fruit(1, 0, 180, 480), fruit(2, 1, 180, 450)];
      engine.round.nextId = 3;
      runSeconds(engine, 2);
      expect(engine.sleepingBodies).assertEqual(2);
      engine.round.bodies.push(fruit(3, 0, 200, 480));
      engine.round.nextId = 4;
      runSeconds(engine, 3);
      expect(engine.round.score).assertEqual(3);
      expect(engine.round.bodies.length).assertEqual(1);
      expect(engine.round.bodies[0].level).assertEqual(2);
      expect(Math.abs(engine.round.bodies[0].y - 472) < 0.2).assertTrue();
    });

    it('rebuilds padded contact pairs after deep positional corrections', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(93);
      engine.round.bodies = [fruit(1, 4, 180, 420), fruit(2, 5, 180, 420), fruit(3, 6, 180, 420)];
      engine.round.nextId = 4;
      runSeconds(engine, 5);
      for (let i = 0; i < engine.round.bodies.length; i += 1) {
        const a = engine.round.bodies[i];
        for (let j = i + 1; j < engine.round.bodies.length; j += 1) {
          const b = engine.round.bodies[j];
          expect(Math.hypot(a.x - b.x, a.y - b.y) >= MARKET_FRUITS[a.level].radius + MARKET_FRUITS[b.level].radius - 1).assertTrue();
        }
      }
    });

    it('restores resting metadata safely and rejects nonexistent resting bodies', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = new MarketEngine(94);
      engine.round.bodies = [fruit(1, 0, 70, 480), fruit(2, 2, 280, 472)];
      engine.round.nextId = 3;
      runSeconds(engine, 2);
      const saved = engine.serialize();
      const restored = new MarketEngine(95);
      expect(restored.restore(saved)).assertTrue();
      restored.aimAt(180); restored.drop(); restored.advance(MARKET_STEP);
      expect(restored.sleepingBodies).assertEqual(2);
      engine.round.resting = [999];
      expect(restored.restore(JSON.stringify(engine.round))).assertFalse();
      engine.round.resting = [1, 1];
      expect(restored.restore(JSON.stringify(engine.round))).assertFalse();
      engine.round.resting = [1];
      engine.round.bodies[0].y = 200;
      expect(restored.restore(JSON.stringify(engine.round))).assertTrue();
      runSeconds(restored, 0.5);
      expect(restored.round.bodies[0].y > 250).assertTrue();
      // Resting metadata must not freeze a corrupted pose through the crate walls.
      engine.round.bodies[0].x = 18;
      engine.round.bodies[0].y = 490;
      expect(restored.restore(JSON.stringify(engine.round))).assertTrue();
      restored.advance(MARKET_STEP);
      expect(restored.round.bodies[0].x).assertEqual(31);
      expect(restored.round.bodies[0].y).assertEqual(480);
    });

    it('settles the reported dense 35-fruit geometry and keeps it asleep during a new free fall', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const engine = denseFruitMarket();
      runSeconds(engine, 10);
      expect(engine.round.ended).assertFalse();
      expect(engine.round.bodies.length).assertEqual(35);
      expect(engine.sleepingBodies).assertEqual(35);
      engine.aimAt(180);
      expect(engine.drop()).assertTrue();
      runSeconds(engine, 0.1);
      expect(engine.sleepingBodies).assertEqual(35);
      for (let i = 0; i < 8; i += 1) {
        engine.aimAt(60 + (i % 3) * 110);
        engine.drop();
        runSeconds(engine, 0.5);
        engine.round.bodies.forEach((body: MarketBody) => {
          const radius = MARKET_FRUITS[body.level].radius;
          expect(Number.isFinite(body.x) && Number.isFinite(body.y)).assertTrue();
          expect(body.x >= 18 + radius - 0.1 && body.x <= 342 - radius + 0.1).assertTrue();
          expect(body.y <= 493 - radius + 0.1).assertTrue();
        });
      }
      expect(engine.round.ended).assertFalse();
    });

    it('fits small phones, tablets, landscape and both half-fold orientations', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const widths = [320, 320, 390, 568, 844, 768, 1024, 1280, 720];
      const heights = [480, 568, 844, 320, 390, 1024, 768, 800, 720];
      for (let i = 0; i < widths.length; i += 1) {
        const layout = marketLayout(widths[i], heights[i], { top: 24, bottom: 20, left: 0, right: 0 });
        expect(layout.limited).assertFalse();
        expect(layout.boardWidth > 0 && layout.boardHeight > 0).assertTrue();
        expect(layout.boardHeight + (layout.wide ? 0 : 108) <= layout.bodyHeight + 0.001).assertTrue();
        expect(layout.boardWidth + (layout.wide ? layout.railWidth + layout.gap : 0) <= layout.width - 2 * layout.gap + 0.001).assertTrue();
      }
      expect(marketLayout(1024, 768, { top: 0, bottom: 0, left: 0, right: 0 }).wide).assertTrue();
      const horizontal = marketLayout(840, 1000, { top: 0, bottom: 0, left: 0, right: 0 },
        { x: 0, y: 480, width: 840, height: 20 });
      expect(horizontal.y).assertEqual(500);
      expect(horizontal.height).assertEqual(500);
      expect(horizontal.halfFoldPane).assertTrue();
      expect(horizontal.limited).assertFalse();
      const vertical = marketLayout(1000, 840, { top: 0, bottom: 0, left: 0, right: 0 },
        { x: 480, y: 0, width: 20, height: 840 });
      expect(vertical.x).assertEqual(500);
      expect(vertical.width).assertEqual(500);
      expect(vertical.halfFoldPane).assertTrue();
      expect(vertical.limited).assertFalse();
    });

    it('requests more room only for tiny windows or unusably small half-fold panes', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const insets: MarketInsets = { top: 24, bottom: 20, left: 0, right: 0 };
      const folded = marketLayout(390, 844, insets, { x: 0, y: 412, width: 390, height: 20 });
      expect(folded.halfFoldPane).assertTrue();
      expect(folded.limited).assertTrue();
      expect(folded.y).assertEqual(432);
      expect(folded.height).assertEqual(392);
      expect(marketLayout(390, 844, insets).limited).assertFalse();
      expect(marketLayout(840, 1000, insets, { x: 0, y: 480, width: 840, height: 20 }).limited).assertFalse();
      expect(marketLayout(500, 840, insets, { x: 240, y: 0, width: 20, height: 840 }).limited).assertTrue();
      expect(marketLayout(344, 368, insets).limited).assertTrue();
      expect(marketLayout(240, 600, insets).limited).assertTrue();
      expect(marketLayout(800, 240, insets).limited).assertTrue();
    });

    it('does not split a window for a crease that lies on another screen region', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      const insets: MarketInsets = { top: 24, bottom: 20, left: 0, right: 0 };
      const normal = marketLayout(390, 844, insets);
      const elsewhere = marketLayout(390, 844, insets, { x: 600, y: 412, width: 800, height: 20 });
      const below = marketLayout(390, 844, insets, { x: 180, y: 1000, width: 20, height: 900 });
      expect(JSON.stringify(elsewhere)).assertEqual(JSON.stringify(normal));
      expect(JSON.stringify(below)).assertEqual(JSON.stringify(normal));
      const partial = marketLayout(390, 844, insets, { x: -40, y: 412, width: 450, height: 20 });
      expect(partial.halfFoldPane).assertTrue();
      expect(partial.limited).assertTrue();
    });

    it('counts both editions as one fruit game in favorite achievements', TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
      expect(achievementPrimaryFavoriteCount(['suika', 'suikaNext'])).assertEqual(1);
      expect(achievementPrimaryFavoriteCount(['suikaNext', 'minesweeper', 'tetris', 'freecell'])).assertEqual(4);
      const event = favoriteAchievementEventAfterPersist('suikaNext', true, true, ['suikaNext'], 12345, 1);
      expect(event !== undefined).assertTrue();
      if (event !== undefined) expect(event.facts[0].value).assertEqual(1);
    });
  });
}
