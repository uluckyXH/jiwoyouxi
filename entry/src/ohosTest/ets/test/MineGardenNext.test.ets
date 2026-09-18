import { describe, it, expect, TestType, Size, Level } from '@ohos/hypium';
import { MineEngine } from '../../../main/ets/gamesNext/minesweeper/MineEngine';
import { MINE_LEVELS, MineLevel, SurveyCell, mineNeighbors } from '../../../main/ets/gamesNext/minesweeper/MineModel';
import { MineCrease, MineInsets, mineLayout } from '../../../main/ets/gamesNext/minesweeper/MineLayout';
import { achievementPrimaryFavoriteCount } from '../../../main/ets/shell/AchievementRegistry';
import { gameLogoPath } from '../../../main/ets/shell/GameRegistry';

const FLAGS = TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0;

export default function mineGardenNextTest(): void {
  describe('MineGardenNext', () => {
    it('each_difficulty_places_exact_mines_and_protects_first_neighborhood', FLAGS, () => {
      MINE_LEVELS.forEach((level: MineLevel) => {
        for (let seed = 1; seed <= 30; seed += 1) {
          const engine = new MineEngine();
          engine.reset(level.key, seed);
          const first = seed % 3 === 0 ? 0 : Math.floor(level.rows * level.cols / 2) + 3;
          engine.open(first);
          expect(engine.cells.filter((cell: SurveyCell) => cell.mine).length).assertEqual(level.mines);
          expect(engine.cells[first].open).assertTrue();
          expect(engine.cells[first].near).assertEqual(0);
          mineNeighbors(first, level.rows, level.cols).forEach((i: number) => expect(engine.cells[i].mine).assertFalse());
          engine.cells.forEach((cell: SurveyCell) => {
            expect(cell.near).assertEqual(mineNeighbors(cell.index, level.rows, level.cols)
              .filter((i: number) => engine.cells[i].mine).length);
          });
        }
      });
    });

    it('flags_before_first_open_do_not_start_or_place_mines', FLAGS, () => {
      const engine = new MineEngine();
      engine.reset('easy', 12);
      expect(engine.flag(4)).assertEqual('flag');
      engine.advance(30000);
      expect(engine.elapsedMs).assertEqual(0);
      expect(engine.phase).assertEqual('ready');
      expect(engine.open(4)).assertEqual('none');
      expect(engine.cells.some((cell: SurveyCell) => cell.mine)).assertFalse();
      for (let i = 5; i < 14; i += 1) engine.flag(i);
      expect(engine.flag(15)).assertEqual('limit');
      expect(engine.flags()).assertEqual(10);
      expect(engine.flag(4)).assertEqual('unflag');
      expect(engine.flag(15)).assertEqual('flag');
      expect(engine.flag(-1)).assertEqual('none');
      expect(engine.open(999)).assertEqual('none');
    });

    it('flood_fill_respects_flags_and_victory_requires_every_safe_cell', FLAGS, () => {
      const engine = new MineEngine();
      engine.reset('easy', 29);
      engine.flag(1);
      engine.open(0);
      expect(engine.cells[1].open).assertFalse();
      expect(engine.everWrongFlag).assertTrue();
      engine.cells.forEach((cell: SurveyCell) => { if (!cell.mine && !cell.flag && !cell.open) engine.open(cell.index); });
      expect(engine.phase).assertEqual('playing');
      engine.flag(1);
      expect(engine.open(1)).assertEqual('won');
      expect(engine.opened()).assertEqual(engine.safeTotal());
      expect(engine.flags()).assertEqual(engine.level.mines);
      expect(engine.manualAllFlags).assertFalse();
    });

    it('correct_chord_opens_neighbors_and_wrong_flags_can_lose', FLAGS, () => {
      let exercised = false;
      for (let seed = 1; seed <= 60 && !exercised; seed += 1) {
        const engine = new MineEngine();
        engine.reset('normal', seed);
        engine.open(0);
        const target = engine.cells.find((cell: SurveyCell) => cell.open && cell.near > 0 &&
          mineNeighbors(cell.index, engine.level.rows, engine.level.cols)
            .some((i: number) => !engine.cells[i].open && !engine.cells[i].mine));
        if (target === undefined) continue;
        const original = engine.serialize();
        const neighbors = mineNeighbors(target.index, engine.level.rows, engine.level.cols);
        const before = engine.opened();
        expect(engine.chord(target.index)).assertEqual('mismatch');
        neighbors.forEach((i: number) => { if (engine.cells[i].mine) engine.flag(i); });
        engine.chord(target.index);
        expect(engine.opened() > before).assertTrue();
        expect(engine.phase === 'lost').assertFalse();
        expect(engine.restore(original)).assertTrue();
        const mines = neighbors.filter((i: number) => engine.cells[i].mine);
        const wrong = neighbors.find((i: number) => !engine.cells[i].open && !engine.cells[i].mine);
        if (wrong === undefined) continue;
        engine.flag(wrong);
        for (let i = 1; i < mines.length; i += 1) engine.flag(mines[i]);
        expect(engine.chord(target.index)).assertEqual('lost');
        expect(engine.cells.filter((cell: SurveyCell) => cell.exploded).length).assertEqual(1);
        exercised = true;
      }
      expect(exercised).assertTrue();
    });

    it('finished_rounds_ignore_input_time_and_auto_flags_do_not_fake_manual_flags', FLAGS, () => {
      const engine = new MineEngine();
      engine.reset('easy', 7);
      engine.open(0);
      engine.advance(12345);
      engine.cells.forEach((cell: SurveyCell) => { if (cell.mine) engine.flag(cell.index); });
      engine.cells.forEach((cell: SurveyCell) => { if (!cell.mine && !cell.open) engine.open(cell.index); });
      expect(engine.phase).assertEqual('won');
      expect(engine.manualAllFlags).assertTrue();
      expect(engine.everWrongFlag).assertFalse();
      expect(engine.score()).assertEqual(9880);
      expect(engine.bestTime()).assertEqual(12345);
      const raw = engine.serialize();
      engine.advance(90000);
      engine.flag(0);
      engine.open(2);
      expect(engine.serialize()).assertEqual(raw);
      engine.reset('hard', 10);
      expect(engine.bestTime()).assertEqual(0);
      engine.reset('easy', 10);
      expect(engine.bestTime()).assertEqual(12345);
    });

    it('save_restore_preserves_board_flags_time_and_future_seeded_generation', FLAGS, () => {
      const engine = new MineEngine();
      const restored = new MineEngine();
      engine.reset('hard', 923);
      engine.flag(30);
      engine.flagMode = true;
      expect(restored.restore(engine.serialize())).assertTrue();
      engine.open(0);
      restored.open(0);
      expect(restored.serialize()).assertEqual(engine.serialize());
      engine.advance(32456);
      engine.cells.forEach((cell: SurveyCell) => { if (cell.mine && !cell.flag && engine.flags() < 5) engine.flag(cell.index); });
      expect(restored.restore(engine.serialize())).assertTrue();
      expect(restored.serialize()).assertEqual(engine.serialize());
      const lost = engine.cells.find((cell: SurveyCell) => cell.mine && !cell.flag);
      if (lost !== undefined) engine.open(lost.index);
      expect(restored.restore(engine.serialize())).assertTrue();
      expect(restored.phase).assertEqual('lost');
    });

    it('corrupt_saves_are_rejected_without_mutating_the_current_round', FLAGS, () => {
      const engine = new MineEngine();
      engine.reset('normal', 7);
      engine.open(0);
      const raw = engine.serialize();
      const bad: string[] = ['', 'null', '{}', '{', raw.replace('"version":1', '"version":9'),
        raw.replace('"elapsedMs":0', '"elapsedMs":-1'), raw.replace('"near":0', '"near":99'),
        raw.replace('"level":"normal"', '"level":"missing"'), raw.replace('"playing"', '"won"')];
      bad.forEach((save: string) => {
        expect(engine.restore(save)).assertFalse();
        expect(engine.serialize()).assertEqual(raw);
      });
    });

    it('phone_tablet_landscape_and_fold_layouts_keep_touch_targets_and_bounds', FLAGS, () => {
      const sizes: number[][] = [[320, 568], [390, 844], [844, 390], [768, 1024], [1024, 768], [1280, 800], [720, 720], [280, 500]];
      const insets: MineInsets = { top: 28, bottom: 20, left: 0, right: 0 };
      MINE_LEVELS.forEach((level: MineLevel) => {
        sizes.forEach((size: number[]) => {
          const layout = mineLayout(size[0], size[1], level.rows, level.cols, insets);
          expect(layout.cell >= 40).assertTrue();
          expect(layout.x + layout.width <= size[0]).assertTrue();
          expect(layout.y + layout.height <= size[1]).assertTrue();
          expect(layout.boardAreaWidth + layout.gap * 2 + (layout.wide ? layout.rail + layout.gap : 0) <= layout.width + 0.01).assertTrue();
        });
      });
      const horizontal: MineCrease = { x: 0, y: 490, width: 768, height: 24 };
      const layout = mineLayout(768, 1024, 16, 12, insets, horizontal);
      expect(layout.y >= 514 || layout.y + layout.height <= 490).assertTrue();
      const vertical: MineCrease = { x: 480, y: 0, width: 24, height: 768 };
      const folded = mineLayout(1024, 768, 16, 12, insets, vertical);
      expect(folded.x >= 504 || folded.x + folded.width <= 480).assertTrue();
    });

    it('new_and_classic_share_logo_and_count_as_one_favorite', FLAGS, () => {
      expect(gameLogoPath('minesweeperNext')).assertEqual(gameLogoPath('minesweeper'));
      expect(achievementPrimaryFavoriteCount(['minesweeper', 'minesweeperNext'])).assertEqual(1);
      expect(achievementPrimaryFavoriteCount(['minesweeperNext', 'suika', 'suikaNext'])).assertEqual(2);
    });
  });
}
