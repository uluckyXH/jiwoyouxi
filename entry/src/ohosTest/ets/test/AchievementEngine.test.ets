import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  achievementGroupsForSnapshot,
  achievementSummaryForSnapshot,
  synchronizeAchievementProgress
} from '../../../main/ets/shell/AchievementEngine';
import { AchievementProgress } from '../../../main/ets/shell/AchievementModule';
import { CoopAppSnapshot, emptySnapshot } from '../../../main/ets/shell/GameModule';

function progressFor(snapshot: CoopAppSnapshot, achievementId: string): AchievementProgress {
  return snapshot.achievements.find((item: AchievementProgress) => item.achievementId === achievementId) as
    AchievementProgress;
}

function legacySnapshot(): CoopAppSnapshot {
  const snapshot = emptySnapshot();
  snapshot.achievementSchemaVersion = 0;
  snapshot.records = [
    { gameId: 'rpsBattle', highScore: 20, playCount: 2, lastPlayedAt: 0 },
    { gameId: 'freecell', highScore: 999, playCount: 2, lastPlayedAt: 0 },
    { gameId: 'minesweeper', highScore: 1200, playCount: 2, lastPlayedAt: 0 },
    { gameId: 'chicken2048', highScore: 9999, playCount: 2, lastPlayedAt: 0 },
    { gameId: 'tetris', highScore: 3000, playCount: 2, lastPlayedAt: 0 },
    { gameId: 'suika', highScore: 1200, playCount: 2, lastPlayedAt: 0 },
    { gameId: 'rps', highScore: 9999, playCount: 99, lastPlayedAt: 0 }
  ];
  snapshot.favorites = ['rpsBattle', 'freecell', 'suika', 'rps'];
  return snapshot;
}

export default function achievementEngineTest(): void {
  describe('AchievementEngineTest', () => {
    it('creates the documented seven groups and no unlocked achievements for a fresh snapshot',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const snapshot = emptySnapshot();
        const groups = achievementGroupsForSnapshot(snapshot, 'all');
        const summary = achievementSummaryForSnapshot(snapshot);

        expect(groups.length).assertEqual(7);
        expect(groups[0].items.length).assertEqual(4);
        expect(summary.unlocked).assertEqual(0);
        expect(summary.total).assertEqual(22);
      });

    it('migrates only reliable global facts and never infers game mastery from historical scores',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const migratedAt = 1787531400000;
        const snapshot = synchronizeAchievementProgress(legacySnapshot(), migratedAt);
        const summary = achievementSummaryForSnapshot(snapshot);

        expect(summary.unlocked).assertEqual(4);
        expect(progressFor(snapshot, 'global.first_settlement').unlockedAt).assertEqual(migratedAt);
        expect(progressFor(snapshot, 'global.favorite_three').isLegacyMigrated).assertEqual(true);
        expect(progressFor(snapshot, 'chicken2048.reach_2048').unlockedAt).assertEqual(0);
        expect(progressFor(snapshot, 'tetris.first_tetris').unlockedAt).assertEqual(0);
      });

    it('keeps an unlocked global achievement after the current favorite list changes',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const migratedAt = 1787531400000;
        const migrated = synchronizeAchievementProgress(legacySnapshot(), migratedAt);
        const currentSnapshot: CoopAppSnapshot = {
          records: migrated.records.slice(),
          favorites: ['rpsBattle'],
          recent: migrated.recent.slice(),
          soundEnabled: migrated.soundEnabled,
          hapticEnabled: migrated.hapticEnabled,
          appearanceMode: migrated.appearanceMode,
          achievementSchemaVersion: migrated.achievementSchemaVersion,
          achievements: migrated.achievements.slice(),
          recentAchievementEventIds: migrated.recentAchievementEventIds.slice()
        };
        const synchronized = synchronizeAchievementProgress(currentSnapshot, migratedAt + 1000);

        expect(progressFor(synchronized, 'global.favorite_three').unlockedAt).assertEqual(migratedAt);
        expect(progressFor(synchronized, 'global.favorite_three').current).assertEqual(3);
      });

    it('filters unlocked and in-progress groups without adding unavailable game achievements',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const snapshot = synchronizeAchievementProgress(legacySnapshot(), 1787531400000);
        const unlockedGroups = achievementGroupsForSnapshot(snapshot, 'unlocked');
        const inProgressGroups = achievementGroupsForSnapshot(snapshot, 'inProgress');
        let inProgressCount = 0;
        inProgressGroups.forEach((group) => {
          inProgressCount += group.items.length;
        });

        expect(unlockedGroups.length).assertEqual(1);
        expect(unlockedGroups[0].items.length).assertEqual(4);
        expect(inProgressGroups.length).assertEqual(6);
        expect(inProgressCount).assertEqual(18);
      });
  });
}
