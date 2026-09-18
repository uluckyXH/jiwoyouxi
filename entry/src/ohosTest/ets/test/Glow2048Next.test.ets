import { GlowRenderTile, glowReconcileTiles } from '../../../main/ets/gamesNext/glow2048/GlowRenderTile';
import { describe, it, expect, TestType, Size, Level } from '@ohos/hypium';
import { GlowEngine, glowCanMove, glowSlide } from '../../../main/ets/gamesNext/glow2048/GlowEngine';
import { GlowDirection, GlowSave, GlowTile, glowMax } from '../../../main/ets/gamesNext/glow2048/GlowModel';
import { GlowInsets, GlowRect, GlowCrease, glowLayout, glowUsesCreases } from '../../../main/ets/gamesNext/glow2048/GlowLayout';
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
    it('downward_pairs_compress_gaps_and_merge_once_at_the_bottom', GLOW_FLAGS, () => {
      const input = glowTestTiles([2,2,2,2, 0,2,2,0, 0,0,0,0, 0,2,0,0]);
      const result = glowSlide(input, 'down');
      expect(glowTestValues(result.tiles).join(',')).assertEqual('0,0,0,0,0,0,0,0,0,2,0,0,2,4,4,2');
      expect(result.gain).assertEqual(8);
    });
    it('stable_render_ids_keep_live_values_and_positions_across_merge_phases', GLOW_FLAGS, () => {
      const input = glowTestTiles([2,0,0,0, 2,0,0,0, 4,0,0,0, 4]);
      let live = glowReconcileTiles([], input);
      const lower = live[3];
      const upper = live[1];
      const result = glowSlide(input, 'down');
      const sliding = result.motions.map((motion): GlowTile => ({ id: motion.id, value: motion.value, index: motion.to }));
      live = glowReconcileTiles(live, sliding);
      expect(upper.index).assertEqual(8);
      expect(upper.value).assertEqual(2);
      live = glowReconcileTiles(live, result.tiles);
      expect(live.find((tile: GlowRenderTile) => tile.id === lower.id) === lower).assertTrue();
      expect(live.find((tile: GlowRenderTile) => tile.id === upper.id) === upper).assertTrue();
      expect(lower.value).assertEqual(8);
      expect(lower.index).assertEqual(12);
      expect(upper.value).assertEqual(4);
      expect(live.length).assertEqual(2);
      expect(input[3].value).assertEqual(4);
      const born: GlowTile = { id: 14, value: 2, index: 0 };
      live = glowReconcileTiles(live, result.tiles.concat([born]));
      expect(live[2].id).assertEqual(14);
      expect(live[2] === lower).assertFalse();
      expect(glowReconcileTiles([], input)[3] === lower).assertFalse();
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
        expect(layout.contentHeight <= layout.body).assertTrue();
      });
      const horizontal = glowLayout(768, 1024, insets, [{ x: 0, y: 490, width: 768, height: 24 }]);
      expect(horizontal.y >= 514 || horizontal.y + horizontal.height <= 490).assertTrue();
      const vertical = glowLayout(1024, 768, insets, [{ x: 480, y: 0, width: 24, height: 768 }]);
      expect(vertical.x >= 504 || vertical.x + vertical.width <= 480).assertTrue();
      expect(horizontal.board >= 272).assertTrue();
    });
    it('every_control_fits_without_overlap_in_phone_tablet_and_short_panes', GLOW_FLAGS, () => {
      const insets: GlowInsets = { top: 28, bottom: 20, left: 0, right: 0 };
      [240,280,320,345,390,430,480,560,600,700,768,844,1024,1280,1600].forEach((width: number) => {
        [280,360,430,520,640,780,900,1024].forEach((height: number) => {
          const l = glowLayout(width, height, insets);
          const boxes: GlowRect[] = [l.stats, l.journey, l.boardBox, l.pad, l.restart, l.help];
          if (l.note.height > 0) boxes.push(l.note);
          boxes.forEach((box: GlowRect, index: number) => {
            expect(box.x >= 0 && box.y >= 0 && box.width > 0 && box.height > 0).assertTrue();
            expect(box.x + box.width <= l.contentWidth + .01).assertTrue();
            expect(box.y + box.height <= l.contentHeight + .01).assertTrue();
            boxes.slice(index + 1).forEach((other: GlowRect) => {
              expect(box.x + box.width <= other.x + .01 || other.x + other.width <= box.x + .01 ||
                box.y + box.height <= other.y + .01 || other.y + other.height <= box.y + .01).assertTrue();
            });
          });
          expect(l.buttonEdge >= 56).assertTrue();
          expect(l.restart.height >= 44 && l.restart.width >= 44).assertTrue();
          expect(l.pad.width).assertEqual(l.buttonEdge * 3 + 8);
          expect(l.pad.height).assertEqual(l.pad.width);
        });
      });
    });
    it('half_fold_uses_a_continuous_pane_and_compact_controls_fit_its_height', GLOW_FLAGS, () => {
      const insets: GlowInsets = { top: 28, bottom: 20, left: 0, right: 0 };
      const half = glowLayout(768, 1024, insets, [{ x: 0, y: 490, width: 768, height: 24 }]);
      expect(half.wide && half.compact).assertTrue();
      expect(half.contentHeight <= half.body).assertTrue();
      expect(half.pad.y + half.pad.height <= half.body).assertTrue();
      expect(half.help.y + half.help.height <= half.body).assertTrue();
      const hinges: GlowCrease[] = [{ x: 400, y: 0, width: 24, height: 1000 },
        { x: 800, y: 0, width: 24, height: 1000 }];
      const triple = glowLayout(1280, 1000, insets, hinges);
      expect(triple.x).assertEqual(824);
      expect(triple.width).assertEqual(456);
      const unfolded = glowLayout(1280, 1000, insets);
      expect(unfolded.x).assertEqual(0);
      expect(unfolded.width).assertEqual(1280);
      expect(unfolded.wide).assertTrue();
      const outside = glowLayout(390, 844, insets, [{ x: 0, y: 900, width: 1280, height: 24 }]);
      expect(outside.height).assertEqual(796);
      [3,13,21,22,23].forEach((status: number) => expect(glowUsesCreases(status)).assertTrue());
      [0,1,2,11,12].forEach((status: number) => expect(glowUsesCreases(status)).assertFalse());
    });
    it('new_and_classic_share_the_existing_logo_and_one_favorite', GLOW_FLAGS, () => {
      expect(gameLogoPath('chicken2048Next')).assertEqual('app/game_logos/game_icon_chicken2048.svg');
      expect(gameLogoPath('chicken2048')).assertEqual(gameLogoPath('chicken2048Next'));
      expect(achievementPrimaryFavoriteCount(['chicken2048', 'chicken2048Next'])).assertEqual(1);
    });
  });
}
