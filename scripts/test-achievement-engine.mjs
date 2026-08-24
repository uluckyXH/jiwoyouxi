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
  const context = { Math: Math, Number: Number };
  vm.runInNewContext(`${runtimeSource}
globalThis.__achievementEngine = {
  ACHIEVEMENT_DEFINITIONS,
  emptySnapshot,
  synchronizeAchievementProgress,
  achievementSummaryForSnapshot,
  achievementGroupsForSnapshot
};
`, context);
  return context.__achievementEngine;
}

function progressFor(snapshot, achievementId) {
  const progress = snapshot.achievements.find((item) => item.achievementId === achievementId);
  assert.ok(progress, `expected progress for ${achievementId}`);
  return progress;
}

function createLegacySnapshot(api) {
  const snapshot = api.emptySnapshot();
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

const api = loadAchievementEngine();

{
  const synchronized = api.synchronizeAchievementProgress(api.emptySnapshot(), 1787531400000);
  const summary = api.achievementSummaryForSnapshot(synchronized);
  const groups = api.achievementGroupsForSnapshot(synchronized, 'all');

  assert.equal(api.ACHIEVEMENT_DEFINITIONS.length, 22, 'the documented first batch should contain 22 achievements');
  assert.equal(groups.length, 7, 'the wall should contain global plus six game groups');
  assert.equal(groups[0].items.length, 4, 'global group should contain its four milestones');
  assert.equal(summary.unlocked, 0, 'a fresh player should not receive a fabricated unlock');
}

{
  const migratedAt = 1787531400000;
  const synchronized = api.synchronizeAchievementProgress(createLegacySnapshot(api), migratedAt);
  const summary = api.achievementSummaryForSnapshot(synchronized);

  assert.equal(summary.unlocked, 4, 'legacy records should unlock only the four reliable global milestones');
  assert.equal(progressFor(synchronized, 'global.first_settlement').unlockedAt, migratedAt);
  assert.equal(progressFor(synchronized, 'global.play_six_games').isLegacyMigrated, true);
  assert.equal(progressFor(synchronized, 'chicken2048.reach_2048').unlockedAt, 0,
    'historical score must not be treated as a 2048 tile achievement');
  assert.equal(progressFor(synchronized, 'tetris.first_tetris').unlockedAt, 0,
    'historical score must not be treated as a four-line clear');
}

{
  const migratedAt = 1787531400000;
  const migrated = api.synchronizeAchievementProgress(createLegacySnapshot(api), migratedAt);
  migrated.favorites = ['rpsBattle'];
  const synchronized = api.synchronizeAchievementProgress(migrated, migratedAt + 1000);

  assert.equal(progressFor(synchronized, 'global.favorite_three').unlockedAt, migratedAt,
    'an unlocked achievement must not be re-locked when current state later changes');
  assert.equal(progressFor(synchronized, 'global.favorite_three').current, 3,
    'monotonic progress should preserve the completed threshold');
}

{
  const snapshot = api.emptySnapshot();
  snapshot.achievementSchemaVersion = 0;
  snapshot.records = [{ gameId: 'rps', highScore: 999999, playCount: 99, lastPlayedAt: 0 }];
  const synchronized = api.synchronizeAchievementProgress(snapshot, 1787531400000);

  assert.equal(api.achievementSummaryForSnapshot(synchronized).unlocked, 0,
    'the legacy rps entry must not leak into the six-game achievement range');
}

{
  const synchronized = api.synchronizeAchievementProgress(createLegacySnapshot(api), 1787531400000);
  const unlockedGroups = api.achievementGroupsForSnapshot(synchronized, 'unlocked');
  const inProgressGroups = api.achievementGroupsForSnapshot(synchronized, 'inProgress');
  const inProgressCount = inProgressGroups.reduce((total, group) => total + group.items.length, 0);

  assert.equal(unlockedGroups.length, 1, 'only the global group should have trusted historical unlocks');
  assert.equal(unlockedGroups[0].items.length, 4);
  assert.equal(inProgressGroups.length, 6, 'all game groups should remain visible as pending work');
  assert.equal(inProgressCount, 18, 'the 18 game-specific achievements must remain locked before event integration');
}

console.log('Achievement engine tests passed');
