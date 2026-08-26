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
  achievementRegistryIssues,
  emptyAchievementState,
  normalizeAchievementState,
  applyAchievementEvent,
  achievementProgressForState,
  achievementSummaryForState
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
  assert.equal(state.completedSessionCount, 0);
  assert.equal(state.playedGameIds.length, 0);
  assert.equal(api.achievementSummaryForState(state).unlocked, 0);
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

console.log('Achievement engine tests passed');
