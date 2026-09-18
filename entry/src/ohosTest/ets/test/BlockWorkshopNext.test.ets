import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import { BlockEngine } from '../../../main/ets/gamesNext/blockWorkshop/BlockEngine';
import { BLOCK_SHAPES, BlockRound } from '../../../main/ets/gamesNext/blockWorkshop/BlockModel';
import { blockLayout, BlockCrease, BlockInsets } from '../../../main/ets/gamesNext/blockWorkshop/BlockLayout';
import { achievementCanonicalGameId, achievementPrimaryFavoriteCount } from '../../../main/ets/shell/AchievementRegistry';
import { gameLogoPath, moduleById } from '../../../main/ets/shell/GameRegistry';

function blockClearFixture(count: number): BlockEngine {
  const game = new BlockEngine(42);
  game.round.board.fill(0);
  for (let row = 22 - count; row < 22; row += 1) {
    for (let col = 0; col < 10; col += 1) if (col !== 4) game.round.board[row * 10 + col] = 2;
  }
  game.round.piece = { kind: 0, turn: 1, x: 2, y: 1 };
  return game;
}

export default function blockWorkshopNextTest(): void {
  describe('BlockWorkshopNext', () => {
    const flags = TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0;
    it('has seven legal four-cell shapes and valid opening queue', flags, () => {
      expect(BLOCK_SHAPES.length).assertEqual(7);
      BLOCK_SHAPES.forEach((turns: number[][]) => turns.forEach((cells: number[]) => {
        expect(new Set<number>(cells).size).assertEqual(4);
        expect(cells.every((cell: number): boolean => cell >= 0 && cell < 16)).assertTrue();
      }));
      for (let seed = 0; seed < 50; seed += 1) {
        const game = new BlockEngine(seed);
        expect(game.fits(game.round.piece)).assertTrue();
        expect(game.round.queue.length).assertEqual(3);
      }
    });
    it('draws each piece once per seven-bag and restores deterministic future bags', flags, () => {
      const game = new BlockEngine(17);
      const sequence: number[] = [];
      for (let i = 0; i < 70; i += 1) {
        sequence.push(game.round.piece.kind);
        game.command('drop'); game.round.board.fill(0);
      }
      for (let i = 0; i < 70; i += 7) expect(new Set<number>(sequence.slice(i, i + 7)).size).assertEqual(7);
      const restored = new BlockEngine(3);
      expect(restored.restore(game.serialize())).assertTrue();
      for (let i = 0; i < 50; i += 1) {
        game.command('drop'); restored.command('drop');
        expect(restored.serialize()).assertEqual(game.serialize());
        game.round.board.fill(0); restored.round.board.fill(0);
      }
    });
    it('hold exchanges pieces once until lock and keeps the preview in order', flags, () => {
      const game = new BlockEngine(9);
      const first = game.round.piece.kind;
      const next = game.round.queue[0];
      expect(game.command('hold')).assertTrue();
      expect(game.round.hold).assertEqual(first);
      expect(game.round.piece.kind).assertEqual(next);
      expect(game.command('hold')).assertFalse();
      game.command('drop');
      const after = game.round.piece.kind;
      const queue = game.round.queue.join(',');
      expect(game.command('hold')).assertTrue();
      expect(game.round.piece.kind).assertEqual(first);
      expect(game.round.hold).assertEqual(after);
      expect(game.round.queue.join(',')).assertEqual(queue);
    });
    it('ghost predicts the landing and soft/hard drops score their exact distance', flags, () => {
      const game = new BlockEngine(15);
      const y = game.round.piece.y;
      const ghost = game.ghostY();
      game.command('down');
      expect(game.round.score).assertEqual(1);
      game.command('drop');
      expect(game.round.score).assertEqual(1 + (ghost - y - 1) * 2);
      expect(game.round.board.filter((cell: number): boolean => cell > 0).length).assertEqual(4);
      expect(game.round.pieces).assertEqual(1);
    });
    it('respects left/right walls and kicks rotations away from wall and floor', flags, () => {
      const game = new BlockEngine(3);
      game.round.piece = { kind: 2, turn: 0, x: 3, y: 4 };
      for (let i = 0; i < 30; i += 1) game.command('left');
      expect(game.round.piece.x).assertEqual(0);
      expect(game.command('left')).assertFalse();
      game.round.piece = { kind: 0, turn: 1, x: 7, y: 4 };
      expect(game.command('rotate')).assertTrue();
      expect(game.fits(game.round.piece)).assertTrue();
      game.round.piece = { kind: 0, turn: 0, x: 3, y: 20 };
      expect(game.command('rotate')).assertTrue();
      expect(game.round.piece.y).assertEqual(18);
      expect(game.fits(game.round.piece)).assertTrue();
    });
    it('allows four rotations in open space and rejects blocked rotations atomically', flags, () => {
      const game = new BlockEngine(2);
      for (let kind = 0; kind < 7; kind += 1) {
        game.round.piece = { kind: kind, turn: 0, x: 3, y: 5 };
        for (let i = 0; i < 4; i += 1) game.command('rotate');
        expect(game.round.piece.turn).assertEqual(0);
        expect(game.round.piece.x).assertEqual(3);
        expect(game.round.piece.y).assertEqual(5);
      }
      game.round.piece = { kind: 0, turn: 0, x: 3, y: 20 };
      game.round.board.fill(1);
      for (let col = 3; col < 7; col += 1) game.round.board[210 + col] = 0;
      const before = JSON.stringify(game.round.piece);
      expect(game.command('rotate')).assertFalse();
      expect(JSON.stringify(game.round.piece)).assertEqual(before);
    });
    it('gravity honors elapsed time and caps one delayed callback to 250ms', flags, () => {
      const game = new BlockEngine(12);
      const y = game.round.piece.y;
      game.advance(250); game.advance(250); game.advance(199);
      expect(game.round.piece.y).assertEqual(y);
      game.advance(1);
      expect(game.round.piece.y).assertEqual(y + 1);
      game.advance(100000);
      expect(game.round.piece.y).assertEqual(y + 1);
      expect(game.round.fallMs).assertEqual(250);
      game.advance(NaN); game.advance(-1);
      expect(game.round.fallMs).assertEqual(250);
    });
    it('locks after 500ms and bounds grounded manipulation resets', flags, () => {
      const game = new BlockEngine(12);
      game.round.piece = { kind: 1, turn: 0, x: 3, y: 20 };
      game.advance(250); game.advance(249);
      expect(game.round.pieces).assertEqual(0);
      game.advance(1);
      expect(game.round.pieces).assertEqual(1);
      const other = new BlockEngine(12);
      other.round.piece = { kind: 1, turn: 0, x: 3, y: 20 };
      for (let i = 0; i < 16; i += 1) {
        other.advance(200); other.advance(200);
        other.command(i % 2 === 0 ? 'left' : 'right');
        if (i < 15) expect(other.round.lockMs).assertEqual(0);
      }
      expect(other.round.resets).assertEqual(15);
      expect(other.round.lockMs).assertEqual(400);
      other.advance(100);
      expect(other.round.pieces).assertEqual(1);
    });
    it('clears one through four rows with exact scoring and stable compaction', flags, () => {
      const points = [100, 300, 500, 800];
      for (let count = 1; count <= 4; count += 1) {
        const game = blockClearFixture(count);
        const dropPoints = (game.ghostY() - game.round.piece.y) * 2;
        game.command('drop');
        expect(game.round.phase).assertEqual('clearing');
        expect(game.round.lines).assertEqual(count);
        expect(game.round.score).assertEqual(points[count - 1] + dropPoints);
        expect(game.command('drop')).assertFalse();
        game.advance(159);
        expect(game.round.phase).assertEqual('clearing');
        game.advance(1);
        expect(game.round.phase).assertEqual('falling');
        expect(game.round.board.filter((cell: number): boolean => cell > 0).length).assertEqual(4 - count);
        if (count < 4) expect(game.round.board[214]).assertEqual(1);
      }
    });
    it('levels up at 20 lines using pre-clear level for points and rewards combos', flags, () => {
      const game = blockClearFixture(1);
      game.round.lines = 19;
      game.round.combo = 0;
      const drop = (game.ghostY() - game.round.piece.y) * 2;
      game.command('drop');
      expect(game.round.score).assertEqual(150 + drop);
      expect(game.round.level).assertEqual(2);
      expect(game.takeEvents().some((event): boolean => event.name === 'level')).assertTrue();
      game.advance(160);
      game.round.board.fill(0);
      game.command('drop');
      expect(game.round.combo).assertEqual(-1);
    });
    it('restores a partly completed clear without scoring or clearing twice', flags, () => {
      const game = blockClearFixture(4);
      game.command('drop'); game.advance(73);
      const restored = new BlockEngine(99);
      expect(restored.restore(game.serialize())).assertTrue();
      game.advance(87); restored.advance(87);
      expect(restored.serialize()).assertEqual(game.serialize());
      expect(restored.round.lines).assertEqual(4);
      expect(restored.takeEvents().length).assertEqual(0);
    });
    it('tops out on blocked spawn and ends only once', flags, () => {
      const game = new BlockEngine(42);
      for (let col = 0; col < 10; col += 1) game.round.board[10 + col] = col === 9 ? 0 : 1;
      game.round.piece = { kind: 1, turn: 0, x: 3, y: 15 };
      game.command('drop');
      expect(game.round.phase).assertEqual('over');
      expect(game.takeEvents().filter((event): boolean => event.name === 'finish').length).assertEqual(1);
      const saved = game.serialize();
      game.advance(200); expect(game.command('drop')).assertFalse();
      expect(game.serialize()).assertEqual(saved);
      expect(game.takeEvents().length).assertEqual(0);
    });
    it('rejects broken or inconsistent saves without replacing the current round', flags, () => {
      const game = new BlockEngine(4);
      const original = game.serialize();
      const corrupt: string[] = ['', '{}', 'null', '[1,2]', original.replace('"version":1', '"version":2')];
      const invalid: BlockRound = JSON.parse(original) as BlockRound;
      invalid.board.fill(1, 210, 220); corrupt.push(JSON.stringify(invalid));
      invalid.board.fill(0); invalid.queue = [0, 20, 3]; corrupt.push(JSON.stringify(invalid));
      invalid.queue = [0, 1, 2]; invalid.piece.x = 20; corrupt.push(JSON.stringify(invalid));
      corrupt.forEach((raw: string) => { expect(game.restore(raw)).assertFalse(); expect(game.serialize()).assertEqual(original); });
    });
    it('survives randomized long play with legal active pieces and bounded state', flags, () => {
      const actions = ['left', 'right', 'rotate', 'reverse', 'hold', 'down', 'drop'];
      let seed = 720;
      for (let run = 0; run < 30; run += 1) {
        const game = new BlockEngine(run);
        for (let i = 0; i < 1000 && game.round.phase !== 'over'; i += 1) {
          seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
          game.command(actions[seed % actions.length]); game.advance(seed % 251); game.takeEvents();
          expect(game.round.board.length).assertEqual(220);
          expect(game.round.board.every((v: number): boolean => Number.isInteger(v) && v >= 0 && v <= 7)).assertTrue();
          if (game.round.phase === 'falling') expect(game.fits(game.round.piece)).assertTrue();
          if (i % 20 === 0) { const copy = new BlockEngine(8); expect(copy.restore(game.serialize())).assertTrue(); }
        }
      }
    });
    it('keeps ordinary phones, landscape, unfolded screens and tablets playable', flags, () => {
      const insets: BlockInsets = { top: 24, bottom: 16, left: 0, right: 0 };
      const sizes: number[][] = [[320,480], [320,568], [390,844], [568,320], [844,390], [720,720],
        [768,1024], [1024,768], [1280,800], [390,720]];
      sizes.forEach((size: number[]) => {
        const view = blockLayout(size[0], size[1], insets);
        expect(view.limited).assertFalse();
        expect(view.boardHeight).assertEqual(view.boardWidth * 2);
        expect(view.boardHeight + 16 <= view.body + 0.001).assertTrue();
        expect(view.boardWidth + 16 + view.rail + view.gap * 3 <= view.contentWidth + 0.001).assertTrue();
        expect((view.keys - view.keyGap) / 2 >= 44).assertTrue();
        const previews = view.compact ? 46 : 60;
        const railHeight = view.wide ? view.stats + view.keys + previews + view.gap * 2 +
          (view.compact ? 0 : previews + view.gap) + (view.body >= 280 ? 48 + view.gap : 0) :
          previews * 4 + (view.compact ? 6 : 10) * 3 +
            (view.ornamentHeight > 0 ? view.ornamentHeight + 20 : 0);
        expect(railHeight <= view.body + 0.001).assertTrue();
      });
    });
    it('enlarges controls on roomy tablets and unfolded screens without shrinking phone controls', flags, () => {
      const insets: BlockInsets = { top: 24, bottom: 16, left: 0, right: 0 };
      const phone = blockLayout(390, 844, insets);
      expect(phone.keys).assertEqual(108); expect(phone.keyGap).assertEqual(8);
      expect(phone.spaciousControls).assertFalse();
      const short = blockLayout(844, 390, insets);
      expect(short.keys).assertEqual(96); expect(short.spaciousControls).assertFalse();
      [[720, 720], [768, 1024], [1024, 768], [1280, 800]].forEach((size: number[]) => {
        const view = blockLayout(size[0], size[1], insets);
        expect(view.spaciousControls).assertTrue();
        expect((view.keys - view.keyGap) / 2 >= 72).assertTrue();
        expect((view.rail - view.keyGap * 2) / 3 >= 85).assertTrue();
        expect(view.boardWidth >= 280).assertTrue();
      });
      const crease: BlockCrease = { x: 0, y: 0, width: 0, height: 0 };
      const fold = blockLayout(600, 720, insets, crease, { foldable: true, status: 1 });
      expect(fold.wide).assertTrue(); expect(fold.spaciousControls).assertTrue(); expect(fold.limited).assertFalse();
      expect(fold.boardWidth + 16 + fold.rail + fold.gap * 3 <= fold.width).assertTrue();
    });
    it('allows phone-sized windows in every fold state and only prompts when space is insufficient', flags, () => {
      const insets: BlockInsets = { top: 24, bottom: 16, left: 0, right: 0 };
      const crease: BlockCrease = { x: 0, y: 0, width: 0, height: 0 };
      [0, 1, 2, 3, 11, 12, 13, 21, 22, 23].forEach((status: number) => {
        [[320, 480], [390, 844], [568, 320], [600, 720], [800, 1000]].forEach((size: number[]) => {
          const view = blockLayout(size[0], size[1], insets, crease, { foldable: true, status: status });
          expect(view.unfold).assertFalse(); expect(view.limited).assertFalse();
          expect(view.boardHeight + 16 <= view.body + 0.001).assertTrue();
          expect(view.boardWidth + 16 + view.rail + view.gap * 3 <= view.contentWidth + 0.001).assertTrue();
        });
      });
      [2, 3, 12, 13, 21, 22, 23].forEach((status: number) => {
        [[250, 800], [390, 420]].forEach((size: number[]) => {
          const view = blockLayout(size[0], size[1], insets, crease, { foldable: true, status: status });
          expect(view.unfold).assertTrue(); expect(view.limited).assertTrue();
        });
      });
      const phone = blockLayout(320, 480, insets, crease, { foldable: false, status: 2 });
      expect(phone.unfold).assertFalse(); expect(phone.limited).assertFalse();
      const tiny = blockLayout(250, 800, insets);
      expect(tiny.limited).assertTrue(); expect(tiny.unfold).assertFalse();
    });
    it('selects the larger fold pane and pauses only when that area is too small', flags, () => {
      const insets: BlockInsets = { top: 24, bottom: 16, left: 0, right: 0 };
      const small = blockLayout(390, 844, insets, { x: 0, y: 415, width: 390, height: 14 });
      expect(small.halfFoldPane).assertTrue(); expect(small.limited).assertTrue();
      const large = blockLayout(1000, 1100, insets, { x: 0, y: 520, width: 1000, height: 20 });
      expect(large.y).assertEqual(540); expect(large.limited).assertFalse();
      const vertical = blockLayout(1000, 800, insets, { x: 380, y: 0, width: 20, height: 800 });
      expect(vertical.x).assertEqual(400); expect(vertical.width).assertEqual(600); expect(vertical.limited).assertFalse();
      expect(blockLayout(250, 800, insets).limited).assertTrue();
      const outside = blockLayout(390, 844, insets, { x: 1000, y: 400, width: 390, height: 20 });
      expect(outside.halfFoldPane).assertFalse();
      const line = blockLayout(390, 844, insets, { x: 0, y: 420, width: 390, height: 0 });
      expect(line.halfFoldPane).assertTrue(); expect(line.limited).assertTrue();
      const phone = blockLayout(320, 480, insets);
      const phonePane = blockLayout(320, 928, insets, { x: 0, y: 460, width: 320, height: 12 },
        { foldable: true, status: 3 });
      expect(phonePane.halfFoldPane).assertTrue(); expect(phonePane.limited).assertFalse();
      expect(phonePane.unfold).assertFalse(); expect(phonePane.cell).assertEqual(phone.cell);
      expect(phonePane.keys).assertEqual(phone.keys);
    });
    it('reuses the classic home icon and canonical achievements without removing its route', flags, () => {
      expect(moduleById('tetrisNext').id).assertEqual('tetrisNext');
      expect(moduleById('tetris').id).assertEqual('tetris');
      expect(gameLogoPath('tetrisNext')).assertEqual(gameLogoPath('tetris'));
      expect(achievementCanonicalGameId('tetrisNext')).assertEqual('tetris');
      expect(achievementPrimaryFavoriteCount(['tetris', 'tetrisNext'])).assertEqual(1);
    });
  });
}
