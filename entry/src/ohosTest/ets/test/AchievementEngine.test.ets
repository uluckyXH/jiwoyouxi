import { describe, expect, it, Level, Size, TestType } from '@ohos/hypium';
import {
  achievementGroupsForState,
  achievementProgressForState,
  achievementSummaryForState,
  achievementViewItemForState,
  applyAchievementEvent,
  emptyAchievementState,
  normalizeAchievementState
} from '../../../main/ets/shell/AchievementEngine';
import {
  achievementRegistryIssues,
  isAchievementBadgeAssetPathValid
} from '../../../main/ets/shell/AchievementRegistry';
import {
  AchievementEvent,
  AchievementFact,
  AchievementProgress,
  AchievementState
} from '../../../main/ets/shell/AchievementModule';

const TEST_OCCURRED_AT: number = 1787617800000;

function createEvent(
  eventId: string,
  sessionId: string,
  gameId: string,
  facts: AchievementFact[],
  type: 'sessionEnd' | 'milestone' = 'milestone',
  isOfficial: boolean = true
): AchievementEvent {
  return {
    eventId: eventId,
    sessionId: sessionId,
    gameId: gameId,
    type: type,
    occurredAt: TEST_OCCURRED_AT,
    isOfficial: isOfficial,
    facts: facts
  };
}

function progressFor(state: AchievementState, achievementId: string): AchievementProgress {
  const progress = achievementProgressForState(state, achievementId);
  if (progress === undefined) {
    throw new Error(`Expected achievement progress for ${achievementId}`);
  }
  return progress;
}

export default function achievementEngineTest(): void {
  describe('AchievementEngineTest', () => {
    it('creates an empty independent state with a valid registry',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const state = emptyAchievementState();

        expect(achievementRegistryIssues().length).assertEqual(0);
        expect(state.completedSessionCount).assertEqual(0);
        expect(state.playedGameIds.length).assertEqual(0);
        expect(achievementSummaryForState(state).unlocked).assertEqual(0);
        expect(achievementSummaryForState(state).total).assertEqual(22);
        expect(achievementGroupsForState(state, 'all').length).assertEqual(7);
        expect(achievementGroupsForState(state, 'unlocked').length).assertEqual(0);
        expect(achievementGroupsForState(state, 'inProgress').length).assertEqual(0);
        expect(isAchievementBadgeAssetPathValid('')).assertEqual(true);
        expect(isAchievementBadgeAssetPathValid('app/achievements/ach_minesweeper_first_clear.png'))
          .assertEqual(true);
        expect(isAchievementBadgeAssetPathValid('app/game_logos/minesweeper.png')).assertEqual(false);
        expect(isAchievementBadgeAssetPathValid('app/achievements/ach_minesweeper_first_clear.jpg'))
          .assertEqual(false);
      });

    it('updates a fact threshold once and rejects a duplicate event id',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const first = applyAchievementEvent(emptyAchievementState(), createEvent(
          'tetris-1:four-line-clear:1',
          'tetris-1',
          'tetris',
          [{ key: 'maxClearedLines', value: 4 }]
        ));
        const duplicate = applyAchievementEvent(first.state, createEvent(
          'tetris-1:four-line-clear:1',
          'tetris-1',
          'tetris',
          [{ key: 'maxClearedLines', value: 4 }]
        ));

        expect(first.disposition).assertEqual('applied');
        expect(first.newlyUnlocked.length).assertEqual(1);
        expect(first.newlyUnlocked[0].achievementId).assertEqual('tetris.first_tetris');
        expect(progressFor(first.state, 'tetris.first_tetris').current).assertEqual(4);
        expect(progressFor(first.state, 'tetris.first_tetris').unlockedAt).assertEqual(TEST_OCCURRED_AT);
        expect(duplicate.disposition).assertEqual('duplicate');
        expect(duplicate.newlyUnlocked.length).assertEqual(0);
        expect(duplicate.state.processedEventIds.length).assertEqual(1);
      });

    it('keeps high-water progress and unlocks each crossed 2048 threshold once',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const low = applyAchievementEvent(emptyAchievementState(), createEvent(
          '2048-1:max-tile:1',
          '2048-1',
          'chicken2048',
          [{ key: 'maxTile', value: 128 }]
        ));
        const high = applyAchievementEvent(low.state, createEvent(
          '2048-1:max-tile:2',
          '2048-1',
          'chicken2048',
          [{ key: 'maxTile', value: 2048 }]
        ));
        const laterLow = applyAchievementEvent(high.state, createEvent(
          '2048-2:max-tile:1',
          '2048-2',
          'chicken2048',
          [{ key: 'maxTile', value: 256 }]
        ));

        expect(progressFor(low.state, 'chicken2048.reach_256').current).assertEqual(128);
        expect(high.newlyUnlocked.length).assertEqual(3);
        expect(progressFor(high.state, 'chicken2048.reach_1024').current).assertEqual(1024);
        expect(progressFor(high.state, 'chicken2048.reach_2048').current).assertEqual(2048);
        expect(progressFor(laterLow.state, 'chicken2048.reach_2048').current).assertEqual(2048);
        expect(laterLow.newlyUnlocked.length).assertEqual(0);
      });

    it('counts only official session-end events for independent global progress',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const official = applyAchievementEvent(emptyAchievementState(), createEvent(
          'rps-battle-1:session-end:1',
          'rps-battle-1',
          'rpsBattle',
          [
            { key: 'won', value: 1 },
            { key: 'supportWon', value: 1 }
          ],
          'sessionEnd'
        ));
        const unofficial = applyAchievementEvent(official.state, createEvent(
          '2048-dev:session-end:1',
          '2048-dev',
          'chicken2048',
          [{ key: 'maxTile', value: 2048 }],
          'sessionEnd',
          false
        ));

        expect(official.state.completedSessionCount).assertEqual(1);
        expect(official.state.playedGameIds.length).assertEqual(1);
        expect(progressFor(official.state, 'global.first_settlement').unlockedAt).assertEqual(TEST_OCCURRED_AT);
        expect(progressFor(official.state, 'rpsBattle.first_battle').unlockedAt).assertEqual(TEST_OCCURRED_AT);
        expect(progressFor(official.state, 'rpsBattle.supporter_wins').unlockedAt).assertEqual(TEST_OCCURRED_AT);
        expect(unofficial.disposition).assertEqual('ignored');
        expect(unofficial.state.completedSessionCount).assertEqual(1);
        expect(achievementProgressForState(unofficial.state, 'chicken2048.reach_2048') === undefined)
          .assertEqual(true);
      });

    it('unlocks the confirmed minesweeper achievements at the 60-second boundary in registry order',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const result = applyAchievementEvent(emptyAchievementState(), createEvent(
          'minesweeper-1:session-end',
          'minesweeper-1',
          'minesweeper',
          [
            { key: 'won', value: 1 },
            { key: 'elapsedSec', value: 60 },
            { key: 'manualAllMinesFlagged', value: 1 },
            { key: 'hasEverFlaggedNonMine', value: 0 }
          ],
          'sessionEnd'
        ));

        expect(result.disposition).assertEqual('applied');
        expect(result.newlyUnlocked.length).assertEqual(4);
        expect(result.newlyUnlocked[0].achievementId).assertEqual('global.first_settlement');
        expect(result.newlyUnlocked[1].achievementId).assertEqual('minesweeper.first_clear');
        expect(result.newlyUnlocked[2].achievementId).assertEqual('minesweeper.quick_clear');
        expect(result.newlyUnlocked[3].achievementId).assertEqual('minesweeper.perfect_flags');
        expect(progressFor(result.state, 'minesweeper.quick_clear').unlockedAt)
          .assertEqual(TEST_OCCURRED_AT);
        expect(progressFor(result.state, 'minesweeper.perfect_flags').unlockedAt)
          .assertEqual(TEST_OCCURRED_AT);
      });

    it('requires a timely win and player-originated correct flags for minesweeper achievements',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const slowWin = applyAchievementEvent(emptyAchievementState(), createEvent(
          'minesweeper-2:session-end',
          'minesweeper-2',
          'minesweeper',
          [
            { key: 'won', value: 1 },
            { key: 'elapsedSec', value: 61 },
            { key: 'manualAllMinesFlagged', value: 1 },
            { key: 'hasEverFlaggedNonMine', value: 0 }
          ],
          'sessionEnd'
        ));
        const wrongFlagWin = applyAchievementEvent(emptyAchievementState(), createEvent(
          'minesweeper-3:session-end',
          'minesweeper-3',
          'minesweeper',
          [
            { key: 'won', value: 1 },
            { key: 'elapsedSec', value: 30 },
            { key: 'manualAllMinesFlagged', value: 1 },
            { key: 'hasEverFlaggedNonMine', value: 1 }
          ],
          'sessionEnd'
        ));
        const autoFlagWin = applyAchievementEvent(emptyAchievementState(), createEvent(
          'minesweeper-4:session-end',
          'minesweeper-4',
          'minesweeper',
          [
            { key: 'won', value: 1 },
            { key: 'elapsedSec', value: 30 },
            { key: 'manualAllMinesFlagged', value: 0 },
            { key: 'hasEverFlaggedNonMine', value: 0 }
          ],
          'sessionEnd'
        ));
        const devAssistedSession = applyAchievementEvent(emptyAchievementState(), createEvent(
          'minesweeper-dev:session-end',
          'minesweeper-dev',
          'minesweeper',
          [
            { key: 'won', value: 1 },
            { key: 'elapsedSec', value: 30 },
            { key: 'manualAllMinesFlagged', value: 0 },
            { key: 'hasEverFlaggedNonMine', value: 0 }
          ],
          'sessionEnd'
        ));
        const failedSession = applyAchievementEvent(emptyAchievementState(), createEvent(
          'minesweeper-5:session-end',
          'minesweeper-5',
          'minesweeper',
          [
            { key: 'won', value: 0 },
            { key: 'elapsedSec', value: 30 },
            { key: 'manualAllMinesFlagged', value: 0 },
            { key: 'hasEverFlaggedNonMine', value: 0 }
          ],
          'sessionEnd'
        ));

        expect(achievementProgressForState(slowWin.state, 'minesweeper.quick_clear') === undefined)
          .assertEqual(true);
        expect(progressFor(slowWin.state, 'minesweeper.perfect_flags').unlockedAt)
          .assertEqual(TEST_OCCURRED_AT);
        expect(progressFor(wrongFlagWin.state, 'minesweeper.quick_clear').unlockedAt)
          .assertEqual(TEST_OCCURRED_AT);
        expect(achievementProgressForState(wrongFlagWin.state, 'minesweeper.perfect_flags') === undefined)
          .assertEqual(true);
        expect(achievementProgressForState(autoFlagWin.state, 'minesweeper.perfect_flags') === undefined)
          .assertEqual(true);
        expect(devAssistedSession.disposition).assertEqual('applied');
        expect(progressFor(devAssistedSession.state, 'global.first_settlement').unlockedAt)
          .assertEqual(TEST_OCCURRED_AT);
        expect(progressFor(devAssistedSession.state, 'minesweeper.first_clear').unlockedAt)
          .assertEqual(TEST_OCCURRED_AT);
        expect(progressFor(devAssistedSession.state, 'minesweeper.quick_clear').unlockedAt)
          .assertEqual(TEST_OCCURRED_AT);
        expect(achievementProgressForState(devAssistedSession.state, 'minesweeper.perfect_flags') === undefined)
          .assertEqual(true);
        expect(failedSession.state.completedSessionCount).assertEqual(1);
        expect(progressFor(failedSession.state, 'global.first_settlement').unlockedAt)
          .assertEqual(TEST_OCCURRED_AT);
        expect(achievementProgressForState(failedSession.state, 'minesweeper.first_clear') === undefined)
          .assertEqual(true);
      });

    it('projects the achievement wall from independent state instead of legacy snapshot data',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const result = applyAchievementEvent(emptyAchievementState(), createEvent(
          'rps-battle-2:session-end:1',
          'rps-battle-2',
          'rpsBattle',
          [
            { key: 'won', value: 1 },
            { key: 'supportWon', value: 1 }
          ],
          'sessionEnd'
        ));
        const firstSettlement = achievementViewItemForState(result.state, 'global.first_settlement');
        const tenSessions = achievementViewItemForState(result.state, 'global.complete_ten_sessions');
        const favorite = achievementViewItemForState(result.state, 'global.favorite_three');
        const allGroups = achievementGroupsForState(result.state, 'all');
        const unlockedGroups = achievementGroupsForState(result.state, 'unlocked');
        const inProgressGroups = achievementGroupsForState(result.state, 'inProgress');
        let itemCount = 0;
        allGroups.forEach((group) => {
          itemCount += group.items.length;
        });

        if (firstSettlement === undefined || tenSessions === undefined || favorite === undefined) {
          throw new Error('Expected registered achievement view items');
        }
        expect(achievementSummaryForState(result.state).unlocked).assertEqual(3);
        expect(firstSettlement.status).assertEqual('unlocked');
        expect(firstSettlement.isLegacyMigrated).assertEqual(false);
        expect(tenSessions.status).assertEqual('inProgress');
        expect(tenSessions.current).assertEqual(1);
        expect(tenSessions.target).assertEqual(10);
        expect(favorite.status).assertEqual('locked');
        expect(favorite.target).assertEqual(3);
        expect(allGroups.length).assertEqual(7);
        expect(itemCount).assertEqual(22);
        expect(unlockedGroups.length).assertEqual(2);
        expect(inProgressGroups.length).assertEqual(1);
        expect(inProgressGroups[0].definition.id).assertEqual('global');
      });

    it('unlocks global counts from new events without reading old game records',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const gameIds: string[] = ['rpsBattle', 'freecell', 'minesweeper', 'chicken2048', 'tetris', 'suika'];
        let state = emptyAchievementState();
        for (let index = 0; index < 10; index += 1) {
          const gameId = gameIds[index % gameIds.length];
          state = applyAchievementEvent(state, createEvent(
            `session-${index}:end:1`,
            `session-${index}`,
            gameId,
            [],
            'sessionEnd'
          )).state;
        }

        expect(state.completedSessionCount).assertEqual(10);
        expect(state.playedGameIds.length).assertEqual(6);
        expect(progressFor(state, 'global.complete_ten_sessions').unlockedAt).assertEqual(TEST_OCCURRED_AT);
        expect(progressFor(state, 'global.play_six_games').unlockedAt).assertEqual(TEST_OCCURRED_AT);
        expect(achievementProgressForState(state, 'global.favorite_three') === undefined).assertEqual(true);
      });

    it('unlocks favorite collector only from the global milestone event without affecting session totals',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const twoFavorites = applyAchievementEvent(emptyAchievementState(), createEvent(
          'favorites:1:1',
          'favorites:1:1',
          'global',
          [{ key: 'favoriteCount', value: 2 }],
          'milestone'
        ));
        const threeFavorites = applyAchievementEvent(twoFavorites.state, createEvent(
          'favorites:2:2',
          'favorites:2:2',
          'global',
          [{ key: 'favoriteCount', value: 3 }],
          'milestone'
        ));
        const repeated = applyAchievementEvent(threeFavorites.state, createEvent(
          'favorites:2:2',
          'favorites:2:2',
          'global',
          [{ key: 'favoriteCount', value: 1 }],
          'milestone'
        ));
        const invalidSessionEnd = applyAchievementEvent(threeFavorites.state, createEvent(
          'global-session-end:1',
          'global-session-end:1',
          'global',
          [],
          'sessionEnd'
        ));

        expect(twoFavorites.disposition).assertEqual('applied');
        expect(progressFor(twoFavorites.state, 'global.favorite_three').current).assertEqual(2);
        expect(threeFavorites.newlyUnlocked.length).assertEqual(1);
        expect(threeFavorites.newlyUnlocked[0].achievementId).assertEqual('global.favorite_three');
        expect(progressFor(threeFavorites.state, 'global.favorite_three').unlockedAt)
          .assertEqual(TEST_OCCURRED_AT);
        expect(threeFavorites.state.completedSessionCount).assertEqual(0);
        expect(threeFavorites.state.playedGameIds.length).assertEqual(0);
        expect(repeated.disposition).assertEqual('duplicate');
        expect(invalidSessionEnd.disposition).assertEqual('ignored');
        expect(invalidSessionEnd.state.processedEventIds.length).assertEqual(2);
      });

    it('normalizes isolated state without consulting historical game records',
      TestType.FUNCTION | Size.SMALLTEST | Level.LEVEL0, () => {
        const normalized = normalizeAchievementState({
          version: 0,
          progresses: [
            { achievementId: 'tetris.first_tetris', current: 4.8, unlockedAt: TEST_OCCURRED_AT + 0.8 },
            { achievementId: 'tetris.first_tetris', current: 0, unlockedAt: 0 }
          ],
          processedEventIds: ['event-1', 'event-1', ''],
          completedSessionCount: -1,
          playedGameIds: ['tetris', 'not-a-game', 'tetris']
        });

        expect(normalized.version).assertEqual(1);
        expect(normalized.progresses.length).assertEqual(1);
        expect(normalized.progresses[0].current).assertEqual(4);
        expect(normalized.processedEventIds.length).assertEqual(1);
        expect(normalized.completedSessionCount).assertEqual(0);
        expect(normalized.playedGameIds.length).assertEqual(1);
        expect(normalized.playedGameIds[0]).assertEqual('tetris');
      });
  });
}
