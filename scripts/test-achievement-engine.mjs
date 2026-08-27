#!/usr/bin/env node

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const projectRoot = resolve(import.meta.dirname, '..');
const sourceFiles = [
  'entry/src/main/ets/shell/AchievementModule.ets',
  'entry/src/main/ets/shell/GameModule.ets',
  'entry/src/main/ets/shell/AchievementRegistry.ets',
  'entry/src/main/ets/shell/AchievementNotice.ets',
  'entry/src/main/ets/shell/AchievementEngine.ets'
];

function loadAchievementEngine() {
  const source = sourceFiles
    .map((file) => readFileSync(resolve(projectRoot, file), 'utf8'))
    .join('\n')
    .replace(/^import\s+[\s\S]*?;\n/gm, '')
    .replace(/^export\s+/gm, '');
  const runtimeSource = stripTypeScriptTypes(source, { mode: 'transform' });
  const context = { Math: Math, Number: Number, Array: Array };
  vm.runInNewContext(`${runtimeSource}
globalThis.__achievementEngine = {
  ACHIEVEMENT_DEFINITIONS,
  ACHIEVEMENT_PROCESSED_EVENT_LIMIT,
  ACHIEVEMENT_NOTICE_INDIVIDUAL_LIMIT,
  isAchievementBadgeAssetPathValid,
  achievementRegistryIssues,
  achievementNoticeItemsForUnlocks,
  emptyAchievementState,
  normalizeAchievementState,
  applyAchievementEvent,
  achievementProgressForState,
  achievementSummaryForState,
  achievementGroupsForState,
  achievementViewItemForState
};
`, context);
  return context.__achievementEngine;
}

function event({
  eventId,
  sessionId,
  gameId,
  type = 'milestone',
  occurredAt = 1787617800000,
  isOfficial = true,
  facts = []
}) {
  return { eventId, sessionId, gameId, type, occurredAt, isOfficial, facts };
}

function progressFor(api, state, achievementId) {
  const progress = api.achievementProgressForState(state, achievementId);
  assert.ok(progress, `expected progress for ${achievementId}`);
  return progress;
}

const api = loadAchievementEngine();

{
  const state = api.emptyAchievementState();
  assert.equal(api.achievementRegistryIssues().length, 0, 'registry definitions must be internally consistent');
  assert.equal(api.ACHIEVEMENT_DEFINITIONS.length, 22, 'the documented first batch should remain intact');
  assert.equal(api.ACHIEVEMENT_DEFINITIONS.every((item) => item.badgeAssetPath === ''), true,
    'placeholder symbols must remain active until the matching badge PNG is bundled');
  assert.equal(api.isAchievementBadgeAssetPathValid('app/achievements/ach_minesweeper_first_clear.png'), true);
  assert.equal(api.isAchievementBadgeAssetPathValid('app/game_logos/minesweeper.png'), false);
  assert.equal(api.isAchievementBadgeAssetPathValid('app/achievements/ach_minesweeper_first_clear.jpg'), false);
  assert.equal(state.completedSessionCount, 0);
  assert.equal(state.playedGameIds.length, 0);
  assert.equal(api.achievementSummaryForState(state).unlocked, 0);
  assert.equal(api.achievementSummaryForState(state).total, 22);
  assert.equal(api.achievementGroupsForState(state, 'all').length, 7);
  assert.equal(api.achievementGroupsForState(state, 'unlocked').length, 0);
  assert.equal(api.achievementGroupsForState(state, 'inProgress').length, 0);
}

{
  const first = api.applyAchievementEvent(api.emptyAchievementState(), event({
    eventId: 'tetris-1:four-line-clear:1',
    sessionId: 'tetris-1',
    gameId: 'tetris',
    facts: [
      { key: 'maxClearedLines', value: 4 },
      { key: 'totalLines', value: 4 },
      { key: 'level', value: 1 }
    ]
  }));

  assert.equal(first.disposition, 'applied');
  assert.equal(first.newlyUnlocked.length, 1);
  assert.equal(first.newlyUnlocked[0].achievementId, 'tetris.first_tetris');
  assert.equal(progressFor(api, first.state, 'tetris.first_tetris').current, 4);
  assert.equal(progressFor(api, first.state, 'tetris.first_tetris').unlockedAt, 1787617800000);

  const repeated = api.applyAchievementEvent(first.state, event({
    eventId: 'tetris-1:four-line-clear:1',
    sessionId: 'tetris-1',
    gameId: 'tetris',
    facts: [{ key: 'maxClearedLines', value: 4 }]
  }));
  assert.equal(repeated.disposition, 'duplicate');
  assert.equal(repeated.newlyUnlocked.length, 0);
  assert.equal(repeated.state.processedEventIds.length, 1);
}

{
  const lowTile = api.applyAchievementEvent(api.emptyAchievementState(), event({
    eventId: '2048-1:max-tile:1',
    sessionId: '2048-1',
    gameId: 'chicken2048',
    facts: [{ key: 'maxTile', value: 128 }]
  }));
  assert.equal(lowTile.newlyUnlocked.length, 0);
  assert.equal(progressFor(api, lowTile.state, 'chicken2048.reach_256').current, 128);

  const highTile = api.applyAchievementEvent(lowTile.state, event({
    eventId: '2048-1:max-tile:2',
    sessionId: '2048-1',
    gameId: 'chicken2048',
    facts: [{ key: 'maxTile', value: 2048 }]
  }));
  assert.equal(highTile.newlyUnlocked.length, 3);
  assert.equal(progressFor(api, highTile.state, 'chicken2048.reach_256').current, 256);
  assert.equal(progressFor(api, highTile.state, 'chicken2048.reach_1024').current, 1024);
  assert.equal(progressFor(api, highTile.state, 'chicken2048.reach_2048').current, 2048);

  const lowerTileAgain = api.applyAchievementEvent(highTile.state, event({
    eventId: '2048-2:max-tile:1',
    sessionId: '2048-2',
    gameId: 'chicken2048',
    facts: [{ key: 'maxTile', value: 256 }]
  }));
  assert.equal(progressFor(api, lowerTileAgain.state, 'chicken2048.reach_2048').current, 2048,
    'an unlocked high-water mark must never regress');
  assert.equal(lowerTileAgain.newlyUnlocked.length, 0);
}

{
  const result = api.applyAchievementEvent(api.emptyAchievementState(), event({
    eventId: 'rps-battle-1:session-end:1',
    sessionId: 'rps-battle-1',
    gameId: 'rpsBattle',
    type: 'sessionEnd',
    facts: [
      { key: 'won', value: 1 },
      { key: 'supportWon', value: 1 },
      { key: 'score', value: 120 }
    ]
  }));
  const unlockedIds = result.newlyUnlocked.map((item) => item.achievementId).sort();
  assert.equal(result.state.completedSessionCount, 1);
  assert.equal(result.state.playedGameIds.length, 1);
  assert.equal(result.state.playedGameIds[0], 'rpsBattle');
  assert.equal(unlockedIds.join(','), [
    'global.first_settlement',
    'rpsBattle.first_battle',
    'rpsBattle.supporter_wins'
  ].join(','));

  const firstSettlement = api.achievementViewItemForState(result.state, 'global.first_settlement');
  const tenSessions = api.achievementViewItemForState(result.state, 'global.complete_ten_sessions');
  const favorite = api.achievementViewItemForState(result.state, 'global.favorite_three');
  const allGroups = api.achievementGroupsForState(result.state, 'all');
  const unlockedGroups = api.achievementGroupsForState(result.state, 'unlocked');
  const inProgressGroups = api.achievementGroupsForState(result.state, 'inProgress');
  const itemCount = allGroups.reduce((count, group) => count + group.items.length, 0);
  assert.equal(api.achievementSummaryForState(result.state).unlocked, 3);
  assert.equal(firstSettlement.status, 'unlocked');
  assert.equal(firstSettlement.isLegacyMigrated, false);
  assert.equal(tenSessions.status, 'inProgress');
  assert.equal(tenSessions.current, 1);
  assert.equal(tenSessions.target, 10);
  assert.equal(favorite.status, 'locked');
  assert.equal(favorite.target, 0);
  assert.equal(allGroups.length, 7);
  assert.equal(itemCount, 22);
  assert.equal(unlockedGroups.length, 2);
  assert.equal(inProgressGroups.length, 1);
  assert.equal(inProgressGroups[0].definition.id, 'global');
}

{
  const perfectRun = api.applyAchievementEvent(api.emptyAchievementState(), event({
    eventId: 'minesweeper-1:session-end',
    sessionId: 'minesweeper-1',
    gameId: 'minesweeper',
    type: 'sessionEnd',
    facts: [
      { key: 'won', value: 1 },
      { key: 'elapsedSec', value: 60 },
      { key: 'manualAllMinesFlagged', value: 1 },
      { key: 'hasEverFlaggedNonMine', value: 0 }
    ]
  }));
  assert.equal(perfectRun.newlyUnlocked.map((item) => item.achievementId).join(','), [
    'global.first_settlement',
    'minesweeper.first_clear',
    'minesweeper.quick_clear',
    'minesweeper.perfect_flags'
  ].join(','), 'the 60-second perfect run should preserve the global-to-game unlock order');
  assert.equal(progressFor(api, perfectRun.state, 'minesweeper.quick_clear').unlockedAt, 1787617800000);
  assert.equal(progressFor(api, perfectRun.state, 'minesweeper.perfect_flags').unlockedAt, 1787617800000);

  const slowWin = api.applyAchievementEvent(api.emptyAchievementState(), event({
    eventId: 'minesweeper-2:session-end',
    sessionId: 'minesweeper-2',
    gameId: 'minesweeper',
    type: 'sessionEnd',
    facts: [
      { key: 'won', value: 1 },
      { key: 'elapsedSec', value: 61 },
      { key: 'manualAllMinesFlagged', value: 1 },
      { key: 'hasEverFlaggedNonMine', value: 0 }
    ]
  }));
  assert.equal(api.achievementProgressForState(slowWin.state, 'minesweeper.quick_clear'), undefined);
  assert.equal(progressFor(api, slowWin.state, 'minesweeper.perfect_flags').unlockedAt, 1787617800000);

  const wrongFlagWin = api.applyAchievementEvent(api.emptyAchievementState(), event({
    eventId: 'minesweeper-3:session-end',
    sessionId: 'minesweeper-3',
    gameId: 'minesweeper',
    type: 'sessionEnd',
    facts: [
      { key: 'won', value: 1 },
      { key: 'elapsedSec', value: 30 },
      { key: 'manualAllMinesFlagged', value: 1 },
      { key: 'hasEverFlaggedNonMine', value: 1 }
    ]
  }));
  assert.equal(progressFor(api, wrongFlagWin.state, 'minesweeper.quick_clear').unlockedAt, 1787617800000);
  assert.equal(api.achievementProgressForState(wrongFlagWin.state, 'minesweeper.perfect_flags'), undefined);

  const autoFlagWin = api.applyAchievementEvent(api.emptyAchievementState(), event({
    eventId: 'minesweeper-4:session-end',
    sessionId: 'minesweeper-4',
    gameId: 'minesweeper',
    type: 'sessionEnd',
    facts: [
      { key: 'won', value: 1 },
      { key: 'elapsedSec', value: 30 },
      { key: 'manualAllMinesFlagged', value: 0 },
      { key: 'hasEverFlaggedNonMine', value: 0 }
    ]
  }));
  assert.equal(api.achievementProgressForState(autoFlagWin.state, 'minesweeper.perfect_flags'), undefined);

  const devAssistedSession = api.applyAchievementEvent(api.emptyAchievementState(), event({
    eventId: 'minesweeper-dev:session-end',
    sessionId: 'minesweeper-dev',
    gameId: 'minesweeper',
    type: 'sessionEnd',
    facts: [
      { key: 'won', value: 1 },
      { key: 'elapsedSec', value: 30 },
      { key: 'manualAllMinesFlagged', value: 0 },
      { key: 'hasEverFlaggedNonMine', value: 0 }
    ]
  }));
  assert.equal(devAssistedSession.disposition, 'applied');
  assert.equal(progressFor(api, devAssistedSession.state, 'global.first_settlement').unlockedAt, 1787617800000);
  assert.equal(progressFor(api, devAssistedSession.state, 'minesweeper.first_clear').unlockedAt, 1787617800000);
  assert.equal(progressFor(api, devAssistedSession.state, 'minesweeper.quick_clear').unlockedAt, 1787617800000);
  assert.equal(api.achievementProgressForState(devAssistedSession.state, 'minesweeper.perfect_flags'), undefined);

  const failedSession = api.applyAchievementEvent(api.emptyAchievementState(), event({
    eventId: 'minesweeper-5:session-end',
    sessionId: 'minesweeper-5',
    gameId: 'minesweeper',
    type: 'sessionEnd',
    facts: [
      { key: 'won', value: 0 },
      { key: 'elapsedSec', value: 30 },
      { key: 'manualAllMinesFlagged', value: 0 },
      { key: 'hasEverFlaggedNonMine', value: 0 }
    ]
  }));
  assert.equal(failedSession.state.completedSessionCount, 1);
  assert.equal(progressFor(api, failedSession.state, 'global.first_settlement').unlockedAt, 1787617800000);
  assert.equal(api.achievementProgressForState(failedSession.state, 'minesweeper.first_clear'), undefined);
}

{
  let state = api.emptyAchievementState();
  const gameIds = ['rpsBattle', 'freecell', 'minesweeper', 'chicken2048', 'tetris', 'suika'];
  for (let index = 0; index < 10; index += 1) {
    const gameId = gameIds[index % gameIds.length];
    state = api.applyAchievementEvent(state, event({
      eventId: `session-${index}:end:1`,
      sessionId: `session-${index}`,
      gameId: gameId,
      type: 'sessionEnd',
      facts: []
    })).state;
  }
  assert.equal(state.completedSessionCount, 10);
  assert.equal(state.playedGameIds.length, 6);
  assert.equal(progressFor(api, state, 'global.complete_ten_sessions').unlockedAt, 1787617800000);
  assert.equal(progressFor(api, state, 'global.play_six_games').unlockedAt, 1787617800000);
  assert.equal(api.achievementProgressForState(state, 'global.favorite_three'), undefined,
    'disabled non-game achievements must not infer progress from unrelated state');
}

{
  const officialState = api.emptyAchievementState();
  const unofficial = api.applyAchievementEvent(officialState, event({
    eventId: '2048-dev:max-tile:1',
    sessionId: '2048-dev',
    gameId: 'chicken2048',
    isOfficial: false,
    facts: [{ key: 'maxTile', value: 2048 }]
  }));
  assert.equal(unofficial.disposition, 'ignored');
  assert.equal(unofficial.state.processedEventIds.length, 0);
  assert.equal(api.achievementProgressForState(unofficial.state, 'chicken2048.reach_2048'), undefined);
}

{
  const unknownFact = api.applyAchievementEvent(api.emptyAchievementState(), event({
    eventId: 'suika-1:unknown-fact:1',
    sessionId: 'suika-1',
    gameId: 'suika',
    facts: [{ key: 'notRegistered', value: 999 }]
  }));
  assert.equal(unknownFact.disposition, 'applied');
  assert.equal(unknownFact.newlyUnlocked.length, 0);

  const invalidKnownFact = api.applyAchievementEvent(unknownFact.state, event({
    eventId: 'suika-1:invalid-score:1',
    sessionId: 'suika-1',
    gameId: 'suika',
    facts: [{ key: 'score', value: Number.NaN }]
  }));
  assert.equal(invalidKnownFact.disposition, 'ignored');
  assert.equal(invalidKnownFact.state.processedEventIds.length, 1);

  const unknownGame = api.applyAchievementEvent(invalidKnownFact.state, event({
    eventId: 'missing-game:session-end:1',
    sessionId: 'missing-game',
    gameId: 'notRegistered',
    type: 'sessionEnd',
    facts: []
  }));
  assert.equal(unknownGame.disposition, 'ignored');
  assert.equal(unknownGame.state.completedSessionCount, 0);
}

{
  const normalized = api.normalizeAchievementState({
    version: 0,
    progresses: [
      { achievementId: 'tetris.first_tetris', current: 4.9, unlockedAt: 1787617800000.9 },
      { achievementId: 'tetris.first_tetris', current: 0, unlockedAt: 0 },
      { achievementId: '', current: 1, unlockedAt: 1 }
    ],
    processedEventIds: ['event-1', 'event-1', '', 'event-2'],
    completedSessionCount: -4,
    playedGameIds: ['tetris', 'not-a-game', 'tetris']
  });
  assert.equal(normalized.version, 1);
  assert.equal(normalized.progresses.length, 1);
  assert.equal(normalized.progresses[0].current, 4);
  assert.equal(normalized.processedEventIds.join(','), 'event-1,event-2');
  assert.equal(normalized.completedSessionCount, 0);
  assert.equal(normalized.playedGameIds.join(','), 'tetris');
}

{
  let state = api.emptyAchievementState();
  for (let index = 0; index < api.ACHIEVEMENT_PROCESSED_EVENT_LIMIT + 1; index += 1) {
    state = api.applyAchievementEvent(state, event({
      eventId: `suika-queue:${index}`,
      sessionId: `suika-${index}`,
      gameId: 'suika',
      facts: []
    })).state;
  }
  assert.equal(state.processedEventIds.length, api.ACHIEVEMENT_PROCESSED_EVENT_LIMIT);
  assert.equal(state.processedEventIds.includes('suika-queue:0'), false);
  assert.equal(state.processedEventIds.includes('suika-queue:32'), true);
}

{
  const notices = api.achievementNoticeItemsForUnlocks([
    { achievementId: 'global.first_settlement', unlockedAt: 1787617800000 },
    { achievementId: 'rpsBattle.first_battle', unlockedAt: 1787617800000 },
    { achievementId: 'rpsBattle.supporter_wins', unlockedAt: 1787617800000 },
    { achievementId: 'chicken2048.reach_2048', unlockedAt: 1787617800000 }
  ]);
  assert.equal(api.ACHIEVEMENT_NOTICE_INDIVIDUAL_LIMIT, 3);
  assert.equal(notices.length, 4);
  assert.equal(notices[0].noticeId, 'global.first_settlement');
  assert.equal(notices[2].noticeId, 'rpsBattle.supporter_wins');
  assert.equal(notices[0].badgeAssetPath, '');
  assert.equal(notices[3].kind, 'summary');
  assert.equal(notices[3].achievementCount, 4);
  assert.equal(notices[3].noticeLevel, 'highlight');
}

{
  const notices = api.achievementNoticeItemsForUnlocks([
    { achievementId: 'global.first_settlement', unlockedAt: 1787617800000 },
    { achievementId: 'minesweeper.first_clear', unlockedAt: 1787617800000 }
  ]);
  assert.equal(notices.length, 2);
  assert.equal(notices[0].noticeId, 'global.first_settlement');
  assert.equal(notices[1].noticeId, 'minesweeper.first_clear');
}

{
  const notices = api.achievementNoticeItemsForUnlocks([
    { achievementId: 'tetris.first_tetris', unlockedAt: 1787617800000 },
    { achievementId: 'tetris.first_tetris', unlockedAt: 1787617800000 },
    { achievementId: 'global.favorite_three', unlockedAt: 1787617800000 },
    { achievementId: 'notRegistered.missing', unlockedAt: 1787617800000 }
  ]);
  assert.equal(notices.length, 1);
  assert.equal(notices[0].noticeId, 'tetris.first_tetris');
}

console.log('Achievement core and notice tests passed');
