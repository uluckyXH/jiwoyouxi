import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  ACHIEVEMENT_NOTICE_INDIVIDUAL_LIMIT,
  achievementNoticeItemsForUnlocks
} from '../../../main/ets/shell/AchievementNotice';
import { AchievementUnlock } from '../../../main/ets/shell/AchievementModule';

const TEST_UNLOCKED_AT: number = 1787617800000;

function unlock(achievementId: string): AchievementUnlock {
  return {
    achievementId: achievementId,
    unlockedAt: TEST_UNLOCKED_AT
  };
}

export default function achievementNoticeTest(): void {
  describe('AchievementNoticeTest', () => {
    it('maps one registered unlock to a self-contained display item',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const notices = achievementNoticeItemsForUnlocks([unlock('tetris.first_tetris')]);

        expect(notices.length).assertEqual(1);
        expect(notices[0].kind).assertEqual('achievement');
        expect(notices[0].gameId).assertEqual('tetris');
        expect(notices[0].title).assertEqual('第一记四消');
        expect(notices[0].summary).assertEqual('单次消除 4 行');
        expect(notices[0].placeholderSymbol).assertEqual('▣');
        expect(notices[0].achievementCount).assertEqual(1);
      });

    it('preserves unlock order for strictly sequential same-session notices',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const notices = achievementNoticeItemsForUnlocks([
          unlock('global.first_settlement'),
          unlock('minesweeper.first_clear')
        ]);

        expect(notices.length).assertEqual(2);
        expect(notices[0].noticeId).assertEqual('global.first_settlement');
        expect(notices[1].noticeId).assertEqual('minesweeper.first_clear');
        expect(notices[0].kind).assertEqual('achievement');
        expect(notices[1].kind).assertEqual('achievement');
      });

    it('shows only the first three items and collapses later unlocks into one summary',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const notices = achievementNoticeItemsForUnlocks([
          unlock('global.first_settlement'),
          unlock('rpsBattle.first_battle'),
          unlock('rpsBattle.supporter_wins'),
          unlock('chicken2048.reach_2048')
        ]);

        expect(ACHIEVEMENT_NOTICE_INDIVIDUAL_LIMIT).assertEqual(3);
        expect(notices.length).assertEqual(4);
        expect(notices[0].achievementIds[0]).assertEqual('global.first_settlement');
        expect(notices[1].achievementIds[0]).assertEqual('rpsBattle.first_battle');
        expect(notices[2].achievementIds[0]).assertEqual('rpsBattle.supporter_wins');
        expect(notices[3].kind).assertEqual('summary');
        expect(notices[3].achievementCount).assertEqual(4);
        expect(notices[3].achievementIds.length).assertEqual(4);
        expect(notices[3].noticeLevel).assertEqual('highlight');
      });

    it('ignores duplicate, disabled and unregistered achievement ids',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const notices = achievementNoticeItemsForUnlocks([
          unlock('tetris.first_tetris'),
          unlock('tetris.first_tetris'),
          unlock('global.favorite_three'),
          unlock('notRegistered.missing')
        ]);

        expect(notices.length).assertEqual(1);
        expect(notices[0].noticeId).assertEqual('tetris.first_tetris');
      });

    it('returns no notification item when there are no newly unlocked achievements',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        expect(achievementNoticeItemsForUnlocks([]).length).assertEqual(0);
      });
  });
}
