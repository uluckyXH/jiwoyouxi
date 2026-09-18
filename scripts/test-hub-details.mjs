#!/usr/bin/env node
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const root = resolve(import.meta.dirname, '..');
const files = [
  'shell/AchievementModule.ets', 'shell/GameModule.ets', 'shell/AchievementRegistry.ets',
  'shell/AchievementEngine.ets', 'design/AchievementPresentation.ets',
  'design/PlayActivity.ets', 'design/HubLayout.ets', 'app/CoopStorage.ets'
];
const source = files.map(file => readFileSync(resolve(root, 'entry/src/main/ets', file), 'utf8')).join('\n')
  .replace(/^import\s+[\s\S]*?;\n/gm, '').replace(/^export /gm, '');
const stored = new Map();
const context = { console, Date, preferences: { getPreferences: async () => ({
  get: async (key, fallback) => stored.get(key) ?? fallback,
  put: async (key, value) => stored.set(key, value), flush: async () => {}
}) } };
vm.runInNewContext(`${stripTypeScriptTypes(source, { mode: 'transform' })}
this.api = { localPlayDay, normalizePlayDays, playDaysWithLegacyRecords, currentPlayStreak, recentPlayWeek,
  emptyAchievementState, applyAchievementEvent, achievementGroupsForState, achievementGroupRenderKey,
  achievementGroupCountLabel, hubLayout, hubCardStacked, CoopStorage };`, context);
const a = context.api;
const now = new Date(2026, 8, 18, 0, 10).getTime();
const today = a.localPlayDay(now);
assert.equal(a.localPlayDay(new Date(2026, 8, 17, 23, 59).getTime()), today - 1, 'local midnight starts a new play day');
assert.equal(a.localPlayDay(new Date(2026, 2, 9, 0, 10).getTime()) -
  a.localPlayDay(new Date(2026, 2, 8, 0, 10).getTime()), 1, 'DST changes do not create a gap');
assert.equal(a.currentPlayStreak([], now), 0);
assert.equal(a.currentPlayStreak([today], now), 1);
assert.equal(a.currentPlayStreak([today - 2, today - 1], now), 2, 'yesterday streak survives until today ends');
assert.equal(a.currentPlayStreak([today - 3, today - 2], now), 0, 'missing yesterday breaks the streak');
assert.equal(a.currentPlayStreak([today - 4, today - 1, today], now), 2);
assert.equal(a.currentPlayStreak(Array.from({ length: 61 }, (_, i) => today - i), now), 61, 'no artificial 30-day cap');
assert.deepEqual(Array.from(a.normalizePlayDays([today, today, today - 1, NaN, -1, 'bad'])), [today - 1, today]);
const migrated = a.playDaysWithLegacyRecords([today - 4], [
  { lastPlayedAt: new Date(2026, 8, 17, 23).getTime() }, { lastPlayedAt: now }, { lastPlayedAt: 0 }
]);
assert.deepEqual(Array.from(migrated), [today - 4, today - 1, today], 'migration uses only known dates, without invented history');
const week = a.recentPlayWeek([today - 1, today], now);
assert.equal(week.length, 7);
assert.equal(week[0].day, today - 6);
assert.equal(week[6].label, '今天');
assert.equal(week.filter(d => d.played).length, 2);
assert.equal(week.filter(d => d.today).length, 1);
assert.equal((await a.CoopStorage.loadPlayDays({})).length, 0);
await a.CoopStorage.savePlayDays({}, [today - 1, today, today]);
assert.deepEqual(Array.from(await a.CoopStorage.loadPlayDays({})), [today - 1, today]);
await a.CoopStorage.save({}, { records: [], favorites: [], recent: [], soundEnabled: true, hapticEnabled: true,
  appearanceMode: 'system', achievements: [], recentAchievementEventIds: [], achievementSchemaVersion: 1 });
assert.deepEqual(Array.from(await a.CoopStorage.loadPlayDays({})), [today - 1, today], 'saving settings cannot erase play history');
await a.CoopStorage.savePlayDays({}, [today + 1]);
assert.deepEqual(Array.from(await a.CoopStorage.loadPlayDays({})), [today - 1, today, today + 1],
  'a partial in-memory history must not overwrite previously saved days');

const event = { eventId: 'filter:session:1', sessionId: 'session:1', gameId: 'tetris', type: 'sessionEnd',
  occurredAt: now, isOfficial: true, facts: [{ key: 'score', value: 100 }] };
const state = a.applyAchievementEvent(a.emptyAchievementState(), event).state;
const global = filter => a.achievementGroupsForState(state, filter).find(group => group.definition.id === 'global');
const all = global('all'), unlocked = global('unlocked'), inProgress = global('inProgress');
assert.ok(all && unlocked && inProgress);
assert.equal(all.items.length, 4);
assert.deepEqual(Array.from(unlocked.items, item => item.definition.id), ['global.first_settlement']);
assert.equal(inProgress.items.length, 2);
assert.ok(inProgress.items.every(item => item.status === 'inProgress'));
assert.equal(a.achievementGroupCountLabel(unlocked, 'unlocked'), '1 项已解锁');
assert.equal(a.achievementGroupCountLabel(inProgress, 'inProgress'), '2 项进行中');
assert.notEqual(a.achievementGroupRenderKey(all, 'all'), a.achievementGroupRenderKey(unlocked, 'unlocked'),
  'a surviving global group must rebuild after filtering');
const later = a.applyAchievementEvent(state, { ...event, eventId: 'filter:session:2', sessionId: 'session:2' }).state;
const laterGlobal = a.achievementGroupsForState(later, 'all').find(group => group.definition.id === 'global');
assert.notEqual(a.achievementGroupRenderKey(all, 'all'), a.achievementGroupRenderKey(laterGlobal, 'all'),
  'progress updates must not reuse stale rows');

for (const width of [320, 360, 390, 420, 600, 820, 1440]) {
  for (const scale of [1, 1.3, 1.6, 2]) {
    const layout = a.hubLayout(width, 844, undefined, [], scale);
    const stacked = a.hubCardStacked(layout.cardWidth, scale);
    const logoSize = layout.cardWidth < 200 ? 44 : 52;
    const textWidth = layout.cardWidth - (stacked ? 24 : 24 + 8 + logoSize);
    assert.ok(textWidth >= 70 * scale, `five readable title characters at ${width} vp / ${scale}x`);
  }
}
assert.equal(a.hubCardStacked(a.hubLayout(390, 844).cardWidth, 1), false, 'phone cards keep compact artwork beside the title');
console.log(`Hub details (${process.env.TZ ?? 'local'}): play-day persistence/migration, calendar/DST, streaks, global filters, render keys and card text room passed.`);
