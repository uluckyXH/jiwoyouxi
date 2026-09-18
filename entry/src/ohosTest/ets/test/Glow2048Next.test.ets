import { describe, it, expect, TestType, Size, Level } from '@ohos/hypium';
import { GlowEngine, glowCanMove, glowSlide } from '../../../main/ets/gamesNext/glow2048/GlowEngine';
import { GlowDirection, GlowSave, GlowTile, glowMax } from '../../../main/ets/gamesNext/glow2048/GlowModel';
import { GlowInsets, glowLayout } from '../../../main/ets/gamesNext/glow2048/GlowLayout';
import { gameLogoPath } from '../../../main/ets/shell/GameRegistry';
import { achievementPrimaryFavoriteCount } from '../../../main/ets/shell/AchievementRegistry';

const GLOW_FLAGS = TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0;
function glowTestTiles(values: number[]): GlowTile[] {
  const tiles: GlowTile[] = [];
  values.forEach((value: number, index: number) => { if (value > 0) tiles.push({ id: index + 1, value: value, index: index }); });
  return tiles;
}
function glowTestValues(tiles: GlowTile[]): number[] {
  const values: number[] = new Array<number>(16).fill(0);
  tiles.forEach((tile: GlowTile) => { values[tile.index] = tile.value; });
  return values;
}
function glowTestSave(values: number[]): GlowSave {
  const engine = new GlowEngine();
  const save = JSON.parse(engine.serialize()) as GlowSave;
  save.tiles = glowTestTiles(values);
  save.nextId = Math.max(...save.tiles.map((tile: GlowTile) => tile.id)) + 1;
  save.moves = save.nextId - 3;
  save.ended = !glowCanMove(save.tiles);
  return save;
}

export default function glow2048NextTest(): void {
  describe('Glow2048Next', () => {
    it('initial_board_has_two_distinct_low_tiles', GLOW_FLAGS, () => {
      const engine = new GlowEngine();
      for (let seed = 0; seed < 200; seed++) {
        engine.reset(seed);
        expect(engine.tiles.length).assertEqual(2);
        expect(engine.tiles[0].index !== engine.tiles[1].index).assertTrue();
        expect(engine.tiles.every((tile: GlowTile) => tile.value === 2 || tile.value === 4)).assertTrue();
        expect(engine.moves).assertEqual(0);
        expect(engine.score).assertEqual(0);
      }
    });
    it('all_four_directions_merge_towards_the_correct_edge', GLOW_FLAGS, () => {
      const horizontal = glowTestTiles([0, 0, 2, 2]);
      const vertical = glowTestTiles([0, 0, 0, 0, 2, 0, 0, 0, 2]);
      expect(glowSlide(horizontal, 'left').tiles[0].index).assertEqual(0);
      expect(glowSlide(horizontal, 'right').tiles[0].index).assertEqual(3);
      expect(glowSlide(vertical, 'up').tiles[0].index).assertEqual(0);
      expect(glowSlide(vertical, 'down').tiles[0].index).assertEqual(12);
      expect(glowSlide(vertical, 'down').gain).assertEqual(4);
    });
    it('a_newly_merged_tile_cannot_merge_twice_in_one_turn', GLOW_FLAGS, () => {
      expect(glowTestValues(glowSlide(glowTestTiles([2, 2, 2, 2]), 'left').tiles).slice(0, 4).join(',')).assertEqual('4,4,0,0');
      expect(glowTestValues(glowSlide(glowTestTiles([2, 2, 2, 0]), 'right').tiles).slice(0, 4).join(',')).assertEqual('0,0,2,4');
      const result = glowSlide(glowTestTiles([4, 4, 8, 0]), 'left');
      expect(glowTestValues(result.tiles).slice(0, 4).join(',')).assertEqual('8,8,0,0');
      expect(result.gain).assertEqual(8);
    });
    it('slides_preserve_input_sum_and_unique_slots_with_complete_motion_paths', GLOW_FLAGS, () => {
      const directions: GlowDirection[] = ['left', 'right', 'up', 'down'];
      for (let seed = 0; seed < 100; seed++) {
        const input = glowTestTiles(new Array<number>(16).fill(0).map((v: number, i: number) =>
          (seed + i * 13) % 5 === 0 ? 0 : Math.pow(2, 1 + (seed * 7 + i) % 4)));
        const before = JSON.stringify(input);
        directions.forEach((direction: GlowDirection) => {
          const result = glowSlide(input, direction);
          expect(result.tiles.reduce((sum: number, tile: GlowTile) => sum + tile.value, 0))
            .assertEqual(input.reduce((sum: number, tile: GlowTile) => sum + tile.value, 0));
          expect(new Set<number>(result.tiles.map((tile: GlowTile) => tile.index)).size).assertEqual(result.tiles.length);
          expect(result.motions.length).assertEqual(input.length);
          expect(new Set<number>(result.motions.map((motion) => motion.id)).size).assertEqual(input.length);
          expect(JSON.stringify(input)).assertEqual(before);
        });
      }
    });
    it('invalid_moves_do_not_spawn_score_or_advance_random_state', GLOW_FLAGS, () => {
      const engine = new GlowEngine();
      expect(engine.restore(JSON.stringify(glowTestSave([2, 4, 8, 16])))).assertTrue();
      const before = engine.serialize();
      expect(engine.move('left').moved).assertFalse();
      expect(engine.serialize()).assertEqual(before);
      expect(engine.move('up').moved).assertFalse();
      expect(engine.serialize()).assertEqual(before);
    });
    it('valid_moves_spawn_exactly_one_tile_and_score_only_merges', GLOW_FLAGS, () => {
      const engine = new GlowEngine();
      const directions: GlowDirection[] = ['left', 'up', 'right', 'down'];
      for (let seed = 0; seed < 60; seed++) {
        engine.reset(seed);
        for (let step = 0; step < 120 && !engine.ended; step++) {
          const direction = directions[(step + seed) % 4];
          const slide = glowSlide(engine.tiles, direction);
          const beforeScore = engine.score;
          const beforeMoves = engine.moves;
          const result = engine.move(direction);
          if (!result.moved) continue;
          expect(engine.tiles.length).assertEqual(slide.tiles.length + 1);
          expect(engine.score).assertEqual(beforeScore + slide.gain);
          expect(engine.moves).assertEqual(beforeMoves + 1);
          const born = engine.tiles.find((tile: GlowTile) => tile.id === result.spawned);
          expect(born !== undefined && (born.value === 2 || born.value === 4)).assertTrue();
          expect(new Set<number>(engine.tiles.map((tile: GlowTile) => tile.id)).size).assertEqual(engine.tiles.length);
          expect(new Set<number>(engine.tiles.map((tile: GlowTile) => tile.index)).size).assertEqual(engine.tiles.length);
        }
      }
    });
    it('full_board_only_ends_when_no_adjacent_pair_can_merge', GLOW_FLAGS, () => {
      const blocked = glowTestTiles([2,4,2,4, 4,2,4,2, 2,4,2,4, 4,2,4,2]);
      expect(glowCanMove(blocked)).assertFalse();
      blocked[15].value = 4;
      expect(glowCanMove(blocked)).assertTrue();
      expect(glowCanMove(blocked.slice(0, 15))).assertTrue();
    });
    it('2048_pauses_once_then_continues_without_resetting_score_or_board', GLOW_FLAGS, () => {
      const engine = new GlowEngine();
      expect(engine.restore(JSON.stringify(glowTestSave([1024, 1024])))).assertTrue();
      const turn = engine.move('left');
      expect(turn.gain).assertEqual(2048);
      expect(engine.needsCelebration()).assertTrue();
      expect(glowMax(engine.tiles)).assertEqual(2048);
      const won = engine.serialize();
      expect(engine.move('right').moved).assertFalse();
      expect(engine.serialize()).assertEqual(won);
      engine.continuePlaying();
      expect(engine.needsCelebration()).assertFalse();
      expect(engine.move('right').moved).assertTrue();
      expect(engine.score >= 2048).assertTrue();
      expect(glowMax(engine.tiles) >= 2048).assertTrue();
    });
    it('streak_is_feedback_without_a_score_multiplier', GLOW_FLAGS, () => {
      const engine = new GlowEngine();
      expect(engine.restore(JSON.stringify(glowTestSave([2, 2, 4, 4])))).assertTrue();
      expect(engine.move('left').gain).assertEqual(12);
      expect(engine.score).assertEqual(12);
      expect(engine.streak).assertEqual(1);
      expect(engine.bestStreak).assertEqual(1);
      engine.move('down');
      expect(engine.streak).assertEqual(0);
      expect(engine.bestStreak).assertEqual(1);
    });
    it('save_restore_preserves_future_random_generation_and_finished_state', GLOW_FLAGS, () => {
      const first = new GlowEngine();
      first.reset(8723);
      first.move('left');
      first.move('down');
      const second = new GlowEngine();
      expect(second.restore(first.serialize())).assertTrue();
      const directions: GlowDirection[] = ['up', 'right', 'down', 'left'];
      for (let i = 0; i < 120; i++) {
        first.move(directions[i % 4]); second.move(directions[i % 4]);
        expect(second.serialize()).assertEqual(first.serialize());
      }
      const ended = glowTestSave([2,4,2,4, 4,2,4,2, 2,4,2,4, 4,2,4,2]);
      ended.reported = true;
      expect(second.restore(JSON.stringify(ended))).assertTrue();
      const before = second.serialize();
      directions.forEach((direction: GlowDirection) => expect(second.move(direction).moved).assertFalse());
      expect(second.serialize()).assertEqual(before);
    });
    it('malformed_saves_are_rejected_without_changing_the_live_round', GLOW_FLAGS, () => {
      const engine = new GlowEngine();
      const before = engine.serialize();
      const bad: string[] = ['', '{', 'null', '{}', '[]', before.replace('"version":1', '"version":2'),
        before.replace('"score":0', '"score":-4'), before.replace('"moves":0', '"moves":1'),
        before.replace('"continued":false', '"continued":true'), before.replace('"ended":false', '"ended":true'),
        before.replace('"reported":false', '"reported":true')];
      const duplicate = JSON.parse(before) as GlowSave;
      duplicate.tiles[1].index = duplicate.tiles[0].index;
      bad.push(JSON.stringify(duplicate));
      duplicate.tiles[0].value = 3;
      bad.push(JSON.stringify(duplicate));
      bad.forEach((raw: string) => { expect(engine.restore(raw)).assertFalse(); expect(engine.serialize()).assertEqual(before); });
    });
    it('phone_tablet_fold_and_short_windows_keep_a_square_board_inside_width', GLOW_FLAGS, () => {
      const insets: GlowInsets = { top: 28, bottom: 20, left: 0, right: 0 };
      [[280,500], [320,568], [345,782], [390,844], [430,932], [844,390], [768,1024], [1280,800], [1600,1000]]
        .forEach((size: number[]) => {
          const layout = glowLayout(size[0], size[1], insets);
          expect(layout.board + (layout.wide ? layout.rail + layout.gap : 0) + layout.gap * 2 <= layout.width).assertTrue();
          expect(layout.cell >= 44).assertTrue();
          expect(layout.cell * 4 + layout.tileGap * 3 + layout.tilePad * 2).assertEqual(layout.board);
          expect(layout.board <= 560).assertTrue();
        });
      [[345,782], [360,780], [390,844], [430,932]].forEach((size: number[]) => {
        const layout = glowLayout(size[0], size[1], insets);
        expect(layout.board + 280 <= layout.body).assertTrue();
      });
      const horizontal = glowLayout(768, 1024, insets, { x: 0, y: 490, width: 768, height: 24 });
      expect(horizontal.y >= 514 || horizontal.y + horizontal.height <= 490).assertTrue();
      const vertical = glowLayout(1024, 768, insets, { x: 480, y: 0, width: 24, height: 768 });
      expect(vertical.x >= 504 || vertical.x + vertical.width <= 480).assertTrue();
      expect(horizontal.board >= 272).assertTrue();
    });
    it('new_and_classic_share_the_existing_logo_and_one_favorite', GLOW_FLAGS, () => {
      expect(gameLogoPath('chicken2048Next')).assertEqual('app/game_logos/game_icon_chicken2048.svg');
      expect(gameLogoPath('chicken2048')).assertEqual(gameLogoPath('chicken2048Next'));
      expect(achievementPrimaryFavoriteCount(['chicken2048', 'chicken2048Next'])).assertEqual(1);
    });
  });
}
