import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  favoriteAchievementEventAfterPersist,
  favoriteSnapshotAfterPersist,
  favoriteSnapshotAfterToggle
} from '../../../main/ets/shell/AchievementFavoriteEvent';
import { achievementPrimaryFavoriteCount } from '../../../main/ets/shell/AchievementRegistry';
import { emptySnapshot } from '../../../main/ets/shell/GameModule';

const TEST_OCCURRED_AT: number = 1787617800000;

export default function achievementFavoriteEventTest(): void {
  describe('AchievementFavoriteEventTest', () => {
    it('counts only unique primary-game favorites',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const count = achievementPrimaryFavoriteCount([
          'rpsBattle',
          'rps',
          'freecell',
          'rpsBattle',
          'not-a-game',
          'minesweeper'
        ]);

        expect(count).assertEqual(3);
      });

    it('creates a collector event only after a successful primary favorite write',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const failedWrite = favoriteAchievementEventAfterPersist(
          false,
          true,
          ['rpsBattle', 'freecell', 'minesweeper'],
          TEST_OCCURRED_AT,
          1
        );
        const removal = favoriteAchievementEventAfterPersist(
          true,
          false,
          ['rpsBattle', 'freecell'],
          TEST_OCCURRED_AT,
          2
        );
        const nonPrimaryFavorite = favoriteAchievementEventAfterPersist(
          true,
          true,
          ['rps'],
          TEST_OCCURRED_AT,
          3
        );
        const event = favoriteAchievementEventAfterPersist(
          true,
          true,
          ['rpsBattle', 'freecell', 'minesweeper'],
          TEST_OCCURRED_AT,
          4
        );

        expect(failedWrite === undefined).assertEqual(true);
        expect(removal === undefined).assertEqual(true);
        expect(nonPrimaryFavorite === undefined).assertEqual(true);
        if (event === undefined) {
          throw new Error('Expected a persisted favorite milestone event');
        }
        expect(event.eventId).assertEqual(`favorites:${TEST_OCCURRED_AT}:4`);
        expect(event.sessionId).assertEqual(`favorites:${TEST_OCCURRED_AT}:4`);
        expect(event.gameId).assertEqual('global');
        expect(event.type).assertEqual('milestone');
        expect(event.facts.length).assertEqual(1);
        expect(event.facts[0].key).assertEqual('favoriteCount');
        expect(event.facts[0].value).assertEqual(3);
      });

    it('restores the previous favorite snapshot when persistence fails',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const previousSnapshot = emptySnapshot();
        const toggleResult = favoriteSnapshotAfterToggle(previousSnapshot, 'rpsBattle');
        const restoredSnapshot = favoriteSnapshotAfterPersist(
          previousSnapshot,
          toggleResult.snapshot,
          false
        );
        const savedSnapshot = favoriteSnapshotAfterPersist(
          previousSnapshot,
          toggleResult.snapshot,
          true
        );

        expect(toggleResult.didAddFavorite).assertEqual(true);
        expect(toggleResult.snapshot.favorites.length).assertEqual(1);
        expect(restoredSnapshot.favorites.length).assertEqual(0);
        expect(savedSnapshot.favorites.length).assertEqual(1);
        expect(savedSnapshot.favorites[0]).assertEqual('rpsBattle');
      });
  });
}
