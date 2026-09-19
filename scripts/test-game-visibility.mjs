#!/usr/bin/env node
// Exercise real Hub selectors, entry guard and achievement/storage adapters.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';

const root = new URL('../entry/src/main/ets/', import.meta.url);
const read = path => readFileSync(new URL(path, root), 'utf8');
const plain = value => JSON.parse(JSON.stringify(value));
function method(source, name) {
  const start = source.search(new RegExp(`^  private ${name}\\(`, 'm'));
  assert.ok(start >= 0, name);
  const end = source.indexOf('\n', start);
  return source.slice(start, source.slice(start, end).endsWith('}') ? end : source.indexOf('\n  }', start) + 4);
}
const hub = read('pages/HubPage.ets');
const files = ['shell/AchievementModule.ets', 'shell/GameModule.ets', 'shell/GameRegistry.ets',
  'shell/AchievementRegistry.ets', 'shell/AchievementEngine.ets', 'shell/AchievementNotice.ets', 'app/CoopStorage.ets'];
const source = files.map(read).join('\n') + '\n' +
  ['HOME_GAME_ORDER', 'HIDDEN_HOME_GAME_IDS'].map(name => hub.match(new RegExp(`const ${name}: string\\[\\] = \\[[\\s\\S]*?\\];`))[0]).join('\n') +
  '\nclass Hub {\n' + ['homeModules', 'favoriteModules', 'recentGames', 'heroGameId'].map(name => method(hub, name)).join('\n') + '\n}' +
  '\nclass Gateway {\n' + method(read('pages/Index.ets'), 'openGame') + '\n}';
const stored = new Map();
const api = vm.runInNewContext(stripTypeScriptTypes(source.replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export /gm, '')) + `\n({
  Hub, Gateway, moduleById, emptySnapshot, emptyAchievementState, normalizeAchievementState, applyAchievementEvent,
  achievementGroupsForState, achievementGroupsForSnapshot, achievementSummaryForState, achievementSummaryForSnapshot,
  achievementViewItemForState, achievementViewItemFor, achievementNoticeItemsForUnlocks, CoopStorage
})`, { console, preferences: { async getPreferences() { return {
  async get(key, fallback) { return stored.get(key) ?? fallback; },
  async put(key, value) { stored.set(key, value); }, async flush() {}
}; } }, CoopMotion: { scenePushDuration: 220 }, Curve: { Friction: 0 } });

const page = new api.Hub();
page.snapshot = api.emptySnapshot();
page.snapshot.favorites = ['tangram', 'bloomLines', 'suikaNext'];
page.snapshot.recent = ['tangram', 'bloomLines'];
page.snapshot.records = [{ gameId: 'tangram', highScore: 6, playCount: 7, lastPlayedAt: 100 }];
const before = JSON.stringify(page.snapshot);
assert.ok(page.homeModules().some(game => game.id === 'bloomLines'));
assert.ok(page.homeModules().every(game => game.id !== 'tangram'));
assert.deepEqual(Array.from(page.favoriteModules(), game => game.id), ['bloomLines', 'suikaNext']);
assert.deepEqual(Array.from(page.recentGames(), game => game.id), ['bloomLines']);
assert.equal(page.heroGameId(), 'bloomLines');
assert.equal(JSON.stringify(page.snapshot), before, 'hiding entries must not prune saved favorites, history or records');
assert.equal(api.moduleById('tangram').id, 'tangram', 'shelved module remains registered');
console.log('PASS 1: Home, favorites, recent and hero exclude Tangram without changing saved data');

const gate = new api.Gateway();
Object.assign(gate, { sceneTransitioning: false, activeGame: 'hub', snapshot: page.snapshot });
gate.openGame('tangram'); // Native methods are deliberately absent: a stale tap must stop before any side effect.
assert.equal(gate.activeGame, 'hub');
assert.equal(gate.sceneTransitioning, false);
Object.assign(gate, { suspendAchievementNotices() {}, recordPlayDay() {}, saveSnapshot() {}, showEntryBadge() {},
  withRecent(snapshot) { return snapshot; }, getUIContext() { return { animateTo(_options, run) { run(); } }; } });
gate.openGame('bloomLines');
assert.equal(gate.activeGame, 'bloomLines');
console.log('PASS 2: Stale Tangram entry is blocked while visible games still launch');

const result = api.applyAchievementEvent(api.emptyAchievementState(), {
  eventId: 'retained:tangram:finish', sessionId: 'retained:tangram', gameId: 'tangram', type: 'sessionEnd',
  occurredAt: 1789794000000, isOfficial: true, facts: [{ key: 'won', value: 1 }, { key: 'collected', value: 6 }]
});
const state = api.normalizeAchievementState(result.state);
const medals = ['tangram.first', 'tangram.three', 'tangram.album'];
assert.ok(medals.every(id => state.progresses.some(p => p.achievementId === id && p.unlockedAt > 0)));
for (const filter of ['all', 'unlocked', 'inProgress']) {
  assert.ok(api.achievementGroupsForState(state, filter).every(group => group.definition.gameId !== 'tangram'));
}
assert.equal(api.achievementSummaryForState(state).total, 25);
assert.equal(api.achievementSummaryForState(state).unlocked, 1, 'retained Tangram medals do not inflate visible completion');
assert.equal(api.achievementViewItemForState(state, 'tangram.first'), undefined);
const notices = api.achievementNoticeItemsForUnlocks(result.newlyUnlocked);
assert.ok(notices.every(notice => notice.gameId !== 'tangram'));
assert.ok(notices.some(notice => notice.achievementIds.includes('global.first_settlement')));
await api.CoopStorage.saveAchievementState({}, state);
assert.deepEqual(plain(await api.CoopStorage.loadAchievementState({})), plain(state));
console.log('PASS 3: Hidden medals survive persistence, but not wall filters, detail, totals or notices');

page.snapshot.achievements = medals.map(achievementId => ({ achievementId, current: 6, unlockedAt: 100,
  notifiedAt: 100, isLegacyMigrated: false }));
for (const filter of ['all', 'unlocked', 'inProgress']) {
  assert.ok(api.achievementGroupsForSnapshot(page.snapshot, filter).every(group => group.definition.gameId !== 'tangram'));
}
assert.equal(api.achievementSummaryForSnapshot(page.snapshot).total, 25);
assert.equal(api.achievementSummaryForSnapshot(page.snapshot).unlocked, 0);
assert.equal(api.achievementViewItemFor(page.snapshot, 'tangram.first'), undefined);
await api.CoopStorage.save({}, page.snapshot);
const restored = await api.CoopStorage.load({});
assert.deepEqual(plain(restored.favorites), plain(page.snapshot.favorites));
assert.deepEqual(plain(restored.records), plain(page.snapshot.records));
assert.deepEqual(plain(restored.recent), plain(page.snapshot.recent));
assert.ok(medals.every(id => restored.achievements.some(p => p.achievementId === id && p.unlockedAt > 0)));
console.log('PASS 4: Legacy wall hides the same game; saved collection and play records survive reload');
