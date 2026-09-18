#!/usr/bin/env node
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';

const root = resolve(import.meta.dirname, '..');
const sources = [
  'entry/src/main/ets/shell/AchievementModule.ets',
  'entry/src/main/ets/shell/GameModule.ets',
  'entry/src/main/ets/design/PlayActivity.ets',
  'entry/src/main/ets/app/CoopStorage.ets',
  'entry/src/main/ets/entryability/EntryAbility.ets'
];
const source = sources.map(file => readFileSync(resolve(root, file), 'utf8')).join('\n')
  .replace(/^import\s+[\s\S]*?;\n/gm, '')
  .replace(/^export default /gm, '').replace(/^export /gm, '');
const persisted = new Map();
const appStorage = new Map();
let preferencesUnavailable = false;
const sandbox = {
  console,
  UIAbility: class {},
  hilog: { info() {}, warn() {}, error() {} },
  ConfigurationConstant: { ColorMode: { COLOR_MODE_DARK: 0, COLOR_MODE_LIGHT: 1, COLOR_MODE_NOT_SET: -1 } },
  AppStorage: { setOrCreate: (key, value) => appStorage.set(key, value) },
  preferences: { getPreferences: async () => {
    if (preferencesUnavailable) throw new Error('Preferences unavailable');
    return {
      get: async (key, fallback) => persisted.get(key) ?? fallback,
      put: async (key, value) => persisted.set(key, value),
      flush: async () => {}
    };
  } }
};
vm.runInNewContext(`${stripTypeScriptTypes(source, { mode: 'transform' })}
this.api = { emptySnapshot, normalizeAppearanceMode, isDarkAppearance, CoopStorage, EntryAbility };
`, sandbox);
const { emptySnapshot, normalizeAppearanceMode, isDarkAppearance, CoopStorage, EntryAbility } = sandbox.api;

assert.equal(emptySnapshot().appearanceMode, 'system', 'fresh installs follow the system');
for (const invalid of [undefined, null, '', 'invalid', 42]) {
  assert.equal(normalizeAppearanceMode(invalid), 'system');
}
for (const systemDark of [true, false]) {
  assert.equal(isDarkAppearance('system', systemDark), systemDark);
  assert.equal(isDarkAppearance('light', systemDark), false, 'manual light ignores system changes');
  assert.equal(isDarkAppearance('dark', systemDark), true, 'manual dark ignores system changes');
}

assert.equal((await CoopStorage.load({})).appearanceMode, 'system');
for (const mode of ['system', 'light', 'dark']) {
  const saved = emptySnapshot();
  saved.appearanceMode = mode;
  saved.favorites = ['tetrisNext'];
  saved.records = [{ gameId: 'tetrisNext', highScore: 1234, playCount: 5, lastPlayedAt: 123456 }];
  assert.equal(await CoopStorage.save({}, saved), true);
  const restored = await CoopStorage.load({});
  assert.equal(restored.appearanceMode, mode, 'all three modes survive a relaunch');
  assert.equal(restored.favorites[0], 'tetrisNext');
  assert.equal(restored.records[0].highScore, 1234, 'theme changes retain game records');
  for (const systemDark of [true, false]) {
    isDarkAppearance(restored.appearanceMode, systemDark);
    await CoopStorage.save({}, restored);
    assert.equal(JSON.parse(persisted.get('snapshot')).appearanceMode, mode,
      'resolving the current palette never replaces the saved preference');
  }
}
for (const legacyMode of ['light', 'dark']) {
  persisted.set('snapshot', JSON.stringify({ ...emptySnapshot(), appearanceMode: legacyMode }));
  assert.equal((await CoopStorage.load({})).appearanceMode, legacyMode, 'existing manual choices are preserved');
}
const legacy = emptySnapshot();
delete legacy.appearanceMode;
persisted.set('snapshot', JSON.stringify(legacy));
assert.equal((await CoopStorage.load({})).appearanceMode, 'system', 'missing legacy preferences follow the system');
persisted.set('snapshot', '{broken');
assert.equal((await CoopStorage.load({})).appearanceMode, 'system');
preferencesUnavailable = true;
assert.equal((await CoopStorage.load({})).appearanceMode, 'system', 'storage failures retain a usable theme');
preferencesUnavailable = false;

const ability = new EntryAbility();
ability.context = { config: { colorMode: 0 } };
ability.onCreate({}, {});
assert.equal(appStorage.get('coop.systemDark'), true, 'cold launch publishes system dark before the page mounts');
ability.onConfigurationUpdate({ colorMode: 1 });
assert.equal(appStorage.get('coop.systemDark'), false, 'live system changes update the UI state');
ability.onConfigurationUpdate({ colorMode: 0 });
ability.onConfigurationUpdate({ fontSizeScale: 1.2 });
ability.onConfigurationUpdate({ colorMode: -1 });
assert.equal(appStorage.get('coop.systemDark'), true, 'unrelated or unspecified configuration changes do not flash light');
ability.onBackground();
ability.context.config.colorMode = 1;
ability.onForeground();
assert.equal(appStorage.get('coop.systemDark'), false, 'foreground refresh catches changes made while backgrounded');
ability.context.config.colorMode = 0;
ability.onForeground();
assert.equal(appStorage.get('coop.systemDark'), true);

console.log('App appearance: system/manual modes, persistence, legacy preferences, cold launch, live updates and foreground refresh passed.');
