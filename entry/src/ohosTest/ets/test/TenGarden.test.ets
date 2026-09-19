import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import { TenEngine } from '../../../main/ets/gamesNext/tenGarden/TenEngine';
import { TenGesture } from '../../../main/ets/gamesNext/tenGarden/TenGesture';
import { TenPath, tenProfile } from '../../../main/ets/gamesNext/tenGarden/TenModel';
import { tenHasMove, tenPuzzle, tenSelect, tenShift, tenValidPath } from '../../../main/ets/gamesNext/tenGarden/TenRules';
import { TenInsets, tenLayout, tenUsesCreases, tenViewport } from '../../../main/ets/gamesNext/tenGarden/TenLayout';
import { tenReconcileTiles } from '../../../main/ets/gamesNext/tenGarden/TenRenderTile';

export default function tenGardenTest(): void {
  describe('TenGarden', () => {
    const kind = TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0;
    it('intro clears in two moves and next requires a persisted settlement', kind, () => {
      const e = new TenEngine();
      expect(e.submit([3, 4])).assertEqual(true);
      expect(e.direction()).assertEqual(1);
      expect(e.round.board.join(',')).assertEqual('0,0,0,0,0,0,3,4,3');
      expect(e.submit([6, 7, 8])).assertEqual(true);
      expect(e.round.phase).assertEqual('complete');
      expect(e.next()).assertEqual(false);
      expect(e.submit([6, 7, 8])).assertEqual(false);
      e.round.reported = true;
      expect(e.next()).assertEqual(true);
      expect(e.round.stage).assertEqual(2);
      expect(e.round.board.length).assertEqual(36);
      expect(tenProfile(e.round).totalWins).assertEqual(1);
    });
    it('all bank puzzles and rotations have playable certificates', kind, () => {
      for (let stage = 2; stage <= 257; stage += 1) {
        const e = new TenEngine(stage);
        e.puzzle.solution.forEach((path: TenPath) => { expect(e.submit(path.cells)).assertEqual(true); });
        expect(e.round.phase).assertEqual('complete');
        expect(e.round.history.length).assertEqual(12);
      }
    });
    it('invalid selections do not mutate values, direction or progress', kind, () => {
      const e = new TenEngine();
      const before = e.serialize();
      [[], [3], [3, 3, 4], [3, 7], [4, 5], [0, 1], [-1, 3], [3, 4, 7]].forEach((path: number[]) => {
        expect(e.submit(path)).assertEqual(false);
        expect(e.serialize()).assertEqual(before);
      });
      expect(tenValidPath([1, 2, 3, 4], [0, 1, 3, 2], 2)).assertEqual(true);
    });
    it('one-axis shifts preserve order and do not refill numbers', kind, () => {
      const board: number[] = [1, 0, 2, 0, 3, 0, 4, 0, 5];
      expect(tenShift(board, [], 3, 0).join(',')).assertEqual('0,0,0,1,0,2,4,3,5');
      expect(tenShift(board, [], 3, 1).join(',')).assertEqual('1,2,0,3,0,0,4,5,0');
      expect(tenShift(board, [], 3, 2).join(',')).assertEqual('1,3,2,4,0,5,0,0,0');
      expect(tenShift(board, [], 3, 3).join(',')).assertEqual('0,1,2,0,0,3,0,4,5');
      expect(board.join(',')).assertEqual('1,0,2,0,3,0,4,0,5');
    });
    it('tap backtracking removes only the intended suffix', kind, () => {
      const board = tenPuzzle(1).values;
      expect(tenSelect(board, [6, 7, 8], 7, 3).join(',')).assertEqual('6,7');
      expect(tenSelect(board, [6, 7], 7, 3).join(',')).assertEqual('6');
      expect(tenSelect(board, [6], 4, 3).join(',')).assertEqual('6');
      expect(tenSelect(board, [3, 4], 7, 3).join(',')).assertEqual('3,4');
    });
    it('a fast drag exposes the first sum-ten path before release', kind, () => {
      const board: number[] = [2, 8, 3, 0, 0, 0, 0, 0, 0];
      const input = new TenGesture();
      input.begin(50, 50, [], 3, 306, 6);
      const selected = input.move(256, 50, board, 3, 306, 6);
      expect(selected.join(',')).assertEqual('0,1');
      expect(tenValidPath(board, selected, 3)).assertEqual(true);
      expect(input.cancel().length).assertEqual(0);
    });
    it('a keyed tile keeps its live position after compaction and undo', kind, () => {
      const e = new TenEngine(2);
      let views = tenReconcileTiles([], e.tiles());
      const moving = views[2];
      expect(moving.id).assertEqual(3);
      e.submit(e.puzzle.solution[0].cells); views = tenReconcileTiles(views, e.tiles());
      e.submit(e.puzzle.solution[1].cells); views = tenReconcileTiles(views, e.tiles());
      expect(views.find(tile => tile.id === 3) === moving).assertEqual(true);
      expect(moving.index).assertEqual(0);
      expect(e.round.board[moving.index]).assertEqual(moving.value);
      e.rewind(); views = tenReconcileTiles(views, e.tiles());
      expect(views.find(tile => tile.id === 3) === moving).assertEqual(true);
      expect(moving.index).assertEqual(2);
      expect(e.round.board[moving.index]).assertEqual(moving.value);
    });
    it('hints validate the target board and reject a stale path without mutation', kind, () => {
      const e = new TenEngine(2);
      const original = e.serialize(), hint = e.hint();
      expect(hint !== undefined).assertEqual(true);
      if (hint === undefined) return;
      expect(e.serialize()).assertEqual(original);
      expect(tenValidPath(e.round.board, hint.path, 6)).assertEqual(true);
      e.submit(hint.path);
      const moved = e.serialize();
      expect(e.applyHint(hint)).assertEqual(false);
      expect(e.serialize()).assertEqual(moved);
      // Reject invalid reference data instead of ever rendering an empty-cell hint.
      const invalid = new TenEngine(); invalid.puzzle.solution[0].cells = [0, 1];
      expect(invalid.hint() === undefined).assertEqual(true);
    });
    it('undo and restart restore exact board and never duplicate credited progress', kind, () => {
      const e = new TenEngine(2), original = e.round.board.join(',');
      const path = e.puzzle.solution[0].cells;
      e.submit(path); e.rewind(); e.submit(path); e.restart();
      expect(e.round.board.join(',')).assertEqual(original);
      expect(e.round.history.length).assertEqual(0);
      expect(e.round.credited).assertEqual(1);
      expect(tenProfile(e.round).totalGroups).assertEqual(3);
    });
    it('a remaining total of ten is not a legal move across empty spaces', kind, () => {
      const board: number[] = new Array<number>(36).fill(0);
      board[0] = 1; board[6] = 6; board[12] = 1; board[3] = 2;
      const original = board.join(',');
      expect(tenHasMove(board, 6)).assertEqual(false);
      expect(tenValidPath(board, [12, 6, 0, 3], 6)).assertEqual(false);
      expect(board.join(',')).assertEqual(original);
      board[3] = 0; board[1] = 2;
      expect(tenHasMove(board, 6)).assertEqual(true);
      expect(tenValidPath(board, [12, 6, 0, 1], 6)).assertEqual(true);
      expect(tenHasMove(new Array<number>(36).fill(0), 6)).assertEqual(false);
    });
    it('previous-stage review preserves and restores the original challenge exactly', kind, () => {
      const e = new TenEngine(3);
      e.submit(e.puzzle.solution[0].cells);
      const original = e.serialize();
      expect(e.previous()).assertEqual(true);
      expect(e.round.stage).assertEqual(2);
      expect(e.resumeStage()).assertEqual(3);
      expect(e.profile().totalGroups).assertEqual(15);
      expect(e.previous()).assertEqual(true);
      expect(e.round.stage).assertEqual(1);
      expect(e.previous()).assertEqual(false);
      const restored = new TenEngine();
      expect(restored.restore(e.serialize())).assertEqual(true);
      expect(restored.resume()).assertEqual(true);
      expect(restored.serialize()).assertEqual(original);
    });
    it('review completion returns to the saved board without requiring or adding a settlement', kind, () => {
      const e = new TenEngine(2);
      e.submit(e.puzzle.solution[0].cells);
      const original = e.serialize();
      e.previous(); e.submit([3, 4]); e.submit([6, 7, 8]);
      expect(e.round.reported).assertEqual(false);
      expect(e.profile().totalGroups).assertEqual(3);
      expect(e.profile().totalWins).assertEqual(1);
      expect(e.next()).assertEqual(true);
      expect(e.serialize()).assertEqual(original);
    });
    it('saved move history and stable tile identities restore atomically', kind, () => {
      const e = new TenEngine(2); e.submit(e.puzzle.solution[0].cells);
      const raw = e.serialize(), restored = new TenEngine();
      expect(restored.restore(raw)).assertEqual(true);
      expect(restored.serialize()).assertEqual(raw);
      const corrupt = e.snapshot(); corrupt.round.ids[0] = 999;
      expect(e.restore(JSON.stringify(corrupt))).assertEqual(false);
      expect(e.serialize()).assertEqual(raw);
      expect(e.restore('{}')).assertEqual(false);
    });
    it('folded phone-size panes remain playable and expanded tablets use a side rail', kind, () => {
      const safe: TenInsets = { top: 24, bottom: 24, left: 0, right: 0 };
      const phone = tenLayout(390, 844, safe), tablet = tenLayout(1280, 900, safe);
      expect(phone.board.width).assertEqual(phone.contentWidth);
      expect(phone.cell >= 44).assertEqual(true);
      expect(tablet.cell > phone.cell).assertEqual(true);
      expect(tablet.wide).assertEqual(true);
      expect(tablet.tools.height > phone.tools.height).assertEqual(true);
      expect(tenViewport(1200, 800, safe, [
        { x: 390, y: 0, width: 20, height: 800 }, { x: 790, y: 0, width: 20, height: 800 }
      ]).width).assertEqual(390);
      expect(tenUsesCreases(2)).assertEqual(false);
      expect(tenUsesCreases(23)).assertEqual(true);
    });
  });
}
