import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import { StarEngine } from '../../../main/ets/gamesNext/starPop/StarEngine';
import { StarGenerator, starVerifyPuzzle } from '../../../main/ets/gamesNext/starPop/StarGenerator';
import { starFallback } from '../../../main/ets/gamesNext/starPop/StarFallback';
import { StarMode, starBonus, starGain, starTarget } from '../../../main/ets/gamesNext/starPop/StarModel';
import { starCollapse, starGroup, starGroups, starRemaining, starValidBoard } from '../../../main/ets/gamesNext/starPop/StarRules';
import { StarInsets, starLayout, starUsesCreases } from '../../../main/ets/gamesNext/starPop/StarLayout';
import { StarScene } from '../../../main/ets/gamesNext/starPop/StarScene';

export default function starPopTest(): void {
  describe('StarPop', () => {
    const kind = TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0;
    it('tile views keep their identity and only affected tiles shrink or move', kind, () => {
      const scene = new StarScene();
      scene.restore('one', [{ id: 0, cell: 64, color: 0 }, { id: 1, cell: 65, color: 1 }], []);
      const first = scene.tiles[0], other = scene.tiles[1];
      scene.shrink([0]); expect(first.scale).assertEqual(.03); expect(other.scale).assertEqual(1);
      scene.hide([0]); expect(first.visible).assertEqual(false); expect(other.visible).assertEqual(true);
      expect(scene.place([{ id: 1, cell: 73, color: 1 }])).assertEqual(1);
      expect(other.cell).assertEqual(73); expect(scene.tiles[1] === other).assertEqual(true);
      expect(scene.place([{ id: 1, cell: 73, color: 1 }])).assertEqual(0);
    });
    it('undo reuses hidden views while a new round replaces their old identities', kind, () => {
      const scene = new StarScene();
      scene.restore('one', [{ id: 5, cell: 72, color: 3 }], []);
      const view = scene.tiles[5]; scene.shrink([5]); scene.hide([5]);
      expect(scene.restore('one', [{ id: 5, cell: 64, color: 3 }], [])).assertEqual(false);
      expect(scene.tiles[5] === view).assertEqual(true);
      expect(view.visible).assertEqual(true); expect(view.scale).assertEqual(1); expect(view.cell).assertEqual(64);
      expect(scene.restore('two', [{ id: 5, cell: 5, color: 1 }], [])).assertEqual(true);
      expect(scene.tiles[5] === view).assertEqual(false); expect(scene.tiles[5].color).assertEqual(1);
    });
    it('orthogonal groups cannot join through a diagonal or a wrapped row', kind, () => {
      const cells: number[] = new Array<number>(80).fill(-1);
      cells[7] = 0; cells[8] = 0; cells[16] = 0; cells[17] = 0;
      expect(starGroup(cells, 7).length).assertEqual(1);
      expect(starGroup(cells, 8).length).assertEqual(3);
      expect(starGroups(cells).length).assertEqual(1);
      expect(starGroup(cells, -1).length).assertEqual(0);
    });
    it('gravity preserves order and empty columns shift left without refilling', kind, () => {
      const cells: number[] = new Array<number>(80).fill(-1);
      const ids: number[] = new Array<number>(80).fill(-1);
      [56, 64, 72, 73, 74, 66].forEach((cell: number) => { cells[cell] = cell === 64 || cell === 72 || cell === 73 ? 0 : 1; ids[cell] = cell; });
      const move = starCollapse(cells, ids, [64, 72, 73]);
      expect(JSON.stringify(move.ids.slice(64, 66))).assertEqual('[-1,66]');
      expect(JSON.stringify(move.ids.slice(72, 74))).assertEqual('[56,74]');
      expect(starRemaining(move.cells)).assertEqual(3);
      expect(starValidBoard(move.cells, move.ids, 4)).assertEqual(true);
      expect(move.gain).assertEqual(45);
    });
    it('scores, end bonuses and bounded target ratios match the public rules', kind, () => {
      expect(starGain(2)).assertEqual(20); expect(starGain(8)).assertEqual(320);
      expect(starBonus(0)).assertEqual(500); expect(starBonus(5)).assertEqual(375);
      expect(starBonus(10)).assertEqual(0); expect(starBonus(80)).assertEqual(0);
      expect(starTarget(1, 2000)).assertEqual(1200);
      expect(starTarget(1000, 2000)).assertEqual(1700);
    });
    it('both modes generate complete reachable witnesses within bounded steps', kind, () => {
      const modes: StarMode[] = ['easy', 'classic'];
      modes.forEach((mode: StarMode) => {
        for (let seed = 1; seed <= 20; seed++) {
          const gen = new StarGenerator(seed, mode);
          while (!gen.done && gen.steps <= 82) gen.advance();
          const puzzle = gen.result();
          expect(puzzle !== undefined).assertEqual(true);
          if (puzzle !== undefined) {
            expect(starVerifyPuzzle(puzzle, mode)).assertEqual(true);
            expect(starTarget(50, puzzle.witness) <= puzzle.witness).assertEqual(true);
          }
          expect(gen.steps <= 82).assertEqual(true);
        }
      });
    });
    it('undo restores the exact board, survives reload and cannot farm cumulative clears', kind, () => {
      const e = new StarEngine(); const before = JSON.stringify(e.round.cells);
      const cell = e.hint()[0]; e.pop(cell); const cleared = e.profile.totalCleared;
      expect(e.undo()).assertEqual(true); expect(JSON.stringify(e.round.cells)).assertEqual(before);
      const restored = new StarEngine(); expect(restored.restore(e.serialize())).assertEqual(true);
      restored.pop(cell); expect(restored.profile.totalCleared).assertEqual(cleared);
      expect(restored.canUndo()).assertEqual(false);
      expect(restored.undo()).assertEqual(false);
    });
    it('passing a stage preserves the journey and only credits the end bonus once', kind, () => {
      const puzzle = starFallback('easy'); const e = new StarEngine();
      puzzle.path.forEach((cell: number) => { e.pop(cell); });
      expect(e.round.status).assertEqual('stageEnd'); expect(e.totalScore()).assertEqual(puzzle.witness);
      const session = e.round.session;
      expect(e.advance(puzzle)).assertEqual(true); expect(e.totalScore()).assertEqual(puzzle.witness);
      expect(e.round.session).assertEqual(session); expect(e.round.stage).assertEqual(2);
      expect(e.advance(puzzle)).assertEqual(false);
      expect(e.restore(e.serialize())).assertEqual(true);
    });
    it('folded phone-size screens remain playable and only genuinely tiny windows are gated', kind, () => {
      const insets: StarInsets = { top: 24, bottom: 16, left: 0, right: 0 };
      expect(starUsesCreases(2)).assertEqual(false);
      expect(starLayout(320, 640, insets).small).assertEqual(false);
      expect(starLayout(390, 844, insets).small).assertEqual(false);
      expect(starLayout(820, 1100, insets).wide).assertEqual(true);
      expect(starLayout(260, 500, insets).small).assertEqual(true);
      const half = starLayout(840, 880, insets, [{ x: 410, y: 0, width: 20, height: 880 }]);
      expect(half.width).assertEqual(410); expect(half.small).assertEqual(false);
    });
  });
}
