import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import { BloomEngine } from '../../../main/ets/gamesNext/bloomLines/BloomEngine';
import { BloomDrag, BloomGridGeometry, bloomCellOrigin, bloomDropCell } from '../../../main/ets/gamesNext/bloomLines/BloomDrag';
import { BloomMode, bloomConfig } from '../../../main/ets/gamesNext/bloomLines/BloomModel';
import { bloomAllLines, bloomLinesAt, bloomPath, bloomReachable } from '../../../main/ets/gamesNext/bloomLines/BloomRules';
import { BloomInsets, bloomLayout, bloomViewport, bloomUsesCreases, sameBloomLayout } from '../../../main/ets/gamesNext/bloomLines/BloomLayout';

function bloomFixture(mode: BloomMode = 'garden'): BloomEngine {
  const engine = new BloomEngine(mode, 42);
  engine.round.board.fill(-1);
  return engine;
}

function bloomPrepareClear(engine: BloomEngine): void {
  engine.round.board.fill(-1);
  for (let index = 0; index < 4; index += 1) { engine.round.board[index] = 0; }
  engine.round.board[bloomConfig(engine.round.mode).size] = 0;
}

export default function bloomLinesTest(): void {
  describe('BloomLines', () => {
    const kind = TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0;
    it('drag coordinates use a stable source and match total finger offsets without drift', kind, () => {
      const grid: BloomGridGeometry = { gridSize: 7, cell: 40, gap: 3, inset: 10 };
      const drag = new BloomDrag();
      drag.begin(8, 2, grid);
      const origin = bloomCellOrigin(8, grid);
      drag.offset(4, 2); drag.offset(19, -7); drag.offset(43, 86);
      expect(drag.x).assertEqual(origin.x + 43);
      expect(drag.y).assertEqual(origin.y + 86);
      expect(drag.target).assertEqual(23);
      drag.cancel(); drag.offset(100, 200);
      expect(drag.from).assertEqual(-1);
      expect(drag.target).assertEqual(-1);
      expect(drag.x).assertEqual(origin.x + 43);
    });
    it('drop hit testing covers all cells and gaps while rejecting margins and out-of-board coordinates', kind, () => {
      [7, 9].forEach((size: number) => {
        const grid: BloomGridGeometry = { gridSize: size, cell: 34, gap: 3, inset: 10 };
        for (let i = 0; i < size * size; i += 1) {
          const point = bloomCellOrigin(i, grid);
          expect(bloomDropCell(point.x + 17, point.y + 17, grid)).assertEqual(i);
        }
        expect(bloomDropCell(9, 20, grid)).assertEqual(-1);
        expect(bloomDropCell(10 + size * 37 - 3, 20, grid)).assertEqual(-1);
        expect(bloomDropCell(44.4, 20, grid)).assertEqual(0);
        expect(bloomDropCell(46, 20, grid)).assertEqual(1);
        expect(bloomDropCell(Number.NaN, 20, grid)).assertEqual(-1);
      });
    });
    it('starts both modes with the promised board, colors and preview', kind, () => {
      const modes: BloomMode[] = ['garden', 'classic'];
      modes.forEach((mode: BloomMode) => {
        const engine = new BloomEngine(mode, 73);
        const config = bloomConfig(mode);
        expect(engine.round.board.length).assertEqual(config.size * config.size);
        expect(engine.round.board.filter((color: number) => color >= 0).length).assertEqual(config.initial);
        expect(engine.round.next.length).assertEqual(config.batch);
        expect(engine.round.board.every((color: number) => color < config.colors)).assertEqual(true);
        expect(engine.restore(engine.serialize())).assertEqual(true);
      });
    });
    it('finds a shortest orthogonal path around an obstacle without wrapping a row', kind, () => {
      const board: number[] = new Array<number>(49).fill(-1);
      board[0] = 0; board[1] = 1;
      expect(JSON.stringify(bloomPath(board, 7, 0, 2))).assertEqual('[0,7,8,9,2]');
      board.fill(1); board[6] = 0; board[7] = -1;
      expect(bloomPath(board, 7, 6, 7).length).assertEqual(0);
      expect(bloomReachable(board, 7, 6).length).assertEqual(0);
      expect(bloomPath(board, 7, -1, 7).length).assertEqual(0);
    });
    it('invalid moves leave the board, preview, score, RNG and undo untouched', kind, () => {
      const engine = bloomFixture();
      engine.round.board.fill(1); engine.round.board[0] = 0; engine.round.board[48] = -1;
      const before = engine.serialize();
      expect(engine.move(0, 48).valid).assertEqual(false);
      expect(engine.move(0, 1).valid).assertEqual(false);
      expect(engine.move(0, 0).valid).assertEqual(false);
      expect(engine.move(48, 0).valid).assertEqual(false);
      expect(engine.serialize()).assertEqual(before);
    });
    it('recognizes all four axes, overlong lines, and never merges across a row edge', kind, () => {
      const lines: number[][] = [[0, 1, 2, 3, 4], [0, 7, 14, 21, 28], [0, 8, 16, 24, 32], [4, 10, 16, 22, 28]];
      lines.forEach((line: number[]) => {
        const board: number[] = new Array<number>(49).fill(-1);
        line.forEach((index: number) => { board[index] = 2; });
        expect(bloomLinesAt(board, 7, line[2]).length).assertEqual(5);
        board[line[0]] = -1;
        expect(bloomLinesAt(board, 7, line[2]).length).assertEqual(0);
      });
      const board: number[] = new Array<number>(49).fill(-1);
      [0, 1, 2, 3, 4, 5].forEach((index: number) => { board[index] = 0; });
      expect(bloomLinesAt(board, 7, 2).length).assertEqual(6);
      board.fill(-1); [5, 6, 7, 8, 9].forEach((index: number) => { board[index] = 0; });
      expect(bloomLinesAt(board, 7, 7).length).assertEqual(0);
    });
    it('a player clear scores immediately and keeps the preview and RNG unchanged', kind, () => {
      const engine = bloomFixture();
      bloomPrepareClear(engine);
      engine.round.board[48] = 3;
      const next = JSON.stringify(engine.round.next);
      const seed = engine.round.seed;
      const turn = engine.move(7, 4);
      expect(turn.valid).assertEqual(true);
      expect(turn.clearFromMove).assertEqual(true);
      expect(turn.removed.length).assertEqual(5);
      expect(turn.spawned.length).assertEqual(0);
      expect(engine.round.score).assertEqual(10);
      expect(engine.round.moves).assertEqual(1);
      expect(engine.round.cleared).assertEqual(5);
      expect(engine.round.seed).assertEqual(seed);
      expect(JSON.stringify(engine.round.next)).assertEqual(next);
      expect(engine.round.board.filter((color: number) => color >= 0).length).assertEqual(1);
    });
    it('clearing the whole board supplies playable beads without adding a move or score', kind, () => {
      const engine = bloomFixture(); bloomPrepareClear(engine);
      const preview = engine.round.next.slice();
      const turn = engine.move(7, 4);
      expect(turn.refilled.length).assertEqual(2);
      expect(JSON.stringify(turn.refilled.map((index: number) => engine.round.board[index]))).assertEqual(JSON.stringify(preview));
      expect(engine.round.score).assertEqual(10);
      expect(engine.round.moves).assertEqual(1);
      expect(engine.round.ended).assertEqual(false);
      expect(engine.restore(engine.serialize())).assertEqual(true);
    });
    it('intersecting diagonal lines count their shared bead once', kind, () => {
      const engine = bloomFixture();
      [8, 16, 32, 40, 12, 18, 30, 36, 0].forEach((index: number) => { engine.round.board[index] = 0; });
      const turn = engine.move(0, 24);
      expect(turn.valid).assertEqual(true);
      expect(turn.removed.length).assertEqual(9);
      expect(turn.gain).assertEqual(18);
      expect(bloomAllLines(turn.afterMove, 7, [16, 18, 24]).length).assertEqual(9);
    });
    it('an unsuccessful move spawns exactly the preview colors and advances it', kind, () => {
      const engine = bloomFixture('classic');
      engine.round.board[0] = 0;
      engine.round.next = [2, 4, 6];
      const turn = engine.move(0, 1);
      expect(turn.spawned.length).assertEqual(3);
      expect(JSON.stringify(turn.spawned.map((index: number) => turn.spawnBoard[index]))).assertEqual('[2,4,6]');
      expect(engine.round.board.filter((color: number) => color >= 0).length).assertEqual(4);
      expect(engine.round.score).assertEqual(0);
      expect(engine.round.moves).assertEqual(1);
      expect(engine.round.next.length).assertEqual(3);
    });
    it('undo restores randomness and preview, while earned lifetime progress stays monotonic', kind, () => {
      const engine = bloomFixture();
      engine.round.board[0] = 0;
      const before = JSON.stringify(engine.round);
      const first = engine.move(0, 1);
      const after = JSON.stringify(engine.round);
      expect(engine.undo()).assertEqual(true);
      expect(JSON.stringify(engine.round)).assertEqual(before);
      expect(JSON.stringify(engine.move(0, 1))).assertEqual(JSON.stringify(first));
      expect(JSON.stringify(engine.round)).assertEqual(after);
      engine.reset('garden', 8); bloomPrepareClear(engine);
      engine.move(7, 4);
      expect(engine.profile.totalCleared).assertEqual(5);
      expect(engine.undo()).assertEqual(true);
      engine.move(7, 4);
      expect(engine.profile.totalCleared).assertEqual(5);
      expect(engine.best()).assertEqual(10);
    });
    it('round replacement keeps lifetime progress and independent mode bests', kind, () => {
      const engine = bloomFixture();
      bloomPrepareClear(engine); engine.move(7, 4);
      const session = engine.round.session;
      engine.reset('classic', 1);
      expect(engine.round.session === session).assertEqual(false);
      expect(engine.profile.bestGarden).assertEqual(10);
      expect(engine.profile.bestClassic).assertEqual(0);
      expect(engine.profile.totalCleared).assertEqual(5);
      expect(engine.history.length).assertEqual(0);
      expect(engine.credited).assertEqual(0);
      bloomPrepareClear(engine); engine.move(9, 4);
      expect(engine.profile.totalCleared).assertEqual(10);
      expect(engine.profile.bestClassic).assertEqual(10);
    });
    it('a full board settles once and cannot be moved or undone', kind, () => {
      const engine = bloomFixture();
      engine.round.board = engine.round.board.map((_color: number, index: number) =>
        (index % 7 + Math.floor(index / 7) * 2) % 5);
      engine.round.board[0] = -1;
      const turn = engine.move(1, 0);
      expect(turn.valid).assertEqual(true);
      expect(turn.spawned.length).assertEqual(1);
      expect(engine.round.ended).assertEqual(true);
      const ended = engine.serialize();
      expect(engine.undo()).assertEqual(false);
      expect(engine.move(0, 1).valid).assertEqual(false);
      expect(engine.serialize()).assertEqual(ended);
      expect(engine.restore(ended)).assertEqual(true);
    });
    it('a line made by the last new bead clears before the full-board check', kind, () => {
      const engine = bloomFixture();
      engine.round.board = engine.round.board.map((_color: number, index: number) =>
        (index % 7 + Math.floor(index / 7) * 2) % 5);
      engine.round.board[0] = -1;
      [1, 2, 3, 4].forEach((index: number) => { engine.round.board[index] = 0; });
      engine.round.next = [0, 1];
      const turn = engine.move(1, 0);
      expect(turn.valid).assertEqual(true);
      expect(turn.clearFromMove).assertEqual(false);
      expect(turn.spawned.length).assertEqual(1);
      expect(turn.removed.length >= 5).assertEqual(true);
      expect(engine.round.ended).assertEqual(false);
      expect(engine.round.score >= 10).assertEqual(true);
    });
    it('restores board, history and high-water credit and rejects corrupt data atomically', kind, () => {
      const engine = bloomFixture(); bloomPrepareClear(engine); engine.move(7, 4); engine.undo();
      const raw = engine.serialize();
      const restored = new BloomEngine();
      expect(restored.restore(raw)).assertEqual(true);
      expect(restored.serialize()).assertEqual(raw);
      const bad = engine.snapshot(); bad.round.board[0] = 99;
      expect(restored.restore(JSON.stringify(bad))).assertEqual(false);
      expect(restored.restore('{"version":1}')).assertEqual(false);
      expect(restored.restore('null')).assertEqual(false);
      expect(restored.restore('broken')).assertEqual(false);
      expect(restored.serialize()).assertEqual(raw);
      restored.move(7, 4);
      expect(restored.profile.totalCleared).assertEqual(5);
    });
    it('makes tablet cells larger while retaining usable phone cells in both modes', kind, () => {
      const insets: BloomInsets = { top: 24, bottom: 24, left: 0, right: 0 };
      const modes: BloomMode[] = ['garden', 'classic'];
      modes.forEach((mode: BloomMode) => {
        const phone = bloomLayout(390, 844, insets, [], mode);
        const tablet = bloomLayout(1280, 900, insets, [], mode);
        expect(phone.wide).assertEqual(false);
        expect(tablet.wide).assertEqual(true);
        expect(phone.cell >= 28).assertEqual(true);
        expect(tablet.cell > phone.cell).assertEqual(true);
        expect(phone.contentWidth <= phone.width).assertEqual(true);
        expect(tablet.boardBox.x + tablet.boardBox.width <= tablet.stats.x).assertEqual(true);
      });
    });
    it('avoids every hinge, including offset windows and two-crease displays', kind, () => {
      const safe: BloomInsets = { top: 20, bottom: 20, left: 0, right: 0 };
      const half = bloomViewport(800, 1200, safe, [{ x: 0, y: 590, width: 800, height: 20 }]);
      expect(half.height).assertEqual(570);
      expect(half.y).assertEqual(20);
      const triple = bloomViewport(1200, 800, safe,
        [{ x: 390, y: 0, width: 20, height: 800 }, { x: 790, y: 0, width: 20, height: 800 }]);
      expect(triple.width).assertEqual(390);
      const outside = bloomViewport(390, 844, safe, [{ x: 800, y: 0, width: 20, height: 844 }]);
      expect(outside.width).assertEqual(390);
      expect(bloomUsesCreases(3)).assertEqual(true);
      expect(bloomUsesCreases(23)).assertEqual(true);
      expect(bloomUsesCreases(1)).assertEqual(false);
      expect(bloomUsesCreases(2)).assertEqual(false);
    });
    it('returns stable positions after repeated fold and unfold, with scrolling for very small panes', kind, () => {
      const safe: BloomInsets = { top: 20, bottom: 20, left: 0, right: 0 };
      const original = bloomLayout(1280, 900, safe);
      bloomLayout(360, 780, safe);
      bloomLayout(1280, 900, safe, [{ x: 0, y: 440, width: 1280, height: 20 }]);
      expect(sameBloomLayout(original, bloomLayout(1280, 900, safe))).assertEqual(true);
      const small = bloomLayout(200, 260, safe);
      expect(small.contentHeight > small.body).assertEqual(true);
      expect(small.contentWidth > small.width).assertEqual(true);
      expect(small.cell > 0).assertEqual(true);
      expect(small.tools.y >= small.boardBox.y + small.boardBox.height).assertEqual(true);
    });
  });
}
