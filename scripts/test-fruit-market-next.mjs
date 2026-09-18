#!/usr/bin/env node
// Executes the pure-logic Hypium cases on the host; device/UI behavior still needs HarmonyOS.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { resolve } from 'node:path';
import vm from 'node:vm';
const root = resolve(import.meta.dirname, '..');
const files = [
  'entry/src/main/ets/shell/AchievementModule.ets',
  'entry/src/main/ets/shell/GameModule.ets',
  'entry/src/main/ets/shell/AchievementRegistry.ets',
  'entry/src/main/ets/shell/AchievementFavoriteEvent.ets',
  'entry/src/main/ets/gamesNext/fruitMarket/MarketModel.ets',
  'entry/src/main/ets/gamesNext/fruitMarket/MarketEngine.ets',
  'entry/src/main/ets/gamesNext/fruitMarket/MarketLayout.ets',
  'entry/src/ohosTest/ets/test/fixtures/FruitMarketDense.ets',
  'entry/src/ohosTest/ets/test/FruitMarketNext.test.ets'
];
const source = files.map(file => readFileSync(resolve(root, file), 'utf8')).join('\n')
  .replace(/^import[\s\S]*?;\s*$/gm, '').replace(/^export default /gm, '').replace(/^export /gm, '');
let passed = 0;
const context = {
  console,
  describe: (_name, run) => run(),
  it: (name, _flags, run) => { run(); passed++; console.log(`PASS ${name}`); },
  expect: actual => ({
    assertEqual: expected => assert.equal(actual, expected),
    assertTrue: () => assert.equal(actual, true),
    assertFalse: () => assert.equal(actual, false)
  }),
  TestType: { FUNCTION: 1 }, Size: { SMALLTEST: 2 }, Level: { LEVEL0: 4 }
};
vm.runInNewContext(stripTypeScriptTypes(source, { mode: 'transform' }) + '\nfruitMarketNextTest();', context);
console.log(`\n${passed} pure-logic cases passed. Native UI/audio/device tests are separate.`);
